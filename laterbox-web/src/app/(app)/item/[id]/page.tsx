// laterbox-web/src/app/(app)/item/[id]/page.tsx
'use client';

import { use } from 'react';
import { ItemDetailView } from '@/components/item/ItemDetailView';

export default function ItemDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  return <ItemDetailView id={id} />;
}
