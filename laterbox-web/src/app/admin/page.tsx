// laterbox-web/src/app/admin/page.tsx
import { redirect } from 'next/navigation';

export default function AdminIndexPage() {
  redirect('/admin/overview');
}
