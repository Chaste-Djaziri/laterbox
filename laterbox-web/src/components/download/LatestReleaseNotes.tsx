'use client';

import { useEffect, useState } from 'react';

type Release = { name: string; body: string; html_url: string };

export function LatestReleaseNotes() {
  const [release, setRelease] = useState<Release | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    fetch('/api/releases', { signal: controller.signal })
      .then(async (response): Promise<Release[]> => response.ok ? response.json() : [])
      .then((releases) => setRelease(releases[0] ?? null))
      .catch(() => {});
    return () => controller.abort();
  }, []);

  if (!release) return null;

  return (
    <section className="rounded-3xl border border-[#e4e0d5] bg-white p-6 sm:p-8" aria-labelledby="latest-release-title">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 id="latest-release-title" className="text-xl font-bold text-[#171711]">Latest release: {release.name}</h2>
        <a href={release.html_url} target="_blank" rel="noopener noreferrer" className="text-sm font-bold underline text-[#171711]">View on GitHub</a>
      </div>
      <div className="mt-4 max-h-64 overflow-auto whitespace-pre-wrap text-sm leading-relaxed text-[#6c6b63]">
        {release.body || 'Release notes are available on GitHub.'}
      </div>
    </section>
  );
}
