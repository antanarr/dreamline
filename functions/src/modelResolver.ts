import { getFirestore } from 'firebase-admin/firestore';
import { UserProfile } from './userProfile';

const db = getFirestore();

export async function loadConfig() {
  const snap = await db.doc('config/current').get();
  const data = snap.data();
  
  return {
    model: {
      pro: data?.model?.pro || 'gpt-4o',
      plus: data?.model?.plus || 'gpt-4o-mini',
      free: {
        initial: data?.model?.free?.initial || 'gpt-4o-mini',
        fallback: data?.model?.free?.fallback || 'gpt-4.1-mini'
      }
    },
    honeymoonDays: data?.honeymoonDays || 7
  };
}

export function resolveModelForUser(tier: string | undefined, createdAt: string | undefined, cfg: any): string {
  if (tier === 'pro') return cfg.model.pro;
  if (tier === 'plus') return cfg.model.plus;
  
  const daysSinceCreation = createdAt 
    ? Math.floor((Date.now() - Date.parse(createdAt)) / 86400000)
    : 999;
  
  return daysSinceCreation <= cfg.honeymoonDays 
    ? cfg.model.free.initial 
    : cfg.model.free.fallback;
}

