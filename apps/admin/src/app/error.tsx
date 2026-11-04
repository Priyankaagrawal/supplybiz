"use client";
export default function ErrorPage({ reset }: { reset: () => void }) { return <section role="alert"><h1 className="text-xl font-semibold">Admin is unavailable</h1><p className="my-4">Try again shortly. Contact your administrator if this continues.</p><button onClick={reset} className="min-h-12 rounded bg-slate-800 px-6 text-white">Try again</button></section>; }
