// laterbox-web/src/app/(marketing)/r/[code]/page.tsx
import type { Metadata } from 'next';
import { ReferralWelcomePage } from '@/components/marketing/ReferralWelcomePage';
import { getBillingAdminClient } from '@/lib/billing/server';

interface PageProps {
  params: Promise<{ code: string }>;
}

async function getReferrerName(code: string): Promise<string | null> {
  try {
    const cleanCode = (code || '').trim().toLowerCase();
    if (!cleanCode) return null;
    const db = getBillingAdminClient();
    const { data: profile, error: profileError } = await db
      .from('affiliate_profiles')
      .select('user_id')
      .eq('referral_code', cleanCode)
      .maybeSingle();

    if (profileError || !profile?.user_id) return null;

    const { data: userRecord, error: userError } = await db.auth.admin.getUserById(profile.user_id);
    if (userError || !userRecord?.user) return null;

    const meta = userRecord.user.user_metadata || {};
    const fullName = (meta.display_name || meta.full_name || meta.name) as string | undefined;
    if (fullName && fullName.trim()) {
      return fullName.trim();
    }

    if (userRecord.user.email) {
      const emailPrefix = userRecord.user.email.split('@')[0];
      const cleanPrefix = emailPrefix.split(/[._-]/)[0];
      if (cleanPrefix) {
        return cleanPrefix.charAt(0).toUpperCase() + cleanPrefix.slice(1);
      }
    }
    return null;
  } catch {
    return null;
  }
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { code } = await params;
  const upperCode = (code || '').toUpperCase();
  const referrerName = await getReferrerName(code);

  const title = referrerName
    ? `${referrerName} invited you to LaterBox · Code ${upperCode}`
    : `You're invited to LaterBox · Code ${upperCode}`;

  const description = referrerName
    ? `Claim ${referrerName}'s personal invitation to LaterBox with invite code ${upperCode}. Get free 500 MB cloud storage, local-first capture, and 30-day storage trial perks.`
    : `Claim your personal invitation to LaterBox with invite code ${upperCode}. Get free 500 MB cloud storage and universal quick capture.`;

  return {
    title,
    description,
    robots: {
      index: false,
      follow: true,
    },
  };
}

export default async function ReferralWelcomeRoute({ params }: PageProps) {
  const { code } = await params;
  const referrerName = await getReferrerName(code);
  return <ReferralWelcomePage referralCode={code} referrerName={referrerName} />;
}
