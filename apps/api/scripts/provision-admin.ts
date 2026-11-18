// Operator-only bootstrap. JSON on stdin; never place credentials in argv or env.
import { Prisma, PrismaClient } from '@prisma/client';
import { assertUnbreached } from '../src/modules/admin-auth/admin-password';
import * as argon2 from 'argon2';
import { z } from 'zod';
import { ADMIN_GRANTS } from '../src/modules/admin-auth/admin-policy';
let stage: 'input' | 'password-check' | 'database' = 'input';
async function main(): Promise<void> {
 let input = '';
 for await (const chunk of process.stdin) { input += String(chunk); if (input.length > 4096) throw new Error('Input too large'); }
 const value = z.object({ email: z.string().email().max(254), password: z.string().min(12).max(128),
   role: z.enum(['SUPER_ADMIN', 'OPS', 'SUPPORT', 'FINANCE']) }).strict().parse(JSON.parse(input));
 if (!Object.prototype.hasOwnProperty.call(ADMIN_GRANTS, value.role)) throw new Error('Invalid role');
 stage = 'password-check';
 await assertUnbreached(value.password);
 stage = 'database';
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
void main().catch((error: unknown) => {
 let reason: string;
 if (error instanceof z.ZodError) {
   const fields = [...new Set(error.issues.map(issue => String(issue.path[0] ?? 'input')))];
   reason = `Invalid ${fields.join(', ')}. Use a valid email, a 12–128 character password and a supported role.`;
 } else if (stage === 'input') {
   reason = 'Expected one JSON object on stdin; do not include prompts or shell output.';
 } else if (stage === 'password-check') {
   reason = error instanceof Error && error.message === 'Password appears in a breach'
     ? 'Password appears in a breach. Choose a different unique password.'
     : 'Password-check service unavailable. Check internet access to api.pwnedpasswords.com and retry.';
 } else if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
   reason = 'An admin account with that email already exists. Sign in with it or use a different email.';
 } else {
   reason = 'Database operation failed. Check DATABASE_URL, migrations and database permissions.';
 }
 // Never print raw exceptions: validation/database details can contain credentials.
 console.error(`Admin creation failed. ${reason}`);
 process.exitCode = 1;
});
