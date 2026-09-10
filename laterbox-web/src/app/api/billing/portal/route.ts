import { NextResponse } from 'next/server';
import { getBillingAdminClient, getRequestUser, paddleRequest } from '@/lib/billing/server';

type PortalSession = { urls: { general: { overview: string } } };

export async function POST(request: Request) {
  const user = await getRequestUser(request);
  if (!user) return NextResponse.json({ error: 'Authentication required.' }, { status: 401 });

  try {
    const admin = getBillingAdminClient();
    const { data: customer, error } = await admin
      .from('billing_customers')
      .select('customer_id')
      .eq('provider', 'paddle')
      .eq('user_id', user.id)
      .maybeSingle();
    if (error) throw error;
    if (!customer?.customer_id) {
      return NextResponse.json({ error: 'No Paddle subscription found.' }, { status: 404 });
    }

    const session = await paddleRequest<PortalSession>(
      `/customers/${encodeURIComponent(customer.customer_id)}/portal-sessions`,
      { method: 'POST', body: '{}' }
    );
    return NextResponse.json({ url: session.urls.general.overview });
  } catch (error) {
    console.error('[billing] portal session failed', error);
    return NextResponse.json({ error: 'Unable to open subscription management.' }, { status: 503 });
  }
}
