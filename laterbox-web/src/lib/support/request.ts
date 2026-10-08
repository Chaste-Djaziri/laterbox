export const supportCategories = ['problem', 'help', 'feedback', 'other'] as const;
export type SupportRequest = {
  email: string; category: typeof supportCategories[number]; subject: string;
  message: string; platform: 'ios' | 'android' | 'web'; appVersion: string;
};

export function parseSupportRequest(value: unknown): SupportRequest | null {
  if (!value || typeof value !== 'object') return null;
  const data = value as Record<string, unknown>;
  const fields = ['email', 'category', 'subject', 'message', 'platform'];
  if (fields.some(field => typeof data[field] !== 'string')) return null;
  const email = (data.email as string).trim();
  const subject = (data.subject as string).trim();
  const message = (data.message as string).trim();
  const appVersion = typeof data.appVersion === 'string' ? data.appVersion.trim() : '';
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
      subject.length < 3 || subject.length > 160 || message.length < 10 || message.length > 5000 ||
      !supportCategories.includes(data.category as SupportRequest['category']) ||
      !['ios', 'android', 'web'].includes(data.platform as string) || appVersion.length > 100) return null;
  return { email, subject, message, appVersion, category: data.category as SupportRequest['category'], platform: data.platform as SupportRequest['platform'] };
}
