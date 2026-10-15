import HomePage from '@/components/marketing/HomePage';
import { publicMetadata, websiteSchema } from '@/lib/seo';
export const metadata = publicMetadata('LaterBox — Save for Later & Bookmark Manager', 'Save links, articles, videos, notes, and files with LaterBox. Organize your library into collections and return to useful content when you are ready.');
export default function Page() {
  return <><script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(websiteSchema).replace(/</g, '\u003c') }} /><HomePage /></>;
}
