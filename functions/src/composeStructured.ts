import { HoroscopeStructured, HoroscopeArea } from './types';

type Transit = { label: string; planetA: string; planetB: string; aspect: string; orb: number; house?: number; tone: 'supportive'|'challenging'|'neutral' };

export function mapTransitsToAreas(transits: Transit[]): HoroscopeArea[] {
  const areas: Record<HoroscopeArea['id'], HoroscopeArea> = {
    relationships: { id:'relationships', title:'Relationships', score:0, bullets:[] },
    work_money: { id:'work_money', title:'Work & Money', score:0, bullets:[] },
    home_body: { id:'home_body', title:'Home & Body', score:0, bullets:[] },
    creativity_learning: { id:'creativity_learning', title:'Thinking & Creativity', score:0, bullets:[] },
    spirituality: { id:'spirituality', title:'Spirituality', score:0, bullets:[] },
    routine_habits: { id:'routine_habits', title:'Routine & Habits', score:0, bullets:[] },
  };
  
  const push = (k: keyof typeof areas, s:number, b:string) => { 
    areas[k].score += s; 
    if (areas[k].bullets.length<4) areas[k].bullets.push(b); 
  };
  
  const toneVal = (t: Transit['tone']) => t==='supportive'? +1 : t==='challenging'? -1 : 0;

  for (const t of transits) {
    const val = toneVal(t.tone) * (t.orb>0? Math.max(0.2, (1 - Math.min(t.orb,6)/6)) : 0.5);
    const lbl = t.label;
    
    const set = new Set([t.planetA.toLowerCase(), t.planetB.toLowerCase()]);
    
    if (set.has('venus') || set.has('moon') || set.has('juno') || (t.house===7)) push('relationships', val, lbl);
    if (set.has('saturn') || set.has('mars') || set.has('sun') || (t.house===10) || (t.house===6)) push('work_money', val, lbl);
    if (set.has('moon') || set.has('cancer') || set.has('saturn') || (t.house===4)) push('home_body', val, lbl);
    if (set.has('mercury') || set.has('uranus') || (t.house===3) || (t.house===5)) push('creativity_learning', val, lbl);
    if (set.has('neptune') || set.has('jupiter') || (t.house===9) || (t.house===12)) push('spirituality', val, lbl);
    push('routine_habits', val*0.6, lbl);
  }
  
  // Add simple do/don't based on score
  for (const a of Object.values(areas)) {
    const s = a.score;
    a.actions = {
      do: s >= 0 ? ['Lean into supportive threads','Schedule a small step','Name one cue to follow'] : ['Name the pressure point','Slow your reply','Set a 10‑min buffer'],
      dont: s >= 0 ? ['Overexplain','Rush the win'] : ['Catastrophize','Take the bait']
    };
  }
  
  return Object.values(areas);
}

export function toStructured(range: HoroscopeStructured['range'], anchorKey: string, model: string, transits: Transit[], headline: string, summary: string): HoroscopeStructured {
  const areas = mapTransitsToAreas(transits).filter(a => a.bullets.length>0).slice(0,6);
  return { 
    range, 
    anchorKey, 
    headline, 
    summary, 
    areas, 
    transits: transits.map(t=>({label:t.label,tone:t.tone})), 
    model, 
    generatedAt:new Date().toISOString() 
  };
}

