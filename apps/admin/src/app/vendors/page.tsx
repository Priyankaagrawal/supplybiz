import { ManagementList, ManagementSearch } from '../management-ui';
export const dynamic = 'force-dynamic';
export default async function Vendors({ searchParams }: { searchParams: Promise<ManagementSearch> }) { return <ManagementList kind="vendors" query={await searchParams} />; }
