import { AstroTime, Body, Ecliptic, EclipticLongitude, GeoVector } from "astronomy-engine";

const PLANETS = ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"] as const;
const OUTERS = new Set(["Uranus", "Neptune", "Pluto"]);
const MAJOR_ASPECTS = [
  { name: "conjunction", angle: 0 },
  { name: "sextile", angle: 60 },
  { name: "square", angle: 90 },
  { name: "trine", angle: 120 },
  { name: "opposition", angle: 180 }
] as const;

const ASPECT_COPY: Record<AspectName, string> = {
  conjunction: "fuses motives",
  sextile: "opens practice rooms",
  square: "pressurizes growth",
  trine: "lets patterns flow",
  opposition: "mirrors polarities"
};

const BODY_WEIGHTS: Record<PlanetName, number> = {
  Sun: 1,
  Moon: 0.9,
  Mercury: 0.75,
  Venus: 0.75,
  Mars: 0.85,
  Jupiter: 0.7,
  Saturn: 0.7,
  Uranus: 0.6,
  Neptune: 0.55,
  Pluto: 0.55
};

export type PlanetName = (typeof PLANETS)[number];
export type AspectName = (typeof MAJOR_ASPECTS)[number]["name"];

export interface AspectHit {
  transitBody: PlanetName;
  natalBody: PlanetName;
  aspect: AspectName;
  delta: number;
  orb: number;
  score: number;
}

export interface DailyTransitSummary {
  dateISO: string;
  headline: string;
  bullets: string[];
  intensityScore: number;
  aspects: AspectHit[];
}

type LongitudeMap = Record<PlanetName, number>;

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function toDate(iso: string, label: string): Date {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) {
    throw new Error(`Invalid ${label}: ${iso}`);
  }
  return date;
}

function midday(date: Date): Date {
  const next = new Date(date);
  next.setUTCHours(12, 0, 0, 0);
  return next;
}

function enumerateDays(start: Date, end: Date): Date[] {
  if (start > end) {
    throw new Error("start date must be before end date");
  }
  const days: Date[] = [];
  const cursor = new Date(start);
  cursor.setUTCHours(12, 0, 0, 0);
  const endMid = midday(end);

  while (cursor.getTime() <= endMid.getTime()) {
    days.push(new Date(cursor));
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return days;
}

function normalizeDegrees(value: number): number {
  return ((value % 360) + 360) % 360;
}

function eclipticLongitude(body: PlanetName | Body, date: Date): number {
  if (body === "Sun") {
    const vec = GeoVector(body as Body, date, true);
    const ecl = Ecliptic(vec);
    return normalizeDegrees(ecl.elon);
  }
  const t = new AstroTime(date);
  const lon = EclipticLongitude(body as Body, t);
  return normalizeDegrees(lon);
}

function longitudeMap(date: Date): LongitudeMap {
  const map = {} as LongitudeMap;
  for (const planet of PLANETS) {
    map[planet] = eclipticLongitude(planet as Body, date);
  }
  return map;
}

function angularSeparation(a: number, b: number): number {
  let diff = Math.abs(a - b) % 360;
  if (diff > 180) diff = 360 - diff;
  return diff;
}

function orbAllowance(transit: PlanetName, natal: PlanetName): number {
  if (transit === "Moon" || natal === "Moon") return 8;
  if (OUTERS.has(transit) || OUTERS.has(natal)) return 3;
  return 6;
}

function describeBullet(hit: AspectHit): string {
  const desc = ASPECT_COPY[hit.aspect];
  const pct = Math.round(hit.score * 100);
  return `${hit.transitBody} ${hit.aspect} ${hit.natalBody} · ${desc} · orb ${hit.delta.toFixed(1)}° · ${pct}%`;
}

function summarizeDay(date: Date, natal: LongitudeMap): DailyTransitSummary {
  const transitPositions = longitudeMap(date);
  const hits: AspectHit[] = [];

  for (const transit of PLANETS) {
    for (const target of PLANETS) {
      const diff = angularSeparation(transitPositions[transit], natal[target]);
      for (const aspect of MAJOR_ASPECTS) {
        const delta = Math.abs(diff - aspect.angle);
        const orb = orbAllowance(transit, target);
        if (delta <= orb) {
          const closeness = 1 - delta / orb;
          const weight = BODY_WEIGHTS[transit];
          const score = +(clamp(closeness, 0, 1) * weight);
          hits.push({
            transitBody: transit,
            natalBody: target,
            aspect: aspect.name,
            delta: +delta.toFixed(2),
            orb,
            score: +score.toFixed(3)
          });
        }
      }
    }
  }

  hits.sort((a, b) => b.score - a.score || a.delta - b.delta);

  const top = hits[0];
  const headline = top ? `${top.transitBody} ${top.aspect} ${top.natalBody}` : "Quiet sky";
  const bullets = hits.length > 0
    ? hits.slice(0, 4).map(describeBullet)
    : ["No major applying aspects within orb today; stay observant."];

  const intensity = clamp(
    hits.slice(0, 3).reduce((sum, hit) => sum + hit.score, 0),
    0,
    1
  );

  return {
    dateISO: date.toISOString(),
    headline,
    bullets,
    intensityScore: +intensity.toFixed(3),
    aspects: hits
  };
}

export function buildTransitRange(params: { birthISO: string; startISO: string; endISO: string }): DailyTransitSummary[] {
  const birth = toDate(params.birthISO, "birthISO");
  const start = toDate(params.startISO, "startISO");
  const end = toDate(params.endISO, "endISO");
  const natal = longitudeMap(birth);
  const days = enumerateDays(start, end);

  return days.map((day) => summarizeDay(day, natal));
}

export const __internal = {
  enumerateDays,
  longitudeMap,
  summarizeDay
};
