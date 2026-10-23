'use client';

import { useState } from 'react';
import { Download, Upload, ShieldCheck, AlertTriangle, Loader2, FileArchive, CheckCircle2 } from 'lucide-react';
import { useAuth } from '@/lib/store/AuthContext';
import { useItems } from '@/lib/store/ItemContext';
import { readLocalAttachment } from '@/lib/utils/local-attachments';
import { createWebBackup, encryptWebBackup, decryptWebBackup, backupPreview, type WebBackup } from '@/lib/utils/web-backup';

function downloadBytes(bytes: Uint8Array, filename: string) {
  const blob = new Blob([Uint8Array.from(bytes).buffer], { type: 'application/octet-stream' });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 30_000);
}

export function BackupRestorePanel() {
  const { user } = useAuth();
  const { items, deletedItems, collections, restoreWebBackup } = useItems();
  const [exportPassword, setExportPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [importPassword, setImportPassword] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<WebBackup | null>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const exportEncrypted = async () => {
    if (busy) return;
    setError(null);
    setMessage(null);
    if (exportPassword.length < 8 || exportPassword !== confirmPassword) {
      setError('Enter matching backup passwords with at least 8 characters.');
      return;
    }
    setBusy(true);
    try {
      const archive = await createWebBackup(items, deletedItems, collections,
        attachment => readLocalAttachment(attachment.id, user?.id || null));
      const ciphertext = await encryptWebBackup(archive, exportPassword);
      downloadBytes(ciphertext, 'LaterBox-Web-' + new Date().toISOString().slice(0, 10) + '.laterboxweb');
      setMessage(archive.unavailableAttachments.length > 0
        ? 'Encrypted backup downloaded. ' + archive.unavailableAttachments.length +
          ' attachment(s) have cloud-only or missing bytes and were NOT included. Keep an additional copy of those files.'
        : 'Encrypted backup downloaded. Keep your password safe; it cannot be recovered.');
      setExportPassword('');
      setConfirmPassword('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not export your backup.');
    } finally {
      setBusy(false);
    }
  };

  const inspect = async () => {
    if (!file || busy) return;
    setError(null);
    setMessage(null);
    setPreview(null);
    setBusy(true);
    try {
      if (file.size > 60 * 1024 * 1024) throw new Error('The selected file is over the 60 MB safety limit.');
      const archive = await decryptWebBackup(await file.arrayBuffer(), importPassword);
      setPreview(archive);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not read this backup.');
    } finally {
      setBusy(false);
    }
  };

  const restore = async () => {
    if (!preview || busy) return;
    const ids = new Set([...items, ...deletedItems].map(item => item.id));
    const plan = backupPreview(preview, ids);
    const newCollectionCount = preview.collections.filter(c =>
      !collections.some(existing => existing.name.trim().toLowerCase() === c.name.trim().toLowerCase())
    ).length;
    if (plan.newItems === 0 && newCollectionCount === 0) {
      setMessage('Everything in this backup is already present. No changes made.');
      return;
    }
    if (!window.confirm('Restore ' + plan.newItems + ' new item(s) and ' + newCollectionCount +
      ' collection(s) to this browser? Existing items are never replaced.')) return;
    setBusy(true);
    setError(null);
    setMessage(null);
    try {
      const result = await restoreWebBackup(preview);
      setMessage('Restored ' + result.restored + ' items, ' + result.restoredCollections +
        ' collections and ' + result.restoredFiles + ' attachment files. Skipped ' +
        result.skipped + ' existing IDs.' +
        (result.missingFiles ? ' ' + result.missingFiles + ' attachment(s) had no recoverable file bytes.' : '') +
        ' Review collections and cloud sync before removing the original backup.');
      setPreview(null);
      setFile(null);
      setImportPassword('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Restore failed; original library was kept.');
    } finally {
      setBusy(false);
    }
  };

  const plan = preview ? backupPreview(preview, new Set([...items, ...deletedItems].map(i => i.id))) : null;
  const newCollections = preview?.collections.filter(c =>
    !collections.some(existing => existing.name.trim().toLowerCase() === c.name.trim().toLowerCase())
  ).length ?? 0;
  return (
    <section className="rounded-3xl border border-[#e4e0d5] bg-white p-6 sm:p-7 space-y-5" aria-label="Backup and restore">
      <div className="space-y-1">
        <h2 className="flex items-center gap-2 text-base font-extrabold text-[#171711]">
          <ShieldCheck className="h-5 w-5" /> Backup & Restore
        </h2>
        <p className="text-xs leading-relaxed text-[#6c6b63]">
          Create a password-protected backup of the items on this browser, collections,
          notes and locally available attachments. No password is uploaded.
        </p>
      </div>
      <div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-xs leading-relaxed text-amber-900">
        <AlertTriangle className="mr-1 inline h-4 w-4 align-text-bottom" />
        Browser backups are not yet compatible with iOS .laterbox archives.
        Cloud-only attachment bytes may be unavailable; we report any omissions.
        Encrypted backups have a 60 MB limit and should be kept somewhere safe.
      </div>

      <div className="space-y-3 rounded-2xl border border-[#e4e0d5] bg-[#faf9f5] p-4">
        <h3 className="flex items-center gap-2 text-sm font-bold text-[#171711]">
          <Download className="h-4 w-4" /> Export encrypted backup
        </h3>
        <div className="grid gap-2 sm:grid-cols-2">
          <input aria-label="Backup password" type="password" autoComplete="new-password"
            placeholder="Password (8+ characters)" value={exportPassword}
            onChange={event => setExportPassword(event.target.value)}
            className="w-full rounded-xl border border-[#e4e0d5] bg-white px-3 py-2.5 text-sm" />
          <input aria-label="Confirm backup password" type="password" autoComplete="new-password"
            placeholder="Confirm password" value={confirmPassword}
            onChange={event => setConfirmPassword(event.target.value)}
            className="w-full rounded-xl border border-[#e4e0d5] bg-white px-3 py-2.5 text-sm" />
        </div>
        <button type="button" onClick={() => void exportEncrypted()} disabled={busy}
          className="inline-flex items-center gap-2 rounded-xl bg-[#171711] px-4 py-2.5 text-xs font-bold text-white disabled:opacity-50">
          {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileArchive className="h-4 w-4" />}
          Download encrypted .laterboxweb
        </button>
      </div>

      <div className="space-y-3 rounded-2xl border border-[#e4e0d5] bg-[#faf9f5] p-4">
        <h3 className="flex items-center gap-2 text-sm font-bold text-[#171711]">
          <Upload className="h-4 w-4" /> Preview and restore
        </h3>
        <input aria-label="Choose LaterBox Web backup" type="file" accept=".laterboxweb,application/octet-stream"
          onChange={event => { setFile(event.target.files?.[0] || null); setPreview(null); setError(null); }}
          className="block max-w-full text-xs text-[#6c6b63] file:mr-3 file:rounded-lg file:border-0 file:bg-[#e6edb0] file:px-3 file:py-2 file:font-bold file:text-[#171711]" />
        <input aria-label="Password for selected backup" type="password" autoComplete="off"
          placeholder="Backup password" value={importPassword}
          onChange={event => { setImportPassword(event.target.value); setPreview(null); }}
          className="w-full rounded-xl border border-[#e4e0d5] bg-white px-3 py-2.5 text-sm" />
        <button type="button" disabled={busy || !file || !importPassword}
          onClick={() => void inspect()}
          className="rounded-xl border border-[#e4e0d5] bg-white px-4 py-2.5 text-xs font-bold text-[#171711] disabled:opacity-50">
          {busy ? 'Checking…' : 'Preview backup'}
        </button>
        {plan && (
          <div className="space-y-2 rounded-xl border border-[#d0db84] bg-[#f3f7d9] p-3 text-xs text-[#171711]" role="status">
            <p className="font-bold">Preview: {plan.total} items, {plan.newItems} new, {plan.conflicts.length} existing IDs skipped</p>
            <p>{preview?.collections.length} collections ({newCollections} new) · {Object.keys(preview?.attachmentFiles || {}).length} file(s) available · {plan.unavailableAttachments} missing at export</p>
            {plan.conflicts.length > 0 && <p className="text-[#6c6b63]">Existing titles include: {plan.conflicts.slice(0, 3).join(', ')}</p>}
            <button type="button" onClick={() => void restore()} disabled={busy || (!plan.newItems && !newCollections)}
              className="rounded-xl bg-[#171711] px-4 py-2.5 font-bold text-white disabled:opacity-50">
              {busy ? 'Restoring…' : 'Restore new items'}
            </button>
          </div>
        )}
      </div>

      {error && <p role="alert" className="rounded-xl bg-red-50 px-3 py-2 text-xs font-semibold text-red-800">{error}</p>}
      {message && <p role="status" className="flex items-start gap-2 rounded-xl bg-[#e6edb0] px-3 py-2 text-xs font-semibold text-[#171711]">
        <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0" /> {message}
      </p>}
      <p className="text-[11px] leading-relaxed text-[#77756d]">
        Restore is additive and skips existing IDs. It does not overwrite or delete items.
        Browser storage and cloud synchronization are separate; confirm restored collections and attachments
        before relying on another device. Keep your backup until checked.
      </p>
    </section>
  );
}
