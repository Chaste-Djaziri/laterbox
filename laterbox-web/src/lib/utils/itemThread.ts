export interface ThreadPollOption {
  id: string;
  text: string;
  votes: number;
}

export interface ThreadPoll {
  question: string;
  options: ThreadPollOption[];
  userVotedOptionId?: string;
}

export interface ItemThreadEntry {
  id: string;
  type: 'message' | 'poll' | 'note';
  authorName?: string;
  content: string;
  createdAt: string;
  updatedAt?: string;
  attachedToId?: string;
  attachedSnippet?: string;
  reactions?: Record<string, number>;
  userReactions?: string[];
  poll?: ThreadPoll;
}

export interface ItemThreadData {
  version: 1;
  entries: ItemThreadEntry[];
}

export const POPULAR_REACTIONS = ['👍', '❤️', '💡', '🔥', '🚀', '👏'];

export function parseItemThread(noteContent?: string | null): ItemThreadEntry[] {
  if (!noteContent || !noteContent.trim()) {
    return [];
  }

  const trimmed = noteContent.trim();

  // Try JSON thread format
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      const parsed = JSON.parse(trimmed);
      if (parsed && Array.isArray(parsed.entries)) {
        return parsed.entries as ItemThreadEntry[];
      }
    } catch {
      // Fallback to plain text note below
    }
  }

  // Legacy plain-text note fallback
  return [
    {
      id: 'initial-note',
      type: 'note',
      authorName: 'Note',
      content: trimmed,
      createdAt: new Date().toISOString(),
    },
  ];
}

export function serializeItemThread(entries: ItemThreadEntry[]): string {
  if (!entries || entries.length === 0) {
    return '';
  }
  const data: ItemThreadData = {
    version: 1,
    entries,
  };
  return JSON.stringify(data);
}

export function addThreadEntry(
  currentEntries: ItemThreadEntry[],
  newEntry: Omit<ItemThreadEntry, 'id' | 'createdAt'>
): ItemThreadEntry[] {
  const entry: ItemThreadEntry = {
    ...newEntry,
    id: `entry-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    createdAt: new Date().toISOString(),
    reactions: {},
    userReactions: [],
  };
  return [...currentEntries, entry];
}

export function editThreadEntry(
  currentEntries: ItemThreadEntry[],
  entryId: string,
  newContent: string
): ItemThreadEntry[] {
  return currentEntries.map((e) => {
    if (e.id !== entryId) return e;
    return {
      ...e,
      content: newContent,
      updatedAt: new Date().toISOString(),
    };
  });
}

export function deleteThreadEntry(
  currentEntries: ItemThreadEntry[],
  entryId: string
): ItemThreadEntry[] {
  return currentEntries.filter((e) => e.id !== entryId);
}

export function toggleThreadReaction(
  currentEntries: ItemThreadEntry[],
  entryId: string,
  emoji: string
): ItemThreadEntry[] {
  return currentEntries.map((entry) => {
    if (entry.id !== entryId) return entry;

    const reactions = { ...(entry.reactions || {}) };
    const userReactions = [...(entry.userReactions || [])];
    const alreadyReacted = userReactions.includes(emoji);

    if (alreadyReacted) {
      // Remove reaction
      const currentCount = reactions[emoji] || 1;
      if (currentCount <= 1) {
        delete reactions[emoji];
      } else {
        reactions[emoji] = currentCount - 1;
      }
      return {
        ...entry,
        reactions,
        userReactions: userReactions.filter((r) => r !== emoji),
      };
    } else {
      // Add reaction
      reactions[emoji] = (reactions[emoji] || 0) + 1;
      userReactions.push(emoji);
      return {
        ...entry,
        reactions,
        userReactions,
      };
    }
  });
}

export function voteThreadPoll(
  currentEntries: ItemThreadEntry[],
  entryId: string,
  optionId: string
): ItemThreadEntry[] {
  return currentEntries.map((entry) => {
    if (entry.id !== entryId || !entry.poll) return entry;

    const currentVoted = entry.poll.userVotedOptionId;
    const sameOption = currentVoted === optionId;

    const updatedOptions = entry.poll.options.map((opt) => {
      let votes = opt.votes || 0;
      if (currentVoted === opt.id) {
        votes = Math.max(0, votes - 1);
      }
      if (!sameOption && opt.id === optionId) {
        votes += 1;
      }
      return { ...opt, votes };
    });

    return {
      ...entry,
      poll: {
        ...entry.poll,
        options: updatedOptions,
        userVotedOptionId: sameOption ? undefined : optionId,
      },
    };
  });
}
