export default function Skeleton({ lines }: { lines: number }) {
  return (
    <div aria-busy="true" className="space-y-3">
      {Array.from({ length: lines }).map((_, i) => (
        <div key={i} className="h-4 animate-pulse rounded bg-slate-200" />
      ))}
    </div>
  )
}
