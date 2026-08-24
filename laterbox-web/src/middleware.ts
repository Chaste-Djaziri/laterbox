import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  const url = request.nextUrl;
  const hostname = request.headers.get('host') || '';

  // Exclude static assets, api endpoints, branding, and files with extensions
  if (
    url.pathname.startsWith('/_next') ||
    url.pathname.startsWith('/api') ||
    url.pathname.startsWith('/branding') ||
    url.pathname.startsWith('/downloads') ||
    url.pathname.includes('.')
  ) {
    return NextResponse.next();
  }

  // 1. Docs Subdomain (e.g. docs.laterbox.dev or docs.localhost:3000)
  const isDocsSubdomain = hostname.startsWith('docs.');
  if (isDocsSubdomain) {
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

  // 2. App Subdomain (e.g. app.laterbox.dev or app.localhost:3000)
  const isAppSubdomain = hostname.startsWith('app.');
  if (isAppSubdomain) {
    // Root on app subdomain maps to /inbox
    if (url.pathname === '/') {
      return NextResponse.rewrite(new URL('/inbox', request.url));
    }
    // Redirect docs path on app to docs subdomain
    if (url.pathname === '/docs' || url.pathname === '/docs/') {
      return NextResponse.redirect(new URL('https://docs.laterbox.dev/', request.url), 308);
    }
    if (url.pathname.startsWith('/docs/')) {
      const cleanPath = url.pathname.replace('/docs', '');
      return NextResponse.redirect(new URL(`https://docs.laterbox.dev${cleanPath}`, request.url), 308);
    }
    // All other app routes (/inbox, /library, /search, /settings, /item, /login, /extension) pass through
    return NextResponse.next();
  }

  // 3. Marketing / Apex Domain (laterbox.dev or www.laterbox.dev)
  const isApexDomain = hostname === 'laterbox.dev' || hostname === 'www.laterbox.dev';
  if (isApexDomain) {
    // Canonical SEO Redirect for Docs: laterbox.dev/docs -> docs.laterbox.dev
    if (url.pathname === '/docs' || url.pathname === '/docs/') {
      return NextResponse.redirect(new URL('https://docs.laterbox.dev/', request.url), 308);
    }
    if (url.pathname.startsWith('/docs/')) {
      const slugPath = url.pathname.replace('/docs', '');
      return NextResponse.redirect(new URL(`https://docs.laterbox.dev${slugPath}`, request.url), 308);
    }

    // App routes on apex domain redirect to app.laterbox.dev
    const isAppPath =
      url.pathname.startsWith('/inbox') ||
      url.pathname.startsWith('/library') ||
      url.pathname.startsWith('/search') ||
      url.pathname.startsWith('/settings') ||
      url.pathname.startsWith('/item') ||
      url.pathname.startsWith('/login') ||
      url.pathname.startsWith('/extension');

    if (isAppPath) {
      return NextResponse.redirect(
        new URL(`https://app.laterbox.dev${url.pathname}${url.search}`, request.url),
        307
      );
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
