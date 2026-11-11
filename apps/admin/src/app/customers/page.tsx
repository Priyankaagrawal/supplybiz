import { ManagementList, ManagementSearch } from '../management-ui';
export const dynamic = 'force-dynamic';
export default async function Customers({ searchParams }: { searchParams: Promise<ManagementSearch> }) { return <ManagementList kind="customers" query={await searchParams} />; }
