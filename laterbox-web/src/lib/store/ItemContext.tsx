'use client';

import React, { createContext, useContext, useEffect, useState, useMemo, useCallback, ReactNode } from 'react';
import { getSupabaseClient } from '../supabase/client';
import { LaterBoxItem, ItemStatus, InboxFilterType, Collection, Attachment } from '../supabase/types';
import { useAuth } from './AuthContext';
import { useBilling } from './BillingContext';
import { normalizeUrl, isUrl, extractDomain } from '../utils/url';
import { storeLocalAttachment } from '../utils/local-attachments';
import { itemRow, queueCapture, syncPendingCaptures } from '../utils/pending-captures';
import { isActive, isDue, migrateSchedule } from '../utils/schedule';

const LOCAL_ITEMS_KEY = 'laterbox_local_items';
const LOCAL_COLLECTIONS_KEY = 'laterbox_local_collections';

export type SyncState = 'synced' | 'syncing' | 'offline' | 'error';

interface ItemContextType {
  items: LaterBoxItem[];
  inboxItems: LaterBoxItem[];
  savedItems: LaterBoxItem[];
  archivedItems: LaterBoxItem[];
  starredItems: LaterBoxItem[];
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
  saveNote: (itemId: string, content: string) => Promise<void>;
  createCollection: (name: string) => Promise<Collection>;
  deleteCollection: (id: string) => Promise<void>;
  addItemToCollection: (collectionId: string, itemId: string) => Promise<void>;
  removeItemFromCollection: (collectionId: string, itemId: string) => Promise<void>;
  syncNow: () => Promise<void>;
  getItemById: (id: string) => LaterBoxItem | undefined;
}

const ItemContext = createContext<ItemContextType | undefined>(undefined);

export function ItemProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { isPro } = useBilling();
  const [items, setItems] = useState<LaterBoxItem[]>([]);
  const [now, setNow] = useState(() => new Date());
  const [collections, setCollections] = useState<Collection[]>([]);
  const [activeFilter, setActiveFilter] = useState<InboxFilterType>('all');
  const [loading, setLoading] = useState(true);
  const [syncStatus, setSyncStatus] = useState<SyncState>('synced');

  // Load from local storage
  const loadLocalData = useCallback(() => {
    try {
      const stored = localStorage.getItem(`${LOCAL_ITEMS_KEY}_${user?.id || 'guest'}`) || localStorage.getItem(LOCAL_ITEMS_KEY);
      if (stored) {
        setItems((JSON.parse(stored) as LaterBoxItem[]).filter(item => (item.user_id || null) === (user?.id || null)).map(migrateSchedule));
      }
      const storedCols = localStorage.getItem(`${LOCAL_COLLECTIONS_KEY}_${user?.id || 'guest'}`) || localStorage.getItem(LOCAL_COLLECTIONS_KEY);
      if (storedCols) {
        setCollections((JSON.parse(storedCols) as Collection[]).filter(collection => (collection.user_id || null) === (user?.id || null)));
      }
    } catch {
      // ignore
    }
  }, [user?.id]);

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

  // Fetch from Supabase
  const fetchData = useCallback(async () => {
    if (!user || !isPro) {
      loadLocalData();
      setSyncStatus('offline');
      setLoading(false);
      return;
    }

    setSyncStatus('syncing');
    try {
      const supabase = getSupabaseClient();

      await syncPendingCaptures(user.id);

      // Fetch items
      const { data: itemRows, error: itemError } = await supabase
        .from('items')
        .select('*')
        .eq('user_id', user.id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (itemError) throw itemError;

      // Fetch metadata
      const { data: metaRows } = await supabase
        .from('item_metadata')
        .select('*')
        .eq('user_id', user.id);

      // Fetch notes
      const { data: noteRows } = await supabase
        .from('item_notes')
        .select('*')
        .eq('user_id', user.id)
        .is('deleted_at', null);

      // Fetch attachments
      const { data: attachmentRows } = await supabase
        .from('attachments')
        .select('*')
        .eq('user_id', user.id)
        .is('deleted_at', null);

      // Fetch collections
      const { data: colRows } = await supabase
        .from('collections')
        .select('*')
        .eq('user_id', user.id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      const metaMap = new Map((metaRows || []).map((m) => [m.item_id, m]));
      const noteMap = new Map((noteRows || []).map((n) => [n.item_id, n]));
      const attachmentMap = new Map<string, Attachment[]>();
      (attachmentRows || []).forEach((att) => {
        const list = attachmentMap.get(att.item_id) || [];
        list.push(att);
        attachmentMap.set(att.item_id, list);
      });

      const mappedItems: LaterBoxItem[] = (itemRows || []).map((item) => ({
        ...migrateSchedule(item),
        metadata: metaMap.get(item.id) || null,
        note: noteMap.get(item.id) || null,
        attachments: attachmentMap.get(item.id) || (JSON.parse(localStorage.getItem(`${LOCAL_ITEMS_KEY}_${user.id}`) || '[]') as LaterBoxItem[]).find(local => local.id === item.id)?.attachments || [],
      }));

      // Deduplicate items by ID and URL/text
      const seenIds = new Set<string>();
      const seenKeys = new Set<string>();
      const deduplicated: LaterBoxItem[] = [];

      for (const item of mappedItems) {
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
      setSyncStatus('synced');
    } catch {
      setSyncStatus('error');
      loadLocalData();
    } finally {
      setLoading(false);
    }
  }, [user, isPro, loadLocalData, saveLocalData]);

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

    if (user && isPro) {
      try {
        const supabase = getSupabaseClient();
        const { error: saveError } = await supabase.from('items').upsert(itemRow(newItem));
        if (saveError) throw saveError;
        await syncPendingCaptures(user.id);

        // Trigger enrichment via fast API & Edge function if it's a URL
        if (normalizedUrl) {
          const enrichUrl = async () => {
            let enrichData: any = null;

            // 1. Try local Next.js /api/enrich first (instant & reliable)
            try {
              const res = await fetch('/api/enrich', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ url: normalizedUrl }),
              });
              if (res.ok) {
                enrichData = await res.json();
              }
            } catch {}

            // 2. Fallback to Supabase Edge Function
            if (!enrichData || !enrichData.title) {
              try {
                const { data } = await supabase.functions.invoke('enrich-url', {
                  body: { url: normalizedUrl },
                });
                if (data && typeof data === 'object') {
                  enrichData = data;
                }
              } catch {}
            }

            if (enrichData && typeof enrichData === 'object') {
              const title = enrichData.title || defaultTitle;
              const description = enrichData.description || null;
              const siteName = enrichData.siteName || enrichData.site_name || domain;
              const faviconUrl = enrichData.faviconUrl || enrichData.favicon_url || initialFavicon;
              const previewImageUrl = enrichData.previewImageUrl || enrichData.preview_image_url || null;
              const contentType =
                enrichData.classification?.contentType ||
                enrichData.classification?.type ||
                enrichData.content_type ||
                'link';

              const metaUpdate: Partial<LaterBoxItem['metadata']> = {
                domain: enrichData.domain || domain,
                site_name: siteName,
                title: title,
                description: description,
                favicon_url: faviconUrl,
                preview_image_url: previewImageUrl,
                content_type: contentType,
                classification_source: 'web',
                structured_data: JSON.stringify({ source: 'web', os: userOs }),
                status: 'enriched',
                enriched_at: new Date().toISOString(),
              };

              // Update item title in items table if previous was generic
              if (title && (newItem.title === domain || newItem.title === 'New Capture')) {
                await supabase
                  .from('items')
                  .update({ title, updated_at: new Date().toISOString() })
                  .eq('id', newItem.id);
              }

              await supabase.from('item_metadata').upsert({
                item_id: newItem.id,
                user_id: user.id,
                ...metaUpdate,
                created_at: now,
                updated_at: new Date().toISOString(),
              });

              setItems((prev) =>
                prev.map((it) =>
                  it.id === newItem.id
                    ? {
                        ...it,
                        title: title || it.title,
                        metadata: { ...it.metadata!, ...metaUpdate },
                      }
                    : it
                )
              );
            }
          };

          enrichUrl().catch(() => null);
        }
      } catch {
        setSyncStatus('error');
      }
    }

    return newItem;
  };

  const setFavorite = async (id: string, favorite: boolean) => {
    const updated = items.map((i) => (i.id === id ? { ...i, favorite, updated_at: new Date().toISOString() } : i));
    setItems(updated);
    saveLocalData(updated);
    const changed = updated.find(item => item.id === id);
    if (changed) queueCapture(changed);

    if (user && isPro) {
      try { await syncPendingCaptures(user.id); } catch { setSyncStatus('error'); }
    }
  };

  const setStatus = async (id: string, status: ItemStatus) => {
    const updated = items.map((i) => (i.id === id ? { ...i, status, updated_at: new Date().toISOString() } : i));
    setItems(updated);
    saveLocalData(updated);
    const changed = updated.find(item => item.id === id);
    if (changed) queueCapture(changed);

    if (user && isPro) {
      try { await syncPendingCaptures(user.id); } catch { setSyncStatus('error'); }
    }
  };

  const reschedule = async (id: string, returnAt: string | null) => {
    const timestamp = new Date().toISOString();
    const updated = items.map(item => item.id === id
      ? { ...item, status: 'deferred' as ItemStatus, return_at: returnAt, updated_at: timestamp } : item);
    setItems(updated); saveLocalData(updated);

    const changed = updated.find(item => item.id === id);
    if (changed) queueCapture(changed);
    if (user && isPro) {
      try { await syncPendingCaptures(user.id); } catch { setSyncStatus('error'); }
    }
  };

  const keepItem = (id: string) => setStatus(id, 'saved');
  const archiveItem = (id: string) => setStatus(id, 'archived');
  const markUnseen = (id: string) => reschedule(id, new Date().toISOString());

  const deleteItem = async (id: string) => {
    const now = new Date().toISOString();
    const deleted = items.find(item => item.id === id);
    if (deleted) queueCapture({ ...deleted, deleted_at: now, updated_at: now });
    const updated = items.filter((i) => i.id !== id);
    setItems(updated);
    saveLocalData(updated);

    if (user && isPro) {
      try { await syncPendingCaptures(user.id); } catch { setSyncStatus('error'); }
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

    if (user && isPro) {
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
    const now = new Date().toISOString();
    const newCol: Collection = {
      id: crypto.randomUUID(),
      user_id: user?.id || null,
      name: name.trim(),
      created_at: now,
      updated_at: now,
    };
    const updated = [newCol, ...collections];
    setCollections(updated);
    saveLocalData(items, updated);

    if (user && isPro) {
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

    if (user && isPro) {
      const supabase = getSupabaseClient();
      await supabase.from('collections').update({ deleted_at: now }).eq('id', id);
    }
  };

  const addItemToCollection = async (collectionId: string, itemId: string) => {
    if (user && isPro) {
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
    if (user && isPro) {
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
        saveNote,
        createCollection,
        deleteCollection,
        addItemToCollection,
        removeItemFromCollection,
        syncNow: fetchData,
        getItemById,
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
