// laterbox-web/src/lib/utils/dashboardNotices.ts
/** Pure notice-list helpers shared by any rotating, independently dismissible notice feed. */
export interface NoticeIdentity { id: string }

export function visibleNotices<T extends NoticeIdentity>(
  notices: readonly T[],
  dismissedIds: ReadonlySet<string>,
): T[] {
  const seen = new Set<string>();
  return notices.filter(notice => {
    if (!notice.id || seen.has(notice.id) || dismissedIds.has(notice.id)) return false;
    seen.add(notice.id);
    return true;
  });
}

export function nextNoticeId(
  ids: readonly string[],
  currentId: string | null,
  direction: 1 | -1 = 1,
): string | null {
  if (!ids.length) return null;
  const index = currentId === null ? -1 : ids.indexOf(currentId);
  if (index < 0) return direction === 1 ? ids[0] : ids[ids.length - 1];
  return ids[(index + direction + ids.length) % ids.length];
}
