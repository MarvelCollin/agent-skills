import { Button } from '@/components/ui/button'
import { Field } from '@/components/ui/field'
import { Input } from '@/components/ui/input'

export function ProfileForm() {
  return (
    <form className="grid grid-cols-6 gap-x-4 gap-y-5">
      <Field label="Full name" className="col-span-6">
        <Input className="h-10" placeholder="Ana Putri" />
      </Field>
      <Button className="h-10 transition-colors duration-150 motion-reduce:transition-none">Save profile</Button>
    </form>
  )
}
