import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Mastering LaterBox Guide | Quick Capture, Shortcuts & Organizing',
  description:
    'Complete getting-started guide to capturing content, using global keyboard shortcuts, organizing with collections, and searching notes in LaterBox.',
  alternates: {
    canonical: 'https://laterbox.dev/tutorial',
  },
  openGraph: {
    title: 'Mastering LaterBox Guide & Keyboard Shortcuts',
    description:
      'Everything you need to know about capturing, reading, syncing, and organizing your knowledge base.',
    url: 'https://laterbox.dev/tutorial',
  },
};

export default function TutorialLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
