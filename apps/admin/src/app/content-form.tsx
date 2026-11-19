'use client';
import { useRef, useState, type FormEvent, type ReactNode } from 'react';

// Only the form/request lifecycle needs client state. Credentials stay in the BFF.
export default function ContentForm({ children, back, label }: { children: ReactNode; back: '/cms'|'/config'; label: string }) {
 const frozen = useRef<FormData | null>(null);
 const [busy, setBusy] = useState(false), [message, setMessage] = useState(''), [retry, setRetry] = useState(true), [uncertain, setUncertain] = useState(false);
 async function submit(event: FormEvent<HTMLFormElement>) {
  event.preventDefault(); if (busy || !retry) return;
  frozen.current ??= new FormData(event.currentTarget);
  setBusy(true); setMessage('Saving...'); setUncertain(true);
  try {
   const response = await fetch('/cms/save', { method: 'POST', body: frozen.current, credentials: 'same-origin' });
   if (response.ok) { window.location.assign(`${back}?result=saved`); return; }
   if (response.status === 401) { window.location.assign('/login?error=expired'); return; }
   if (response.status >= 500 || response.status === 429) setMessage('Could not confirm whether this request saved. Retry the same frozen request below. Keep this page open.');
   else {
    setRetry(false);
    setMessage(response.status === 409 ? 'This record changed or the legal version already exists. Reload and review current values before saving again.' : 'The request was refused. Check your permissions and fields, then reload.');
   }
  } catch { setMessage('Connection unavailable. This request may already have saved. Keep this page open and retry the same frozen request.'); }
  finally { setBusy(false); }
 }
 return <form onSubmit={event => { void submit(event); }} className="my-4 grid gap-3 rounded border bg-white p-4">
  <fieldset disabled={busy || uncertain} className="grid min-w-0 gap-3">{children}</fieldset>
  <p role="status" aria-live="polite" className="break-words">{message}</p>
  <button disabled={busy || !retry} className="min-h-12 rounded bg-slate-800 px-6 text-white disabled:opacity-50">{busy ? 'Saving...' : uncertain ? 'Retry same request' : label}</button>
  {uncertain && <a className="inline-flex min-h-12 items-center underline" href={back}>Reload and review saved records before starting a different request</a>}
 </form>;
}
