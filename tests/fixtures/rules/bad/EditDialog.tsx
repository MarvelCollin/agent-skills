import { Dialog, DialogContent, DialogFooter } from '@/components/ui/dialog'
import { useEditForm } from './useEditForm'

export function EditDialog() {
  const { open, setOpen, isValid, save } = useEditForm()
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-lg">
        <form onSubmit={save}>
          <DialogFooter>
            <button type="submit" disabled={!isValid}>Save</button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
