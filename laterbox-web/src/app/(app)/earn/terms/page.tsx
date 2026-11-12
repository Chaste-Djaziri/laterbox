// laterbox-web/src/app/(app)/earn/terms/page.tsx
import {redirect} from 'next/navigation';

// Keep the original authenticated path working, but publish one canonical
// version of Earn terms so eligibility and payout rules cannot diverge.
export default function EarnTermsRedirect() {
  redirect('/earn-terms');
}
