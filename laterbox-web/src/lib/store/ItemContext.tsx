'use client';
import { importLocalCaptures } from '../extension/local-import';

import React, { createContext, useContext, useEffect, useState, useMemo, useCallback, ReactNode } from 'react';
import { getSupabaseClient } from '../supabase/client';
import { LaterBoxItem, ItemStatus, InboxFilterType, Collection, Attachment, ItemMetadata } from '../supabase/types';
import { useAuth } from './AuthContext';
import { normalizeUrl, isUrl, extractDomain } from '../utils/url';
import { storeLocalAttachment } from '../utils/local-attachments';
import { itemRow, queueCapture, syncPendingCaptures, isAuthError } from '../utils/pending-captures';
import { uploadWithNotificationHandoff } from '../notifications/client';
import { isActive, isDue, migrateSchedule } from '../utils/schedule';
import { createQueryRecovery } from '../utils/query-recovery';

const LOCAL_ITEMS_KEY = 'laterbox_local_items';
const LOCAL_COLLECTIONS_KEY = 'laterbox_local_collections';
const LOCAL_DELETED_ITEMS_KEY = 'laterbox_local_deleted_items';

export type SyncState = 'synced' | 'syncing' | 'offline' | 'error';

interface ItemContextType {
  items: LaterBoxItem[];
  inboxItems: LaterBoxItem[];
  savedItems: LaterBoxItem[];
  archivedItems: LaterBoxItem[];
  starredItems: LaterBoxItem[];
  deletedItems: LaterBoxItem[];
  filteredInboxItems: LaterBoxItem[];
  collections: Collection[];
  activeFilter: InboxFilterType;
  setActiveFilter: (filter: InboxFilterType) => void;
  loading: boolean;
  syncStatus: SyncState;
  saveItem: (value: string, options?: { id?: string; textSelector?: string; files?: File[]; returnAt?: string | null; type?: string }) => Promise<LaterBoxItem>;
  now: Date;
  reschedule: (id: string, returnAt: string | null) => Promise<void>;
  setFavorite: (id: string, favorite: boolean) => Promise<void>;
  setStatus: (id: string, status: ItemStatus) => Promise<void>;
  keepItem: (id: string) => Promise<void>;
  archiveItem: (id: string) => Promise<void>;
  markUnseen: (id: string) => Promise<void>;
  deleteItem: (id: string) => Promise<void>;
  restoreItem: (id: string) => Promise<void>;
  permanentlyDeleteItem: (id: string) => Promise<void>;
  emptyTrash: () => Promise<void>;
  saveNote: (itemId: string, content: string) => Promise<void>;
  createCollection: (name: string) => Promise<Collection>;
  deleteCollection: (id: string) => Promise<void>;
  addItemToCollection: (collectionId: string, itemId: string, colOverride?: Collection) => Promise<void>;
  removeItemFromCollection: (collectionId: string, itemId: string) => Promise<void>;
  syncNow: () => Promise<void>;
  getItemById: (id: string) => LaterBoxItem | undefined;
  hasDemoItems: boolean;
  clearDemoItems: () => void;
  restoreDemoItems: () => void;
}

const ItemContext = createContext<ItemContextType | undefined>(undefined);

const DEFAULT_GUEST_ITEMS: LaterBoxItem[] = [];

export function ItemProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [items, setItems] = useState<LaterBoxItem[]>([]);
  const [deletedItems, setDeletedItems] = useState<LaterBoxItem[]>([]);
  const [now, setNow] = useState(() => new Date());
  const [collections, setCollections] = useState<Collection[]>([]);
  const [activeFilter, setActiveFilter] = useState<InboxFilterType>('all');
  const [loading, setLoading] = useState(true);
  const [syncStatus, setSyncStatus] = useState<SyncState>('synced');
  const isFetchingRef = React.useRef(false);

  // Load from local storage
  const loadLocalData = useCallback(() => {
    try {
      const stored = localStorage.getItem(`${LOCAL_ITEMS_KEY}_${user?.id || 'guest'}`) || localStorage.getItem(LOCAL_ITEMS_KEY);
      if (stored) {
        const parsed = (JSON.parse(stored) as LaterBoxItem[])
          .filter(item => (item.user_id || null) === (user?.id || null))
          .filter(item => !item.id.startsWith('guest-item-'));
        setItems(parsed.map(migrateSchedule));
      } else {
        setItems([]);
      }
      const storedCols = localStorage.getItem(`${LOCAL_COLLECTIONS_KEY}_${user?.id || 'guest'}`) || localStorage.getItem(LOCAL_COLLECTIONS_KEY);
      if (storedCols) {
        setCollections((JSON.parse(storedCols) as Collection[]).filter(collection => (collection.user_id || null) === (user?.id || null)));
      } else {
        setCollections([]);
      }
      const storedDeleted = localStorage.getItem(`${LOCAL_DELETED_ITEMS_KEY}_${user?.id || 'guest'}`) || localStorage.getItem(LOCAL_DELETED_ITEMS_KEY);
      if (storedDeleted) {
        setDeletedItems(JSON.parse(storedDeleted) as LaterBoxItem[]);
      } else {
        setDeletedItems([]);
      }
    } catch {
      // ignore
    }
  }, [user?.id]);

  // Gracefully handle unrecoverable sync/network failures without destroying user session
  const handleAuthFailure = useCallback(() => {
    loadLocalData();
    setSyncStatus('offline');
    setLoading(false);
  }, [loadLocalData]);

  // Save to local storage
  const saveLocalData = useCallback((newItems: LaterBoxItem[], newCols?: Collection[]) => {
    try {
      localStorage.setItem(`${LOCAL_ITEMS_KEY}_${user?.id || 'guest'}`,  JSON.stringify(newItems));
      if (newCols) {
        localStorage.setItem(`${LOCAL_COLLECTIONS_KEY}_${user?.id || 'guest'}`,  JSON.stringify(newCols));
      }
    } catch {
      // ignore
    }
  }, [user?.id]);

  const saveLocalDeleted = useCallback((newDeleted: LaterBoxItem[]) => {
    try {
      localStorage.setItem(`${LOCAL_DELETED_ITEMS_KEY}_${user?.id || 'guest'}`, JSON.stringify(newDeleted));
    } catch {
      // ignore
    }
  }, [user?.id]);

  useEffect(() => {
    if (user || window.location.origin !== 'http://localhost:8080') return;
    let disposed = false;
    let running = false;
    const importCaptures = async () => {
      if (running || disposed) return;
      running = true;
      try {
        if (await importLocalCaptures() && !disposed) loadLocalData();
      } catch (error) {
        // Unavailable extension is normal; storage/import failures retain the extension outbox.
        console.warn('[local library]', error);
      } finally { running = false; }
    };
    void importCaptures();
    const timer = setInterval(() => void importCaptures(), 3000);
    const refresh = () => { if (!disposed) loadLocalData(); };
    window.addEventListener('storage', refresh);
    return () => { disposed = true; clearInterval(timer); window.removeEventListener('storage', refresh); };
  }, [user, loadLocalData]);

  // Migrate guest items to authenticated user on login and upload to Supabase
  const migrateGuestItems = useCallback(async (userId: string) => {
    try {
      const guestStored = localStorage.getItem(`${LOCAL_ITEMS_KEY}_guest`);
      if (!guestStored) return;
      const guestItems = JSON.parse(guestStored) as LaterBoxItem[];
      // Filter out demo items
      const userItems = guestItems.filter((i) => !i.id.startsWith('guest-item-') && i.content?.user_id !== '');
      if (userItems.length === 0) return;

      const supabase = getSupabaseClient();
      for (const item of userItems) {
        const migrated: LaterBoxItem = {
          ...item,
          user_id: userId,
          updated_at: new Date().toISOString(),
        };
        // Upsert to Supabase
        await supabase.from('items').upsert(itemRow(migrated));
        if (migrated.metadata) {
          await supabase.from('item_metadata').upsert({
            ...migrated.metadata,
            item_id: migrated.id,
            user_id: userId,
            updated_at: new Date().toISOString(),
          });
        }
        if (migrated.note?.content) {
          await supabase.from('item_notes').upsert({
            item_id: migrated.id,
            user_id: userId,
            content: migrated.note.content,
            created_at: migrated.note.created_at || new Date().toISOString(),
            updated_at: new Date().toISOString(),
          });
        }
      }
      // Reset guest storage once migrated
      localStorage.setItem(`${LOCAL_ITEMS_KEY}_guest`, JSON.stringify(guestItems.filter(i => i.content?.user_id === '')));
    } catch (err) {
      console.warn('[ItemContext] Error migrating guest items:', err);
    }
  }, []);

  // Fetch from Supabase
  const fetchData = useCallback(async () => {
    if (!user || !user.id) {
      loadLocalData();
      setSyncStatus('offline');
      setLoading(false);
      return;
    }

    if (isFetchingRef.current) return;
    isFetchingRef.current = true;

    setSyncStatus('syncing');
    try {
      const supabase = getSupabaseClient();

      // Ensure active and valid session before executing cloud operations
      const { data: sessionData } = await supabase.auth.getSession();
      const currentSession = sessionData?.session;
      if (!currentSession) {
        handleAuthFailure();
        return;
      }

      // Pre-hydrate from local storage immediately so items remain visible while syncing
      loadLocalData();

      // Automatically migrate any items saved while in guest mode to user account
      await migrateGuestItems(user.id);

      // Sync any local pending captures safely
      try {
        await syncPendingCaptures(user.id);
      } catch (syncErr: any) {
        console.warn('[ItemContext] Non-fatal sync pending error:', syncErr);
      }

      const recoverQuery = createQueryRecovery(() => supabase.auth.refreshSession());
      const fetchWithRetry: typeof recoverQuery = async query => {
        const result = await recoverQuery(query);
        // Publish/cache only complete snapshots; preserve local data on any query failure.
        if (result.error) throw result.error;
        return result;
      };

      // Fetch items from Supabase with bounded clock skew recovery
      const { data: itemRows } = await fetchWithRetry(() =>
        supabase
          .from('items')
          .select('*')
          .eq('user_id', user.id)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
      );

      // Fetch recently deleted items
      const { data: deletedRows } = await fetchWithRetry(() =>
        supabase
          .from('items')
          .select('*')
          .eq('user_id', user.id)
          .not('deleted_at', 'is', null)
          .order('deleted_at', { ascending: false })
          .limit(100)
      );

      // Fetch metadata
      const { data: metaRows } = await fetchWithRetry(() =>
        supabase
          .from('item_metadata')
          .select('*')
          .eq('user_id', user.id)
      );

      // Fetch notes
      const { data: noteRows } = await fetchWithRetry(() =>
        supabase
          .from('item_notes')
          .select('*')
          .eq('user_id', user.id)
          .is('deleted_at', null)
      );

      // Fetch attachments
      const { data: attachmentRows } = await fetchWithRetry(() =>
        supabase
          .from('attachments')
          .select('*')
          .eq('user_id', user.id)
          .is('deleted_at', null)
      );

      // Fetch collections
      const { data: colRows } = await fetchWithRetry(() =>
        supabase
          .from('collections')
          .select('*')
          .eq('user_id', user.id)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
      );

      // Fetch collection items join
      const { data: colItemRows } = await fetchWithRetry(() =>
        supabase
          .from('collection_items')
          .select('*')
          .eq('user_id', user.id)
          .is('deleted_at', null)
      );

      const colMap = new Map((colRows || []).map((c) => [c.id, c]));
      const itemColsMap = new Map<string, Collection[]>();
      (colItemRows || []).forEach((ci) => {
        const col = colMap.get(ci.collection_id);
        if (col) {
          const list = itemColsMap.get(ci.item_id) || [];
          if (!list.some(existing => existing.id === col.id)) {
            list.push(col);
          }
          itemColsMap.set(ci.item_id, list);
        }
      });

      const metaMap = new Map((metaRows || []).map((m) => [m.item_id, m]));
      const noteMap = new Map((noteRows || []).map((n) => [n.item_id, n]));
      const attachmentMap = new Map<string, Attachment[]>();
      (attachmentRows || []).forEach((att) => {
        const list = attachmentMap.get(att.item_id) || [];
        list.push(att);
        attachmentMap.set(att.item_id, list);
      });

      const cachedItems = JSON.parse(localStorage.getItem(`${LOCAL_ITEMS_KEY}_${user.id}`) || '[]') as LaterBoxItem[];
      const remoteIds = new Set((itemRows || []).map((item) => item.id));

      const mappedItems: LaterBoxItem[] = (itemRows || []).map((item) => {
        const localCached = cachedItems.find(local => local.id === item.id && local.user_id === user.id);
        const remoteCols = itemColsMap.get(item.id) || [];
        const combinedCols = [...remoteCols];
        (localCached?.collections || []).forEach(lc => {
          if (!combinedCols.some(c => c.id === lc.id)) combinedCols.push(lc);
        });

        // Merge remote and local metadata safely so local enrichment is NEVER clobbered by empty remote rows
        const remoteMeta = metaMap.get(item.id);
        const localMeta = localCached?.metadata;
        const mergedMeta: ItemMetadata | null = remoteMeta || localMeta
          ? ({
              ...(localMeta || {}),
              ...(remoteMeta || {}),
              preview_image_url: remoteMeta?.preview_image_url || localMeta?.preview_image_url || null,
              title: remoteMeta?.title || localMeta?.title || null,
              structured_data: remoteMeta?.structured_data || localMeta?.structured_data || null,
              description: remoteMeta?.description || localMeta?.description || null,
              favicon_url: remoteMeta?.favicon_url || localMeta?.favicon_url || null,
            } as ItemMetadata)
          : null;

        // Resolve title: keep enriched local title if remote title is default or generic
        const resolvedTitle =
          item.title && item.title !== 'New Capture' && !item.title.startsWith('http')
            ? item.title
            : (localCached?.title || item.title);

        // Resolve text_content: keep extracted reader content if remote has empty text
        const resolvedTextContent = item.text_content || localCached?.text_content || null;

        return {
          ...migrateSchedule(item),
          title: resolvedTitle,
          text_content: resolvedTextContent,
          metadata: mergedMeta,
          note: noteMap.get(item.id) || localCached?.note || null,
          collections: combinedCols,
          attachments: [...new Map([...(localCached?.attachments || []), ...(attachmentMap.get(item.id) || [])].filter(attachment => !attachment.deleted_at).map(attachment => [attachment.id, attachment])).values()],
        };
      });

      // Preserve newly captured local items that have not yet appeared in remote snapshot
      const pendingLocals = cachedItems.filter(local => !remoteIds.has(local.id) && !local.deleted_at);
      const combinedItems = [...pendingLocals, ...mappedItems];

      // Deduplicate items by ID and URL/text
      const seenIds = new Set<string>();
      const seenKeys = new Set<string>();
      const deduplicated: LaterBoxItem[] = [];

      for (const item of combinedItems) {
        if (seenIds.has(item.id)) continue;
        seenIds.add(item.id);

        const key = item.url ? `url:${item.url}` : item.text_content ? `text:${item.text_content}` : null;
        if (key && seenKeys.has(key)) continue;
        if (key) seenKeys.add(key);

        deduplicated.push(item);
      }

      setItems(deduplicated);
      setCollections(colRows || []);
      saveLocalData(deduplicated, colRows || []);

      if (deletedRows) {
        const mappedDeleted = deletedRows.map((item: any) => ({
          ...migrateSchedule(item),
          metadata: metaMap.get(item.id) || null,
          note: noteMap.get(item.id) || null,
          attachments: attachmentMap.get(item.id) || [],
          collections: itemColsMap.get(item.id) || [],
        }));
        setDeletedItems(mappedDeleted);
        saveLocalDeleted(mappedDeleted);
      }

      setSyncStatus('synced');
    } catch (err) {
      console.warn('[ItemContext] Cloud snapshot failed; retaining cached data:', err);
      handleAuthFailure();
    } finally {
      isFetchingRef.current = false;
      setLoading(false);
    }
  }, [user?.id, loadLocalData, saveLocalData, handleAuthFailure, migrateGuestItems]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Save Item (URL, text, or file attachments)
  const saveItem = async (
    value: string,
    options?: { id?: string; textSelector?: string; files?: File[]; returnAt?: string | null; type?: string }
  ): Promise<LaterBoxItem> => {
    const trimmed = value.trim();
    const files = options?.files || [];

    if (!trimmed && files.length === 0) {
      throw new Error('Enter a URL, some text, or upload an attachment.');
    }

    let normalizedUrl: string | null = null;
    let textContent: string | null = files.length ? trimmed || null : null;

    if (files.length === 0) {
      if (isUrl(trimmed)) {
        normalizedUrl = normalizeUrl(trimmed);
      } else {
        const urlMatch = trimmed.match(/(https?:\/\/[^\s]+)/);
        if (urlMatch) {
          const matchedUrl = urlMatch[0];
          const remainingText = trimmed
            .replace(matchedUrl, '')
            .trim()
            .replace(/^["“”\s]+|["“”\s]+$/g, '');
          if (remainingText.length > 0) {
            const snippet = remainingText.slice(0, 120);
            const encoded = encodeURIComponent(snippet);
            if (matchedUrl.includes(':~:text=')) {
              normalizedUrl = matchedUrl;
            } else if (matchedUrl.includes('#')) {
              normalizedUrl = `${matchedUrl}:~:text=${encoded}`;
            } else {
              normalizedUrl = `${matchedUrl}#:~:text=${encoded}`;
            }
            textContent = remainingText;
          } else {
            normalizedUrl = normalizeUrl(matchedUrl);
          }
        } else {
          textContent = trimmed || null;
        }
      }
    }

    const now = new Date().toISOString();
    const itemId = options?.id || crypto.randomUUID();

    // Deduplication check: do not add if identical URL or text exists in inbox (and no files)
    if (files.length === 0) {
      const existing = items.find(
        (i) =>
          isActive(i) &&
          !i.deleted_at &&
          ((normalizedUrl && i.url === normalizedUrl) || (textContent && i.text_content === textContent))
      );

      if (existing) {
        return existing;
      }
    }

    const domain = normalizedUrl ? extractDomain(normalizedUrl) : null;
    const defaultTitle = files.length > 0
      ? files[0].name
      : domain || textContent?.slice(0, 60) || 'New Capture';

    const itemType = files.length > 0
      ? 'file'
      : normalizedUrl
        ? textContent
          ? 'note'
          : 'link'
        : 'text';

    const userOs = typeof window !== 'undefined'
      ? (() => {
          const ua = window.navigator.userAgent || '';
          const platform = (window.navigator as any).userAgentData?.platform || window.navigator.platform || '';
          const maxTouchPoints = window.navigator.maxTouchPoints || 0;
          if (/iPad|iPhone|iPod/.test(ua) || (platform === 'MacIntel' && maxTouchPoints > 1)) return 'iOS';
          if (/Android/i.test(ua)) return 'Android';
          if (/Win/i.test(ua) || /Win/i.test(platform)) return 'Windows';
          if (/Linux/i.test(ua) || /Linux/i.test(platform)) return 'Linux';
          if (/Mac/i.test(ua) || /Mac/i.test(platform)) return 'macOS';
          return 'Web';
        })()
      : 'Web';

    const initialFavicon = domain ? `https://www.google.com/s2/favicons?domain=${domain}&sz=128` : null;

    const newItem: LaterBoxItem = {
      id: itemId,
      user_id: user?.id || null,
      url: normalizedUrl,
      title: defaultTitle,
      text_content: textContent,
      text_selector: options?.textSelector || null,
      type: options?.type || itemType,
      favorite: false,
      status: 'deferred',
      return_at: options?.returnAt ?? null,
      created_at: now,
      updated_at: now,
      attachments: [],
      metadata: normalizedUrl
        ? {
            item_id: itemId,
            user_id: user?.id || null,
            domain: domain,
            site_name: domain,
            title: domain,
            favicon_url: initialFavicon,
            status: 'pending',
            attempt_count: 0,
            content_type: 'link',
            classification_source: 'web',
            structured_data: JSON.stringify({ source: 'web', os: userOs }),
            created_at: now,
            updated_at: now,
          }
        : null,
    };

    // Commit file bytes locally before reporting capture success, including offline/guest captures.
    newItem.attachments = await Promise.all(files.map(file => storeLocalAttachment(file, itemId, user?.id || null)));

    const updated = [newItem, ...items];
    setItems(updated);
    saveLocalData(updated);
    queueCapture(newItem);

    // ── Enrich URL metadata for ALL users (Pro writes to Supabase; others update local state only) ──
    if (normalizedUrl) {
      const runEnrich = async () => {
        let enrichData: Record<string, unknown> | null = null;

        // 1. Try local Next.js /api/enrich first (fast, reliable)
        try {
          const res = await fetch('/api/enrich', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ url: normalizedUrl }),
          });
          if (res.ok) {
            enrichData = await res.json() as Record<string, unknown>;
          }
        } catch { /* ignore */ }

        if (enrichData && typeof enrichData === 'object') {
          const enrichedTitle = (enrichData.title as string) || defaultTitle;
          const description = (enrichData.description as string) || null;
          const siteName = (enrichData.siteName as string) || (enrichData.site_name as string) || domain;
          const faviconUrl = (enrichData.faviconUrl as string) || (enrichData.favicon_url as string) || initialFavicon;
          const previewImageUrl = (enrichData.previewImageUrl as string) || (enrichData.preview_image_url as string) || null;
          const contentType =
            (enrichData.classification as Record<string, string>)?.contentType ||
            (enrichData.classification as Record<string, string>)?.type ||
            (enrichData.content_type as string) ||
            'link';

          const embedProvider = (enrichData.embedProvider as string) ?? null;
          const embedUrl = (enrichData.embedUrl as string) ?? null;
          const embedHeight = (enrichData.embedHeight as number) ?? null;

          // Real keywords from page — use as tags
          const keywords: string[] = Array.isArray(enrichData.keywords) ? (enrichData.keywords as string[]) : [];

          const markdown = typeof enrichData.markdown === 'string' ? enrichData.markdown : '';
          const htmlContent = typeof enrichData.htmlContent === 'string' ? enrichData.htmlContent : '';
          const textContent = typeof enrichData.textContent === 'string' ? enrichData.textContent : '';
          const author = typeof enrichData.author === 'string' ? enrichData.author : null;
          const publishedTime = typeof enrichData.publishedTime === 'string' ? enrichData.publishedTime : null;
          const readingTimeMinutes = typeof enrichData.readingTimeMinutes === 'number' ? enrichData.readingTimeMinutes : null;

          const structuredData = {
            source: 'web',
            os: userOs,
            ...(keywords.length > 0 ? { tags: keywords } : {}),
            ...(embedProvider ? { embedProvider, embedUrl, embedHeight } : {}),
            ...(author ? { author } : {}),
            ...(publishedTime ? { publishedTime } : {}),
            ...(readingTimeMinutes ? { readingTimeMinutes } : {}),
            ...(markdown ? { markdown } : {}),
            ...(htmlContent ? { htmlContent } : {}),
            ...(textContent ? { textContent } : {}),
          };

          const metaUpdate: Partial<LaterBoxItem['metadata']> = {
            domain: (enrichData.domain as string) || domain,
            site_name: siteName,
            title: enrichedTitle,
            description: description,
            favicon_url: faviconUrl,
            preview_image_url: previewImageUrl,
            content_type: contentType,
            classification_source: 'web',
            structured_data: JSON.stringify(structuredData),
            status: 'enriched',
            enriched_at: new Date().toISOString(),
          };

          const enrichedTextContent = newItem.text_content || markdown || textContent || null;

          let updatedEnrichedItem: LaterBoxItem = {
            ...newItem,
            title: enrichedTitle || newItem.title,
            text_content: enrichedTextContent,
            metadata: { ...newItem.metadata!, ...metaUpdate },
          };

          // Update React state immediately AND persist to local storage for ALL users
          setItems((prev) => {
            const next = prev.map((it) => {
              if (it.id === newItem.id) {
                updatedEnrichedItem = {
                  ...it,
                  title: enrichedTitle || it.title,
                  text_content: enrichedTextContent || it.text_content,
                  metadata: { ...(it.metadata || {}), ...metaUpdate } as LaterBoxItem['metadata'],
                };
                return updatedEnrichedItem;
              }
              return it;
            });
            saveLocalData(next);
            return next;
          });

          // Keep offline sync queue in sync with enriched metadata
          queueCapture(updatedEnrichedItem);

          // Persist to Supabase for logged-in users
          if (user) {
            try {
              const supabase = getSupabaseClient();

              await uploadWithNotificationHandoff(newItem.id, newItem.return_at, async () => {
                const { error: saveError } = await supabase.from('items').upsert(itemRow(updatedEnrichedItem));
                if (saveError) throw saveError;
              });

              await supabase.from('item_metadata').upsert({
                item_id: newItem.id,
                user_id: user.id,
                ...metaUpdate,
                created_at: now,
                updated_at: new Date().toISOString(),
              });

              await syncPendingCaptures(user.id);
            } catch {
              setSyncStatus('error');
            }
          }
        } else if (user) {
          // Enrichment failed — still persist the raw item to Supabase
          try {
            const supabase = getSupabaseClient();
            await uploadWithNotificationHandoff(newItem.id, newItem.return_at, async () => {
              const { error: saveError } = await supabase.from('items').upsert(itemRow(newItem));
              if (saveError) throw saveError;
            });
            await syncPendingCaptures(user.id);
          } catch {
            setSyncStatus('error');
          }
        }
      };

      runEnrich().catch(() => null);
    } else if (user) {
      // No URL (text/file capture) — persist directly
      try {
        const supabase = getSupabaseClient();
        await uploadWithNotificationHandoff(newItem.id, newItem.return_at, async () => {
          const { error: saveError } = await supabase.from('items').upsert(itemRow(newItem));
          if (saveError) throw saveError;
        });
        await syncPendingCaptures(user.id);
      } catch {
        setSyncStatus('error');
      }
    }

    return newItem;
  };

  const safeSyncPending = async (userId: string) => {
    try {
      await syncPendingCaptures(userId);
    } catch (err: any) {
      console.warn('[ItemContext] safeSyncPending warning:', err);
      setSyncStatus('error');
    }
  };

  const setFavorite = async (id: string, favorite: boolean) => {
    const updated = items.map((i) => (i.id === id ? { ...i, favorite, updated_at: new Date().toISOString() } : i));
    setItems(updated);
    saveLocalData(updated);
    const changed = updated.find(item => item.id === id);
    if (changed) queueCapture(changed);

    if (user) {
      await safeSyncPending(user.id);
    }
  };

  const setStatus = async (id: string, status: ItemStatus) => {
    const updated = items.map((i) => (i.id === id ? { ...i, status, updated_at: new Date().toISOString() } : i));
    setItems(updated);
    saveLocalData(updated);
    const changed = updated.find(item => item.id === id);
    if (changed) queueCapture(changed);

    if (user) {
      await safeSyncPending(user.id);
    }
  };

  const reschedule = async (id: string, returnAt: string | null) => {
    const timestamp = new Date().toISOString();
    const updated = items.map(item => item.id === id
      ? { ...item, status: 'deferred' as ItemStatus, return_at: returnAt, updated_at: timestamp } : item);
    setItems(updated); saveLocalData(updated);

    const changed = updated.find(item => item.id === id);
    if (changed) queueCapture(changed);
    if (user) {
      await safeSyncPending(user.id);
    }
  };

  const keepItem = (id: string) => setStatus(id, 'saved');
  const archiveItem = (id: string) => setStatus(id, 'archived');
  const markUnseen = (id: string) => reschedule(id, new Date().toISOString());

  const deleteItem = async (id: string) => {
    const now = new Date().toISOString();
    const deleted = items.find(item => item.id === id);
    if (deleted) {
      const deletedItem = { ...deleted, deleted_at: now, updated_at: now };
      queueCapture(deletedItem);
      setDeletedItems(prev => {
        const next = [deletedItem, ...prev.filter(i => i.id !== id)];
        saveLocalDeleted(next);
        return next;
      });
    }
    const updated = items.filter((i) => i.id !== id);
    setItems(updated);
    saveLocalData(updated);

    if (user) {
      await safeSyncPending(user.id);
    }
  };

  const restoreItem = async (id: string) => {
    const itemToRestore = deletedItems.find(i => i.id === id);
    if (!itemToRestore) return;
    const now = new Date().toISOString();
    const restored: LaterBoxItem = { ...itemToRestore, deleted_at: null, status: 'inbox', updated_at: now };

    setDeletedItems(prev => {
      const next = prev.filter(i => i.id !== id);
      saveLocalDeleted(next);
      return next;
    });

    const newItems = [restored, ...items.filter(i => i.id !== id)];
    setItems(newItems);
    saveLocalData(newItems);

    queueCapture(restored);
    if (user) {
      const supabase = getSupabaseClient();
      await supabase.from('items').update({ deleted_at: null, status: 'inbox', updated_at: now }).eq('id', id);
      await safeSyncPending(user.id);
    }
  };

  const permanentlyDeleteItem = async (id: string) => {
    setDeletedItems(prev => {
      const next = prev.filter(i => i.id !== id);
      saveLocalDeleted(next);
      return next;
    });

    if (user) {
      const supabase = getSupabaseClient();
      await supabase.from('items').delete().eq('id', id).eq('user_id', user.id);
    }
  };

  const emptyTrash = async () => {
    const ids = deletedItems.map(i => i.id);
    setDeletedItems([]);
    saveLocalDeleted([]);

    if (user && ids.length > 0) {
      const supabase = getSupabaseClient();
      await supabase.from('items').delete().in('id', ids).eq('user_id', user.id);
    }
  };

  const saveNote = async (itemId: string, content: string) => {
    const trimmed = content.trim();
    const now = new Date().toISOString();

    const updated = items.map((item) => {
      if (item.id !== itemId) return item;
      return {
        ...item,
        note: trimmed
          ? {
              item_id: itemId,
              user_id: user?.id || null,
              content: trimmed,
              created_at: item.note?.created_at || now,
              updated_at: now,
            }
          : null,
      };
    });

    setItems(updated);
    saveLocalData(updated);

    if (user) {
      const supabase = getSupabaseClient();
      if (trimmed) {
        await supabase.from('item_notes').upsert({
          item_id: itemId,
          user_id: user.id,
          content: trimmed,
          created_at: now,
          updated_at: now,
        });
      } else {
        await supabase.from('item_notes').update({ deleted_at: now }).eq('item_id', itemId);
      }
    }
  };

  const createCollection = async (name: string): Promise<Collection> => {
    const trimmed = name.trim();
    if (!trimmed) {
      throw new Error('Collection name cannot be empty');
    }

    // 1. Check in-memory/state collections (case-insensitive)
    const existing = collections.find(
      (c) => c.name.trim().toLowerCase() === trimmed.toLowerCase() && !c.deleted_at
    );
    if (existing) {
      return existing;
    }

    // 2. Check remote database for matching existing collection
    if (user) {
      const supabase = getSupabaseClient();
      const { data: dbExisting } = await supabase
        .from('collections')
        .select('*')
        .eq('user_id', user.id)
        .ilike('name', trimmed)
        .is('deleted_at', null)
        .maybeSingle();

      if (dbExisting) {
        if (!collections.some((c) => c.id === dbExisting.id)) {
          const merged = [dbExisting, ...collections];
          setCollections(merged);
          saveLocalData(items, merged);
        }
        return dbExisting;
      }
    }

    const now = new Date().toISOString();
    const newCol: Collection = {
      id: crypto.randomUUID(),
      user_id: user?.id || null,
      name: trimmed,
      created_at: now,
      updated_at: now,
    };
    const updated = [newCol, ...collections];
    setCollections(updated);
    saveLocalData(items, updated);

    if (user) {
      const supabase = getSupabaseClient();
      await supabase.from('collections').insert({
        id: newCol.id,
        user_id: user.id,
        name: newCol.name,
        created_at: newCol.created_at,
        updated_at: newCol.updated_at,
      });
    }
    return newCol;
  };

  const deleteCollection = async (id: string) => {
    const now = new Date().toISOString();
    const updated = collections.filter((c) => c.id !== id);
    setCollections(updated);
    saveLocalData(items, updated);

    if (user) {
      const supabase = getSupabaseClient();
      await supabase.from('collections').update({ deleted_at: now }).eq('id', id);
    }
  };

  const addItemToCollection = async (collectionId: string, itemId: string, colOverride?: Collection) => {
    const col = colOverride || collections.find((c) => c.id === collectionId);
    setItems((prev) => {
      const updated = prev.map((i) => {
        if (i.id !== itemId) return i;
        const currentCols = i.collections || [];
        if (col && !currentCols.some((c) => c.id === collectionId)) {
          return { ...i, collections: [...currentCols, col] };
        }
        return i;
      });
      saveLocalData(updated, collections);
      return updated;
    });

    if (user) {
      const supabase = getSupabaseClient();
      await supabase.from('collection_items').upsert({
        collection_id: collectionId,
        item_id: itemId,
        user_id: user.id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    }
  };

  const removeItemFromCollection = async (collectionId: string, itemId: string) => {
    setItems((prev) => {
      const updated = prev.map((i) => {
        if (i.id !== itemId) return i;
        const currentCols = i.collections || [];
        return { ...i, collections: currentCols.filter((c) => c.id !== collectionId) };
      });
      saveLocalData(updated, collections);
      return updated;
    });

    if (user) {
      const supabase = getSupabaseClient();
      await supabase
        .from('collection_items')
        .update({ deleted_at: new Date().toISOString() })
        .eq('collection_id', collectionId)
        .eq('item_id', itemId);
    }
  };

  const getItemById = (id: string) => items.find((i) => i.id === id);

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const tick = () => {
      const current = new Date(); setNow(current);
      const midnight = new Date(current); midnight.setHours(24, 0, 0, 0);
      let deadline = midnight.getTime();
      for (const item of items) {
        const time = item.return_at ? new Date(item.return_at).getTime() : 0;
        if (isActive(item) && time > current.getTime()) deadline = Math.min(deadline, time);
      }
      clearTimeout(timer); timer = setTimeout(tick, Math.max(1, deadline - current.getTime()));
    };
    tick(); window.addEventListener('focus', tick); document.addEventListener('visibilitychange', tick);
    return () => { clearTimeout(timer); window.removeEventListener('focus', tick); document.removeEventListener('visibilitychange', tick); };
  }, [items]);

  const inboxItems = useMemo(() => items.filter(i => isDue(i, now))
    .sort((a, b) => new Date(a.return_at || a.created_at).getTime() - new Date(b.return_at || b.created_at).getTime()), [items, now]);
  const savedItems = useMemo(() => items.filter((i) => i.status === 'saved'), [items]);
  const archivedItems = useMemo(() => items.filter((i) => i.status === 'archived'), [items]);
  const starredItems = useMemo(() => items.filter((i) => i.favorite), [items]);

  const filteredInboxItems = useMemo(() => {
    if (activeFilter === 'all') return inboxItems;
    return inboxItems.filter((item) => {
      switch (activeFilter) {
        case 'starred':
          return item.favorite;
        case 'notes':
          return !item.url || (item.text_content && item.text_content.length > 0);
        case 'articles':
          return item.metadata?.content_type === 'article' || (!item.metadata?.content_type && item.url);
        case 'videos':
          return item.metadata?.content_type === 'video' || (item.url && item.url.includes('youtube.com'));
        case 'music':
          return (
            item.metadata?.content_type === 'music' ||
            (item.url && (item.url.includes('spotify.com') || item.url.includes('soundcloud.com')))
          );
        default:
          return true;
      }
    });
  }, [inboxItems, activeFilter]);

  const hasDemoItems = false;

  const clearDemoItems = useCallback(() => {
    setItems((prev) => {
      const next = prev.filter((item) => !item.id.startsWith('guest-item-'));
      saveLocalData(next);
      return next;
    });
  }, [saveLocalData]);

  const restoreDemoItems = useCallback(() => {
    // No-op: Guest demo items have been removed
  }, []);

  return (
    <ItemContext.Provider
      value={{
        items,
        now,
        reschedule,
        inboxItems,
        savedItems,
        archivedItems,
        starredItems,
        deletedItems,
        filteredInboxItems,
        collections,
        activeFilter,
        setActiveFilter,
        loading,
        syncStatus,
        saveItem,
        setFavorite,
        setStatus,
        keepItem,
        archiveItem,
        markUnseen,
        deleteItem,
        restoreItem,
        permanentlyDeleteItem,
        emptyTrash,
        saveNote,
        createCollection,
        deleteCollection,
        addItemToCollection,
        removeItemFromCollection,
        syncNow: fetchData,
        getItemById,
        hasDemoItems,
        clearDemoItems,
        restoreDemoItems,
      }}
    >
      {children}
    </ItemContext.Provider>
  );
}

export function useItems() {
  const context = useContext(ItemContext);
  if (!context) {
    throw new Error('useItems must be used within an ItemProvider');
  }
  return context;
}
