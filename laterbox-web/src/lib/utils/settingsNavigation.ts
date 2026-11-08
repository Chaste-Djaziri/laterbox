// laterbox-web/src/lib/utils/settingsNavigation.ts
/** The supported Settings routes, shared by navigation, page routing and breadcrumbs. */
export const SETTINGS_SECTIONS = [
  { id: 'account', label: 'Account & security', title: 'Account & security', description: 'Manage your identity, connected sign-ins, password and account access.', group: 'general', icon: 'user-round' },
  { id: 'preferences', label: 'Schedule & preferences', title: 'Schedule & preferences', description: 'Choose when things return and how LaterBox behaves.', group: 'general', icon: 'calendar-clock' },
  { id: 'notifications', label: 'Notifications', title: 'Notifications', description: 'Manage Inbox reminders and notification delivery.', group: 'general', icon: 'bell' },
  { id: 'sync', label: 'Cloud sync & storage', title: 'Cloud sync & storage', description: 'Review local data, cloud status and manual synchronization.', group: 'data', icon: 'cloud' },
  { id: 'backup', label: 'Backup & restore', title: 'Backup & restore', description: 'Protect your library with an encrypted backup or restore a previous copy.', group: 'data', icon: 'database-backup' },
  { id: 'apps', label: 'Apps & extensions', title: 'Apps & extensions', description: 'Connect a browser extension and find LaterBox on other devices.', group: 'data', icon: 'puzzle' },
  { id: 'billing', label: 'Plans & billing', title: 'Plans & billing', description: 'Review your plan, storage allowance and subscription options.', group: 'more', icon: 'crown' },
  { id: 'updates', label: 'Updates & version', title: 'Updates & version', description: 'Check for the latest web build and apply available updates.', group: 'more', icon: 'refresh-cw' },
  { id: 'legal', label: 'Privacy & legal', title: 'Privacy & legal', description: 'Read LaterBox policies and terms of service.', group: 'more', icon: 'shield-check' },
] as const;

export type SettingsSectionId = (typeof SETTINGS_SECTIONS)[number]['id'];

export function isSettingsSectionId(section: string): section is SettingsSectionId {
  return SETTINGS_SECTIONS.some(entry => entry.id === section);
}

export function getSettingsSection(section: SettingsSectionId) {
  return SETTINGS_SECTIONS.find(entry => entry.id === section)!;
}
