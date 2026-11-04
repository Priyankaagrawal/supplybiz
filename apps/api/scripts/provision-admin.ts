// Operator-only bootstrap. JSON on stdin; never place credentials in argv or env.
import { PrismaClient } from '@prisma/client';
import { assertUnbreached } from '../src/modules/admin-auth/admin-password';
import * as argon2 from 'argon2';
import { z } from 'zod';
import { ADMIN_GRANTS } from '../src/modules/admin-auth/admin-policy';
async function main(): Promise<void> {
 let input = '';
 for await (const chunk of process.stdin) { input += String(chunk); if (input.length > 4096) throw new Error('Input too large'); }
 const value = z.object({ email: z.string().email().max(254), password: z.string().min(12).max(128),
   role: z.enum(['SUPER_ADMIN', 'OPS', 'SUPPORT', 'FINANCE']) }).strict().parse(JSON.parse(input));
 if (!Object.prototype.hasOwnProperty.call(ADMIN_GRANTS, value.role)) throw new Error('Invalid role');
 await assertUnbreached(value.password);
 const db = new PrismaClient();
 try {
   await db.$transaction(async tx => {
     const user = await tx.admin_users.create({ data: { email: value.email.toLowerCase(),
       password_hash: await argon2.hash(value.password, { type: argon2.argon2id }), role: value.role } });
     await tx.admin_auth_events.create({ data: { admin_id: user.id, action: 'ACCOUNT_PROVISIONED' } });
   });
 } finally { await db.$disconnect(); }
 console.log('Admin created. Complete authenticator enrolment at sign in.');
}
void main().catch(() => { console.error('Admin creation failed. Check input, duplicate account, breach status and provider/database availability.'); process.exitCode = 1; });
