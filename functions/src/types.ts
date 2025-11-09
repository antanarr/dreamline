export type HoroscopeArea = {
  id: 'relationships'|'work_money'|'home_body'|'creativity_learning'|'spirituality'|'routine_habits';
  title: string;
  score: number;            // -1..+1 (pressure/support)
  bullets: string[];        // 2–4 tight bullets
  actions?: { do?: string[]; dont?: string[] };
};

export type HoroscopeStructured = {
  range: 'day'|'week'|'month'|'year';
  anchorKey: string;        // e.g., 2025-11-06, 2025-W45, 2025-11, 2025
  headline: string;         // 1 sentence, second-person
  summary: string;          // 2–4 sentences, clinical‑poetic
  areas: HoroscopeArea[];
  transits: { label: string; tone: 'supportive'|'challenging'|'neutral'; }[];
  model: string;
  generatedAt: string;      // ISO
};

