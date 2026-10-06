import type { LaterBoxItem } from '@/lib/supabase/types';

export type AmbiguousContentType = 'article' | 'video' | 'music' | 'note' | 'file';

export interface AmbiguousDateRange {
  start?: Date;
  end?: Date;
  label: string;
}

export interface ParsedSearchQuery {
  rawQuery: string;
  cleanedKeywords: string;
  contentType?: AmbiguousContentType;
  dateRange?: AmbiguousDateRange;
  hasAmbiguousFilters: boolean;
  explanation: string;
}

export interface SearchResultItem {
  item: LaterBoxItem;
  score: number;
  matchedFields: string[];
  dateMatch?: boolean;
  formatMatch?: boolean;
  aiExplanation?: string;
}

const MONTH_NAMES: Record<string, number> = {
  january: 0,
  jan: 0,
  february: 1,
  feb: 1,
  march: 2,
  mar: 2,
  april: 3,
  apr: 3,
  may: 4,
  june: 5,
  jun: 5,
  july: 6,
  jul: 6,
  august: 7,
  aug: 7,
  september: 8,
  sep: 8,
  sept: 8,
  october: 9,
  oct: 9,
  november: 10,
  nov: 10,
  december: 11,
  dec: 11,
};

const FORMAT_TYPOS: Record<string, AmbiguousContentType> = {
  // Video
  video: 'video',
  videos: 'video',
  cideo: 'video',
  cideos: 'video',
  vedio: 'video',
  vedios: 'video',
  vids: 'video',
  vid: 'video',
  youtube: 'video',
  yt: 'video',
  tiktok: 'video',
  vimeo: 'video',
  reels: 'video',

  // Article
  article: 'article',
  articles: 'article',
  artical: 'article',
  articals: 'article',
  artcle: 'article',
  artcles: 'article',
  reading: 'article',
  read: 'article',
  reads: 'article',
  blog: 'article',
  blogs: 'article',
  post: 'article',
  posts: 'article',
  essay: 'article',
  essays: 'article',
  story: 'article',

  // Music
  music: 'music',
  musiv: 'music',
  song: 'music',
  songs: 'music',
  audio: 'music',
  spotify: 'music',
  track: 'music',
  tracks: 'music',
  playlist: 'music',
  album: 'music',
  podcast: 'music',
  podcasts: 'music',

  // Note
  note: 'note',
  notes: 'note',
  memo: 'note',
  memos: 'note',
  thought: 'note',
  thoughts: 'note',
  jotting: 'note',
  jottings: 'note',
  reminder: 'note',
  reminders: 'note',

  // File
  file: 'file',
  files: 'file',
  pdf: 'file',
  pdfs: 'file',
  doc: 'file',
  docs: 'file',
  document: 'file',
  documents: 'file',
  attachment: 'file',
  attachments: 'file',
  psd: 'file',
  zip: 'file',
};

// Levenshtein distance for fuzzy keyword tolerance
export function levenshteinDistance(a: string, b: string): number {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;

  const row = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let prev = i;
    for (let j = 1; j <= b.length; j++) {
      const val = a[i - 1] === b[j - 1] ? row[j - 1] : Math.min(row[j - 1], prev, row[j]) + 1;
      row[j - 1] = prev;
      prev = val;
    }
    row[b.length] = prev;
  }
  return row[b.length];
}

function parseMonthDate(monthStr: string, year?: number, isEnd = false, refDate = new Date()): Date {
  const mIndex = MONTH_NAMES[monthStr.toLowerCase()];
  if (mIndex === undefined) return refDate;
  const targetYear = year ?? refDate.getFullYear();
  if (isEnd) {
    // End of that month (day 0 of next month gives last day of target month)
    return new Date(Date.UTC(targetYear, mIndex + 1, 0, 23, 59, 59, 999));
  }
  return new Date(Date.UTC(targetYear, mIndex, 1, 0, 0, 0, 0));
}

export function parseAmbiguousQuery(rawQuery: string, refDate = new Date()): ParsedSearchQuery {
  const trimmed = rawQuery.trim();
  if (!trimmed) {
    return {
      rawQuery: '',
      cleanedKeywords: '',
      hasAmbiguousFilters: false,
      explanation: '',
    };
  }

  let workingQuery = trimmed.toLowerCase();
  let contentType: AmbiguousContentType | undefined;
  let dateRange: AmbiguousDateRange | undefined;
  const explanationParts: string[] = [];

  // 1. Content format extraction (including typos)
  // Check tokens or phrases for format cues
  const formatTokens = Object.keys(FORMAT_TYPOS).sort((a, b) => b.length - a.length);
  for (const token of formatTokens) {
    // Check word boundaries for format cue
    const tokenRegex = new RegExp(`\\b${token}\\b`, 'i');
    if (tokenRegex.test(workingQuery)) {
      contentType = FORMAT_TYPOS[token];
      explanationParts.push(`Type: ${contentType.toUpperCase()}`);
      // Remove the format cue or phrases like "a video", "a cideo", "videos", etc.
      workingQuery = workingQuery.replace(new RegExp(`\\b(a|an|the|my)?\\s*${token}\\b`, 'gi'), ' ');
      break;
    }
  }

  // 2. Date extraction: Ranges ("between X and Y", "from X to Y")
  const betweenMonthsRegex = /\b(?:between|from)\s+([a-z]+)\s+(?:and|to)\s+([a-z]+)(?:\s+(\d{4}))?\b/i;
  const betweenDatesRegex = /\b(?:between|from)\s+(\d{4}-\d{1,2}-\d{1,2}|\d{1,2}\/\d{1,2}(?:\/\d{2,4})?|[a-z]+\s+\d{1,2})\s+(?:and|to)\s+(\d{4}-\d{1,2}-\d{1,2}|\d{1,2}\/\d{1,2}(?:\/\d{2,4})?|[a-z]+\s+\d{1,2})(?:\s+(\d{4}))?\b/i;
  const singleMonthRegex = /\b(?:in|during|saved in|from|of)?\s*([a-z]+)(?:\s+(\d{4}))?\b/i;

  const matchBetweenMonths = workingQuery.match(betweenMonthsRegex);
  if (matchBetweenMonths && MONTH_NAMES[matchBetweenMonths[1]] !== undefined && MONTH_NAMES[matchBetweenMonths[2]] !== undefined) {
    const m1 = matchBetweenMonths[1];
    const m2 = matchBetweenMonths[2];
    const y = matchBetweenMonths[3] ? parseInt(matchBetweenMonths[3], 10) : refDate.getFullYear();
    const start = parseMonthDate(m1, y, false, refDate);
    const end = parseMonthDate(m2, y, true, refDate);
    const label = `Between ${m1.charAt(0).toUpperCase() + m1.slice(1)} and ${m2.charAt(0).toUpperCase() + m2.slice(1)}${matchBetweenMonths[3] ? ` ${y}` : ''}`;
    dateRange = { start, end, label };
    explanationParts.push(label);
    workingQuery = workingQuery.replace(matchBetweenMonths[0], ' ');
  } else {
    // Check relative phrases
    if (/\b(?:saved\s+)?last\s+week\b/i.test(workingQuery)) {
      const end = new Date(refDate.getTime());
      const start = new Date(refDate.getTime() - 14 * 24 * 60 * 60 * 1000);
      dateRange = { start, end, label: 'Past 14 Days' };
      explanationParts.push('Past 14 Days');
      workingQuery = workingQuery.replace(/\b(?:saved\s+)?last\s+week\b/gi, ' ');
    } else if (/\b(?:saved\s+)?this\s+week\b/i.test(workingQuery)) {
      const day = refDate.getDay();
      const diffToMonday = refDate.getDate() - day + (day === 0 ? -6 : 1);
      const start = new Date(refDate.setDate(diffToMonday));
      start.setHours(0, 0, 0, 0);
      const end = new Date();
      dateRange = { start, end, label: 'This Week' };
      explanationParts.push('This Week');
      workingQuery = workingQuery.replace(/\b(?:saved\s+)?this\s+week\b/gi, ' ');
    } else if (/\b(?:saved\s+)?last\s+month\b/i.test(workingQuery)) {
      const y = refDate.getMonth() === 0 ? refDate.getFullYear() - 1 : refDate.getFullYear();
      const m = refDate.getMonth() === 0 ? 11 : refDate.getMonth() - 1;
      const start = new Date(Date.UTC(y, m, 1, 0, 0, 0));
      const end = new Date(Date.UTC(y, m + 1, 0, 23, 59, 59));
      dateRange = { start, end, label: 'Last Month' };
      explanationParts.push('Last Month');
      workingQuery = workingQuery.replace(/\b(?:saved\s+)?last\s+month\b/gi, ' ');
    } else if (/\b(?:saved\s+)?this\s+month\b/i.test(workingQuery)) {
      const y = refDate.getFullYear();
      const m = refDate.getMonth();
      const start = new Date(Date.UTC(y, m, 1, 0, 0, 0));
      const end = new Date(Date.UTC(y, m + 1, 0, 23, 59, 59));
      dateRange = { start, end, label: 'This Month' };
      explanationParts.push('This Month');
      workingQuery = workingQuery.replace(/\b(?:saved\s+)?this\s+month\b/gi, ' ');
    } else if (/\b(?:saved\s+)?yesterday\b/i.test(workingQuery)) {
      const start = new Date(refDate);
      start.setDate(start.getDate() - 1);
      start.setHours(0, 0, 0, 0);
      const end = new Date(start);
      end.setHours(23, 59, 59, 999);
      dateRange = { start, end, label: 'Yesterday' };
      explanationParts.push('Yesterday');
      workingQuery = workingQuery.replace(/\b(?:saved\s+)?yesterday\b/gi, ' ');
    } else if (/\b(?:saved\s+)?today\b/i.test(workingQuery)) {
      const start = new Date(refDate);
      start.setHours(0, 0, 0, 0);
      const end = new Date(refDate);
      end.setHours(23, 59, 59, 999);
      dateRange = { start, end, label: 'Today' };
      explanationParts.push('Today');
      workingQuery = workingQuery.replace(/\b(?:saved\s+)?today\b/gi, ' ');
    } else {
      // Check for standalone single month (e.g. "saved in october", "in october", "october 2026")
      const monthMatches = workingQuery.match(/\b(?:saved\s+in|in|from|during)?\s*(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|sept|october|oct|november|nov|december|dec)(?:\s+(\d{4}))?\b/i);
      if (monthMatches) {
        const monthKey = monthMatches[1].toLowerCase();
        const year = monthMatches[2] ? parseInt(monthMatches[2], 10) : refDate.getFullYear();
        const start = parseMonthDate(monthKey, year, false, refDate);
        const end = parseMonthDate(monthKey, year, true, refDate);
        const capitalizedMonth = monthKey.charAt(0).toUpperCase() + monthKey.slice(1);
        const label = `${capitalizedMonth} ${year}`;
        dateRange = { start, end, label };
        explanationParts.push(`Saved in ${label}`);
        workingQuery = workingQuery.replace(monthMatches[0], ' ');
      }
    }
  }

  // 3. Clean residual query keywords (strip conversational noise)
  const stopWords = new Set([
    'a', 'an', 'the', 'i', 'saved', 'i saved', 'save', 'saved in', 'items', 'item',
    'between', 'which', 'date', 'and', 'from', 'to', 'in', 'during', 'about',
    'for', 'called', 'titled', 'show', 'show me', 'find', 'search', 'my', 'that',
    'which date and which', 'me', 'with', 'of', 'on', 'at', 'recently', 'recent'
  ]);

  const rawTokens = workingQuery
    .replace(/[^\w\s.-]/g, ' ')
    .split(/\s+/)
    .filter(Boolean);

  const meaningfulTokens = rawTokens.filter((token) => !stopWords.has(token));
  const cleanedKeywords = meaningfulTokens.join(' ').trim();

  const hasAmbiguousFilters = Boolean(contentType || dateRange || (meaningfulTokens.length < rawTokens.length && rawTokens.length > 0));

  let finalExplanation = '';
  if (explanationParts.length > 0) {
    finalExplanation = explanationParts.join(' • ');
    if (cleanedKeywords) {
      finalExplanation += ` • Matching "${cleanedKeywords}"`;
    }
  } else if (cleanedKeywords) {
    finalExplanation = `Matching "${cleanedKeywords}"`;
  }

  return {
    rawQuery: trimmed,
    cleanedKeywords,
    contentType,
    dateRange,
    hasAmbiguousFilters,
    explanation: finalExplanation || trimmed,
  };
}

export function filterAndRankAmbiguousItems(
  items: LaterBoxItem[],
  parsed: ParsedSearchQuery
): SearchResultItem[] {
  const { contentType, dateRange, cleanedKeywords, rawQuery } = parsed;
  const keywordsLower = (cleanedKeywords || rawQuery).toLowerCase().trim();
  const searchTokens = keywordsLower ? keywordsLower.split(/\s+/).filter(Boolean) : [];

  const results: SearchResultItem[] = [];

  for (const item of items) {
    let score = 0;
    const matchedFields: string[] = [];
    let formatMatch = true;
    let dateMatch = true;

    // 1. Content format validation & bonus
    const cType = item.metadata?.content_type || (item.url ? 'link' : 'note');
    const ext = item.url?.split('.').pop()?.toLowerCase() || '';
    const isFile = item.type === 'file' || ['pdf', 'psd', 'zip', 'docx', 'xlsx', 'txt'].includes(ext);
    const isVideo = cType === 'video' || item.url?.includes('youtube.com') || item.url?.includes('youtu.be') || item.url?.includes('vimeo.com') || item.url?.includes('tiktok.com');
    const isMusic = cType === 'music' || item.url?.includes('spotify.com') || item.url?.includes('music.apple.com') || item.url?.includes('soundcloud.com');
    const isNote = !item.url && (item.type === 'note' || Boolean(item.text_content));
    const isArticle = cType === 'article' || (Boolean(item.url) && !isVideo && !isMusic && !isFile);

    if (contentType) {
      if (contentType === 'video' && !isVideo) formatMatch = false;
      else if (contentType === 'music' && !isMusic) formatMatch = false;
      else if (contentType === 'file' && !isFile) formatMatch = false;
      else if (contentType === 'note' && !isNote) formatMatch = false;
      else if (contentType === 'article' && !isArticle) formatMatch = false;

      if (!formatMatch) {
        continue; // Exclude non-matching format if explicitly requested
      } else {
        score += 30;
        matchedFields.push('format');
      }
    }

    // 2. Date range validation & bonus
    if (dateRange && (dateRange.start || dateRange.end)) {
      const itemDate = new Date(item.created_at || item.updated_at || Date.now());
      if (dateRange.start && itemDate < dateRange.start) {
        dateMatch = false;
      }
      if (dateRange.end && itemDate > dateRange.end) {
        dateMatch = false;
      }

      if (!dateMatch) {
        continue; // Exclude item if outside requested date range
      } else {
        score += 40;
        matchedFields.push('date');
      }
    }

    // 3. Keyword & Semantic text scoring
    const title = (item.metadata?.title || item.title || '').toLowerCase();
    const domain = (item.metadata?.domain || (item.url ? new URL(item.url, 'http://localhost').hostname : '')).toLowerCase();
    const desc = (item.metadata?.description || item.text_content || '').toLowerCase();
    const noteContent = (item.note?.content || '').toLowerCase();
    const collectionNames = (item.collections || []).map((c) => c.name.toLowerCase()).join(' ');

    if (searchTokens.length === 0) {
      // If query was purely a filter like "a cideo i saved in october", keep all items matching filters
      score += 10;
    } else {
      let matchedTokensCount = 0;
      for (const token of searchTokens) {
        let tokenMatched = false;

        // Exact substring matches
        if (title.includes(token)) {
          score += 25;
          tokenMatched = true;
          if (!matchedFields.includes('title')) matchedFields.push('title');
        }
        if (desc.includes(token)) {
          score += 15;
          tokenMatched = true;
          if (!matchedFields.includes('description')) matchedFields.push('description');
        }
        if (domain.includes(token)) {
          score += 15;
          tokenMatched = true;
          if (!matchedFields.includes('domain')) matchedFields.push('domain');
        }
        if (noteContent.includes(token)) {
          score += 20;
          tokenMatched = true;
          if (!matchedFields.includes('notes')) matchedFields.push('notes');
        }
        if (collectionNames.includes(token)) {
          score += 15;
          tokenMatched = true;
          if (!matchedFields.includes('collection')) matchedFields.push('collection');
        }

        // Fuzzy match if not exact match (typo tolerance)
        if (!tokenMatched && token.length >= 4) {
          const allWords = `${title} ${desc} ${noteContent}`.split(/\s+/);
          for (const word of allWords) {
            if (word.length >= 3 && Math.abs(word.length - token.length) <= 2) {
              const dist = levenshteinDistance(token, word);
              if (dist <= 1 || (dist <= 2 && token.length >= 6)) {
                score += 10;
                tokenMatched = true;
                if (!matchedFields.includes('fuzzy')) matchedFields.push('fuzzy');
                break;
              }
            }
          }
        }

        if (tokenMatched) {
          matchedTokensCount++;
        }
      }

      // If keywords were provided and NONE matched, skip this item
      if (matchedTokensCount === 0) {
        continue;
      }
    }

    results.push({
      item,
      score,
      matchedFields,
      dateMatch,
      formatMatch,
    });
  }

  // Sort descending by score, then by recency
  return results.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return new Date(b.item.created_at).getTime() - new Date(a.item.created_at).getTime();
  });
}
