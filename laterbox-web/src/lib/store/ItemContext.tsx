'use client';

import React, { createContext, useContext, useEffect, useState, useMemo, useCallback, ReactNode } from 'react';
import { getSupabaseClient } from '../supabase/client';
import { LaterBoxItem, ItemStatus, InboxFilterType, Collection, Attachment } from '../supabase/types';
import { useAuth } from './AuthContext';
import { normalizeUrl, isUrl, extractDomain } from '../utils/url';
import { uploadAttachmentFile } from '../utils/attachment';

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
  saveItem: (value: string, options?: { id?: string; textSelector?: string; files?: File[] }) => Promise<LaterBoxItem>;
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
  const [items, setItems] = useState<LaterBoxItem[]>([]);
  const [collections, setCollections] = useState<Collection[]>([]);
  const [activeFilter, setActiveFilter] = useState<InboxFilterType>('all');
  const [loading, setLoading] = useState(true);
  const [syncStatus, setSyncStatus] = useState<SyncState>('synced');

  // Load from local storage
  const loadLocalData = useCallback(() => {
    try {
      const stored = localStorage.getItem(LOCAL_ITEMS_KEY);
      if (stored) {
        setItems(JSON.parse(stored));
      }
      const storedCols = localStorage.getItem(LOCAL_COLLECTIONS_KEY);
      if (storedCols) {
        setCollections(JSON.parse(storedCols));
      }
    } catch {
      // ignore
    }
  }, []);

  // Save to local storage
  const saveLocalData = useCallback((newItems: LaterBoxItem[], newCols?: Collection[]) => {
    try {
      localStorage.setItem(LOCAL_ITEMS_KEY, JSON.stringify(newItems));
      if (newCols) {
        localStorage.setItem(LOCAL_COLLECTIONS_KEY, JSON.stringify(newCols));
      }
    } catch {
      // ignore
    }
  }, []);

  // Fetch from Supabase
  const fetchData = useCallback(async () => {
    if (!user) {
      loadLocalData();
      setLoading(false);
      return;
    }

    setSyncStatus('syncing');
    try {
      const supabase = getSupabaseClient();

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
        ...item,
        metadata: metaMap.get(item.id) || null,
        note: noteMap.get(item.id) || null,
        attachments: attachmentMap.get(item.id) || [],
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
  }, [user, loadLocalData, saveLocalData]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Save Item (URL, text, or file attachments)
  const saveItem = async (
    value: string,
    options?: { id?: string; textSelector?: string; files?: File[] }
  ): Promise<LaterBoxItem> => {
    const trimmed = value.trim();
    const files = options?.files || [];

    if (!trimmed && files.length === 0) {
      throw new Error('Enter a URL, some text, or upload an attachment.');
    }

    const isLink = files.length === 0 && isUrl(trimmed);
    const normalizedUrl = isLink ? normalizeUrl(trimmed) : null;
    const textContent = isLink ? null : trimmed || null;
    const now = new Date().toISOString();
    const itemId = options?.id || crypto.randomUUID();

    // Deduplication check: do not add if identical URL or text exists in inbox (and no files)
    if (files.length === 0) {
      const existing = items.find(
        (i) =>
          i.status === 'inbox' &&
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

    const itemType = files.length > 0 ? 'file' : isLink ? 'link' : 'text';

    const newItem: LaterBoxItem = {
      id: itemId,
      user_id: user?.id || null,
      url: normalizedUrl,
      title: defaultTitle,
      text_content: textContent,
      text_selector: options?.textSelector || null,
      type: itemType,
      favorite: false,
      status: 'inbox',
      created_at: now,
      updated_at: now,
      attachments: [],
      metadata: isLink
        ? {
            item_id: itemId,
            user_id: user?.id || null,
            domain: domain,
            site_name: domain,
            title: domain,
            status: 'pending',
            attempt_count: 0,
            content_type: 'link',
            created_at: now,
            updated_at: now,
          }
        : null,
    };

    // Upload files if provided
    let uploadedAttachments: Attachment[] = [];
    if (files.length > 0 && user) {
      try {
        const uploadPromises = files.map((file) =>
          uploadAttachmentFile(file, itemId, user.id)
        );
        uploadedAttachments = await Promise.all(uploadPromises);
        newItem.attachments = uploadedAttachments;
      } catch (err) {
        console.warn('[LaterBox] Attachment upload warning:', err);
      }
    }

    const updated = [newItem, ...items];
    setItems(updated);
    saveLocalData(updated);

    if (user) {
      try {
        const supabase = getSupabaseClient();
        await supabase.from('items').upsert({
          id: newItem.id,
          user_id: user.id,
          url: newItem.url,
          title: newItem.title,
          text_content: newItem.text_content,
          text_selector: newItem.text_selector,
          type: newItem.type,
          favorite: newItem.favorite,
          status: newItem.status,
          created_at: newItem.created_at,
          updated_at: newItem.updated_at,
        });

        // Trigger enrichment via Edge function if it's a URL
        if (isLink && normalizedUrl) {
          supabase.functions
            .invoke('enrich-url', { body: { url: normalizedUrl } })
            .then(async ({ data: enrichData }) => {
              if (enrichData && typeof enrichData === 'object') {
                const metaUpdate: Partial<LaterBoxItem['metadata']> = {
                  domain: enrichData.domain || domain,
                  site_name: enrichData.site_name,
                  title: enrichData.title,
                  description: enrichData.description,
                  favicon_url: enrichData.favicon_url,
                  preview_image_url: enrichData.preview_image_url,
                  content_type: enrichData.classification?.type || 'link',
                  status: 'enriched',
                  enriched_at: new Date().toISOString(),
                };

                await supabase.from('item_metadata').upsert({
                  item_id: newItem.id,
                  user_id: user.id,
                  ...metaUpdate,
                  created_at: now,
                  updated_at: new Date().toISOString(),
                });

                setItems((prev) =>
                  prev.map((it) => (it.id === newItem.id ? { ...it, metadata: { ...it.metadata!, ...metaUpdate } } : it))
                );
              }
            })
            .catch(() => null);
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

    if (user) {
      const supabase = getSupabaseClient();
      await supabase.from('items').update({ favorite, updated_at: new Date().toISOString() }).eq('id', id);
    }
  };

  const setStatus = async (id: string, status: ItemStatus) => {
    const updated = items.map((i) => (i.id === id ? { ...i, status, updated_at: new Date().toISOString() } : i));
    setItems(updated);
    saveLocalData(updated);

    if (user) {
      const supabase = getSupabaseClient();
      await supabase.from('items').update({ status, updated_at: new Date().toISOString() }).eq('id', id);
    }
  };

  const keepItem = (id: string) => setStatus(id, 'saved');
  const archiveItem = (id: string) => setStatus(id, 'archived');
  const markUnseen = (id: string) => setStatus(id, 'inbox');

  const deleteItem = async (id: string) => {
    const now = new Date().toISOString();
    const updated = items.filter((i) => i.id !== id);
    setItems(updated);
    saveLocalData(updated);

    if (user) {
      const supabase = getSupabaseClient();
      await supabase.from('items').update({ deleted_at: now }).eq('id', id);
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

  const addItemToCollection = async (collectionId: string, itemId: string) => {
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

  const inboxItems = useMemo(() => items.filter((i) => i.status === 'inbox'), [items]);
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
