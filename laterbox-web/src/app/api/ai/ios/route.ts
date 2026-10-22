import { NextResponse } from 'next/server';
import { getBillingAdminClient, getRequestUser } from '@/lib/billing/server';

export const dynamic = 'force-dynamic';
const intents = new Set(['chat', 'capture', 'search', 'clarify']);
const stringFields = ['reply', 'content', 'title', 'category', 'contentType', 'summary', 'formattedContent', 'query', 'returnDate'];

export async function POST(request: Request) {
  // Fail closed before authentication, body parsing, or any model request.
  if (process.env.IOS_GEMINI_FALLBACK_ENABLED !== 'true') {
    return NextResponse.json({ error: 'Gemini fallback is disabled.' }, { status: 503 });
  }
  try {
    const user = await getRequestUser(request);
    if (!user) return NextResponse.json({ error: 'Authentication required.' }, { status: 401 });
    const admin = getBillingAdminClient();
    const { data: pro, error } = await admin.rpc('has_pro_entitlement', { target_user_id: user.id });
    if (error || pro !== true) return NextResponse.json({ error: 'Verified Pro access required.' }, { status: 403 });

    const body = (await request.json()) as { prompt?: unknown };
    if (typeof body.prompt !== 'string' || !body.prompt.trim() || body.prompt.length > 12000) {
      return NextResponse.json({ error: 'Invalid prompt.' }, { status: 400 });
    }
    const key = process.env.GEMINI_API_KEY;
    const model = process.env.IOS_GEMINI_MODEL || process.env.MODEL || 'gemini-3.8-flash';
    const bazaarKey = process.env.BAZAARLINK_API_KEY;

    if (!key && !bazaarKey) return NextResponse.json({ error: 'Fallback is not configured.' }, { status: 503 });

    const systemInstruction =
      'You are Later AI, an intelligent personal digital vault assistant. Classify chat, capture, search, or clarify. For captures, deduce what the user wants most out of the input, especially for mixed content (to-do phrasing with links, videos, images, or documents). If the phrasing indicates an action to do or buy in the future (e.g. watch, read, buy, review, check out, call, finish), classify contentType as "task", formulate a clear action title, generate task checklist items formatted as markdown "- [ ] item" in formattedContent, and deduce the best returnDate (e.g. "tonight", "tomorrow at 9am", "this weekend", or specific ISO string). Otherwise classify as link, video, article, music, document, or note with an accurate, non-generic title and 1-sentence summary. Preserve exact original capture content, explicit tags, collections, and dates. Never claim a save succeeded. Return all action fields; unused strings must be empty.';

    let action: any = null;

    if (key && model && /^[a-zA-Z0-9.-]+$/.test(model)) {
      try {
        const response = await fetch('https://generativelanguage.googleapis.com/v1beta/interactions', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
          signal: AbortSignal.timeout(20000),
          body: JSON.stringify({
            model,
            store: false,
            system_instruction: systemInstruction,
            input: body.prompt,
            generation_config: { max_output_tokens: 2048 },
            response_format: {
              type: 'text', mime_type: 'application/json',
              schema: {
                type: 'object',
                properties: {
                  ...Object.fromEntries(stringFields.map(field => [field, { type: 'string' }])),
                  intent: { type: 'string', enum: [...intents] },
                  contentType: { type: 'string', enum: ['', 'link', 'article', 'video', 'music', 'document', 'note', 'task'] },
                  tags: { type: 'array', items: { type: 'string' } },
                },
                required: ['intent', 'tags', ...stringFields],
              },
            },
          }),
        });
        if (response.ok) {
          const payload = await response.json() as { status?: string; steps?: { type?: string; content?: { type?: string; text?: string }[] }[] };
          if (payload.status === 'completed') {
            const text = payload.steps?.filter(step => step.type === 'model_output')
              .flatMap(step => step.content ?? []).filter(part => part.type === 'text').map(part => part.text ?? '').join('');
            action = JSON.parse(text ?? '');
          }
        }
      } catch (geminiErr) {
        console.warn('[Gemini iOS Error]:', geminiErr);
      }
    }

    // Free BazaarLink OpenAI-compatible fallback if Gemini is absent or failed
    if (!action && bazaarKey) {
      try {
        const bazaarModel = process.env.BAZAARLINK_MODEL || 'qwen/qwen3.7-flash';
        const bzResponse = await fetch('https://api.bazaarlink.ai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${bazaarKey}`,
          },
          signal: AbortSignal.timeout(20000),
          body: JSON.stringify({
            model: bazaarModel,
            messages: [
              { role: 'system', content: `${systemInstruction} Always respond in valid JSON format matching the schema with fields: intent, reply, content, title, category, contentType, summary, formattedContent, query, returnDate, tags.` },
              { role: 'user', content: body.prompt }
            ],
            response_format: { type: 'json_object' },
            temperature: 0.2,
          }),
        });
        if (bzResponse.ok) {
          const bzData = await bzResponse.json() as { choices?: { message?: { content?: string } }[] };
          const rawContent = bzData.choices?.[0]?.message?.content ?? '{}';
          action = JSON.parse(rawContent);
        }
      } catch (bzErr) {
        console.warn('[BazaarLink Fallback Error]:', bzErr);
      }
    }

    if (!action || !intents.has(action.intent) || stringFields.some(field => typeof action[field] !== 'string') ||
        !Array.isArray(action.tags) || action.tags.some((tag: unknown) => typeof tag !== 'string')) {
      throw new Error('Invalid or failed generation');
    }

    return NextResponse.json({ action }, { headers: { 'Cache-Control': 'no-store' } });
  } catch {
    return NextResponse.json({ error: 'Unable to complete remote generation.' }, { status: 502 });
  }
}
