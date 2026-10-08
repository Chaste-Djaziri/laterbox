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
    // Node environment fallback
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
  const requestedAssetId = Number(request.nextUrl.searchParams.get('assetId'));

  try {
    // A release-history link includes the immutable GitHub asset ID, so it
    // always downloads the file from that exact release rather than a newer
    // asset with the same filename.
    if (Number.isSafeInteger(requestedAssetId) && requestedAssetId > 0) {
      const assetDownloadRes = await fetch(
        `https://api.github.com/repos/${GITHUB_REPO}/releases/assets/${requestedAssetId}`,
        {
          headers: {
            ...authHeader,
            'Accept': 'application/octet-stream',
          },
          redirect: 'manual',
        }
      );

      const signedLocation = assetDownloadRes.headers.get('location');
      if (signedLocation) {
        return NextResponse.redirect(signedLocation, { status: 302 });
      }

      if (assetDownloadRes.ok && assetDownloadRes.body) {
        return new NextResponse(assetDownloadRes.body as any, {
          status: 200,
          headers: {
            'Content-Type': getMimeType(filename),
            'Content-Disposition': `attachment; filename="${filename}"`,
            'X-Content-Type-Options': 'nosniff',
            'Cache-Control': 'public, max-age=3600, s-maxage=3600',
          },
        });
      }

      return new NextResponse(`File not found: ${filename}`, { status: 404 });
    }

    const lowerFilename = filename.toLowerCase();
    const isApk = lowerFilename.endsWith('.apk');
    const isChromeExt = lowerFilename.includes('chrome');
    const isFirefoxExt = lowerFilename.includes('firefox');
    const isSafariExt = lowerFilename.includes('safari');

    let candidates = [filename];
    if (isApk) {
      candidates = [
        filename,
        'laterbox.apk',
        'LaterBox.apk',
        'laterbox-android.apk',
        'laterbox-android-release.apk',
        'app-release.apk',
      ];
    } else if (isChromeExt) {
      candidates = [
        filename,
        'laterbox-chrome-extension.zip',
        'chrome-extension.zip',
        'laterbox-chrome.zip',
      ];
    } else if (isFirefoxExt) {
      candidates = [
        filename,
        'laterbox-firefox-extension.zip',
        'firefox-extension.zip',
        'laterbox-firefox.zip',
      ];
    } else if (isSafariExt) {
      candidates = [
        filename,
        'laterbox-safari-extension.zip',
        'safari-extension.zip',
        'laterbox-safari.zip',
      ];
    }

    // 0. Check if the file is available in the web app's static /downloads directory
    for (const cand of candidates) {
      try {
        const localStaticUrl = new URL(`/downloads/${cand}`, request.url);
        const localRes = await fetch(localStaticUrl.toString());
        if (localRes.ok && localRes.body) {
          const resHeaders = new Headers({
            'Content-Type': getMimeType(cand),
            'Content-Disposition': `attachment; filename="${cand}"`,
            'Content-Transfer-Encoding': 'binary',
            'X-Content-Type-Options': 'nosniff',
            'Cache-Control': 'public, max-age=3600, s-maxage=3600',
            'Access-Control-Allow-Origin': '*',
          });
          const contentLength = localRes.headers.get('content-length');
          if (contentLength) {
            resHeaders.set('Content-Length', contentLength);
          }
          return new NextResponse(localRes.body as any, {
            status: 200,
            headers: resHeaders,
          });
        }
      } catch {
        // Fallback to GitHub Release resolution
      }
    }

    // 1. If token is available, resolve asset via GitHub Release API for direct binary access
    if (token) {
      try {
        const releasesRes = await fetch(
          `https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=10`,
          {
            headers: {
              ...authHeader,
              'Accept': 'application/vnd.github.v3+json',
            },
          }
        );

        if (releasesRes.ok) {
          const releases = (await releasesRes.json()) as Array<{
            assets?: Array<{ id: number; name: string; url: string; size: number }>;
          }>;

          let matchedAsset: { id: number; name: string; url: string; size: number } | undefined;
          for (const rel of releases) {
            for (const cand of candidates) {
              const found = rel.assets?.find(
                (a) => a.name.toLowerCase() === cand.toLowerCase()
              );
              if (found) {
                matchedAsset = found;
                break;
              }
            }
            if (matchedAsset) break;
          }

          if (matchedAsset) {
            // Request direct signed asset URL from GitHub API with manual redirect
            const assetDownloadRes = await fetch(
              `https://api.github.com/repos/${GITHUB_REPO}/releases/assets/${matchedAsset.id}`,
              {
                headers: {
                  ...authHeader,
                  'Accept': 'application/octet-stream',
                },
                redirect: 'manual',
              }
            );

            const signedLocation = assetDownloadRes.headers.get('location');

            if (signedLocation) {
              // Fetch raw pre-signed asset stream without auth headers
              const rawStreamRes = await fetch(signedLocation);

              if (rawStreamRes.ok && rawStreamRes.body) {
                const mimeType = getMimeType(matchedAsset.name || filename);
                const resHeaders = new Headers({
                  'Content-Type': mimeType,
                  'Content-Disposition': `attachment; filename="${matchedAsset.name || filename}"`,
                  'Content-Transfer-Encoding': 'binary',
                  'X-Content-Type-Options': 'nosniff',
                  'Cache-Control': 'public, max-age=3600, s-maxage=3600',
                  'Access-Control-Allow-Origin': '*',
                });

                const contentLength = rawStreamRes.headers.get('content-length');
                if (contentLength) {
                  resHeaders.set('Content-Length', contentLength);
                }

                return new NextResponse(rawStreamRes.body as any, {
                  status: 200,
                  headers: resHeaders,
                });
              }

              // Direct redirect to signed storage URL fallback
              return NextResponse.redirect(signedLocation, { status: 302 });
            }
          }
        }
      } catch (apiErr) {
        console.warn('GitHub API release resolution fallback:', apiErr);
      }
    }

    // 2. Direct Release Download URL (Public or authenticated fallback across candidates)
    for (const cand of candidates) {
      const downloadUrl = `https://github.com/${GITHUB_REPO}/releases/latest/download/${cand}`;
      const upstreamRes = await fetch(downloadUrl, {
        headers: {
          ...authHeader,
          'Accept': 'application/octet-stream',
        },
        redirect: 'follow',
      });

      if (upstreamRes.ok && upstreamRes.body) {
        const mimeType = getMimeType(cand);
        const resHeaders = new Headers({
          'Content-Type': mimeType,
          'Content-Disposition': `attachment; filename="${cand}"`,
          'Content-Transfer-Encoding': 'binary',
          'X-Content-Type-Options': 'nosniff',
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
      }
    }

    // 3. Fallback for Android APK to known release asset if latest tag resolution was delayed
    if (isApk) {
      const fallbackUrl = `https://github.com/${GITHUB_REPO}/releases/download/v1.0.170/laterbox-android.apk`;
      const fallbackRes = await fetch(fallbackUrl, {
        headers: {
          ...authHeader,
          'Accept': 'application/octet-stream',
        },
        redirect: 'follow',
      });

      if (fallbackRes.ok && fallbackRes.body) {
        const resHeaders = new Headers({
          'Content-Type': 'application/vnd.android.package-archive',
          'Content-Disposition': 'attachment; filename="LaterBox.apk"',
          'Content-Transfer-Encoding': 'binary',
          'X-Content-Type-Options': 'nosniff',
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
    }

    return new NextResponse(`File not found: ${filename}`, { status: 404 });
  } catch (error) {
    console.error(`Direct stream failed for ${filename}:`, error);
    return new NextResponse(`Download failed for ${filename}`, { status: 500 });
  }
}
