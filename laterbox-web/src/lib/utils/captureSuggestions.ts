import { resolveReturnPreset, returnLabel, type ReturnPreset } from './schedule';

export type CaptureKind = 'link' | 'note' | 'task' | 'file';
export type AutoReturnPreset = Exclude<ReturnPreset, 'now' | 'oneHour' | 'oneMonth'>;

export interface CaptureSuggestion {
  title: string;
  tags: string[];
  preset: AutoReturnPreset;
  returnAt: string | null;
  reason: string;
}

const TAGS: { tag: string; pattern: RegExp }[] = [
  { tag: 'Reading', pattern: /\b(read|article|book|blog|newsletter|essay|research|documentation|docs)\b/i },
  { tag: 'Work', pattern: /\b(work|meeting|project|client|presentation|deadline|report|office)\b/i },
  { tag: 'Urgent', pattern: /\b(urgent|asap|right away|important|due today)\b/i },
  { tag: 'Personal', pattern: /\b(personal|family|home|groceries|shopping|friend|appointment)\b/i },
  { tag: 'Finance', pattern: /\b(finance|invoice|budget|bill|payment|bank|tax)\b/i },
  { tag: 'Inspiration', pattern: /\b(idea|inspiration|design|creative|sketch|reference)\b/i },
];

/** Lightweight, local suggestions. Nothing is uploaded or silently AI-generated. */
export function suggestCapture(
  content: string,
  kind: CaptureKind,
  fileNames: string[] = [],
  now = new Date(),
): CaptureSuggestion {
  const trimmed = content.trim();
  const firstLine = trimmed.split(/\r?\n/, 1)[0]?.trim() ?? '';
  const url = /^https?:\/\/\S+$/i.test(firstLine) || /^www\.\S+$/i.test(firstLine);
  const matchUrl = trimmed.match(/https?:\/\/[^\s]+/i);
  let suggestedTitle = firstLine;
  if (url) {
    try {
      suggestedTitle = new URL(firstLine.startsWith('www.') ? 'https://' + firstLine : firstLine)
        .hostname.replace(/^www\./, '');
    } catch { /* use the original text if the URL is malformed */ }
  } else if (!trimmed && fileNames.length) {
    suggestedTitle = fileNames[0];
  } else if (matchUrl && trimmed !== matchUrl[0]) {
    suggestedTitle = trimmed.replace(matchUrl[0], '').trim() || matchUrl[0];
  }

  const title = (suggestedTitle || fileNames[0] || '').slice(0, 100);
  // A bare URL's hostname should not accidentally match natural-language
  // keywords (e.g. a domain containing 'work' or 'today').
  const language = trimmed.replace(/https?:\/\/[^\s]+/gi, '').replace(/\bwww\.[^\s]+/gi, '').trim();
  const tags = TAGS.filter(({ pattern }) => pattern.test(language)).map(({ tag }) => tag).slice(0, 3);

  let preset: AutoReturnPreset = 'tomorrow';
  let reason = 'Suggested for tomorrow. You can change this before saving.';

  if (/\b(next week|in (?:a|one|1) week|7 days)\b/i.test(language)) {
    preset = 'oneWeek';
    reason = 'You mentioned next week.';
  } else if (/\b(weekend|saturday|sunday)\b/i.test(language)) {
    preset = 'weekend';
    reason = 'You mentioned the weekend.';
  } else if (/\b(today|tonight|this evening|this afternoon|asap|urgent|in \d+ hours?)\b/i.test(language)) {
    preset = 'laterToday';
    reason = 'You mentioned something time-sensitive.';
  } else if (/\b(someday|no rush|no deadline|whenever)\b/i.test(language)) {
    preset = 'someday';
    reason = 'You indicated that there is no deadline.';
  } else if (kind === 'link' || /\b(watch|read|article|video|podcast)\b/i.test(language)) {
    preset = 'weekend';
    reason = 'Suggested a relaxed time for saved content.';
  } else if (kind === 'file') {
    preset = 'tomorrow';
    reason = 'Suggested for tomorrow so this file does not get forgotten.';
  }

  const returnAt = resolveReturnPreset(preset, now);
  return { title, tags, preset, returnAt, reason };
}

export function captureSummary(content: string, fileNames: string[] = []): string {
  const lines = content.trim().split(/\r?\n/).filter(Boolean);
  const summary = lines.length ? lines[0].slice(0, 125) : '';
  const fileLabel = fileNames.length > 0
    ? fileNames.length + ' attached ' + (fileNames.length === 1 ? 'file' : 'files')
    : '';
  return [summary, fileLabel].filter(Boolean).join(' · ') || 'No content added yet';
}

export function suggestionLabel(suggestion: CaptureSuggestion): string {
  return suggestion.returnAt ? returnLabel(suggestion.returnAt) : 'Someday (no deadline)';
}
