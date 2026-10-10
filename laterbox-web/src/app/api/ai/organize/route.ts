import { NextRequest, NextResponse } from 'next/server';

export interface OrganizeSuggestion {
  itemId: string;
  tags: string[];
  collection: string;
  nextStep: string;
  recommendedSchedule: 'today' | 'tomorrow' | 'weekend' | 'someday';
  reasoning: string;
}

export interface OrganizeResponse {
  success: boolean;
  model: string;
  summary: string;
  suggestions: OrganizeSuggestion[];
  error?: string;
}

const FALLBACK_MODELS = [
  'gemini-3.5-flash-lite',
  'gemini-3.5-flash',
  'gemini-flash-latest',
];

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as { items?: any[]; existingCollections?: string[] };
    const { items, existingCollections = [] } = body;

    if (!Array.isArray(items) || items.length === 0) {
      return NextResponse.json(
        { success: false, error: 'No items provided for organization.' },
        { status: 400 }
      );
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return NextResponse.json(
        { success: false, error: 'GEMINI_API_KEY is not configured in .env' },
        { status: 500 }
      );
    }

    let configuredModel = (process.env.MODEL || 'gemini-3.5-flash-lite').trim();
    // Auto-map deprecated 2.5 flash lite to 3.5 flash lite
    if (configuredModel === 'gemini-2.5-flash-lite' || configuredModel === 'gemini-2.5-flash') {
      configuredModel = 'gemini-3.5-flash-lite';
    }

    // Prepare simplified item descriptors to keep context size minimal and fast
    const simplifiedItems = items.map((item) => ({
      id: item.id,
      title: item.title || item.metadata?.title || item.url || 'Untitled',
      type: item.type || item.metadata?.content_type || 'link',
      url: item.url || null,
      domain: item.metadata?.domain || (item.url ? new URL(item.url, 'http://localhost').hostname : null),
      description: item.metadata?.description || item.text_content?.slice(0, 300) || null,
      existingNote: item.note?.content || null,
    }));

    const prompt = `You are the AI Organizer for LaterBox, a calm personal digital vault.
Your job is to inspect the user's inbox items and suggest smart tags, appropriate collections, actionable next steps, and return schedules.

Existing collections in user's vault:
${existingCollections.length > 0 ? existingCollections.join(', ') : 'None yet'}

Inbox items to organize:
${JSON.stringify(simplifiedItems, null, 2)}

For EVERY item in the list, produce a structured recommendation:
1. "itemId": The exact matching id from the input item.
2. "tags": 2 to 4 clean, relevant lowercase tags with '#' prefix (e.g., ["#design", "#inspiration"], ["#dev", "#cloud"]).
3. "collection": The best collection name for this item:
   - REUSE RULE: If an existing collection in the user's vault fits this item, you MUST reuse that exact collection name (matching spelling and casing). Never create duplicate or near-duplicate variations of an existing collection.
   - GROUPING RULE: If 2 or more items in this inbox batch share a topic, theme, or category (e.g. design assets, tech articles, client work, finance), you MUST assign them to the EXACT SAME collection name so they are filed together into one collection rather than creating multiple separate collections.
   - NAMING RULE: Keep collection names concise and human-friendly (e.g. "Design Inspiration", "Reading List", "Tech & Architecture", "Client Projects", "Finance & Invoices", "Personal Notes").
4. "nextStep": A single concise, actionable next step sentence (e.g., "Review landing page mockup with design team", "Watch 24-min tutorial this weekend", "Read 7-min article and archive to library", "Extract key quote into project notes").
5. "recommendedSchedule": One of: "today" (urgent/review today), "tomorrow" (schedule for tomorrow morning), "weekend" (longer read/media for the weekend), or "someday" (ideas, inspiration, reference material with no deadline pressure).
6. "reasoning": One short sentence explaining why this organization makes sense.

Respond strictly in valid JSON format matching this schema:
{
  "summary": "Brief 1-2 sentence overview of the organization analysis",
  "suggestions": [
    {
      "itemId": "string",
      "tags": ["#tag1", "#tag2"],
      "collection": "string",
      "nextStep": "string",
      "recommendedSchedule": "today" | "tomorrow" | "weekend" | "someday",
      "reasoning": "string"
    }
  ]
}`;

    // Helper map to normalize and unify collections across suggestions:
    // 1. Matches case-insensitively against existing collections in the user's vault and uses existing casing.
    // 2. Unifies new collection names in the batch so casing/whitespace differences map to one single collection.
    const canonicalCollectionMap = new Map<string, string>();
    for (const ec of existingCollections) {
      if (typeof ec === 'string' && ec.trim()) {
        canonicalCollectionMap.set(ec.trim().toLowerCase(), ec.trim());
      }
    }

    const normalizeCollectionName = (rawName: unknown): string => {
      const trimmed = typeof rawName === 'string' ? rawName.trim() : '';
      if (!trimmed) return 'Reading List';
      const lower = trimmed.toLowerCase();
      if (canonicalCollectionMap.has(lower)) {
        return canonicalCollectionMap.get(lower)!;
      }
      canonicalCollectionMap.set(lower, trimmed);
      return trimmed;
    };

    const modelsToTry = [configuredModel, ...FALLBACK_MODELS.filter((m) => m !== configuredModel)];
    let responseText = '';
    let usedModel = configuredModel;
    let lastError = '';

    for (const model of modelsToTry) {
      try {
        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }],
              generationConfig: {
                responseMimeType: 'application/json',
                temperature: 0.2,
              },
            }),
          }
        );

        if (res.ok) {
          const data = (await res.json()) as any;
          const candidate = data.candidates?.[0]?.content?.parts?.[0]?.text;
          if (candidate) {
            responseText = candidate;
            usedModel = model;
            break;
          }
        } else {
          const errData = (await res.json().catch(() => ({}))) as any;
          lastError = errData?.error?.message || `HTTP ${res.status}`;
          console.warn(`[AI Organize] Model ${model} failed:`, lastError);
        }
      } catch (err) {
        lastError = err instanceof Error ? err.message : String(err);
        console.warn(`[AI Organize] Error with ${model}:`, lastError);
      }
    }

    if (!responseText) {
      // Fallback generator if Gemini API is unreachable or exhausted
      console.warn('[AI Organize] Using fallback heuristic generator due to Gemini API error:', lastError);
      const fallbackSuggestions: OrganizeSuggestion[] = simplifiedItems.map((item) => {
        const titleLower = item.title.toLowerCase();
        const isDesign = titleLower.endsWith('.psd') || titleLower.includes('design');
        const isPdf = titleLower.endsWith('.pdf') || titleLower.includes('feedback') || titleLower.includes('report');
        const isVideo = item.type === 'video' || item.domain?.includes('youtube');
        const isMusic = item.type === 'music' || item.domain?.includes('spotify');
        const isArticle = item.type === 'article' || titleLower.includes('power of') || titleLower.includes('guide');

        let tags = ['#inbox', '#review'];
        let collection = normalizeCollectionName('Reading List');
        let nextStep = 'Review and archive to library';
        let recommendedSchedule: 'today' | 'tomorrow' | 'weekend' | 'someday' = 'tomorrow';

        if (isDesign) {
          tags = ['#design', '#inspiration', '#ui'];
          collection = normalizeCollectionName('Design Inspiration');
          nextStep = 'Inspect design assets and extract brand palette';
          recommendedSchedule = 'someday';
        } else if (isPdf) {
          tags = ['#feedback', '#client', '#product'];
          collection = normalizeCollectionName('Client Projects');
          nextStep = 'Read feedback notes and send reply';
          recommendedSchedule = 'today';
        } else if (isVideo) {
          tags = ['#video', '#engineering', '#tech'];
          collection = normalizeCollectionName('Tech & Architecture');
          nextStep = 'Watch 24-min tutorial and note architecture takeaways';
          recommendedSchedule = 'weekend';
        } else if (isMusic) {
          tags = ['#music', '#chill', '#focus'];
          collection = normalizeCollectionName('Focus Audio');
          nextStep = 'Listen while reviewing notes';
          recommendedSchedule = 'weekend';
        } else if (isArticle) {
          tags = ['#productivity', '#mindset', '#reading'];
          collection = normalizeCollectionName('Reading List');
          nextStep = 'Read 7-min summary and tag key takeaways';
          recommendedSchedule = 'tomorrow';
        }

        return {
          itemId: item.id,
          tags,
          collection,
          nextStep,
          recommendedSchedule,
          reasoning: `Categorized into ${collection} based on content type and title.`,
        };
      });

      return NextResponse.json({
        success: true,
        model: 'heuristic-fallback',
        summary: `Analyzed ${simplifiedItems.length} items using local intelligence rules.`,
        suggestions: fallbackSuggestions,
      });
    }

    // Clean JSON response (strip markdown wrappers if present)
    let cleaned = responseText.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.replace(/^```json\s*/, '').replace(/\s*```$/, '');
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.replace(/^```\s*/, '').replace(/\s*```$/, '');
    }

    const parsed = JSON.parse(cleaned);
    const rawSuggestions = Array.isArray(parsed.suggestions) ? parsed.suggestions : [];
    const suggestions: OrganizeSuggestion[] = rawSuggestions.map((item: any) => ({
      itemId: String(item.itemId || ''),
      tags: Array.isArray(item.tags) ? item.tags : [],
      collection: normalizeCollectionName(item.collection),
      nextStep: String(item.nextStep || 'Review and file in library'),
      recommendedSchedule: ['today', 'tomorrow', 'weekend', 'someday'].includes(item.recommendedSchedule)
        ? item.recommendedSchedule
        : 'tomorrow',
      reasoning: String(item.reasoning || ''),
    }));

    return NextResponse.json({
      success: true,
      model: usedModel,
      summary: parsed.summary || `Organized ${suggestions.length} items with Gemini.`,
      suggestions,
    });
  } catch (error) {
    console.error('[AI Organize] Route exception:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to process AI organization.',
      },
      { status: 500 }
    );
  }
}
