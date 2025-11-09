import { DateTime } from 'luxon';

export function anchorKeyFor(range: 'day'|'week'|'month'|'year', d = new Date(), tz = 'UTC'): string {
  const dt = DateTime.fromJSDate(d).setZone(tz);
  
  if (range === 'day') return dt.toISODate()!;
  
  if (range === 'month') return `${dt.toFormat('yyyy-MM')}`;
  
  if (range === 'year') return `${dt.toFormat('yyyy')}`;
  
  const week = dt.weekNumber;
  return `${dt.weekYear}-W${String(week).padStart(2,'0')}`;
}

