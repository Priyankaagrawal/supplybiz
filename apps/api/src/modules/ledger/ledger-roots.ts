// Append-only reversal chains resolve to their immutable original source.
import { Prisma } from '@prisma/client';
export function ledgerRoots(vendorId:string){return Prisma.sql`WITH RECURSIVE ledger_roots AS (
  SELECT id,ref_type,ref_id,type AS root_type FROM ledger_entries WHERE vendor_id=${vendorId}::uuid AND reverses_entry_id IS NULL
  UNION ALL
  SELECT e.id,r.ref_type,r.ref_id,r.root_type FROM ledger_entries e JOIN ledger_roots r ON r.id=e.reverses_entry_id WHERE e.vendor_id=${vendorId}::uuid
)`;}
