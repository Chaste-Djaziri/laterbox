import { assertEquals } from "jsr:@std/assert";
import {
  classify,
  classifyByDomain,
  classifyByJsonLdTypes,
  classifyByOgType,
  extractJsonLd,
  extractOgType,
  extractYouTubeVideoId,
  handler,
  typeByJsonLdType,
} from "./index.ts";

Deno.test("OPTIONS returns an empty successful preflight", async () => {
  const response = await handler(
    new Request("https://example.test/enrich-url", { method: "OPTIONS" }),
  );

  assertEquals(response.status, 204);
  assertEquals(await response.text(), "");
});

Deno.test("upstream rate limits remain HTTP 429", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = () => Promise.resolve(new Response(null, { status: 429 }));
  try {
    const response = await handler(
      new Request("https://example.test/enrich-url", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ url: "https://93.184.216.34" }),
      }),
    );

    assertEquals(response.status, 429);
    assertEquals(await response.json(), { error: "Rate limited" });
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("extractJsonLd parses a single object", () => {
  const html = `<script type="application/ld+json">
    { "@type": "Article", "headline": "Hello" }
  </script>`;
  const blocks = extractJsonLd(html);
  assertEquals(blocks.length, 1);
  assertEquals(blocks[0]["@type"], "Article");
});

Deno.test("extractJsonLd parses array of objects", () => {
  const html = `<script type="application/ld+json">
    [{ "@type": "Article" }, { "@type": "Organization" }]
  </script>`;
  const blocks = extractJsonLd(html);
  assertEquals(blocks.length, 2);
  assertEquals(blocks[0]["@type"], "Article");
  assertEquals(blocks[1]["@type"], "Organization");
});

Deno.test("extractJsonLd handles @graph", () => {
  const html = `<script type="application/ld+json">
    { "@context": "https://schema.org", "@graph": [
      { "@type": "Organization", "name": "Acme" },
      { "@type": "Article", "headline": "Deep" }
    ]}
  </script>`;
  const blocks = extractJsonLd(html);
  assertEquals(blocks.length, 3);
  assertEquals(blocks[0]["@type"], undefined); // graph wrapper
  assertEquals(blocks[1]["@type"], "Organization");
  assertEquals(blocks[2]["@type"], "Article");
});

Deno.test("extractJsonLd skips malformed blocks", () => {
  const html = `<script type="application/ld+json">
    { "@type": "Article"
  </script>
  <script type="application/ld+json">
    { "@type": "Book" }
  </script>`;
  const blocks = extractJsonLd(html);
  assertEquals(blocks.length, 1);
  assertEquals(blocks[0]["@type"], "Book");
});

Deno.test("extractJsonLd handles array @type", () => {
  const html = `<script type="application/ld+json">
    { "@type": ["Article", "NewsArticle"], "headline": "X" }
  </script>`;
  const blocks = extractJsonLd(html);
  assertEquals(blocks.length, 1);
  assertEquals((blocks[0]["@type"] as string[]), ["Article", "NewsArticle"]);
});

Deno.test("extractJsonLd handles multiple script blocks", () => {
  const html = `
    <script type="application/ld+json">{ "@type": "Product" }</script>
    <script type="application/ld+json">{ "@type": "Organization" }</script>
  `;
  const blocks = extractJsonLd(html);
  assertEquals(blocks.length, 2);
});

Deno.test("extractJsonLd ignores non-jsonld scripts", () => {
  const html = `
    <script type="text/javascript">var x = 1;</script>
    <script type="application/ld+json">{ "@type": "Book" }</script>
  `;
  const blocks = extractJsonLd(html);
  assertEquals(blocks.length, 1);
  assertEquals(blocks[0]["@type"], "Book");
});

Deno.test("typeByJsonLdType maps article variants", () => {
  assertEquals(typeByJsonLdType("Article"), "article");
  assertEquals(typeByJsonLdType("NewsArticle"), "article");
  assertEquals(typeByJsonLdType("BlogPosting"), "article");
  assertEquals(typeByJsonLdType("WebPage"), null);
});

Deno.test("typeByJsonLdType maps video, product, event, place, book, music", () => {
  assertEquals(typeByJsonLdType("VideoObject"), "video");
  assertEquals(typeByJsonLdType("Product"), "product");
  assertEquals(typeByJsonLdType("SportsEvent"), "event");
  assertEquals(typeByJsonLdType("LocalBusiness"), "place");
  assertEquals(typeByJsonLdType("Audiobook"), "book");
  assertEquals(typeByJsonLdType("MusicRecording"), "music");
  assertEquals(typeByJsonLdType("SoftwareSourceCode"), "repository");
});

Deno.test("classifyByJsonLdTypes picks the first mapped type", () => {
  const jsonLd = [{ "@type": ["WebPage", "Article"], headline: "Hi" }];
  const result = classifyByJsonLdTypes(
    ["WebPage", "Article"],
    jsonLd,
  );
  assertEquals(result?.type, "article");
  assertEquals(result?.source, "jsonLd");
  assertEquals(result?.confidence, 0.9);
});

Deno.test("classifyByJsonLdTypes ignores unmapped types", () => {
  const jsonLd = [{ "@type": ["WebPage", "FAQPage"] }];
  const result = classifyByJsonLdTypes(["WebPage", "FAQPage"], jsonLd);
  // WebPage and FAQPage are not in our taxonomy; nothing maps.
  assertEquals(result, null);
});

Deno.test("classifyByDomain maps YouTube and GitHub", () => {
  assertEquals(
    classifyByDomain("www.youtube.com", "/watch?v=123")?.type,
    "video",
  );
  assertEquals(
    classifyByDomain("youtu.be", "/abc")?.type,
    "video",
  );
  assertEquals(
    classifyByDomain("github.com", "/flutter/flutter")?.type,
    "repository",
  );
  assertEquals(
    classifyByDomain("github.com", "/owner/repo/issues/1")?.structuredData,
    { owner: "owner", repository: "repo" },
  );
  assertEquals(classifyByDomain("example.com", "/x") ?? null, null);
});

Deno.test("classify domain rule overrides JSON-LD type", () => {
  // GitHub repo page with a JSON-LD Article (e.g. a blog post) → repository.
  const uri = new URL("https://github.com/flutter/flutter");
  const jsonLd = [{ "@type": "Article", headline: "A blog" }];
  const result = classify(uri, null, jsonLd);
  assertEquals(result.type, "repository");
  assertEquals(result.source, "domainRule");
  assertEquals(result.confidence, 0.95);
});

Deno.test("classify JSON-LD Article falls back from domain rule", () => {
  const uri = new URL("https://someblog.com/2025/hello");
  const jsonLd = [{ "@type": "Article", headline: "Hello" }];
  const result = classify(uri, null, jsonLd);
  assertEquals(result.type, "article");
  assertEquals(result.source, "jsonLd");
});

Deno.test("classify falls back to og:type then link", () => {
  const uri = new URL("https://example.com/page");
  assertEquals(classify(uri, "video.movie", []).type, "video");
  assertEquals(classify(uri, "website", []).type, "link");
  assertEquals(classify(uri, null, []).type, "link");
});

Deno.test("classifyByOgType maps music and product", () => {
  assertEquals(classifyByOgType("music.song")?.type, "music");
  assertEquals(classifyByOgType("product")?.type, "product");
  assertEquals(classifyByOgType("website"), null);
});

Deno.test("og:type 'video.*' maps to video", () => {
  assertEquals(classifyByOgType("video.movie")?.type, "video");
  assertEquals(classifyByOgType("video.episode")?.type, "video");
});

Deno.test("extractOgType reads og:type meta tag", () => {
  const html = '<meta property="og:type" content="article">';
  assertEquals(extractOgType(html), "article");
  assertEquals(extractOgType("<title>nothing</title>"), null);
});

Deno.test("extractYouTubeVideoId extracts video ID across watch, shorts, embed, and youtu.be", () => {
  assertEquals(
    extractYouTubeVideoId(new URL("https://www.youtube.com/watch?v=dQw4w9WgXcQ")),
    "dQw4w9WgXcQ",
  );
  assertEquals(
    extractYouTubeVideoId(new URL("https://youtu.be/dQw4w9WgXcQ?si=123")),
    "dQw4w9WgXcQ",
  );
  assertEquals(
    extractYouTubeVideoId(new URL("https://www.youtube.com/shorts/dQw4w9WgXcQ")),
    "dQw4w9WgXcQ",
  );
  assertEquals(
    extractYouTubeVideoId(new URL("https://www.youtube.com/embed/dQw4w9WgXcQ")),
    "dQw4w9WgXcQ",
  );
  assertEquals(
    extractYouTubeVideoId(new URL("https://example.com/watch?v=dQw4w9WgXcQ")),
    null,
  );
});
