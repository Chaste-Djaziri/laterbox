'use client';
import { getAccessToken, refreshAccessToken } from '../auth/tokens';
import { importLocalCaptures } from '../extension/local-import';

import React, { createContext, useContext, useEffect, useState, useMemo, useCallback, ReactNode } from 'react';
import { getSupabaseClient } from '../supabase/client';
import { LaterBoxItem, ItemStatus, InboxFilterType, Collection, Attachment, ItemMetadata, ItemContent } from '../supabase/types';
import { useAuth } from './AuthContext';
import { useBilling } from './BillingContext';
import { normalizeUrl, isUrl, extractDomain } from '../utils/url';
import { storeLocalAttachment } from '../utils/local-attachments';
import {
  itemRow,
  queueCapture,
  queueHardDelete,
  syncPendingCaptures,
  syncCloudQueue,
  pullCloudChanges,
  pushCloudChanges,
  checkRemoteChangesWeb,
  isAuthError,
} from '../utils/pending-captures';
import { uploadWithNotificationHandoff } from '../notifications/client';
import { isActive, isDue, transitionItemStatus, moveItemToInbox, restoreItemToInbox, scheduleItemReturn } from '../utils/schedule';
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
  pendingPullCount: number;
  pendingPushCount: number;
  isPulling: boolean;
  isPushing: boolean;
  saveItem: (value: string, options?: { id?: string; textSelector?: string; files?: File[]; returnAt?: string | null; type?: string; title?: string; tags?: string[] }) => Promise<LaterBoxItem>;
  now: Date;
  reschedule: (id: string, returnAt: string | null) => Promise<void>;
  setFavorite: (id: string, favorite: boolean) => Promise<void>;
  setStatus: (id: string, status: ItemStatus) => Promise<void>;
  keepItem: (id: string) => Promise<void>;
  archiveItem: (id: string) => Promise<void>;
  markSeen: (id: string) => Promise<void>;
  markUnseen: (id: string) => Promise<void>;
  deleteItem: (id: string) => Promise<void>;
  restoreItem: (id: string) => Promise<void>;
  permanentlyDeleteItem: (id: string) => Promise<void>;
  emptyTrash: () => Promise<void>;
  saveNote: (itemId: string, content: string) => Promise<void>;
  attachFilesToItem: (itemId: string, files: File[]) => Promise<Attachment[]>;
  createCollection: (name: string) => Promise<Collection>;
  deleteCollection: (id: string) => Promise<void>;
  renameCollection: (id: string, name: string) => Promise<void>;
  addItemToCollection: (collectionId: string, itemId: string, colOverride?: Collection) => Promise<void>;
  removeItemFromCollection: (collectionId: string, itemId: string) => Promise<void>;
  syncNow: () => Promise<void>;
  pullChanges: () => Promise<void>;
  pushChanges: () => Promise<void>;
  pullAndPushChanges: () => Promise<void>;
  checkRemoteChanges: () => Promise<void>;
  getItemById: (id: string) => LaterBoxItem | undefined;
  hasDemoItems: boolean;
  clearDemoItems: () => void;
  restoreDemoItems: () => void;
}

const ItemContext = createContext<ItemContextType | undefined>(undefined);

const DEFAULT_GUEST_ITEMS: LaterBoxItem[] = [];

export function ItemProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { isPro } = useBilling();
  const [items, setItems] = useState<LaterBoxItem[]>([]);
  const [deletedItems, setDeletedItems] = useState<LaterBoxItem[]>([]);
  const [now, setNow] = useState(() => new Date());
  const [collections, setCollections] = useState<Collection[]>([]);
  const [activeFilter, setActiveFilter] = useState<InboxFilterType>('all');
  const [loading, setLoading] = useState(true);
  const [syncStatus, setSyncStatus] = useState<SyncState>('synced');
  const [pendingPullCount, setPendingPullCount] = useState(0);
  const remoteCheckVersion = React.useRef(0);
  const [pendingPushCount, setPendingPushCount] = useState(0);
  const [isPulling, setIsPulling] = useState(false);
  const [isPushing, setIsPushing] = useState(false);
  const isFetchingRef = React.useRef(false);

  // Load from local storage
  const loadLocalData = useCallback(() => {
    try {
      const stored = localStorage.getItem(`${LOCAL_ITEMS_KEY}_${user?.id || 'guest'}`) || localStorage.getItem(LOCAL_ITEMS_KEY);
      if (stored) {
        const parsed = (JSON.parse(stored) as LaterBoxItem[])
          .filter(item => (item.user_id || null) === (user?.id || null))
          .filter(item => !item.id.startsWith('guest-item-'));
        setItems(parsed);
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
    // Pro users sync automatically with the cloud; Free users import extension captures into local device storage
    if (user && isPro) return;
    let disposed = false;
    let running = false;
    const importCaptures = async () => {
      if (running || disposed) return;
      running = true;
      try {
        if (await importLocalCaptures(user?.id) && !disposed) loadLocalData();
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
  }, [user, isPro, loadLocalData]);

  // Migrate guest items to authenticated user on login and upload to Supabase
  const migrateGuestItems = useCallback(async (userId: string) => {
    try {
      const guestStored = localStorage.getItem(`${LOCAL_ITEMS_KEY}_guest`);
      const legacyStored = localStorage.getItem(LOCAL_ITEMS_KEY);
      const guestItems = (guestStored ? JSON.parse(guestStored) as LaterBoxItem[] : []).concat(
        legacyStored && !guestStored ? JSON.parse(legacyStored) as LaterBoxItem[] : []
      );
      // Filter out demo items
      const userItems = guestItems.filter((i) => !i.id.startsWith('guest-item-') && i.content?.user_id !== '');
      if (userItems.length === 0) return;

      // Merge into local storage for this authenticated user (preserves items for Free accounts)
      const userKey = `${LOCAL_ITEMS_KEY}_${userId}`;
      const userStored = localStorage.getItem(userKey);
      const currentUserItems = userStored ? (JSON.parse(userStored) as LaterBoxItem[]) : [];
      const userItemIds = new Set(currentUserItems.map(i => i.id));
      const newlyMigrated: LaterBoxItem[] = userItems.map(item => ({
        ...item,
        user_id: userId,
        updated_at: new Date().toISOString(),
      }));
      const mergedLocal = [...currentUserItems, ...newlyMigrated.filter(i => !userItemIds.has(i.id))];
      localStorage.setItem(userKey, JSON.stringify(mergedLocal));

      if (isPro) {
        const supabase = getSupabaseClient();
        for (const item of newlyMigrated) {
          // Upsert to Supabase
          await supabase.from('items').upsert(itemRow(item));
          if (item.metadata) {
            await supabase.from('item_metadata').upsert({
              ...item.metadata,
              item_id: item.id,
              user_id: userId,
              updated_at: new Date().toISOString(),
            });
          }
          if (item.note?.content) {
            await supabase.from('item_notes').upsert({
              item_id: item.id,
              user_id: userId,
              content: item.note.content,
              created_at: item.note.created_at || new Date().toISOString(),
              updated_at: new Date().toISOString(),
            });
          }
        }
      }
      // Reset guest storage once migrated
      localStorage.setItem(`${LOCAL_ITEMS_KEY}_guest`, JSON.stringify(guestItems.filter(i => i.content?.user_id === '')));
    } catch (err) {
      console.warn('[ItemContext] Error migrating guest items:', err);
    }
  }, [isPro]);

  const checkRemoteChanges = useCallback(async () => {
    const version = ++remoteCheckVersion.current;
    if (!user || !user.id || !isPro) {
      setPendingPullCount(0);
      setPendingPushCount(0);
      return;
    }
    try {
      const counts = await checkRemoteChangesWeb(user.id);
      if (version !== remoteCheckVersion.current) return;
      setPendingPullCount(counts.pendingPullCount);
      setPendingPushCount(counts.pendingPushCount);
    } catch {
      // ignore
    }
  }, [user?.id, isPro]);

  const pullChanges = useCallback(async () => {
    if (!user || !user.id || !isPro) return;
    setIsPulling(true);
    setSyncStatus('syncing');
    try {
      const result = await pullCloudChanges(user.id);
      if (result) {
        setItems(result.items);
        setDeletedItems(result.deletedItems);
        setCollections(result.collections);
        setSyncStatus('synced');
      } else {
        handleAuthFailure();
      }
    } catch (err) {
      console.warn('[ItemContext] pullChanges error:', err);
      handleAuthFailure();
    } finally {
      setIsPulling(false);
      void checkRemoteChanges();
    }
  }, [user?.id, isPro, handleAuthFailure, checkRemoteChanges]);

  const pushChanges = useCallback(async () => {
    if (!user || !user.id || !isPro) return;
    setIsPushing(true);
    setSyncStatus('syncing');
    try {
      await pushCloudChanges(user.id);
      setSyncStatus('synced');
    } catch (err) {
      console.warn('[ItemContext] pushChanges error:', err);
      handleAuthFailure();
    } finally {
      setIsPushing(false);
      void checkRemoteChanges();
    }
  }, [user?.id, isPro, handleAuthFailure, checkRemoteChanges]);

  const pullAndPushChanges = useCallback(async () => {
    if (!user || !user.id || !isPro) return;
    setIsPulling(true);
    setIsPushing(true);
    setSyncStatus('syncing');
    try {
      const result = await syncCloudQueue(user.id);
      if (result) {
        setItems(result.items);
        setDeletedItems(result.deletedItems);
        setCollections(result.collections);
        setSyncStatus('synced');
      } else {
        handleAuthFailure();
      }
    } catch (err) {
      console.warn('[ItemContext] pullAndPushChanges error:', err);
      handleAuthFailure();
    } finally {
      setIsPulling(false);
      setIsPushing(false);
      void checkRemoteChanges();
    }
  }, [user?.id, isPro, handleAuthFailure, checkRemoteChanges]);

  // Fetch from Supabase
  const fetchData = useCallback(async () => {
    if (!user || !user.id) {
      loadLocalData();
      setSyncStatus('offline');
      setLoading(false);
      return;
    }

    // For Free users, load and display local data on this device without syncing to cloud
    if (!isPro) {
      loadLocalData();
      await migrateGuestItems(user.id);
      loadLocalData();
      setSyncStatus('offline');
      setLoading(false);
      return;
    }

    if (isFetchingRef.current) return;
    isFetchingRef.current = true;

    setSyncStatus('syncing');
    try {
      // Pre-hydrate from local storage immediately so items remain visible while syncing
      loadLocalData();

      // Automatically migrate any items saved while in guest mode to user account
      await migrateGuestItems(user.id);

      // Migrate any local-only items saved while on Free plan to cloud
      const stored = localStorage.getItem(`${LOCAL_ITEMS_KEY}_${user.id}`);
      if (stored) {
        try {
          const localItems = JSON.parse(stored) as LaterBoxItem[];
          for (const item of localItems) {
            queueCapture(item);
          }
        } catch {}
      }

      // Execute queued pull-before-push cloud sync with timestamp conflict resolution
      const syncResult = await syncCloudQueue(user.id);
      if (syncResult) {
        setItems(syncResult.items);
        setDeletedItems(syncResult.deletedItems);
        setCollections(syncResult.collections);
        setSyncStatus('synced');
      } else {
        handleAuthFailure();
      }
    } catch (err) {
      console.warn('[ItemContext] Cloud snapshot failed; retaining cached data:', err);
      handleAuthFailure();
    } finally {
      isFetchingRef.current = false;
      setLoading(false);
      void checkRemoteChanges();
    }
  }, [user?.id, isPro, loadLocalData, handleAuthFailure, migrateGuestItems, checkRemoteChanges]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useEffect(() => {
    if (!user || !user.id || !isPro) return;
    void checkRemoteChanges();
    const interval = setInterval(() => {
      void checkRemoteChanges();
    }, 15000);
    const onFocus = () => void checkRemoteChanges();
    window.addEventListener('focus', onFocus);
    window.addEventListener('online', onFocus);
    return () => {
      clearInterval(interval);
      window.removeEventListener('focus', onFocus);
      window.removeEventListener('online', onFocus);
    };
  }, [user?.id, isPro, checkRemoteChanges]);

  // Save Item (URL, text, or file attachments)
  const saveItem = async (
    value: string,
    options?: { id?: string; textSelector?: string; files?: File[]; returnAt?: string | null; type?: string; title?: string; tags?: string[] }
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
    const userTitle = options?.title?.trim() || null;
    const initialTags = [...new Set((options?.tags ?? []).map(tag => tag.trim().replace(/^#/, '')).filter(Boolean))].slice(0, 12);

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
      title: userTitle || defaultTitle,
      text_content: textContent,
      text_selector: options?.textSelector || null,
      type: options?.type || itemType,
      favorite: false,
      status: 'deferred',
      return_at: options?.returnAt ?? null,
      inbox_entered_at: null,
      created_at: now,
      updated_at: now,
      attachments: [],
      metadata: normalizedUrl || initialTags.length > 0 || userTitle
        ? {
            item_id: itemId,
            user_id: user?.id || null,
            domain,
            site_name: domain,
            title: userTitle || domain,
            favicon_url: initialFavicon,
            status: 'pending',
            attempt_count: 0,
            content_type: normalizedUrl ? 'link' : (options?.type || 'note'),
            classification_source: 'web',
            structured_data: JSON.stringify({
              source: 'web', os: userOs,
              ...(initialTags.length > 0 ? { tags: initialTags } : {}),
            }),
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
    if (isPro) {
      queueCapture(newItem);
    }

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
          const enrichedTitle = userTitle || (enrichData.title as string) || defaultTitle;
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
            ...((initialTags.length > 0 || keywords.length > 0)
              ? { tags: [...new Set([...initialTags, ...keywords])].slice(0, 24) } : {}),
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

          // Persist to Supabase for logged-in users via queued cloud sync
          if (user) {
            await safeSyncPending(user.id);
          }
        } else if (user) {
          // Enrichment failed — still persist to Supabase via queued cloud sync
          await safeSyncPending(user.id);
        }
      };

      runEnrich().catch(() => null);
    } else if (user) {
      // No URL (text/file capture) — persist directly via queued cloud sync
      await safeSyncPending(user.id);
    }

    return newItem;
  };

  const safeSyncPending = async (userId: string) => {
    if (!isPro) {
      try { await pushCloudChanges(userId, true); }
      catch { setSyncStatus('error'); }
      return;
    }
    try {
      setSyncStatus('syncing');
      const result = await syncCloudQueue(userId);
      if (result) {
        setItems(result.items);
        setDeletedItems(result.deletedItems);
        if (result.collections) setCollections(result.collections);
        setSyncStatus('synced');
      }
    } catch (err: any) {
      console.warn('[ItemContext] safeSyncPending warning:', err);
      setSyncStatus('error');
    } finally {
      void checkRemoteChanges();
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
    const timestamp = new Date().toISOString();
    const updated = items.map((i) => i.id === id ? transitionItemStatus(i, status, timestamp) : i);
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
      ? scheduleItemReturn(item, returnAt, timestamp) : item);
    setItems(updated); saveLocalData(updated);

    const changed = updated.find(item => item.id === id);
    if (changed) queueCapture(changed);
    if (user) {
      await safeSyncPending(user.id);
    }
  };

  const keepItem = (id: string) => setStatus(id, 'saved');
  const archiveItem = (id: string) => setStatus(id, 'archived');
  const markUnseen = async (id: string) => {
    const timestamp = new Date().toISOString();
    const updated = items.map(item => item.id === id ? moveItemToInbox(item, timestamp) : item);
    setItems(updated);
    saveLocalData(updated);
    const changed = updated.find(item => item.id === id);
    if (changed) queueCapture(changed);
    if (user) await safeSyncPending(user.id);
  };

  const markSeen = async (id: string) => {
    const item = items.find(i => i.id === id);
    if (!item || item.status !== 'inbox' || item.seen) return;
    const timestamp = new Date().toISOString();

    let updatedMetadata = item.metadata;
    let structured: any = {};
    if (updatedMetadata?.structured_data) {
      try {
        structured = typeof updatedMetadata.structured_data === 'string'
          ? JSON.parse(updatedMetadata.structured_data)
          : { ...(updatedMetadata.structured_data as any) };
      } catch {}
    }
    structured.seen = true;

    const newMetadata: any = updatedMetadata ? {
      ...updatedMetadata,
      structured_data: typeof updatedMetadata.structured_data === 'string'
        ? JSON.stringify(structured)
        : structured,
      updated_at: timestamp,
    } : {
      item_id: item.id,
      user_id: item.user_id,
      status: 'pending',
      attempt_count: 0,
      structured_data: structured,
      created_at: timestamp,
      updated_at: timestamp,
    };

    const updated = items.map(i => i.id === id ? { ...i, seen: true, metadata: newMetadata, updated_at: timestamp } : i);
    setItems(updated);
    saveLocalData(updated);
    const changed = updated.find(i => i.id === id);
    if (changed) queueCapture(changed);
    if (user) {
      await safeSyncPending(user.id);
    }
  };

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
    const restored = restoreItemToInbox(itemToRestore, now);

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
      queueHardDelete(user.id, id);
      await safeSyncPending(user.id);
    }
  };

  const emptyTrash = async () => {
    const ids = deletedItems.map(i => i.id);
    setDeletedItems([]);
    saveLocalDeleted([]);

    if (user && ids.length > 0) {
      for (const id of ids) {
        queueHardDelete(user.id, id);
      }
      await safeSyncPending(user.id);
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

  const attachFilesToItem = async (itemId: string, files: File[]): Promise<Attachment[]> => {
    if (!files || files.length === 0) return [];
    const newAttachments = await Promise.all(
      files.map((file) => storeLocalAttachment(file, itemId, user?.id || null))
    );
    const updated = items.map((item) => {
      if (item.id !== itemId) return item;
      return {
        ...item,
        attachments: [...(item.attachments || []), ...newAttachments],
      };
    });
    setItems(updated);
    saveLocalData(updated);
    return newAttachments;
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
    if (user && isPro) {
      const supabase = getSupabaseClient();
      const { error: membershipError } = await supabase.from('collection_items')
        .update({ deleted_at: now, updated_at: now }).eq('collection_id', id).eq('user_id', user.id);
      if (membershipError) throw membershipError;
      const { error } = await supabase.from('collections').update({ deleted_at: now, updated_at: now })
        .eq('id', id).eq('user_id', user.id);
      if (error) throw error;
    }
    const updated = collections.filter((c) => c.id !== id);
    const detach = (item: LaterBoxItem) => ({ ...item, collections: item.collections?.filter(c => c.id !== id) });
    const active = items.map(detach);
    const deleted = deletedItems.map(detach);
    setCollections(updated);
    setItems(active);
    setDeletedItems(deleted);
    saveLocalData(active, updated);
    saveLocalDeleted(deleted);
  };

  const renameCollection = async (id: string, name: string) => {
    const trimmed = name.trim();
    if (!trimmed || trimmed.length > 80) throw new Error('Use a collection name between 1 and 80 characters.');
    if (collections.some(c => c.id !== id && c.name.toLowerCase() === trimmed.toLowerCase())) {
      throw new Error('A collection with that name already exists.');
    }
    const now = new Date().toISOString();
    if (user && isPro) {
      const supabase = getSupabaseClient();
      const { error } = await supabase.from('collections').update({ name: trimmed, updated_at: now })
        .eq('id', id).eq('user_id', user.id);
      if (error) throw error;
    }
    const rename = (c: Collection) => c.id === id ? { ...c, name: trimmed, updated_at: now } : c;
    const updated = collections.map(rename);
    const refresh = (item: LaterBoxItem) => ({ ...item, collections: item.collections?.map(rename) });
    const active = items.map(refresh);
    const deleted = deletedItems.map(refresh);
    setCollections(updated); setItems(active); setDeletedItems(deleted);
    saveLocalData(active, updated); saveLocalDeleted(deleted);
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
        markSeen,
        markUnseen,
        deleteItem,
        restoreItem,
        permanentlyDeleteItem,
        emptyTrash,
        saveNote,
        attachFilesToItem,
        createCollection,
        deleteCollection,
        renameCollection,
        addItemToCollection,
        removeItemFromCollection,
        syncNow: pullAndPushChanges,
        pullChanges,
        pushChanges,
        pullAndPushChanges,
        checkRemoteChanges,
        pendingPullCount,
        pendingPushCount,
        isPulling,
        isPushing,
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
