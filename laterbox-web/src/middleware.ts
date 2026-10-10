import { clerkMiddleware } from '@clerk/nextjs/server';
import { clerkAuthEnabled, authorizedOrigins } from './lib/auth/config';
import { NextRequest, NextResponse } from 'next/server';

function routeDomain(request: NextRequest) {
  const url = request.nextUrl;
  const hostname = request.headers.get('host') || '';
  const origin = request.headers.get('origin');
  const allowed = authorizedOrigins();
  const isTrustedOrigin = Boolean(
    origin && (allowed.includes(origin) || allowed.some(a => a.replace(/^https?:\/\//, '') === origin.replace(/^https?:\/\//, '')))
  );

  const applyCors = (response: NextResponse) => {
    if (isTrustedOrigin && origin) {
      response.headers.set('Access-Control-Allow-Origin', origin);
      response.headers.set('Access-Control-Allow-Credentials', 'true');
      response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD');
      response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, rsc, next-router-state-tree, next-router-prefetch, next-url');
    }
    return response;
  };

  // Preflight handling for cross-subdomain requests
  if (request.method === 'OPTIONS') {
    if (isTrustedOrigin && origin) {
      return new NextResponse(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': origin,
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With, rsc, next-router-state-tree, next-router-prefetch, next-url',
          'Access-Control-Max-Age': '86400',
        },
      });
    }
  }

  // Exclude static assets, api endpoints, branding, and files with extensions
  if (
    url.pathname.startsWith('/_next') ||
    url.pathname.startsWith('/api') ||
    url.pathname.startsWith('/branding') ||
    url.pathname.startsWith('/downloads') ||
    url.pathname.includes('.')
  ) {
    return applyCors(NextResponse.next());
  }

  // 1. Docs Subdomain (e.g. docs.laterbox.dev or docs.localhost:3000)
  const isDocsSubdomain = hostname.startsWith('docs.');
  if (isDocsSubdomain) {
    if (url.pathname === '/') {
      return applyCors(NextResponse.rewrite(new URL('/docs', request.url)));
    }
    // If accessed as docs.laterbox.dev/docs/slug, redirect cleanly to docs.laterbox.dev/slug
    if (url.pathname === '/docs' || url.pathname === '/docs/') {
      return applyCors(NextResponse.redirect(new URL('/', request.url), 308));
    }
    if (url.pathname.startsWith('/docs/')) {
      const cleanPath = url.pathname.replace('/docs', '');
      return applyCors(NextResponse.redirect(new URL(cleanPath, request.url), 308));
    }
    return applyCors(NextResponse.rewrite(new URL(`/docs${url.pathname}`, request.url)));
  }

  // 2. App Subdomain (e.g. app.laterbox.dev or app.localhost:3000)
  const isAppSubdomain = hostname.startsWith('app.');
  if (isAppSubdomain) {
    // Root on app subdomain maps to /inbox
    if (url.pathname === '/') {
      return applyCors(NextResponse.rewrite(new URL('/inbox', request.url)));
    }
    // Redirect legacy /home to /inbox
    if (url.pathname === '/home') {
      return applyCors(NextResponse.redirect(new URL('/inbox', request.url), 307));
    }
    // In-app downloads aliases (/download or /apps -> /downloads)
    if (url.pathname === '/download' || url.pathname === '/apps') {
      return applyCors(NextResponse.rewrite(new URL('/downloads', request.url)));
    }
    // In-app guide alias (/guide -> /tutorial)
    if (url.pathname === '/guide') {
      return applyCors(NextResponse.rewrite(new URL('/tutorial', request.url)));
    }
    // In-app plans alias (/pricing -> /plans)
    if (url.pathname === '/pricing') {
      return applyCors(NextResponse.rewrite(new URL('/plans', request.url)));
    }
    // Redirect docs path on app to docs subdomain
    if (url.pathname === '/docs' || url.pathname === '/docs/') {
      return applyCors(NextResponse.redirect(new URL('https://docs.laterbox.dev/', request.url), 308));
    }
    if (url.pathname.startsWith('/docs/')) {
      const cleanPath = url.pathname.replace('/docs', '');
      return applyCors(NextResponse.redirect(new URL(`https://docs.laterbox.dev${cleanPath}`, request.url), 308));
    }
    // All other app routes (/inbox, /library, /settings, /plans, /item, /login, /extension, /downloads, /tutorial) pass through
    return applyCors(NextResponse.next());
  }

  // 3. Marketing / Apex Domain (laterbox.dev or www.laterbox.dev)
  const isApexDomain = hostname === 'laterbox.dev' || hostname === 'www.laterbox.dev';
  if (isApexDomain) {
    // Marketing plans alias on apex domain (laterbox.dev/plans -> /pricing)
    if (url.pathname === '/plans') {
      return applyCors(NextResponse.rewrite(new URL('/pricing', request.url)));
    }
    // Canonical SEO Redirect for Docs: laterbox.dev/docs -> docs.laterbox.dev
    if (url.pathname === '/docs' || url.pathname === '/docs/') {
      return applyCors(NextResponse.redirect(new URL('https://docs.laterbox.dev/', request.url), 308));
    }
    if (url.pathname.startsWith('/docs/')) {
      const slugPath = url.pathname.replace('/docs', '');
      return applyCors(NextResponse.redirect(new URL(`https://docs.laterbox.dev${slugPath}`, request.url), 308));
    }

    // App routes on apex domain redirect to app.laterbox.dev
    const isAppPath =
      ['/today', '/upcoming', '/someday'].some(path => url.pathname === path) ||
      url.pathname.startsWith('/inbox') ||
      url.pathname.startsWith('/library') ||
      url.pathname.startsWith('/settings') ||
      url.pathname.startsWith('/help') ||
      url.pathname.startsWith('/downloads') ||
      url.pathname.startsWith('/item') ||
      url.pathname.startsWith('/login') ||
      url.pathname.startsWith('/extension');

    if (isAppPath) {
      return applyCors(NextResponse.redirect(
        new URL(`https://app.laterbox.dev${url.pathname}${url.search}`, request.url),
        307
      ));
    }
  }

  return applyCors(NextResponse.next());
}

const clerkHandler = clerkMiddleware((_auth, request) => routeDomain(request), { authorizedParties: authorizedOrigins() });
export default clerkAuthEnabled ? clerkHandler : routeDomain;

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
};
