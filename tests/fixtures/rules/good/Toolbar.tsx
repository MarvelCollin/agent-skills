import { Input } from '@/components/ui/input'

export function Toolbar({ query, onQuery }: { query: string, onQuery: (value: string) => void }) {
  return (
    <div className="flex gap-2">
      <div className="relative w-full sm:w-72">
        <Input aria-label="Search products" value={query} onChange={(e) => onQuery(e.target.value)} />
      </div>
      <div className="data-[state=open]:animate-in data-[state=open]:fade-in-0" data-state="open">Filters</div>
    </div>
  )
}
