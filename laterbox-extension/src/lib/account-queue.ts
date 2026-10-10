import type { Capture, CaptureResult, QueuedCapture } from '../types/capture';
export type Connection = { userId: string; token: string; isPro: boolean | null };
export interface QueueDependencies {
  connection(): Promise<Connection>;
  read(): Promise<QueuedCapture[]>;
  write(queue: QueuedCapture[]): Promise<void>;
  send(capture: Capture, token: string): Promise<CaptureResult>;
  state(result: CaptureResult, pending: number): Promise<void>;
}
export function createAccountQueue(deps: QueueDependencies) {
  let tail: Promise<unknown> = Promise.resolve();
  const serial = <T>(fn: () => Promise<T>): Promise<T> => {
    const next = tail.then(fn,fn); tail = next.catch(()=>{}); return next;
  };
  const matching = (queue: QueuedCapture[], userId: string) => queue.filter(row=>row.userId===userId).length;
  const save = (capture: Capture): Promise<CaptureResult> => serial(async () => {
    const account = await deps.connection();
    if (!account.userId || !account.token) { const result = { status: 'needsAuth' } as const; await deps.state(result,0); return result; }
    const entry = { userId: account.userId, capture: { ...capture, captureId: capture.captureId || crypto.randomUUID() } };
    const queue = await deps.read(); queue.push(entry);
    // Persist before sending: replay remains safe if the worker is suspended after acceptance.
    await deps.write(queue);
    const result = await deps.send(entry.capture,account.token);
    if (result.status === 'saved' || result.status === 'proRequired' || result.status === 'error') {
      await deps.write(queue.filter(row=>row!==entry));
    }
    await deps.state(result,matching(await deps.read(),account.userId));
    return result;
  });
  const flush = (): Promise<number> => serial(async () => {
    const account = await deps.connection();
    if (!account.userId || !account.token || account.isPro !== true) return 0;
    let queue = await deps.read(); if (!matching(queue,account.userId)) return 0; let count = 0; let last: CaptureResult = { status: 'saved' };
    for (const entry of [...queue]) {
      if (entry.userId !== account.userId) continue;
      const current = await deps.connection();
      if (current.userId !== account.userId || current.token !== account.token) break;
      last = await deps.send(entry.capture,account.token);
      if (last.status !== 'saved') break;
      queue = queue.filter(row=>row!==entry); await deps.write(queue); count++;
    }
    await deps.state(last,matching(queue,account.userId));
    return count;
  });
  return { save, flush };
}
