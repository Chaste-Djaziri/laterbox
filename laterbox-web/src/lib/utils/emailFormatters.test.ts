import test from 'node:test';
import assert from 'node:assert/strict';
import {
  resolveItemPreviewImageUrl,
} from './emailFormatters';
import { LaterBoxItem } from '@/lib/supabase/types';

test('resolveItemPreviewImageUrl prioritizes metadata preview image and sanitizes letterboxed youtube covers', () => {
  const itemWithCover = {
    id: '1',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    title: 'Test',
    type: 'link',
    status: 'inbox',
    metadata: {
      item_id: '1',
      status: 'enriched',
      attempt_count: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      preview_image_url: 'https://img.youtube.com/vi/abc/hqdefault.jpg',
    },
  } as unknown as LaterBoxItem;

  assert.equal(
    resolveItemPreviewImageUrl(itemWithCover),
    'https://img.youtube.com/vi/abc/mqdefault.jpg'
  );

  const itemProtocolRelative = {
    id: '2',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    title: 'Test 2',
    type: 'link',
    status: 'inbox',
    metadata: {
      item_id: '2',
      status: 'enriched',
      attempt_count: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      preview_image_url: '//cdn.example.com/photo.jpg',
    },
  } as unknown as LaterBoxItem;

  assert.equal(
    resolveItemPreviewImageUrl(itemProtocolRelative),
    'https://cdn.example.com/photo.jpg'
  );
});

test('resolveItemPreviewImageUrl derives youtube thumbnail when metadata is missing', () => {
  const itemYouTubeShorts = {
    id: '3',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    title: 'Shorts',
    url: 'https://youtube.com/shorts/xyz123',
    type: 'video',
    status: 'inbox',
  } as unknown as LaterBoxItem;

  assert.equal(
    resolveItemPreviewImageUrl(itemYouTubeShorts),
    'https://img.youtube.com/vi/xyz123/mqdefault.jpg'
  );

  const itemYouTubeWatch = {
    id: '4',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    title: 'Watch',
    url: 'https://www.youtube.com/watch?v=watch123&feature=share',
    type: 'video',
    status: 'inbox',
  } as unknown as LaterBoxItem;

  assert.equal(
    resolveItemPreviewImageUrl(itemYouTubeWatch),
    'https://img.youtube.com/vi/watch123/mqdefault.jpg'
  );
});

test('resolveItemPreviewImageUrl detects direct image urls and attachments', () => {
  const itemDirectImage = {
    id: '5',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    title: 'Direct Image',
    url: 'https://example.com/image.png?size=large',
    type: 'link',
    status: 'inbox',
  } as unknown as LaterBoxItem;

  assert.equal(
    resolveItemPreviewImageUrl(itemDirectImage),
    'https://example.com/image.png?size=large'
  );

  const itemWithAttachment = {
    id: '6',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    title: 'Attachment',
    type: 'file',
    status: 'inbox',
    attachments: [
      {
        id: 'att-1',
        item_id: '6',
        original_file_name: 'doc.pdf',
        file_extension: 'pdf',
        mime_type: 'application/pdf',
        byte_size: 100,
      },
      {
        id: 'att-2',
        item_id: '6',
        original_file_name: 'cover.jpg',
        file_extension: 'jpg',
        mime_type: 'image/jpeg',
        byte_size: 200,
        thumbnail_object_key: 'https://storage.laterbox.dev/thumb/cover.jpg',
      },
    ],
  } as unknown as LaterBoxItem;

  assert.equal(
    resolveItemPreviewImageUrl(itemWithAttachment),
    'https://storage.laterbox.dev/thumb/cover.jpg'
  );
});

test('resolveItemPreviewImageUrl returns null for notes and items without imagery', () => {
  const plainNote = {
    id: '7',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    title: 'My note',
    text_content: 'Remember to buy groceries',
    type: 'note',
    status: 'inbox',
  } as unknown as LaterBoxItem;

  assert.equal(resolveItemPreviewImageUrl(plainNote), null);
});
