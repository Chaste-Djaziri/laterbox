'use client';

import { useState } from 'react';
import { useAuth } from '@/lib/store/AuthContext';

export function SupportForm() {
  const { user, session } = useAuth();
  const [email, setEmail] = useState(user?.email || '');
  const [category, setCategory] = useState('problem');
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [reference, setReference] = useState('');
  const field = 'w-full rounded-xl border border-[#e4e0d5] bg-white px-3 py-2.5 text-sm text-[#171711] focus:outline-none focus:ring-2 focus:ring-[#bac77e]';

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    if (busy) return;
    setBusy(true); setError('');
    try {
      const response = await fetch('/api/support', {
        method: 'POST', headers: { 'Content-Type': 'application/json', ...(session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {}) },
        body: JSON.stringify({ email, category, subject, message, platform: 'web', appVersion: '' }),
      });
      const result = (await response.json().catch(() => ({}))) as { id?: unknown; error?: unknown };
      if (!response.ok || typeof result.id !== 'string') throw new Error(typeof result.error === 'string' && result.error ? result.error : 'We could not send your request. Please try again.');
      setReference(result.id); setSubject(''); setMessage('');
    } catch (failure) { setError(failure instanceof Error ? failure.message : 'Please try again.'); }
    finally { setBusy(false); }
  }

  return (
    <section className="rounded-2xl border border-[#e4e0d5] bg-white/60 p-5 space-y-4">
      <div><h2 className="font-bold text-[#171711]">Help &amp; Report a Problem</h2><p className="text-sm text-[#6c6b63] mt-1">Tell us what happened or how we can help. Include steps to reproduce a problem. Please leave out passwords and sensitive information.</p></div>
      {reference ? <div role="status" className="space-y-3 text-sm"><p>Your request has been received. We can reply to {email}.</p><p className="break-all text-xs text-[#6c6b63]">Reference: {reference}</p><button type="button" onClick={() => setReference('')} className="font-semibold underline">Send another request</button></div> :
        <form onSubmit={submit} className="space-y-3">
          <fieldset disabled={busy} className="space-y-3 disabled:opacity-60">
            <label className="block text-sm space-y-1"><span>What do you need?</span><select value={category} onChange={e => setCategory(e.target.value)} className={field}><option value="problem">Report a problem</option><option value="help">I need help</option><option value="feedback">Feedback or suggestion</option><option value="other">Something else</option></select></label>
            <label className="block text-sm space-y-1"><span>Reply email</span><input type="email" autoComplete="email" required maxLength={254} value={email} onChange={e => setEmail(e.target.value)} className={field} /></label>
            <label className="block text-sm space-y-1"><span>Subject</span><input required minLength={3} maxLength={160} value={subject} onChange={e => setSubject(e.target.value)} className={field} /></label>
            <label className="block text-sm space-y-1"><span>Message</span><textarea required minLength={10} maxLength={5000} rows={5} value={message} onChange={e => setMessage(e.target.value)} className={field} /></label>
            <p className="text-xs text-[#6c6b63]">Your email, message, and platform are saved with this request.</p>
            <button type="submit" className="rounded-xl bg-[#171711] px-4 py-2.5 text-sm font-bold text-[#e6edb0]">{busy ? 'Sending…' : 'Send request'}</button>
          </fieldset>
          {error && <p role="alert" className="text-sm text-red-700">{error}</p>}
        </form>}
    </section>
  );
}
