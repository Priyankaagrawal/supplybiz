import type { ReactNode } from 'react';
import './globals.css';
export const metadata = { title: 'Supply Biz Admin' };
export default function Layout({ children }: { children: ReactNode }) {
 return <html lang="en"><body className="bg-slate-50 text-slate-900"><main className="mx-auto max-w-3xl p-6">{children}</main></body></html>;
}
