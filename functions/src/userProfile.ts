import { getFirestore } from 'firebase-admin/firestore';

export interface UserProfile {
  tier?: 'free' | 'plus' | 'pro';
  createdAt?: string;
}

export async function getOrInitUserProfile(uid: string): Promise<UserProfile> {
  const db = getFirestore();
  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  
  if (snap.exists) {
    const data = snap.data();
    return {
      tier: data?.tier || 'free',
      createdAt: data?.createdAt || new Date().toISOString()
    };
  }
  
  // Initialize with defaults
  const profile: UserProfile = {
    tier: 'free',
    createdAt: new Date().toISOString()
  };
  
  await ref.set({ ...profile, _ts: new Date() }, { merge: true });
  return profile;
}

