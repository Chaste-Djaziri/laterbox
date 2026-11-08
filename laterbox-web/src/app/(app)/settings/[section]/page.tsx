// laterbox-web/src/app/(app)/settings/[section]/page.tsx
import { notFound, redirect } from 'next/navigation';
import { SettingsContent } from '@/components/settings/SettingsContent';
import { isSettingsSectionId } from '@/lib/utils/settingsNavigation';

export default async function SettingsSectionPage({
  params,
}: {
  params: Promise<{ section: string }>;
}) {
  const { section } = await params;
  if (section === 'overview') redirect('/settings/account');
  if (!isSettingsSectionId(section)) notFound();
  return <SettingsContent section={section} />;
}
