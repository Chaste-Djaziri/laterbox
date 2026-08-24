import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  const url = request.nextUrl;
  const hostname = request.headers.get('host') || '';

  // 1. Docs Subdomain (e.g. docs.laterbox.dev or docs.localhost:3000)
  const isDocsSubdomain = hostname.startsWith('docs.');

  if (isDocsSubdomain) {
    // Avoid rewriting static assets, api endpoints, and internal Next.js paths
    if (
      !url.pathname.startsWith('/_next') &&
      !url.pathname.startsWith('/api') &&
      !url.pathname.startsWith('/branding') &&
      !url.pathname.startsWith('/downloads') &&
      !url.pathname.includes('.')
    ) {
      if (url.pathname === '/') {
        return NextResponse.rewrite(new URL('/docs', request.url));
      }
      // If accessed as docs.laterbox.dev/docs/slug, redirect cleanly to docs.laterbox.dev/slug
      if (url.pathname === '/docs' || url.pathname === '/docs/') {
        return NextResponse.redirect(new URL('/', request.url), 308);
      }
      if (url.pathname.startsWith('/docs/')) {
        const cleanPath = url.pathname.replace('/docs', '');
        return NextResponse.redirect(new URL(cleanPath, request.url), 308);
      }
      return NextResponse.rewrite(new URL(`/docs${url.pathname}`, request.url));
    }
  }

  // 2. Canonical SEO Redirect from laterbox.dev/docs to docs.laterbox.dev
  if (!isDocsSubdomain && (hostname === 'laterbox.dev' || hostname === 'www.laterbox.dev')) {
    if (url.pathname === '/docs' || url.pathname === '/docs/') {
      return NextResponse.redirect(new URL('https://docs.laterbox.dev/', request.url), 308);
    }
    if (url.pathname.startsWith('/docs/')) {
      const slugPath = url.pathname.replace('/docs', '');
      return NextResponse.redirect(new URL(`https://docs.laterbox.dev${slugPath}`, request.url), 308);
    }
  }

  // 3. App Subdomain (e.g. app.laterbox.dev or app.localhost:3000)
  const isAppSubdomain = hostname.startsWith('app.');
  if (isAppSubdomain) {
    if (
      !url.pathname.startsWith('/_next') &&
      !url.pathname.startsWith('/api') &&
      !url.pathname.startsWith('/branding') &&
      !url.pathname.includes('.')
    ) {
      if (url.pathname === '/') {
        return NextResponse.rewrite(new URL('/inbox', request.url));
      }
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
