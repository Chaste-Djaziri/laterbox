import { SITE_URL } from '@/lib/seo';

export function PublicInfoPage({ title, intro, path, sections }: {
  title: string; intro: string; path: string; sections: { title: string; text: string }[];
}) {
  const schema = { '@context': 'https://schema.org', '@type': 'BreadcrumbList', itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'LaterBox', item: SITE_URL },
    { '@type': 'ListItem', position: 2, name: title, item: SITE_URL + path },
  ] };
  return <article className="mx-auto max-w-4xl px-6 py-16 sm:py-24">
    <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(schema).replace(/</g, '\u003c') }} />
    <p className="mb-4 text-sm font-bold uppercase tracking-widest text-[#6c6b63]">LaterBox</p>
    <h1 className="text-4xl font-black tracking-tight sm:text-6xl">{title}</h1>
    <p className="mt-6 text-lg leading-relaxed text-[#6c6b63]">{intro}</p>
    <div className="mt-12 space-y-8">{sections.map(section => <section key={section.title} className="rounded-3xl border border-[#e4e0d5] bg-white p-7">
      <h2 className="text-2xl font-bold">{section.title}</h2>
      <p className="mt-3 leading-relaxed text-[#6c6b63]">{section.text}</p>
    </section>)}</div>
  </article>;
}
