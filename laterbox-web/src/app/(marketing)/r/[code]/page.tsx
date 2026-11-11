// laterbox-web/src/app/(marketing)/r/[code]/page.tsx
import { use } from 'react';
import type { Metadata } from 'next';
import { ReferralWelcomePage } from '@/components/marketing/ReferralWelcomePage';

interface PageProps {
  params: Promise<{ code: string }>;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { code } = await params;
  const upperCode = (code || '').toUpperCase();
  return {
    title: `You're invited to LaterBox · Code ${upperCode}`,
    description: `Claim your personal invitation to LaterBox with invite code ${upperCode}. Get free 500 MB cloud storage and universal quick capture.`,
    robots: {
      index: false,
      follow: true,
    },
  };
}

export default function ReferralWelcomeRoute({ params }: PageProps) {
  const { code } = use(params);
  return <ReferralWelcomePage referralCode={code} />;
}
