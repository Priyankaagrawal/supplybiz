/** Exact integer paise; never round a persisted BigInt through Number. */
export function dashboardMoney(paise: string): string {
 if (!/^\d+$/.test(paise)) throw new Error('Invalid recorded amount');
 const amount = BigInt(paise), hundred = BigInt(100);
 return `₹${new Intl.NumberFormat('en-IN').format(amount / hundred)}.${(amount % hundred).toString().padStart(2, '0')}`;
}
export function deliverySuccess(delivered: number, failed: number): string {
 const attempts = delivered + failed;
 return attempts === 0 ? 'No completed attempts' : `${(100 * delivered / attempts).toFixed(1)}% (${delivered} of ${attempts})`;
}
