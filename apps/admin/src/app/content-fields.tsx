import { randomUUID } from 'node:crypto';
import { csrf } from '../lib/security';
import { contentSignature } from '../lib/content';
export function ContentFields({ token, action, id }: { token: string; action: string; id: string }) {
 const key = randomUUID();
 return <><input type="hidden" name="csrf" value={csrf(token)} /><input type="hidden" name="action" value={action} /><input type="hidden" name="id" value={id} />
 <input type="hidden" name="key" value={key} /><input type="hidden" name="signature" value={contentSignature(token, `${action}:${id}`, key)} /></>;
}
