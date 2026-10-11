import { initializeApp } from "firebase/app"
import { getFirestore, collection, getDocs } from "firebase/firestore"

const app = initializeApp({
  apiKey: "AIzaExampleOnlyWebConfig",
  authDomain: "pocketcoach-demo.firebaseapp.com",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID
})

export const db = getFirestore(app)

export async function getPlans() {
  const snapshot = await getDocs(collection(db, "plans"))
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }))
}
