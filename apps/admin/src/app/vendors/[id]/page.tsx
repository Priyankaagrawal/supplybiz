import { ManagementDetail } from '../../management-ui';
export const dynamic = 'force-dynamic';
export default async function Vendor({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ result?: string }> }) { return <ManagementDetail kind="vendors" id={(await params).id} result={(await searchParams).result} />; }
