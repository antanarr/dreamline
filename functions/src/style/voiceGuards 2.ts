const BANNED_TERMS = [
  "lucky",
  "luck",
  "manifest",
  "manifesting",
  "destined",
  "destiny",
  "aura",
  "vibes",
  "today you will",
  "today you'll",
  "fortune"
] as const;

const REQUIRED_IMAGERY = [
  "pulse",
  "fiber",
  "grain",
  "signal",
  "field",
  "lab",
  "specimen",
  "breath",
  "circuit",
  "atlas",
  "nerve",
  "archive"
] as const;

export function findBannedTerms(text: string): string[] {
  const lower = text.toLowerCase();
  const hits = new Set<string>();
  for (const term of BANNED_TERMS) {
    if (lower.includes(term)) {
      hits.add(term);
    }
  }
  return Array.from(hits.values());
}

function hasImagery(text: string): boolean {
  const lower = text.toLowerCase();
  return REQUIRED_IMAGERY.some((token) => lower.includes(token));
}

function sentenceLengths(text: string): number[] {
  return text
    .split(/[.!?]+/)
    .map((chunk) => chunk.trim())
    .filter(Boolean)
    .map((chunk) => chunk.split(/\s+/).filter(Boolean).length);
}

export function clinicalVoiceIssues(text: string): string[] {
  const issues: string[] = [];
  const trimmed = text.trim();

  if (!trimmed) {
    issues.push("empty manuscript");
    return issues;
  }

  const banned = findBannedTerms(trimmed);
  if (banned.length) {
    issues.push(`banned terms: ${banned.join(", ")}`);
  }

  if (!hasImagery(trimmed)) {
    issues.push("missing tactile/clinical imagery");
  }

  if (sentenceLengths(trimmed).some((len) => len > 40)) {
    issues.push("sentence exceeds 40 words");
  }

  return issues;
}

export const voiceGuardConstants = {
  BANNED_TERMS,
  REQUIRED_IMAGERY
};
