import { describe, it } from 'node:test';
import assert from 'node:assert';
import { extractArticleContent } from './articleExtractor';

describe('extractArticleContent', () => {
  it('extracts headings, paragraphs, lists, and code blocks as clean markdown and html', () => {
    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <title>Test Page</title>
        </head>
        <body>
          <header><nav><a href="/home">Home</a></nav></header>
          <article>
            <h1>Understanding React 19 Actions</h1>
            <p>React 19 introduces async actions that revolutionize form handling.</p>
            <h2>Key Advantages</h2>
            <ul>
              <li>Automatic pending states</li>
              <li>Optimistic updates with <strong>useOptimistic</strong></li>
              <li>Integrated server actions</li>
            </ul>
            <blockquote>Actions simplify mutation workflows across the app.</blockquote>
            <pre><code>const [state, formAction] = useActionState(fn, null);</code></pre>
            <p>For more details, visit <a href="/docs/actions">the docs</a>.</p>
          </article>
          <footer>Copyright 2026</footer>
        </body>
      </html>
    `;

    const result = extractArticleContent(html, 'https://example.com/blog/react-19');

    // Markdown checks
    assert.ok(result.markdown.includes('# Understanding React 19 Actions'));
    assert.ok(result.markdown.includes('## Key Advantages'));
    assert.ok(result.markdown.includes('- Automatic pending states'));
    assert.ok(result.markdown.includes('**useOptimistic**'));
    assert.ok(result.markdown.includes('> Actions simplify mutation workflows across the app.'));
    assert.ok(result.markdown.includes('```\nconst [state, formAction] = useActionState(fn, null);\n```'));
    assert.ok(result.markdown.includes('[the docs](https://example.com/docs/actions)'));

    // Clean HTML checks
    assert.ok(result.htmlContent.includes('<h1>Understanding React 19 Actions</h1>'));
    assert.ok(result.htmlContent.includes('<h2>Key Advantages</h2>'));
    assert.ok(result.htmlContent.includes('<a href="https://example.com/docs/actions" target="_blank" rel="noopener noreferrer">the docs</a>'));
    assert.ok(!result.htmlContent.includes('<header>'));
    assert.ok(!result.htmlContent.includes('<footer>'));

    // Text content checks
    assert.ok(result.textContent.includes('React 19 introduces async actions'));
    assert.ok(result.readingTimeMinutes >= 1);
  });

  it('extracts metadata from JSON-LD schema if present', () => {
    const html = `
      <html>
        <head>
          <script type="application/ld+json">
          {
            "@context": "https://schema.org",
            "@type": "NewsArticle",
            "headline": "Space Exploration Milestone",
            "description": "Probe reaches outer orbit successfully.",
            "image": "https://example.com/photos/space.jpg",
            "datePublished": "2026-10-06T18:00:00Z",
            "author": {
              "@type": "Person",
              "name": "Alex Vance"
            }
          }
          </script>
        </head>
        <body>
          <article>
            <h1>Space Exploration Milestone</h1>
            <p>Probe reaches outer orbit successfully after a five-year voyage.</p>
          </article>
        </body>
      </html>
    `;

    const result = extractArticleContent(html, 'https://example.com/space');

    assert.strictEqual(result.title, 'Space Exploration Milestone');
    assert.strictEqual(result.description, 'Probe reaches outer orbit successfully.');
    assert.strictEqual(result.previewImageUrl, 'https://example.com/photos/space.jpg');
    assert.strictEqual(result.author, 'Alex Vance');
    assert.strictEqual(result.publishedTime, '2026-10-06T18:00:00Z');
  });

  it('resolves relative image URLs against base URL', () => {
    const html = `
      <html>
        <body>
          <main>
            <p>An amazing illustration:</p>
            <img src="/assets/hero.png" alt="Architecture Diagram" />
          </main>
        </body>
      </html>
    `;

    const result = extractArticleContent(html, 'https://myblog.org/articles/post-1');
    assert.ok(result.markdown.includes('![Architecture Diagram](https://myblog.org/assets/hero.png)'));
    assert.ok(result.htmlContent.includes('src="https://myblog.org/assets/hero.png"'));
  });
});
