import type { User } from './UserCard.types'

export function UserCard({ user }: { user: User }) {
  return <p>{user.name}</p>
}
