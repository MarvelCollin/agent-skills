import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { SelectTrigger } from '@/components/ui/select'

export function ProfileForm() {
  return (
    <form className="flex flex-wrap gap-2">
      <Input className="h-9 w-64" placeholder="Full name" />
      <SelectTrigger className="h-11">Role</SelectTrigger>
      <Button className="h-10 transition-all duration-700">Save</Button>
      <div className="panel" style={{ transition: 'height 300ms ease' }}>More</div>
      <div className="toast" style={{ transitionTimingFunction: 'cubic-bezier(0.34, 1.56, 0.64, 1)' }}>Saved</div>
    </form>
  )
}
