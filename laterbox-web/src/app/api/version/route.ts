import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

import { APP_VERSION, BUILD_TIME, BUILD_NUMBER, MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION } from '@/lib/version';

export async function GET() {
  return NextResponse.json(
    {
      app: 'laterbox-web',
      version: APP_VERSION,
      major: MAJOR_VERSION,
      minor: MINOR_VERSION,
      patch: PATCH_VERSION,
      buildNumber: BUILD_NUMBER,
      buildTime: BUILD_TIME,
      timestamp: Date.now(),
    },
    {
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    }
  );
}
