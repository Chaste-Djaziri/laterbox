import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

// Current build identifier (can be overridden by environment or deployment)
const BUILD_TIME = process.env.BUILD_TIME || new Date().toISOString();
const APP_VERSION = process.env.NEXT_PUBLIC_APP_VERSION || '1.0.0';

export async function GET() {
  return NextResponse.json(
    {
      app: 'laterbox-web',
      version: APP_VERSION,
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
