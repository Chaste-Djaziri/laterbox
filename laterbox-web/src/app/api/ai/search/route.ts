import { NextResponse } from 'next/server';
import { getBillingAdminClient, getRequestUser } from '@/lib/billing/server';
import { parseAmbiguousQuery } from '@/lib/search/ambiguousSearch';

export const dynamic = 'force-dynamic';

export interface AiSearchRequestItem {
  id: string;
  title?: string;
  type?: string;
  url?: string;
  domain?: string;
  description?: string;
  created_at: string;
  note?: string;
  collections?: string[];
}

export interface AiSearchResponse {
  success: boolean;
  isAi: boolean;
  model: string;
  summary: string;
  parsedFilters: {
    contentType?: string;
    dateRange?: {
      start?: string;
      end?: string;
      label: string;
    };
    semanticKeywords: string[];
  };
  rankedItemIds: string[];
  explanations?: Record<string, string>;
  error?: string;
}

export async function POST(request: Request) {
  try {
    // 1. Verify user authentication and Pro plan entitlement
    const user = await getRequestUser(request);
    if (!user) {
      return NextResponse.json(
        { error: 'Authentication required for Gemini AI Search.' },
        { status: 401 }
      );
    }

    const admin = getBillingAdminClient();
    const { data: pro, error: proError } = await admin.rpc('has_pro_entitlement', {
      target_user_id: user.id,
    });

    if (proError || pro !== true) {
      return NextResponse.json(
        { error: 'Verified Pro access required for Gemini AI Search.' },
        { status: 403 }
      );
    }

    // 2. Validate request body
    const body = (await request.json()) as {
      query?: unknown;
      items?: AiSearchRequestItem[];
      referenceDate?: string;
    };

    if (typeof body.query !== 'string' || !body.query.trim()) {
      return NextResponse.json(
        { error: 'A search query string is required.' },
        { status: 400 }
      );
    }

    const query = body.query.trim();
    const candidateItems = Array.isArray(body.items) ? body.items.slice(0, 100) : [];
    const refDate = body.referenceDate ? new Date(body.referenceDate) : new Date();

    // Deterministic baseline parse
    const localParsed = parseAmbiguousQuery(query, refDate);

    const apiKey = process.env.GEMINI_API_KEY;
    let modelName = (process.env.MODEL || 'gemini-3.5-flash-lite').trim();
    if (modelName === 'gemini-2.5-flash-lite' || modelName === 'gemini-2.5-flash') {
      modelName = 'gemini-3.5-flash-lite';
    }

    // 3. If Gemini is not configured, fallback gracefully with Pro authorization confirmed
    if (!apiKey) {
      return NextResponse.json({
        success: true,
        isAi: false,
        model: 'Deterministic Semantic Parser',
        summary: `Parsed intent: ${localParsed.explanation}`,
        parsedFilters: {
          contentType: localParsed.contentType,
          dateRange: localParsed.dateRange
            ? {
                start: localParsed.dateRange.start?.toISOString(),
                end: localParsed.dateRange.end?.toISOString(),
                label: localParsed.dateRange.label,
              }
            : undefined,
          semanticKeywords: localParsed.cleanedKeywords ? [localParsed.cleanedKeywords] : [],
        },
        rankedItemIds: candidateItems.map((item) => item.id),
      });
    }

    // 4. Query Gemini for semantic query analysis & item ranking
    const prompt = `You are the Gemini AI Search Engine for LaterBox, a personal digital vault.
Analyze the user's ambiguous or natural language search query and evaluate candidate vault items.

Query: "${query}"
Reference date (Today): ${refDate.toISOString()}

Candidate Items (JSON):
${JSON.stringify(
  candidateItems.map((item) => ({
    id: item.id,
    title: item.title || 'Untitled',
    type: item.type || 'link',
    domain: item.domain || null,
    created_at: item.created_at,
    description: item.description?.slice(0, 200) || null,
    note: item.note?.slice(0, 150) || null,
    collections: item.collections || [],
  })),
  null,
  2
)}

Instructions:
1. Extract "contentType": "video" | "article" | "music" | "note" | "file" | null. Account for typos (e.g. "cideo" -> "video", "artical" -> "article").
2. Extract "dateRange": If user mentions dates like "in october", "between May and August", "last week", provide "start" (ISO), "end" (ISO), and a readable "label" (e.g. "October 2026").
3. Extract "semanticKeywords": Array of clean search terms excluding filler words.
4. "rankedItemIds": Array of item ids that match the semantic intent, ordered best to worst match.
5. "explanations": Object mapping itemId to a short 1-sentence rationale of why it matched.
6. "summary": A concise 1-sentence explanation of what Gemini searched for.

Return valid JSON adhering strictly to:
{
  "contentType": string | null,
  "dateRange": { "start": string, "end": string, "label": string } | null,
  "semanticKeywords": string[],
  "rankedItemIds": string[],
  "explanations": { [itemId: string]: string },
  "summary": string
}`;

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(
      modelName
    )}:generateContent?key=${apiKey}`;

    const geminiRes = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(15000),
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.1,
          responseMimeType: 'application/json',
        },
      }),
    });

    if (!geminiRes.ok) {
      console.warn(`[Gemini Search] API responded with ${geminiRes.status}. Using heuristic fallback.`);
      return NextResponse.json({
        success: true,
        isAi: false,
        model: `${modelName} (fallback)`,
        summary: `Analyzed query: ${localParsed.explanation}`,
        parsedFilters: {
          contentType: localParsed.contentType,
          dateRange: localParsed.dateRange
            ? {
                start: localParsed.dateRange.start?.toISOString(),
                end: localParsed.dateRange.end?.toISOString(),
                label: localParsed.dateRange.label,
              }
            : undefined,
          semanticKeywords: localParsed.cleanedKeywords ? [localParsed.cleanedKeywords] : [],
        },
        rankedItemIds: candidateItems.map((item) => item.id),
      });
    }

    const geminiData = (await geminiRes.json()) as any;
    const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
    const parsed = JSON.parse(rawText);

    return NextResponse.json({
      success: true,
      isAi: true,
      model: modelName,
      summary: parsed.summary || `Later AI identified: ${localParsed.explanation}`,
      parsedFilters: {
        contentType: parsed.contentType || localParsed.contentType,
        dateRange: parsed.dateRange || (localParsed.dateRange ? {
          start: localParsed.dateRange.start?.toISOString(),
          end: localParsed.dateRange.end?.toISOString(),
          label: localParsed.dateRange.label,
        } : undefined),
        semanticKeywords: Array.isArray(parsed.semanticKeywords) && parsed.semanticKeywords.length > 0
          ? parsed.semanticKeywords
          : (localParsed.cleanedKeywords ? [localParsed.cleanedKeywords] : []),
      },
      rankedItemIds: Array.isArray(parsed.rankedItemIds) ? parsed.rankedItemIds : candidateItems.map(c => c.id),
      explanations: parsed.explanations || {},
    });
  } catch (err: any) {
    console.error('[Gemini Search Error]:', err);
    return NextResponse.json(
      { error: err.message || 'Internal AI Search Error' },
      { status: 500 }
    );
  }
}
