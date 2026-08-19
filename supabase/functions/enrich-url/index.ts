// enrich-url: fetches a URL and returns deterministic HTML, Open Graph and
// Twitter Card metadata. Open Graph wins, then Twitter Card, then plain HTML.
//
// Security model: this function is effectively public (guest mode), so it
// enforces strict SSRF protections: http/https only, private/loopback/link-
// local/cloud-metadata IPs are rejected (both by hostname blocklist and by
// DNS resolution), redirects are re-validated at every hop, and responses are
// bounded by size and timeout.
//
// It never writes to the `items` table and never exposes a service key.

const MAX_HTML_BYTES = 2_000_000;
const MAX_REDIRECTS = 5;
const FETCH_TIMEOUT_MS = 10_000;
const USER_AGENT =
  "Mozilla/5.0 (compatible; LaterBox/1.0; metadata-enricher)";

class UnsupportedError extends Error {}
class FetchError extends Error {}
class TimeoutError extends Error {}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (data: unknown, status: number) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  let url: string;
  try {
    const body = await req.json();
    if (typeof body?.url !== "string" || body.url.trim().length === 0) {
      throw new Error("missing url");
    }
    url = body.url.trim();
  } catch {
    return json({ error: "Invalid body: expected {\"url\": string}" }, 400);
  }

  try {
    const result = await enrich(url);
    return json(result, 200);
  } catch (error) {
    if (error instanceof UnsupportedError) {
      return json({ error: error.message }, 422);
    }
    if (error instanceof TimeoutError) {
      return json({ error: "Timed out fetching URL" }, 504);
    }
    if (error instanceof FetchError) {
      return json({ error: error.message }, 502);
    }
    console.error("enrich-url internal error", error);
    return json({ error: "Internal error" }, 500);
  }
});

async function enrich(raw: string) {
  const target = parseAndValidateUrl(raw);
  const { html, finalUrl } = await fetchHtml(target);
  const parsed = parseHtml(html, finalUrl);
  const finalUri = new URL(finalUrl);

  return {
    domain: stripWww(finalUri.hostname),
    siteName: parsed.siteName,
    title: parsed.title,
    description: parsed.description,
    faviconUrl: parsed.favicon,
    previewImageUrl: parsed.previewImage,
  };
}

function parseAndValidateUrl(raw: string): URL {
  let parsed: URL;
  try {
    parsed = new URL(raw);
  } catch {
    throw new UnsupportedError("Invalid URL");
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    throw new UnsupportedError("Unsupported protocol");
  }
  const host = parsed.hostname.toLowerCase();
  if (isBlockedHostname(host)) throw new UnsupportedError("Blocked host");
  return parsed;
}

function isBlockedHostname(host: string): boolean {
  if (!host) return true;
  const lower = host.toLowerCase();
  if (lower === "localhost" || lower.endsWith(".localhost")) return true;
  if (lower.endsWith(".local") || lower.endsWith(".internal")) return true;
  if (lower === "metadata" || lower.endsWith(".metadata.google.internal")) {
    return true;
  }
  if (
    lower === "instance-data" ||
    lower === "instance-data.ec2.internal" ||
    lower.endsWith(".compute.amazonaws.com")
  ) {
    return true;
  }
  if (!isIp(lower) && !lower.includes(".")) return true; // single-label host
  return false;
}

function isIp(value: string): boolean {
  if (value.includes(":")) return true; // assume IPv6 literal
  return /^\d+\.\d+\.\d+\.\d+$/.test(value);
}

function isPrivateIp(ip: string): boolean {
  if (ip.includes(":")) {
    const lower = ip.toLowerCase();
    if (lower === "::" || lower === "::1") return true;
    if (lower.startsWith("::ffff:")) return isPrivateIp(lower.slice(7));
    // fc00::/7 ULA, fe80::/10 link-local, ::/96 ipv4-compatible
    if (lower.startsWith("fc") || lower.startsWith("fd")) return true;
    if (lower.startsWith("fe8") || lower.startsWith("fe9")) return true;
    if (lower.startsWith("fea") || lower.startsWith("feb")) return true;
    return false;
  }
  const octets = ip.split(".").map(Number);
  const [a, b] = octets;
  if (a === 0 || a === 10) return true;
  if (a === 100 && b >= 64 && b <= 127) return true; // CGNAT
  if (a === 127) return true;
  if (a === 169 && b === 254) return true; // link-local / cloud metadata
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a === 192 && b === 168) return true;
  if (a >= 224) return true; // multicast / reserved
  return false;
}

async function resolveAndValidateHost(host: string): Promise<void> {
  if (isIp(host)) {
    if (isPrivateIp(host)) throw new UnsupportedError("Private host");
    return;
  }
  const addresses: string[] = [];
  for (const recordType of ["A", "AAAA"] as const) {
    try {
      addresses.push(...(await Deno.resolveDns(host, recordType)));
    } catch {
      // The record type may not exist for this host; try the other one.
    }
  }
  if (addresses.length === 0) throw new FetchError("Host did not resolve");
  for (const address of addresses) {
    if (isPrivateIp(address)) throw new UnsupportedError("Private host");
  }
}

async function fetchHtml(url: URL): Promise<{ html: string; finalUrl: string }> {
  let current = url;
  for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
    if (current.protocol !== "http:" && current.protocol !== "https:") {
      throw new UnsupportedError("Unsupported redirect protocol");
    }
    if (isBlockedHostname(current.hostname)) {
      throw new UnsupportedError("Blocked redirect host");
    }
    await resolveAndValidateHost(current.hostname);

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

    let response: Response;
    try {
      response = await fetch(current, {
        redirect: "manual",
        signal: controller.signal,
        headers: {
          "user-agent": USER_AGENT,
          accept: "text/html,application/xhtml+xml",
        },
      });
    } catch (error) {
      if ((error as Error)?.name === "AbortError") {
        throw new TimeoutError();
      }
      throw new FetchError("Request failed");
    } finally {
      clearTimeout(timer);
    }

    if (response.status === 301 || response.status === 302 ||
        response.status === 303 || response.status === 307 ||
        response.status === 308) {
      const location = response.headers.get("location");
      if (!location) throw new FetchError("Redirect without location");
      current = new URL(location, current);
      continue;
    }
    if (response.status === 429) throw new FetchError("Rate limited");
    if (response.status >= 400) throw new FetchError(`HTTP ${response.status}`);

    const contentType = response.headers.get("content-type") ?? "";
    if (!/text\/html|application\/xhtml\+xml/i.test(contentType)) {
      throw new UnsupportedError("Not HTML content");
    }

    const html = await readBodyLimited(response, MAX_HTML_BYTES);
    return { html, finalUrl: current.toString() };
  }
  throw new FetchError("Too many redirects");
}

async function readBodyLimited(
  response: Response,
  maxBytes: number,
): Promise<string> {
  const reader = response.body?.getReader();
  if (!reader) throw new FetchError("Empty response body");
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.length;
    if (total > maxBytes) {
      await reader.cancel();
      throw new UnsupportedError("Response too large");
    }
    chunks.push(value);
  }
  const combined = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    combined.set(chunk, offset);
    offset += chunk.length;
  }
  return new TextDecoder().decode(combined);
}

function parseHtml(html: string, finalUrl: string): {
  title: string | null;
  description: string | null;
  favicon: string | null;
  siteName: string | null;
  previewImage: string | null;
} {
  const base = extractBaseUrl(html, finalUrl);
  return {
    title: firstMeta(html, ["og:title", "twitter:title"]) ?? extractTitle(html),
    description:
      firstMeta(html, ["og:description", "twitter:description"]) ??
      extractMeta(html, "description"),
    favicon: resolveAbsoluteUrl(extractFavicon(html), base),
    siteName:
      extractMeta(html, "og:site_name") ??
      extractMeta(html, "application-name"),
    previewImage: resolveAbsoluteUrl(
      firstMeta(html, [
        "og:image",
        "og:image:secure_url",
        "twitter:image",
        "twitter:image:src",
      ]),
      base,
    ),
  };
}

function firstMeta(html: string, keys: string[]): string | null {
  for (const key of keys) {
    const value = extractMeta(html, key);
    if (value) return value;
  }
  return null;
}

function extractTitle(html: string): string | null {
  const match = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  if (!match) return null;
  const title = decodeEntities(match[1]).replace(/\s+/g, " ").trim();
  return title.length === 0 ? null : title;
}

function extractMeta(html: string, key: string): string | null {
  const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp(
    `<meta[^>]+(?:name|property)=["']${escaped}["'][^>]*>`,
    "i",
  );
  const match = html.match(pattern);
  if (!match) return null;
  const content = match[0].match(/content=["']([\s\S]*?)["']/i);
  if (!content) return null;
  const value = decodeEntities(content[1]).replace(/\s+/g, " ").trim();
  return value.length === 0 ? null : value;
}

function extractBaseUrl(html: string, finalUrl: string): string {
  const match = html.match(/<base[^>]+href=["']([^"']*)["'][^>]*>/i);
  if (!match) return finalUrl;
  try {
    return new URL(decodeEntities(match[1]).trim(), finalUrl).toString();
  } catch {
    return finalUrl;
  }
}

function resolveAbsoluteUrl(value: string | null, base: string): string | null {
  if (!value) return null;
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  try {
    const resolved = new URL(trimmed, base).toString();
    if (resolved.startsWith("http://") || resolved.startsWith("https://")) {
      return resolved;
    }
  } catch {
    // Unresolvable URL; treat as absent.
  }
  return null;
}

function extractFavicon(html: string): string | null {
  const pattern = /<link[^>]+rel=["'][^"']*icon[^"']*["'][^>]*>/gi;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(html)) !== null) {
    const rel = (match[0].match(/rel=["']([^"']*)["']/i)?.[1] ?? "")
      .toLowerCase();
    if (!rel.includes("icon")) continue;
    const href = match[0].match(/href=["']([^"']*)["']/i)?.[1];
    if (!href) continue;
    if (/^data:/i.test(href.trim())) continue;
    return decodeEntities(href).trim();
  }
  return null;
}

function decodeEntities(value: string): string {
  return value
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&apos;/gi, "'")
    .replace(/&#0*39;/gi, "'")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&#(\d+);/g, (_, digits: string) =>
      String.fromCodePoint(Number(digits)),
    )
    .replace(/&#x([0-9a-f]+);/gi, (_, hex: string) =>
      String.fromCodePoint(parseInt(hex, 16)),
    );
}

function stripWww(host: string): string {
  return host.startsWith("www.") ? host.slice(4) : host;
}
