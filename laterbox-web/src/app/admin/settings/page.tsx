// laterbox-web/src/app/admin/settings/page.tsx
import { redirect } from 'next/navigation';

export default function AdminSettingsRedirectPage() {
  redirect('/admin/operations');
}

