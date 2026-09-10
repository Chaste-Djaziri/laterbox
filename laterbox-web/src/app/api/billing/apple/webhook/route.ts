import { NextResponse } from 'next/server';
import { decodeNotificationData, verifyAppleNotification } from '@/lib/billing/apple';
import { processAppleNotification } from '@/lib/billing/process-apple';

export const dynamic = 'force-dynamic';

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as { signedPayload?: string };
    if (!body.signedPayload) {
      return NextResponse.json({ error: 'signedPayload is required.' }, { status: 400 });
    }
    const notification = await verifyAppleNotification(body.signedPayload);
    if (!notification.notificationUUID) {
      return NextResponse.json({ error: 'Notification identifier is missing.' }, { status: 400 });
    }
    const decoded = await decodeNotificationData(notification);
    await processAppleNotification(
      notification.notificationUUID,
      String(notification.notificationType || 'UNKNOWN'),
      new Date(notification.signedDate ?? Date.now()).toISOString(),
      decoded.transaction,
      decoded.renewal,
    );
    return new NextResponse(null, { status: 204 });
  } catch (error) {
    console.error('[billing] Apple notification failed', error);
    return NextResponse.json(
      { error: 'Unable to process App Store notification.' },
      { status: 500 },
    );
  }
}
