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
    const res = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=15`, {
      headers: authHeader,
      next: { revalidate: 300 }, // Cache 5 min
    });

    if (res.ok) {
      const releases = (await res.json()) as Array<{
        tag_name: string;
        name: string;
        published_at: string;
        assets: Array<{
          name: string;
          size: number;
          browser_download_url: string;
        }>;
      }>;

      // Transform all asset download URLs to use the internal laterbox.dev proxy
      const transformedReleases = releases.map((rel) => ({
        tag_name: rel.tag_name,
        name: rel.name || rel.tag_name,
        published_at: rel.published_at,
        assets: (rel.assets || []).map((asset) => ({
          name: asset.name,
          size: asset.size,
          browser_download_url: `/api/download/${encodeURIComponent(asset.name)}`,
        })),
      }));

      return NextResponse.json(transformedReleases, {
        headers: {
          'Cache-Control': 'public, max-age=300, s-maxage=300',
        },
      });
    }
  } catch (error) {
    console.error('Failed to fetch releases:', error);
  }

  // Fallback release list with internal proxy URLs
  return NextResponse.json(
    [
      {
        tag_name: 'v1.0.20',
        name: 'LaterBox v1.0.20',
        published_at: new Date().toISOString(),
        assets: [
          { name: 'laterbox-macos-apple-silicon.dmg', browser_download_url: '/api/download/laterbox-macos-apple-silicon.dmg', size: 26650283 },
          { name: 'laterbox-macos-intel.dmg', browser_download_url: '/api/download/laterbox-macos-intel.dmg', size: 26650283 },
          { name: 'laterbox-macos-installer.pkg', browser_download_url: '/api/download/laterbox-macos-installer.pkg', size: 23386222 },
          { name: 'laterbox-macos-universal.zip', browser_download_url: '/api/download/laterbox-macos-universal.zip', size: 23408107 },
          { name: 'laterbox-ios.ipa', browser_download_url: '/api/download/laterbox-ios.ipa', size: 25415861 },
          { name: 'laterbox-android-release.apk', browser_download_url: '/api/download/laterbox-android-release.apk', size: 66794291 },
          { name: 'laterbox-android.apk', browser_download_url: '/api/download/laterbox-android.apk', size: 66794291 },
          { name: 'laterbox-windows-setup.exe', browser_download_url: '/api/download/laterbox-windows-setup.exe', size: 12863119 },
          { name: 'laterbox-windows-x64.zip', browser_download_url: '/api/download/laterbox-windows-x64.zip', size: 14988560 },
          { name: 'laterbox-linux-x64.tar.gz', browser_download_url: '/api/download/laterbox-linux-x64.tar.gz', size: 12703419 },
          { name: 'laterbox-linux-x64.zip', browser_download_url: '/api/download/laterbox-linux-x64.zip', size: 12715443 },
          { name: 'laterbox-chrome-extension.zip', browser_download_url: '/api/download/laterbox-chrome-extension.zip', size: 41255 },
          { name: 'laterbox-firefox-extension.zip', browser_download_url: '/api/download/laterbox-firefox-extension.zip', size: 41245 },
          { name: 'laterbox-safari-extension.zip', browser_download_url: '/api/download/laterbox-safari-extension.zip', size: 41219 },
        ],
      },
    ],
    {
      headers: {
        'Cache-Control': 'public, max-age=300, s-maxage=300',
      },
    }
  );
}
