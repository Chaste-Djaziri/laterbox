import type { Metadata } from 'next';

export const SITE_URL = 'https://laterbox.dev';
export const DOCS_URL = 'https://docs.laterbox.dev';
export const SOCIAL_IMAGE = {
  url: SITE_URL + '/branding/og-preview.png',
  width: 1200,
  height: 630,
  alt: 'LaterBox — Save for Later & Bookmark Manager',
};

export function publicMetadata(title: string, description: string, path = '/', origin = SITE_URL): Metadata {
  const url = new URL(path, origin).href;
  return {
    title: { absolute: title },
    description,
    alternates: { canonical: url },
    openGraph: { title, description, url, siteName: 'LaterBox', locale: 'en_US', type: 'website', images: [SOCIAL_IMAGE] },
    twitter: { card: 'summary_large_image', title, description, images: [SOCIAL_IMAGE.url] },
    robots: { index: true, follow: true },
  };
}

export const organization = {
  '@type': 'Organization',
  '@id': SITE_URL + '/#organization',
  name: 'LaterBox',
  url: SITE_URL,
  logo: SITE_URL + '/branding/laterbox-icon.png',
  sameAs: ['https://github.com/Chaste-Djaziri/laterbox'],
};

export const websiteSchema = {
  '@context': 'https://schema.org',
  '@graph': [
    organization,
    { '@type': 'WebSite', '@id': SITE_URL + '/#website', name: 'LaterBox', url: SITE_URL, publisher: { '@id': organization['@id'] } },
    {
      '@type': 'SoftwareApplication', '@id': SITE_URL + '/#software',
      name: 'LaterBox', url: SITE_URL, applicationCategory: 'ProductivityApplication',
      operatingSystem: 'Web, iOS, Android',
      description: 'Save links, notes, and files, organize collections, and return to saved content.',
      author: { '@id': organization['@id'] },
      offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD', description: 'Free local library and browser capture. Optional Pro subscription for additional services.' },
    },
  ],
};
