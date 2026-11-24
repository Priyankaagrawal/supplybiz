'use client';
import { useRef, useState, type FormEvent, type ReactNode } from 'react';
export default function PrivacyForm({children,download=false}:{children:ReactNode;download?:boolean}) {
 const frozen=useRef<FormData|null>(null),[busy,setBusy]=useState(false),[locked,setLocked]=useState(false),[retry,setRetry]=useState(true),[message,setMessage]=useState('');
 async function submit(e:FormEvent<HTMLFormElement>){
  e.preventDefault();if(busy||!retry)return;frozen.current??=new FormData(e.currentTarget);setBusy(true);setLocked(true);setMessage('Processing...');
  try{
   const response=await fetch('/privacy/save',{method:'POST',body:frozen.current,credentials:'same-origin'});
   if(response.ok){
    if(!download){frozen.current=null;window.location.assign('/privacy?result=saved');return;}
    const blob=await response.blob(),url=URL.createObjectURL(blob),link=document.createElement('a');link.href=url;link.download='subject-data.json';link.click();URL.revokeObjectURL(url);setMessage('Downloaded a current snapshot. Retrying creates a fresh snapshot and an access audit event.');
   }else if(response.status===401){frozen.current=null;window.location.assign('/login?error=expired');}
   else if(response.status>=500||response.status===429)setMessage('Result uncertain. Keep this tab open and retry the same request.');
   else{setRetry(false);frozen.current=null;setMessage('Request refused or changed. Check current permissions, ownership, expiry and fields; reload to review before trying again.');}
  }catch{setMessage('Connection unavailable. Keep this tab open and retry the same frozen request.');}finally{setBusy(false);}
 }
 return <form onSubmit={e=>{void submit(e);}} className="my-4 grid gap-3 rounded border bg-white p-4"><fieldset disabled={locked} className="grid min-w-0 gap-3">{children}</fieldset><p role="status" aria-live="polite">{message}</p><button disabled={busy||!retry} className="min-h-12 rounded bg-slate-800 px-6 text-white disabled:opacity-50">{busy?'Processing...':locked?'Retry same request':download?'Download subject JSON':'Save privacy request'}</button>{locked&&<a className="inline-flex min-h-12 items-center underline" href="/privacy">Reload and review requests</a>}</form>;
}
