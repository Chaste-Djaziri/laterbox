import { NextRequest, NextResponse } from 'next/server';

const GITHUB_REPO = 'Chaste-Djaziri/laterbox';

export async function GET(request: NextRequest) {
  let cfEnvToken = '';
  try {
    const { getCloudflareContext } = await import('@opennextjs/cloudflare');
    const cfEnv = getCloudflareContext()?.env as Record<string, any> | undefined;
    cfEnvToken = cfEnv?.GITHUB_TOKEN || cfEnv?.GITHUB_ACCESS_TOKEN || '';
  } catch {
    // Node fallback
  }

  const token =
    request.headers.get('x-github-token') ||
    request.nextUrl.searchParams.get('token') ||
    cfEnvToken ||
    process.env.GITHUB_TOKEN ||
    process.env.GITHUB_ACCESS_TOKEN ||
    process.env.NEXT_PUBLIC_GITHUB_TOKEN ||
    '';

  const authHeader: HeadersInit = token
    ? {
        'Authorization': `Bearer ${token}`,
        'User-Agent': 'LaterBox-Web/1.0',
        'Accept': 'application/vnd.github.v3+json',
      }
    : {
        'User-Agent': 'LaterBox-Web/1.0',
        'Accept': 'application/vnd.github.v3+json',
      };

  try {
    const res = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=30`, {
      headers: authHeader,
      next: { revalidate: 120 }, // Cache 2 min
    });

    if (res.ok) {
      const releases = (await res.json()) as Array<{
        id?: number;
        tag_name: string;
        name?: string;
        draft?: boolean;
        body?: string;
        html_url?: string;
        published_at: string;
        assets: Array<{
          name: string;
          size: number;
          browser_download_url: string;
        }>;
      }>;

      const publishedReleases = Array.isArray(releases)
        ? releases.filter((release) => !release.draft)
        : [];

      if (Array.isArray(publishedReleases) && publishedReleases.length > 0) {
        // Transform all asset download URLs to use the internal laterbox.dev proxy
        const transformedReleases = publishedReleases
          .sort((a, b) => Date.parse(b.published_at) - Date.parse(a.published_at))
          .map((rel) => ({
            id: rel.id,
            tag_name: rel.tag_name,
            name: rel.name || rel.tag_name,
            body: rel.body || '',
            html_url: rel.html_url || `https://github.com/${GITHUB_REPO}/releases/tag/${rel.tag_name}`,
            published_at: rel.published_at,
            assets: (rel.assets || []).map((asset) => ({
              name: asset.name,
              size: asset.size,
              browser_download_url: `/api/download/${encodeURIComponent(asset.name)}`,
            })),
          }));

        return NextResponse.json(transformedReleases, {
          headers: {
            'Cache-Control': 'public, max-age=120, s-maxage=120',
          },
        });
      }

      console.error('GitHub returned no published releases.');
    } else {
      console.error(`GitHub releases request failed: ${res.status} ${res.statusText}`);
    }
  } catch (error) {
    console.error('Failed to fetch releases:', error);
  }

  return NextResponse.json(
    { error: 'Live GitHub release data is currently unavailable.' },
    {
      status: 502,
      headers: {
        'Cache-Control': 'no-store',
      },
    }
  );
}
