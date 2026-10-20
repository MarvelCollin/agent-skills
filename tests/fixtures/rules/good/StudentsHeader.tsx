import { TableHead, TableHeader, TableRow } from '@/components/ui/table'

export function StudentsHeader() {
  return (
    <TableHeader className="sticky top-0">
      <TableRow>
        <TableHead>Name</TableHead>
      </TableRow>
    </TableHeader>
  )
}
