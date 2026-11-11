import { randomUUID } from 'node:crypto';
import { csrf } from '../../lib/security';
import { planSignature } from '../../lib/plans';
export function PlanFields({ token, scope }: { token: string; scope: string }) {
 const key = randomUUID();
 return <><input type="hidden" name="csrf" value={csrf(token)} /><input type="hidden" name="key" value={key} />
 <input type="hidden" name="signature" value={planSignature(token, scope, key)} /></>;
}
