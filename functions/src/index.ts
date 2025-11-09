import * as functions from "firebase-functions";
import { onRequest } from "firebase-functions/v2/https";
import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import corsLib from "cors";
import fetch from "node-fetch";
import { z } from "zod";
import { defineSecret } from "firebase-functions/params";
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
const ENABLE_SELF_CHECK = true;

// Schemas
const ExtractSchema = z.object({
  symbols: z.array(z.object({ name: z.string(), count: z.number().int().nonnegative() })),
  tone: z.string(),
  archetypes: z.array(z.string())
});

const InterpretSchema = z.object({
  shortSummary: z.string(),
  longForm: z.string(),
  actionPrompt: z.string(),
  symbolCards: z.array(z.object({
    name: z.string(),
    meaning: z.string(),
    personalNote: z.string().optional()
  }))
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

// Oracle: interpret (history + transits + symbol notes + self-check)
export const oracleInterpret = onRequest({ secrets: [OPENAI_KEY], cors: true, invoker: "public" }, async (req, res) => {
  return cors(req, res, async () => {
    const OPENAI = OPENAI_KEY.value();
    if (!OPENAI) return res.status(503).json({ error: "LLM unavailable" });

    const { dream, extraction, transit, history, model = "gpt-4.1-mini" } = req.body || {};

    const system =
`You are the Dreamline Oracle. Write brief, reflective readings that connect the user's dream symbols with their ongoing motifs and today's transits. Stay grounded in the given dream text, extracted symbols, history, and transit summary.

VOICE: Second person; calm, lyrical but clear. Avoid clichés; one vivid image max. Short summary 1–2 sentences. Long form 3–6 sentences (≈120–180 words). End with one concrete micro‑action.

RESONANCE: Mirror one phrase from dream/history; name one universal tension bound to THIS imagery; tie one symbol to the transit headline as an influence (no predictions).

GUARDRAILS: No deterministic forecasts; no medical/legal/financial advice; no diagnosis; no real‑world names not in the dream. If user went off-topic, gently reframe toward symbol work.

OUTPUT: Follow schema exactly (shortSummary, longForm, actionPrompt, symbolCards[] with concise meanings). Use symbol notes when helpful.`;

    const schema = {
      type: "object",
      properties: {
        shortSummary: { type: "string" },
        longForm: { type: "string" },
        actionPrompt: { type: "string" },
        symbolCards: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string" },
              meaning: { type: "string" },
              personalNote: { type: "string" }
            },
            required: ["name", "meaning"],
            additionalProperties: false
          }
        }
      },
      required: ["shortSummary", "longForm", "actionPrompt", "symbolCards"],
      additionalProperties: false
    };

    const grounding = "Symbol notes: " + Object.entries(SYMBOL_NOTES).map(([k, v]) => `${k}: ${v}`).join(" | ");

    const prompt = [
      { role: "system", content: system + "\n" + grounding },
      { role: "user", content: "Dream: " + String(dream ?? "") },
      { role: "user", content: "Extraction: " + JSON.stringify(extraction ?? {}) },
      { role: "user", content: "Transit: " + JSON.stringify(transit ?? {}) },
      { role: "user", content: "History: " + JSON.stringify(history ?? {}) }
    ];

    const r = await callResponses(model, {
      input: prompt,
      response_format: {
        type: "json_schema",
        json_schema: { name: "OracleInterpretation", schema, strict: true }
      }
    }, OPENAI);

    const text = r.output_text ?? (r.output?.[0]?.content?.[0]?.text ?? "");
    const parsed = InterpretSchema.safeParse(JSON.parse(text));

    if (!parsed.success) return res.status(422).json({ error: parsed.error.flatten() });

    const final = await selfCheckRevise(parsed.data, extraction, transit, history, OPENAI, model);

    res.json(final);
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
  range: z.enum(["day", "week", "month", "year"]).default("day"),
  items: z.array(HoroscopeItemSchema).min(1),
  history: MotifHistorySchema.optional(),
  birth: BirthSchema.optional(),
  model: z.string().optional(),
  uid: z.string().optional(),
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

    const { range, items, history, birth, model: requestedModel, uid = "me", forceRefresh, tz: tzInput } = parsed.data;
    const tz = (tzInput || 'UTC') as string;
    const anchorKey = anchorKeyFor(range, new Date(), tz);
    const force = forceRefresh === true;

    // Check cache unless force refresh
    if (!force) {
      const cacheRef = db.doc(`users/${uid}/horoscope-cache/${range}_${anchorKey}`);
      const cacheSnap = await cacheRef.get();
      if (cacheSnap.exists) {
        const d = cacheSnap.data() as any;
        if (d?.item) {
          return res.json({ item: d.item, cached: true });
        }
      }
    }

    // Get user profile and config for model selection
    const prof = await getOrInitUserProfile(uid);
    const cfg = await loadConfig();
    const model = requestedModel || 
                  (prof.tier === 'pro' ? cfg.model.pro :
                   prof.tier === 'plus' ? cfg.model.plus :
                   (prof.createdAt && ((Date.now() - Date.parse(prof.createdAt)) / 86400000) <= cfg.honeymoonDays) 
                     ? cfg.model.free.initial 
                     : cfg.model.free.fallback);

    // Convert transit items to Transit format for structured output
    // Extract aspects from items (assuming items come from astroTransitsRange which includes aspects)
    const transits: any[] = [];
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

    // Build prompt for structured output with model-written areas
    const ctx = {
      motifs: history?.topSymbols || [],
      transits: transits.map((t: any) => ({ label: t.label, tone: t.tone }))
    };
    
    const sys = `Write precise, second‑person, clinical‑poetic horoscopes. Avoid clichés. Sound human, not mystical fluff. Use the user's dream motifs and current transits. Keep language personal: "You may feel…", "Are you noticing…".`;
    
    const usr = {
      instruction: `Produce JSON that matches the provided schema. Include 6 areas with short bullets and practical do/don't.`,
      range, anchorKey, tz,
      motifs: ctx.motifs,
      transits: ctx.transits
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
      range, anchorKey, model,
      headline: json.headline || "A clear window opens.",
      summary: json.summary || "Take one small, deliberate step.",
      areas: json.areas || [],
      transits: ctx.transits,
      generatedAt: new Date().toISOString()
    };

    // Cache the result
    const cacheRef = db.doc(`users/${uid}/horoscope-cache/${range}_${anchorKey}`);
    await cacheRef.set({ 
      item, 
      _ts: FieldValue.serverTimestamp(), 
      range, 
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
