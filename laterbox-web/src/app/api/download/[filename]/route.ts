import { NextRequest, NextResponse } from 'next/server';

const GITHUB_REPO = 'Chaste-Djaziri/laterbox';

function getMimeType(filename: string): string {
  const ext = filename.split('.').pop()?.toLowerCase();
  switch (ext) {
    case 'dmg':
      return 'application/x-apple-diskimage';
    case 'pkg':
    case 'ipa':
    case 'aab':
      return 'application/octet-stream';
    case 'apk':
      return 'application/vnd.android.package-archive';
    case 'exe':
      return 'application/x-msdownload';
    case 'zip':
      return 'application/zip';
    case 'gz':
    case 'tgz':
      return 'application/gzip';
    default:
      return 'application/octet-stream';
  }
}

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ filename: string }> }
) {
  const { filename } = await context.params;

  if (!filename) {
    return new NextResponse('Filename parameter is required', { status: 400 });
  }

  // Token extraction from all possible runtime environments: Cloudflare context, process.env, headers, query param
  let cfEnvToken = '';
  try {
    const { getCloudflareContext } = await import('@opennextjs/cloudflare');
    const cfEnv = getCloudflareContext()?.env as Record<string, any> | undefined;
    cfEnvToken = cfEnv?.GITHUB_TOKEN || cfEnv?.GITHUB_ACCESS_TOKEN || '';
  } catch {
    // Standard Node / local environment
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
        'User-Agent': 'LaterBox-Direct-Downloader/1.0',
      }
    : {
        'User-Agent': 'LaterBox-Direct-Downloader/1.0',
      };

  const downloadUrl = `https://github.com/${GITHUB_REPO}/releases/latest/download/${filename}`;

  try {
    // 1. If token is available, resolve asset via GitHub Release API for direct binary access
    if (token) {
      try {
        const releaseApiUrl = `https://api.github.com/repos/${GITHUB_REPO}/releases/latest`;
        const relRes = await fetch(releaseApiUrl, {
          headers: {
            ...authHeader,
            'Accept': 'application/vnd.github.v3+json',
          },
        });

        if (relRes.ok) {
          const relData = (await relRes.json()) as {
            assets?: Array<{ id: number; name: string; url: string; size: number }>;
          };

          const matchedAsset = relData.assets?.find(
            (a) => a.name.toLowerCase() === filename.toLowerCase()
          );

          if (matchedAsset) {
            const assetDownloadRes = await fetch(
              `https://api.github.com/repos/${GITHUB_REPO}/releases/assets/${matchedAsset.id}`,
              {
                headers: {
                  ...authHeader,
                  'Accept': 'application/octet-stream',
                },
                redirect: 'follow',
              }
            );

            if (assetDownloadRes.ok && assetDownloadRes.body) {
              const mimeType = getMimeType(filename);
              const resHeaders = new Headers({
                'Content-Type': mimeType,
                'Content-Disposition': `attachment; filename="${filename}"`,
                'Cache-Control': 'public, max-age=3600, s-maxage=3600',
                'Access-Control-Allow-Origin': '*',
              });

              const contentLength = assetDownloadRes.headers.get('content-length');
              if (contentLength) {
                resHeaders.set('Content-Length', contentLength);
              }

              return new NextResponse(assetDownloadRes.body as any, {
                status: 200,
                headers: resHeaders,
              });
            }
          }
        }
      } catch (apiErr) {
        console.warn('GitHub API asset resolution fallback:', apiErr);
      }
    }

    // 2. Direct Release Download URL (Public or authenticated fallback)
    const upstreamRes = await fetch(downloadUrl, {
      headers: {
        ...authHeader,
        'Accept': 'application/octet-stream',
      },
      redirect: 'follow',
    });

    if (!upstreamRes.ok || !upstreamRes.body) {
      // Fallback: direct release tag if latest alias resolves slowly
      const fallbackUrl = `https://github.com/${GITHUB_REPO}/releases/download/v1.0.10/${filename}`;
      const fallbackRes = await fetch(fallbackUrl, {
        headers: {
          ...authHeader,
          'Accept': 'application/octet-stream',
        },
        redirect: 'follow',
      });

      if (!fallbackRes.ok || !fallbackRes.body) {
        // Fallback: 302 redirect directly to GitHub URL
        return NextResponse.redirect(downloadUrl, { status: 302 });
      }

      const mimeType = getMimeType(filename);
      const resHeaders = new Headers({
        'Content-Type': mimeType,
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Cache-Control': 'public, max-age=3600, s-maxage=3600',
        'Access-Control-Allow-Origin': '*',
      });

      const contentLength = fallbackRes.headers.get('content-length');
      if (contentLength) {
        resHeaders.set('Content-Length', contentLength);
      }

      return new NextResponse(fallbackRes.body as any, {
        status: 200,
        headers: resHeaders,
      });
    }

    const mimeType = getMimeType(filename);
    const resHeaders = new Headers({
      'Content-Type': mimeType,
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Cache-Control': 'public, max-age=3600, s-maxage=3600',
      'Access-Control-Allow-Origin': '*',
    });

    const contentLength = upstreamRes.headers.get('content-length');
    if (contentLength) {
      resHeaders.set('Content-Length', contentLength);
    }

    return new NextResponse(upstreamRes.body as any, {
      status: 200,
      headers: resHeaders,
    });
  } catch (error) {
    console.error(`Direct stream failed for ${filename}:`, error);
    return NextResponse.redirect(downloadUrl, { status: 302 });
  }
}
