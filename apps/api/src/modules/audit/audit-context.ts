import { Prisma } from '@prisma/client';
import { isIP } from 'node:net';
// Transaction-local context: never carries across pooled connections. Use only
// server-authenticated identities and the socket IP, never forwarded/client IDs.
export async function auditContext(tx: Prisma.TransactionClient, actorId?: string, ip?: string): Promise<void> {
  await tx.$queryRaw`SELECT set_config('supplybiz.audit_actor', ${actorId ?? ''}, true),
    set_config('supplybiz.audit_ip', ${ip && isIP(ip) ? ip : ''}, true)`;
}
