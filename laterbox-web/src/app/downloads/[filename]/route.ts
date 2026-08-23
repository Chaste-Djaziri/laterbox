import { NextRequest } from 'next/server';
import { GET as apiDownloadGet } from '@/app/api/download/[filename]/route';

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ filename: string }> }
) {
  return apiDownloadGet(request, context);
}
