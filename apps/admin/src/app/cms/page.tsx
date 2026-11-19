// S-A-12 / FR-408 / T-158. React escapes every plaintext preview.
import { randomUUID } from 'node:crypto';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { api } from '../../lib/api';
import { ContentFields } from '../content-fields';
import ContentForm from '../content-form';
import type { components } from '../../../../../packages/ts-client/src/generated/openapi';
export const dynamic = 'force-dynamic';
type Faq = components['schemas']['FaqRow'];
function FaqForm({ token, row }: { token: string; row?: Faq }) {
 const id = row?.id ?? randomUUID();
 return <ContentForm back="/cms" label={row ? 'Save FAQ' : 'Create FAQ'}><ContentFields token={token} action="faq" id={id} />
 <input type="hidden" name="expectedUpdatedAt" value={row?.updatedAt ?? ''} />
 <label htmlFor={`${id}-topic`}>Topic (lowercase slug)</label><input className="min-h-12 rounded border p-2" id={`${id}-topic`} name="topic" required pattern="[a-z][a-z0-9-]{0,39}" defaultValue={row?.topic ?? 'general'} />
 <label htmlFor={`${id}-question`}>English question</label><input className="min-h-12 rounded border p-2" id={`${id}-question`} name="question" maxLength={200} required defaultValue={row?.question} />
 <label htmlFor={`${id}-answer`}>English answer (plain text)</label><textarea className="min-h-32 rounded border p-2" id={`${id}-answer`} name="answer" maxLength={5000} required defaultValue={row?.answer} />
 <label className="flex min-h-12 items-center gap-3"><input type="checkbox" name="published" defaultChecked={row?.published ?? false} />Publish FAQ (uncheck to hide without deleting)</label>
 </ContentForm>;
}
export default async function Cms({ searchParams }: { searchParams: Promise<{ offset?: string; result?: string }> }) {
 const token = (await cookies()).get('sb_admin')?.value; if (!token) redirect('/login');
 const query = await searchParams, offset = query.offset && /^\d{1,6}$/.test(query.offset) && Number(query.offset) <= 100000 ? Number(query.offset) : 0;
 const client = api(token);
 try {
  const me = await client.GET('/api/v1/admin/auth/me');
  if (me.response.status === 401) redirect('/login?error=expired');
  if (!me.data?.permissions.includes('cms.manage')) return <p role="alert">You do not have permission to manage content.</p>;
  const [faqs, history, terms, privacy] = await Promise.all([
   client.GET('/api/v1/admin/faqs', { params: { query: { offset } } }), client.GET('/api/v1/admin/legal'),
   client.GET('/api/v1/admin/legal/{type}', { params: { path: { type: 'TERMS' } } }),
   client.GET('/api/v1/admin/legal/{type}', { params: { path: { type: 'PRIVACY' } } }),
  ]);
  if (!faqs.data || !history.data || !terms.data && terms.response.status !== 404 || !privacy.data && privacy.response.status !== 404) return <p role="alert">Could not load current content. Reload to try again.</p>;
  return <><Link className="inline-flex min-h-12 items-center underline" href="/">Admin workspace</Link><h1 className="text-2xl font-semibold">Help and legal content</h1>
   {query.result === 'saved' && <p role="status">Content saved.</p>}
   <p className="my-4">English plain text only. Published FAQs appear in the public content API. Publishing Terms or Privacy creates an immutable version; review approved wording before publishing. Existing consent records are retained.</p>
   <h2 className="text-xl font-semibold">Create FAQ</h2><FaqForm token={token} />
   <h2 className="text-xl font-semibold">FAQs</h2>{faqs.data.items.length === 0 && <p>No FAQs on this page.</p>}
   {faqs.data.items.map(row => <details className="my-3 rounded border p-3" key={row.id}><summary className="min-h-12 cursor-pointer break-words p-3">{row.topic}: {row.question} ({row.published ? 'Published' : 'Hidden'})</summary><FaqForm token={token} row={row} /></details>)}
   <p>{offset + faqs.data.items.length} of {faqs.data.total} FAQs</p><nav aria-label="FAQ pages" className="flex flex-wrap gap-4">{offset > 0 && <Link className="inline-flex min-h-12 items-center underline" href={`/cms?offset=${Math.max(0,offset-20)}`}>Previous page</Link>}{offset+20 < faqs.data.total && <Link className="inline-flex min-h-12 items-center underline" href={`/cms?offset=${offset+20}`}>Next page</Link>}</nav>
   {(['TERMS','PRIVACY'] as const).map(type => {
    const current = type === 'TERMS' ? terms.data : privacy.data;
    return <section key={type} className="my-6"><h2 className="text-xl font-semibold">{type === 'TERMS' ? 'Terms' : 'Privacy'}</h2>
     {current ? <><p>Current version: {current.version} · {current.publishedAt}</p><details className="rounded border p-3"><summary className="min-h-12 cursor-pointer">Read current published text</summary><h3>{current.title}</h3><p className="whitespace-pre-wrap break-words">{current.text}</p></details></> : <p>No published version. No placeholder legal text will be published.</p>}
     <ContentForm back="/cms" label="Publish new legal version"><ContentFields token={token} action="legal" id={type} />
      <input type="hidden" name="expectedVersion" value={current?.version ?? ''} />
      <label htmlFor={`${type}-version`}>New immutable version</label><input className="min-h-12 rounded border p-2" id={`${type}-version`} name="version" maxLength={50} pattern="[A-Za-z0-9][A-Za-z0-9._-]{0,49}" required />
      <label htmlFor={`${type}-title`}>English title</label><input className="min-h-12 rounded border p-2" id={`${type}-title`} name="title" maxLength={120} required />
      <label htmlFor={`${type}-text`}>Approved English text</label><textarea className="min-h-64 rounded border p-2" id={`${type}-text`} name="text" maxLength={50000} required />
      <label className="flex min-h-12 items-center gap-3"><input type="checkbox" name="confirm" required />I reviewed this text and intend to publish a new legal version.</label>
     </ContentForm></section>;
   })}
   <h2 className="text-xl font-semibold">Latest 20 published legal versions</h2>
   {history.data.items.map(row => <details key={`${row.type}:${row.version}`} className="my-3 rounded border p-3"><summary className="min-h-12 cursor-pointer break-words">{row.type}: {row.version} · {row.publishedAt}</summary><h3>{row.title}</h3><p className="whitespace-pre-wrap break-words">{row.text}</p><p className="break-all">SHA-256: {row.sha256}</p></details>)}
  </>;
 } catch (e) {
  // Next redirect is a framework control-flow exception, not a service outage.
  if (e instanceof Error && 'digest' in e) throw e;
  return <p role="alert">Content service unavailable. Reload to try again.</p>;
 }
}
