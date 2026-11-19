'use client';
import { useRef, useState, type FormEvent, type ReactNode } from 'react';
export default function AdminOperationForm({children,report=false}:{children:ReactNode;report?:boolean}) {
 const frozen=useRef<FormData|null>(null),[busy,setBusy]=useState(false),[locked,setLocked]=useState(false),[retry,setRetry]=useState(true),[message,setMessage]=useState('');
 async function submit(event:FormEvent<HTMLFormElement>) {
  event.preventDefault();if(busy||!retry)return;
  frozen.current??=new FormData(event.currentTarget);setBusy(true);setLocked(true);setMessage('Processing...');
  try {
   const response=await fetch('/admins/save',{method:'POST',body:frozen.current,credentials:'same-origin'});
   if(response.ok) {
    if(!report){frozen.current=null;window.location.assign('/admins?result=saved');return;}
    const blob=await response.blob(),url=URL.createObjectURL(blob),link=document.createElement('a');
    link.href=url;link.download='platform-summary.csv';link.click();URL.revokeObjectURL(url);
    setMessage('CSV downloaded. Retry downloads the same snapshot. Reload for a fresh snapshot.');
   } else if(response.status===401) {frozen.current=null;window.location.assign('/login?error=expired');}
   else if(response.status>=500||response.status===429)setMessage('Result uncertain. Keep this page open and retry the same request.');
   else {setRetry(false);frozen.current=null;setMessage('Request refused. Check permissions and fields, then reload to review current records. A changed record or your own account cannot be overwritten.');}
  } catch {setMessage('Connection unavailable. Keep this page open and retry the same frozen request.');}
  finally {setBusy(false);}
 }
 return <form onSubmit={e=>{void submit(e);}} className="my-4 grid gap-3 rounded border bg-white p-4">
  <fieldset disabled={locked} className="grid min-w-0 gap-3">{children}</fieldset>
  <p role="status" aria-live="polite">{message}</p>
  <button disabled={busy||!retry} className="min-h-12 rounded bg-slate-800 px-6 text-white disabled:opacity-50">{busy?'Processing...':locked?'Retry same request':report?'Download CSV':'Save account'}</button>
  {locked&&<a className="inline-flex min-h-12 items-center underline" href={report?'/reports':'/admins'}>Reload and review before starting a different request</a>}
 </form>;
}
