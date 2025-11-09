import * as functions from "firebase-functions";
import { onRequest } from "firebase-functions/v2/https";
import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import corsLib from "cors";
import fetch from "node-fetch";
import { z } from "zod";
import { defineSecret } from "firebase-functions/params";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { clinicalVoiceIssues, voiceGuardConstants } from "./style/voiceGuards.js";
import { buildTransitRange } from "./astro/transitEngine.js";
import { anchorKeyFor } from "./anchors.js";
import { HoroscopeSchema as HoroscopeJSONSchema } from "./schemas.js";
import { HoroscopeStructured } from "./types.js";
import { loadConfig, resolveModelForUser } from "./modelResolver.js";
import { getOrInitUserProfile } from "./userProfile.js";

if (!getApps().length) {
  initializeApp();
}

const db = getFirestore();
const cors = corsLib({ origin: true });

const OPENAI_KEY = defineSecret("OPENAI_API_KEY");
const OPENAI_BASE = process.env.OPENAI_BASE || "https://api.openai.com";
const ENABLE_SELF_CHECK = false;

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PROMPT_DIR = join(__dirname, "../prompts");
const DREAM_INTERPRET_SYSTEM_PROMPT = readFileSync(join(PROMPT_DIR, "dream_interpret_system.md"), "utf-8").trim();
const DREAM_INTERPRET_USER_TEMPLATE = readFileSync(join(PROMPT_DIR, "dream_interpret_user.md"), "utf-8").trim();

// Schemas
const ExtractSchema = z.object({
  symbols: z.array(z.object({ name: z.string(), count: z.number().int().nonnegative() })),
  tone: z.string(),
  archetypes: z.array(z.string())
});

const InterpretSchema = z.object({
  headline: z.string(),
  summary: z.string(),
  psychology: z.string(),
  astrology: z.string().nullable(),
  symbols: z.array(z.object({
    name: z.string(),
    meaning: z.string(),
    confidence: z.number().min(0).max(1)
  })),
  actions: z.array(z.string()).min(2).max(4),
  disclaimer: z.string()
});

const ChatSchema = z.object({
  reply: z.string(),
  followupPrompt: z.string().optional(),
  warnings: z.array(z.string()).optional()
});

const HoroscopeSchema = z.object({
  range: z.enum(["day", "week", "month", "year"]),
  items: z.array(z.object({
    dateISO: z.string(),
    headline: z.string(),
    bullets: z.array(z.string())
  }))
});

// Helpers
async function callResponses(model: string, input: any, OPENAI: string): Promise<any> {
  // Transform response_format to text.format for Responses API
  const payload: any = { model, max_output_tokens: 1200 };
  
  // Map the input messages to the Responses API format
  if (input.input) {
    payload.input = input.input;
  }
  
  // Handle response_format -> text format transformation for Responses API
  if (input.response_format) {
    // Old format: { type: "json_schema", json_schema: { name, schema, strict } }
    // New format: { text: { format: { type, name, schema, strict } } }
    const rf = input.response_format;
    if (rf.type === "json_schema" && rf.json_schema) {
      payload.text = {
        format: {
          type: "json_schema",
          name: rf.json_schema.name,
          schema: rf.json_schema.schema,
          strict: rf.json_schema.strict
        }
      };
    } else {
      // If it's not json_schema, just pass it through
      payload.text = {
        format: rf
      };
    }
  }
  
  // Pass through other parameters like temperature
  if (input.temperature !== undefined) {
    payload.temperature = input.temperature;
  }
  
  const res = await fetch(`${OPENAI_BASE}/v1/responses`, {
    method: "POST",
    headers: { "Authorization": `Bearer ${OPENAI}`, "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
  if (!res.ok) {
    const body = await res.text();
    throw new functions.https.HttpsError("internal", `OpenAI error ${res.status}: ${body}`);
  }
  return await res.json();
}

// Mini symbol lexicon
const SYMBOL_NOTES: Record<string, string> = {
  water: "Emotion seeking motion; permeability; intuition.",
  door: "Threshold between familiar and new; agency over entry.",
  room: "Compartmentalized psyche; safety or secrecy.",
  house: "Self-structure; identity; security; roles.",
  bird: "Message, perspective; aspiration.",
  teeth: "Power/articulation; vulnerability about expression.",
  flight: "Freedom vs avoidance; higher vantage.",
  ocean: "Vast unconscious; dissolution of edges."
};

// Scope gate
export const scopeGate = onRequest({ secrets: [OPENAI_KEY], cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const OPENAI = OPENAI_KEY.value();
    if (!OPENAI) return res.status(503).json({ error: "LLM unavailable" });

    const { text, model = "gpt-4.1-mini" } = req.body || {};

    const prompt = [
      { role: "system", content: "Classify whether the user message is in-scope for Dreamline (dream symbols, emotions, subconscious motifs, or the supplied transits). OUT-OF-SCOPE: politics/news/medical/legal/finance requests or general life coaching without dream content. Respond as JSON {inScope:boolean, reason:string} only." },
      { role: "user", content: String(text ?? "") }
    ];

    const r = await callResponses(model, {
      input: prompt,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "ScopeGate",
          schema: {
            type: "object",
            properties: {
              inScope: { type: "boolean" },
              reason: { type: "string" }
            },
            required: ["inScope", "reason"],
            additionalProperties: false
          },
          strict: true
        }
      }
    }, OPENAI);

    const textOut = r.output_text ?? (r.output?.[0]?.content?.[0]?.text ?? "{}");
    try {
      res.json(JSON.parse(textOut));
    } catch {
      res.json({ inScope: true, reason: "fallback" });
    }
  });
});

// Oracle: extract
export const oracleExtract = onRequest({ secrets: [OPENAI_KEY], cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const OPENAI = OPENAI_KEY.value();
    if (!OPENAI) return res.status(503).json({ error: "LLM unavailable" });

    const dream = String(req.body?.dream || "");
    const model = String(req.body?.model || "gpt-4.1-mini");

    const system = "You are Dreamline's extraction engine. Detect concrete dream symbols (nouns/noun phrases), the emotional tone, and 1–3 archetypes. Be conservative; do not invent. Use canonical symbols when possible (e.g., water, door, room, house, flight, bird, ocean, teeth). Tone is a single lowercase descriptor. Archetypes from a small lexicon (threshold, journey, shadow, rebirth, loss, security, transformation). Output schema exactly.";

    const schema = {
      type: "object",
      properties: {
        symbols: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string" },
              count: { type: "integer", minimum: 0 }
            },
            required: ["name", "count"],
            additionalProperties: false
          }
        },
        tone: { type: "string" },
        archetypes: { type: "array", items: { type: "string" } }
      },
      required: ["symbols", "tone", "archetypes"],
      additionalProperties: false
    };

    const prompt = [
      { role: "system", content: system },
      { role: "user", content: dream }
    ];

    const r = await callResponses(model, {
      input: prompt,
      response_format: {
        type: "json_schema",
        json_schema: { name: "OracleExtraction", schema, strict: true }
      }
    }, OPENAI);

    const text = r.output_text ?? (r.output?.[0]?.content?.[0]?.text ?? "");
    const parsed = ExtractSchema.safeParse(JSON.parse(text));

    if (!parsed.success) return res.status(422).json({ error: parsed.error.flatten() });

    res.json(parsed.data);
  });
});

// Self-check/Revise helper
async function selfCheckRevise(draftJson: any, extraction: any, transit: any, history: any, OPENAI: string, model: string) {
  if (!ENABLE_SELF_CHECK) return draftJson;

  const sys = "Score the provided Dreamline Oracle draft (JSON) on 5 beats: mirror phrase, anchor symbol, tension named, transit tie, micro-action. Return JSON {scores:{mirror:0..1,anchor:0..1,tension:0..1,transit:0..1,action:0..1}}. If any < 0.6, revise the draft once to satisfy all five beats and return ONLY the final JSON matching the OracleInterpretation schema.";

  const prompt = [
    { role: "system", content: sys },
    { role: "user", content: "Draft:" + JSON.stringify(draftJson) },
    { role: "user", content: "Extraction:" + JSON.stringify(extraction) },
    { role: "user", content: "Transit:" + JSON.stringify(transit) },
    { role: "user", content: "History:" + JSON.stringify(history || {}) },
    { role: "user", content: "Symbol notes:" + JSON.stringify(SYMBOL_NOTES) }
  ];

  const r = await callResponses(model, { input: prompt }, OPENAI);

  const txt = r.output_text ?? (r.output?.[0]?.content?.[0]?.text ?? "");

  try {
    const parsed = JSON.parse(txt);
    // If it looks like a score wrapper, keep original; if it looks like full schema, use it.
    if (parsed && parsed.shortSummary && parsed.longForm && parsed.actionPrompt && parsed.symbolCards) return parsed;
    return draftJson;
  } catch {
    return draftJson;
  }
}

function summarizeComposeContext(range: string, items: unknown, history?: unknown, birth?: unknown): string {
  const payload = {
    range,
    items,
    history: history ?? {},
    birth: birth ?? {}
  };
  return JSON.stringify(payload);
}

async function enforceClinicalText(text: string, context: string, model: string, OPENAI: string) {
  let draft = text.trim();
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const issues = clinicalVoiceIssues(draft);
    if (issues.length === 0) return draft;

    const system = `You edit Dreamline copy. Remove banned terms (${voiceGuardConstants.BANNED_TERMS.join(", ")}). Include at least one tactile word from (${voiceGuardConstants.REQUIRED_IMAGERY.join(", ")}). Keep sentences under 40 words and maintain a clinical-poetic tone.`;
    const prompt = [
      { role: "system", content: system },
      { role: "user", content: "Context JSON: " + context },
      { role: "user", content: "Original: " + draft },
      { role: "user", content: "Issues: " + issues.join("; ") },
      { role: "user", content: "Rewrite the passage once, preserving factual details." }
    ];

    const revision = await callResponses(model, { input: prompt }, OPENAI);
    draft = (revision.output_text ?? (revision.output?.[0]?.content?.[0]?.text ?? draft)).trim();
  }

  const remaining = clinicalVoiceIssues(draft);
  if (remaining.length) {
    throw new functions.https.HttpsError("invalid-argument", `Style guard failed: ${remaining.join("; ")}`);
  }
  return draft;
}

function summarizeHistoryForPrompt(history: any): string {
  if (!history || typeof history !== "object") return "None provided.";
  const parts: string[] = [];
  if (Array.isArray(history.userPhrases) && history.userPhrases.length) {
    parts.push(`User phrases: ${history.userPhrases.join(", ")}`);
  }
  if (Array.isArray(history.topSymbols) && history.topSymbols.length) {
    parts.push(`Top symbols: ${history.topSymbols.join(", ")}`);
  }
  if (Array.isArray(history.archetypeTrends) && history.archetypeTrends.length) {
    parts.push(`Archetype trends: ${history.archetypeTrends.join(", ")}`);
  }
  return parts.length ? parts.join(" | ") : "None provided.";
}

function summarizeTransitForPrompt(transit: any): string {
  if (!transit || typeof transit !== "object") return "No transit context provided.";
  const headline = typeof transit.headline === "string" && transit.headline.length ? transit.headline : "Unknown transit";
  const notes = Array.isArray(transit.notes) && transit.notes.length ? transit.notes.join(" • ") : "";
  const symbolLexicon = Object.entries(SYMBOL_NOTES).map(([k, v]) => `${k}: ${v}`).join(" | ");
  return [headline, notes, `Symbol lexicon: ${symbolLexicon}`].filter(Boolean).join(" | ");
}

function formatBirthForPrompt(birth: any) {
  if (!birth || typeof birth !== "object") {
    return { date: "Unknown", time: "Unknown", place: "Unknown" };
  }
  return {
    date: birth.date ?? birth.birthDate ?? "Unknown",
    time: birth.time ?? birth.birthTime ?? "Unknown",
    place: birth.place ?? birth.placeText ?? "Unknown"
  };
}

function applyTemplate(template: string, replacements: Record<string, string>): string {
  let output = template;
  for (const [key, value] of Object.entries(replacements)) {
    const pattern = new RegExp(`{{${key}}}`, "g");
    output = output.replace(pattern, () => value);
  }
  return output;
}

// Oracle: interpret (history + transits + symbol notes + self-check)
export const oracleInterpret = onRequest({ secrets: [OPENAI_KEY], cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const OPENAI = OPENAI_KEY.value();
    if (!OPENAI) return res.status(503).json({ error: "LLM unavailable" });

    const { dream, extraction, transit, history, birth, model = "gpt-4.1-mini" } = req.body || {};

    const schema = {
      type: "object",
      properties: {
        headline: { type: "string" },
        summary: { type: "string" },
        psychology: { type: "string" },
        astrology: { anyOf: [{ type: "string" }, { type: "null" }] },
        symbols: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string" },
              meaning: { type: "string" },
              confidence: { type: "number", minimum: 0, maximum: 1 }
            },
            required: ["name", "meaning", "confidence"],
            additionalProperties: false
          }
        },
        actions: {
          type: "array",
          minItems: 2,
          maxItems: 4,
          items: { type: "string" }
        },
        disclaimer: { type: "string" }
      },
      required: ["headline", "summary", "psychology", "astrology", "symbols", "actions", "disclaimer"],
      additionalProperties: false
    };

    const dreamText = typeof dream === "string" && dream.trim().length ? dream.trim() : "No dream supplied.";
    const lifeNotes = summarizeHistoryForPrompt(history);
    const astroContext = summarizeTransitForPrompt(transit);
    const birthSummary = formatBirthForPrompt(birth);

    const userPrompt = applyTemplate(DREAM_INTERPRET_USER_TEMPLATE, {
      dream_text: dreamText,
      life_notes: lifeNotes,
      birth_date: birthSummary.date,
      birth_time: birthSummary.time,
      birth_place: birthSummary.place,
      astro_context: astroContext
    });

    const prompt = [
      { role: "system", content: DREAM_INTERPRET_SYSTEM_PROMPT },
      { role: "user", content: userPrompt },
      { role: "user", content: "Dream extraction JSON: " + JSON.stringify(extraction ?? {}) },
      { role: "user", content: "Transit JSON: " + JSON.stringify(transit ?? {}) },
      { role: "user", content: "History JSON: " + JSON.stringify(history ?? {}) }
    ];

    const r = await callResponses(model, {
      input: prompt,
      response_format: {
        type: "json_schema",
        json_schema: { name: "DreamInterpretation", schema, strict: true }
      },
      temperature: 0.6
    }, OPENAI);

    const text = r.output_text ?? (r.output?.[0]?.content?.[0]?.text ?? "");

    try {
      const parsed = InterpretSchema.parse(JSON.parse(text));
      res.json(parsed);
    } catch (error) {
      return res.status(422).json({ error: "Schema violation", detail: (error as Error).message, raw: text });
    }
  });
});

// Oracle: chat (Pro) with scope gate
export const oracleChat = onRequest({ secrets: [OPENAI_KEY], cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const OPENAI = OPENAI_KEY.value();
    if (!OPENAI) return res.status(503).json({ error: "LLM unavailable" });

    const { messages, history, dreamContext, transit, model = "gpt-4.1-mini" } = req.body || {};

    const gate = await callResponses(model, {
      input: [
        { role: "system", content: "Return JSON {inScope:boolean, reason:string} for dream/astrology relevance." },
        { role: "user", content: String(messages?.slice(-1)?.[0]?.content ?? "") }
      ],
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "ScopeGate",
          schema: {
            type: "object",
            properties: {
              inScope: { type: "boolean" },
              reason: { type: "string" }
            },
            required: ["inScope", "reason"],
            additionalProperties: false
          },
          strict: true
        }
      }
    }, OPENAI);

    const gateText = gate.output_text ?? (gate.output?.[0]?.content?.[0]?.text ?? "{}");
    let inScope = true;
    try {
      inScope = JSON.parse(gateText).inScope;
    } catch {}

    if (!inScope) {
      return res.json({
        reply: "I focus on dream symbols, inner patterns, and today's sky. Share a dream line or symbol and I'll help interpret.",
        followupPrompt: "What symbol stands out from your last dream?",
        warnings: ["out_of_scope"]
      });
    }

    const system = "You are the Dreamline Oracle Chat. Stay anchored to dream symbols, emotions, archetypes, and the provided transits/history. No predictions or medical/legal/financial advice. 2–5 sentences, end with one reflective question.";

    const payload = [
      { role: "system", content: system },
      { role: "user", content: "Transit: " + JSON.stringify(transit ?? {}) },
      { role: "user", content: "History: " + JSON.stringify(history ?? {}) },
      ...(dreamContext ? [{ role: "user", content: "Dream context: " + dreamContext }] : []),
      ...((messages ?? []) as Array<{ role: string; content: string }>)
    ];

    const r = await callResponses(model, {
      input: payload,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "OracleChatReply",
          schema: {
            type: "object",
            properties: {
              reply: { type: "string" },
              followupPrompt: { type: "string" }
            },
            required: ["reply"],
            additionalProperties: false
          },
          strict: true
        }
      }
    }, OPENAI);

    const text = r.output_text ?? (r.output?.[0]?.content?.[0]?.text ?? "");
    const parsed = ChatSchema.safeParse(JSON.parse(text));

    if (!parsed.success) return res.status(422).json({ error: parsed.error.flatten() });

    res.json(parsed.data);
  });
});

// Astro transits — range composer
const RangeSchema = z.object({
  birthISO: z.string(),
  startISO: z.string(),
  endISO: z.string(),
  range: z.enum(["day", "week", "month", "year"]).default("day")
});

const HoroscopeItemSchema = z.object({
  dateISO: z.string(),
  headline: z.string(),
  bullets: z.array(z.string())
});

const MotifHistorySchema = z.object({
  topSymbols: z.array(z.string()).default([]),
  archetypeTrends: z.array(z.string()).default([]),
  userPhrases: z.array(z.string()).default([]),
  tones7d: z.record(z.number()).default({})
});

const BirthSchema = z.object({
  dateISO: z.string().optional(),
  placeName: z.string().optional(),
  lat: z.number().optional(),
  lon: z.number().optional(),
  utcOffsetMinutes: z.number().optional()
});

const HoroscopeComposeSchema = z.object({
  range: z.enum(["day", "week", "month", "year"]).optional().default("day"),
  period: z.enum(["day", "week", "month", "year"]).optional(), // Swift app sends "period" instead of "range"
  items: z.array(HoroscopeItemSchema).optional(), // Make optional - fetch from Firestore if not provided
  history: MotifHistorySchema.optional(),
  birth: BirthSchema.optional(),
  birthInstantUTC: z.number().optional(), // Swift app format
  tzID: z.string().optional(), // Swift app format
  placeText: z.string().optional(), // Swift app format
  timeKnown: z.boolean().optional(), // Swift app format
  model: z.string().optional(),
  uid: z.string().optional(),
  force: z.boolean().optional(), // Swift app sends "force"
  forceRefresh: z.boolean().optional(),
  tz: z.string().optional()
});

export const astroTransitsRange = onRequest({ cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const parsed = RangeSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
      return res.status(400).json({ error: parsed.error.flatten() });
    }

    try {
      const { birthISO, startISO, endISO, range } = parsed.data;
      const summaries = buildTransitRange({ birthISO, startISO, endISO });
      const items = range === "day" ? summaries.slice(0, 1) : summaries;
      res.json({ range, items });
    } catch (err: any) {
      res.status(400).json({ error: err?.message ?? "invalid request" });
    }
  });
});

// Horoscope compose (text from transits)
export const horoscopeCompose = onRequest({ secrets: [OPENAI_KEY], cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const OPENAI = OPENAI_KEY.value();
    if (!OPENAI) return res.status(503).json({ error: "LLM unavailable" });

    const parsed = HoroscopeComposeSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
      return res.status(400).json({ error: parsed.error.flatten() });
    }

    // Handle both Swift app format (period) and standard format (range)
    const rangeValue = parsed.data.range || parsed.data.period || "day";
    const forceValue = parsed.data.forceRefresh === true || parsed.data.force === true;
    
    const { items, history, birth, birthInstantUTC, tzID, placeText, timeKnown, model: requestedModel, uid = "me", tz: tzInput } = parsed.data;
    const tz = (tzInput || tzID || 'UTC') as string;
    const anchorKey = anchorKeyFor(rangeValue as any, new Date(), tz);
    const force = forceValue;
    
    // Get user profile first (needed for tier-based logic)
    const prof = await getOrInitUserProfile(uid);
    
    // Always fetch recent dreams to weave into horoscope
    // Fetch more dreams for pattern analysis (up to 30 days of history)
    let recentDreams: any[] = [];
    let dreamPatterns: any[] = [];
    try {
      const dreamsSnap = await db.collection(`users/${uid}/dreams`)
        .orderBy('createdAt', 'desc')
        .limit(30) // Fetch last 30 dreams for pattern analysis
        .get();
      
      const allDreams = dreamsSnap.docs.map(doc => {
        const data = doc.data();
        return {
          dateISO: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
          headline: data.title || data.headline || "Dream",
          bullets: data.symbols || data.themes || data.motifs || [],
          symbols: data.symbols || [],
          archetypes: data.archetypes || [],
          createdAt: data.createdAt?.toDate?.() || new Date()
        };
      });
      
      // Recent dreams (last 7 days) for current context
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      recentDreams = allDreams.filter(d => d.createdAt >= sevenDaysAgo);
      
      // Look for recurring symbols in older dreams (8-30 days ago)
      const olderDreams = allDreams.filter(d => d.createdAt < sevenDaysAgo);
      const recentSymbols = new Set(recentDreams.flatMap(d => d.symbols));
      
      // Find patterns: same symbols appearing in different time periods
      for (const symbol of recentSymbols) {
        const pastOccurrences = olderDreams.filter(d => d.symbols.includes(symbol));
        if (pastOccurrences.length > 0) {
          dreamPatterns.push({
            symbol,
            recentCount: recentDreams.filter(d => d.symbols.includes(symbol)).length,
            pastOccurrence: pastOccurrences[0], // Most recent past occurrence
            daysAgo: Math.floor((Date.now() - pastOccurrences[0].createdAt.getTime()) / (24 * 60 * 60 * 1000))
          });
        }
      }
    } catch (err) {
      // No dreams or error fetching - continue with empty arrays
      recentDreams = [];
      dreamPatterns = [];
    }
    
    // Create a hash of recent dreams for cache key (so new dreams = new cache entry)
    const dreamHash = recentDreams.length > 0 
      ? recentDreams.map(d => `${d.headline.slice(0, 20)}${d.symbols.join(',')}`).join('|').slice(0, 50)
      : 'nodreams';
    
    // Check cache unless force refresh
    if (!force) {
      const cacheRef = db.doc(`users/${uid}/horoscope-cache/${rangeValue}_${anchorKey}_${dreamHash}`);
      const cacheSnap = await cacheRef.get();
      if (cacheSnap.exists) {
        const d = cacheSnap.data() as any;
        if (d?.item) {
          return res.json({ item: d.item, cached: true });
        }
      }
    }
    const cfg = await loadConfig();
    const model = requestedModel || 
                  (prof.tier === 'pro' ? cfg.model.pro :
                   prof.tier === 'plus' ? cfg.model.plus :
                   (prof.createdAt && ((Date.now() - Date.parse(prof.createdAt)) / 86400000) <= cfg.honeymoonDays) 
                     ? cfg.model.free.initial 
                     : cfg.model.free.fallback);

    // Convert transit items to Transit format for structured output
    // Note: This section is for parsing transit data, not dreams
    // If items were provided (from astroTransitsRange), parse them for transit aspects
    const transits: any[] = [];
    if (items && items.length > 0) {
    for (const item of items) {
      // If items have aspects array (from DailyTransitSummary), use them
      const itemWithAspects = item as any;
      if (itemWithAspects.aspects && Array.isArray(itemWithAspects.aspects)) {
        for (const aspect of itemWithAspects.aspects) {
          const tone = aspect.aspect === 'square' || aspect.aspect === 'opposition' 
            ? 'challenging' 
            : aspect.aspect === 'trine' || aspect.aspect === 'sextile'
            ? 'supportive'
            : 'neutral';
          transits.push({
            label: `${aspect.transitBody} ${aspect.aspect} ${aspect.natalBody}`,
            planetA: aspect.transitBody,
            planetB: aspect.natalBody,
            aspect: aspect.aspect,
            orb: aspect.orb || aspect.delta || 0,
            tone
          });
        }
      } else {
        // Fallback: parse headline if aspects not available
        const parts = item.headline.split(' ');
        if (parts.length >= 3) {
          transits.push({
            label: item.headline,
            planetA: parts[0],
            planetB: parts[2] || '',
            aspect: parts[1] || 'conjunction',
            orb: 0,
            tone: 'neutral' as const
          });
        }
      }
    }
    }

    // Build prompt for structured output with model-written areas
    const ctx = {
      motifs: history?.topSymbols || [],
      transits: transits.map((t: any) => ({ label: t.label, tone: t.tone })),
      recentDreams: recentDreams.map(d => ({
        date: d.dateISO.split('T')[0],
        symbols: d.symbols,
        archetypes: d.archetypes
      })),
      dreamPatterns: dreamPatterns.map(p => ({
        symbol: p.symbol,
        daysAgo: p.daysAgo,
        recurring: p.recentCount > 1
      }))
    };
    
    // Tier-aware system prompt
    const isPaid = prof.tier === 'pro' || prof.tier === 'plus';
    const dreamIntegrationInstructions = isPaid
      ? `Deeply integrate the user's recent dreams and recurring patterns. When you spot a recurring symbol (e.g., water appearing again after X days), explain the astrological significance and timing. Connect dream symbols to current transits. Be specific about dates and planetary positions.`
      : `If dream patterns exist, give a brief teaser (1 sentence max) hinting at recurring symbols or timing, but keep it vague. Frame it as "There's something interesting about [symbol] appearing now..." to encourage upgrade. Do NOT give away the full analysis.`;
    
    const sys = `Write precise, second‑person, clinical‑poetic horoscopes. Avoid clichés. Sound human, not mystical fluff. Use the user's dream motifs and current transits. Keep language personal: "You may feel…", "Are you noticing…".
    
${dreamIntegrationInstructions}

The horoscope structure:
- headline: Short, evocative (5-8 words)
- summary: One guiding sentence
- areas: 6 life areas (relationships, work_money, home_body, creativity_learning, spirituality, routine_habits) with 2-4 bullets each and do/don't recommendations`;
    
    const usr = {
      instruction: `Produce JSON that matches the provided schema.`,
      range: rangeValue, anchorKey, tz,
      userTier: prof.tier,
      motifs: ctx.motifs,
      transits: ctx.transits,
      recentDreams: ctx.recentDreams.length > 0 ? ctx.recentDreams : undefined,
      dreamPatterns: ctx.dreamPatterns.length > 0 ? ctx.dreamPatterns : undefined
    };

    const resp = await callResponses(model, {
      input: [
        { role: "system", content: sys },
        { role: "user", content: JSON.stringify(usr) }
      ],
      temperature: 0.6,
      seed: 42,
      response_format: {
        type: "json_schema",
        json_schema: HoroscopeJSONSchema
      }
    }, OPENAI);

    const json = JSON.parse((resp as any).output_text || "{}");
    
    const item: HoroscopeStructured = {
      range: rangeValue, anchorKey, model,
      headline: json.headline || "A clear window opens.",
      summary: json.summary || "Take one small, deliberate step.",
      areas: json.areas || [],
      transits: ctx.transits,
      generatedAt: new Date().toISOString()
    };

    // Cache the result (include dream hash so new dreams = new horoscope)
    const cacheRef = db.doc(`users/${uid}/horoscope-cache/${rangeValue}_${anchorKey}_${dreamHash}`);
    await cacheRef.set({ 
      item, 
      _ts: FieldValue.serverTimestamp(), 
      range: rangeValue, 
      anchorKey, 
      model 
    }, { merge: true });

    return res.json({ item, cached: false, model, tz });
  });
});

// Horoscope read (cache-only, no generation)
export const horoscopeRead = onRequest({ secrets: [OPENAI_KEY], cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const { uid, range = 'day', tz: tzInput } = req.body || {};
    
    if (!uid) {
      return res.status(400).json({ error: "uid required" });
    }
    
    const tz = (tzInput || 'UTC') as string;
    const anchorKey = anchorKeyFor(range as 'day'|'week'|'month'|'year', new Date(), tz);
    const snap = await db.doc(`users/${uid}/horoscope-cache/${range}_${anchorKey}`).get();
    
    return res.json(snap.exists ? { item: snap.data()?.item, cached: true } : { item: null, cached: false });
  });
});

// Usage counter (atomic)
export const incrementUsage = onRequest({ cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const { uid, key } = req.body || {};

    if (!uid || !key) return res.status(400).json({ error: "uid and key required" });

    const ref = db.collection("users").doc(uid).collection("usage").doc(key);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const count = (snap.exists ? (snap.get("count") as number) : 0) + 1;
      tx.set(ref, { count, updatedAt: new Date() }, { merge: true });
    });

    res.json({ ok: true });
  });
});

// Best Days endpoint - returns favorable transit days for the week
export const bestDaysForWeek = onRequest({ cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const { uid, birthISO } = req.body || {};

    if (!uid) return res.status(400).json({ error: "uid required" });

    // TODO: Calculate actual favorable transits based on natal chart
    // For now, return placeholder data
    const now = new Date();
    const days = [];

    // Generate next 7 days
    for (let i = 1; i <= 7; i++) {
      const date = new Date(now);
      date.setDate(date.getDate() + i);
      
      // Placeholder logic: alternate between different types
      const types = [
        { title: "Best day for risks", reason: "Mars trine Sun" },
        { title: "Great day for therapy", reason: "Moon conjunct Neptune" },
        { title: "Good day for decisions", reason: "Mercury sextile Jupiter" },
        { title: "Perfect for creativity", reason: "Venus trine Neptune" }
      ];
      
      const typeIndex = i % types.length;
      
      days.push({
        date: date.toISOString().split('T')[0],
        title: types[typeIndex].title,
        reason: types[typeIndex].reason,
        dreamContext: null // Will be populated when dream analysis is integrated
      });
    }

    // Return top 2 favorable days
    res.json({ days: days.slice(0, 2) });
  });
});

// Submit accuracy feedback endpoint
export const submitAccuracyFeedback = onRequest({ cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const { uid, areaId, horoscopeDate, accurate } = req.body || {};

    if (!uid || !areaId || horoscopeDate === undefined || accurate === undefined) {
      return res.status(400).json({ error: "uid, areaId, horoscopeDate, and accurate are required" });
    }

    await db.collection("feedback").add({
      uid,
      areaId,
      horoscopeDate: new Date(horoscopeDate),
      accurate: Boolean(accurate),
      timestamp: FieldValue.serverTimestamp()
    });

    res.json({ success: true });
  });
});
