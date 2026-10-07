import { Dialog, DialogBody, DialogContent, DialogFooter } from '@/components/ui/dialog'
import { useEditForm } from './useEditForm'

export function EditDialog() {
  const { open, setOpen, isSaving, save } = useEditForm()
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent size="lg">
        <form onSubmit={save}>
          <DialogBody />
          <DialogFooter>
            <button type="submit" disabled={isSaving}>Save</button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
