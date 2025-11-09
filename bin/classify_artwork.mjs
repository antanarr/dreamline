#!/usr/bin/env node

import path from 'node:path';
import fs from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import fg from 'fast-glob';
import OpenAI from 'openai';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');
process.chdir(repoRoot);

const INBOX_DIR = path.join(repoRoot, 'Artwork_Inbox');
const MANIFEST_PATH = path.join(repoRoot, 'artwork_manifest.json');

const TARGET_OPTIONS = {
  zodiac: [
    'zodiac_aries',
    'zodiac_taurus',
    'zodiac_gemini',
    'zodiac_cancer',
    'zodiac_leo',
    'zodiac_virgo',
    'zodiac_libra',
    'zodiac_scorpio',
    'zodiac_sagittarius',
    'zodiac_capricorn',
    'zodiac_aquarius',
    'zodiac_pisces'
  ],
  planet_line: [
    'planet_sun_line',
    'planet_moon_line',
    'planet_mercury_line',
    'planet_venus_line',
    'planet_mars_line',
    'planet_jupiter_line',
    'planet_saturn_line',
    'planet_uranus_line',
    'planet_neptune_line',
    'planet_pluto_line'
  ],
  planet_fill: [
    'planet_sun_fill',
    'planet_moon_fill',
    'planet_mercury_fill',
    'planet_venus_fill',
    'planet_mars_fill',
    'planet_jupiter_fill',
    'planet_saturn_fill',
    'planet_uranus_fill',
    'planet_neptune_fill',
    'planet_pluto_fill'
  ],
  aspect: [
    'aspect_conjunction',
    'aspect_sextile',
    'aspect_square',
    'aspect_trine',
    'aspect_opposition'
  ],
  transit: [
    'transit_intensity_1',
    'transit_intensity_2',
    'transit_intensity_3',
    'transit_favorable',
    'transit_challenging',
    'transit_reflective'
  ],
  symbol: [
    'symbol_water',
    'symbol_door',
    'symbol_room',
    'symbol_house',
    'symbol_bird',
    'symbol_teeth',
    'symbol_flight',
    'symbol_ocean',
    'symbol_wall',
    'symbol_truck',
    'symbol_car',
    'symbol_road',
    'symbol_building'
  ],
  archetype: [
    'archetype_threshold',
    'archetype_journey',
    'archetype_shadow',
    'archetype_rebirth',
    'archetype_loss',
    'archetype_security',
    'archetype_transformation',
    'archetype_boundary'
  ],
  oracle_hero: ['oracle_hero_square', 'oracle_hero_header'],
  oracle_icon: ['icon_oracle'],
  horoscope_bg: ['bg_horoscope_card'],
  insights_corner_tl: ['insights_corner_tl'],
  insights_corner_br: ['insights_corner_br'],
  empty_journal: ['empty_journal'],
  onboarding: [
    'ob_welcome',
    'ob_privacy',
    'ob_birth',
    'ob_notifications',
    'ob_sample',
    'ob_completion'
  ],
  loading_sprite: ['loader_oracle_spritesheet'],
  loading_static: ['loader_oracle_static'],
  pattern_stargrid_tile: ['pattern_stargrid_tile'],
  pattern_gradientnoise_tile: ['pattern_gradientnoise_tile'],
  bg_nebula_full: ['bg_nebula_full'],
  lock_screen_illustration: ['lock_screen_illustration'],
  pdf_header: ['pdf_header'],
  pdf_footer: ['pdf_footer'],
  pdf_watermark: ['pdf_watermark'],
  tab_icon: ['tab_journal', 'tab_today', 'tab_insights', 'tab_me'],
  appicon_primary_1024: ['appicon_primary_1024'],
  appicon_primary_2048: ['appicon_primary_2048'],
  appicon_variant_lilac_1024: ['appicon_variant_lilac_1024']
};

const CLASSIFICATION_INSTRUCTIONS = `
You classify Dreamline app artwork into canonical asset buckets.

Return JSON that matches the provided schema exactly. Only use category values from the schema enum.

Guidelines:
- zodiac: pick the matching zodiac sign from [aries, taurus, gemini, cancer, leo, virgo, libra, scorpio, sagittarius, capricorn, aquarius, pisces] and set target_name to "zodiac_[sign]".
- planet_line / planet_fill: select planet from [sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto] and set target_name to "planet_[name]_line" or "planet_[name]_fill".
- aspect: choose one of [conjunction, sextile, square, trine, opposition] and set target_name to "aspect_[type]".
- transit micro-icons: choose one of [intensity_1, intensity_2, intensity_3, favorable, challenging, reflective] and set target_name to "transit_[label]".
- dream symbols: choose one of [water, door, room, house, bird, teeth, flight, ocean, wall, truck, car, road, building] and set target_name to "symbol_[item]".
- archetypes: choose one of [threshold, journey, shadow, rebirth, loss, security, transformation, boundary] and set target_name to "archetype_[name]".
- oracle hero illustrations: choose "oracle_hero_square" or "oracle_hero_header" for target_name.
- oracle icon: target_name must be "icon_oracle".
- horoscope background: target_name is "bg_horoscope_card".
- insights corners: choose "insights_corner_tl" or "insights_corner_br".
- empty state: target_name "empty_journal".
- onboarding: choose one of [welcome, privacy, birth, notifications, sample, completion] with target_name "ob_[step]".
- loaders: spritesheet => "loader_oracle_spritesheet"; static => "loader_oracle_static".
- patterns/backgrounds: choose the matching canonical name from [pattern_stargrid_tile, pattern_gradientnoise_tile, bg_nebula_full].
- lock screen illustration -> "lock_screen_illustration".
- pdf branding: choose one of [pdf_header, pdf_footer, pdf_watermark].
- tab icons: choose one of [tab_journal, tab_today, tab_insights, tab_me]; these are monochrome template icons.
- app icons: identify the 2048px and 1024px primaries and the lilac 1024 variant; set target_name to "appicon_primary_2048", "appicon_primary_1024", or "appicon_variant_lilac_1024" accordingly.

If unsure, pick the closest category and provide clarification in notes. Never invent new categories or names.
`;

const ALL_TARGET_NAMES = new Set(Object.values(TARGET_OPTIONS).flat());
const GENERIC_TOKENS = new Set([
  'symbol',
  'zodiac',
  'planet',
  'aspect',
  'transit',
  'archetype',
  'oracle',
  'icon',
  'hero',
  'square',
  'header',
  'card',
  'background',
  'bg',
  'pattern',
  'tile',
  'gradient',
  'intensity',
  'loader',
  'sprite',
  'static',
  'tab',
  'insights',
  'corner',
  'empty',
  'journal',
  'lock',
  'screen',
  'illustration',
  'pdf',
  'watermark',
  'footer',
  'primary',
  'variant',
  'appicon',
  'brand'
]);

function requireEnv(name) {
  if (!process.env[name]) {
    console.error(`Missing required environment variable ${name}.`);
    process.exitCode = 1;
    return false;
  }
  return true;
}

function sanitizeApiKey(raw) {
  if (typeof raw !== 'string') return null;
  const trimmed = raw.trim();
  if (/\s/.test(trimmed) || trimmed.length < 10) {
    return null;
  }
  return trimmed;
}

function validateApiKey(key) {
  if (!key) {
    console.error('OPENAI_API_KEY is not set to a usable value. Please export a valid key (starts with "sk-").');
    process.exitCode = 1;
    return false;
  }
  if (!/^sk-[A-Za-z0-9_-]{15,}$/.test(key)) {
    console.error('OPENAI_API_KEY appears invalid. Ensure it is the raw API key (e.g., "sk-...") with no extra commands or whitespace.');
    process.exitCode = 1;
    return false;
  }
  return true;
}

function tokenize(value) {
  if (!value) return [];
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
    .split(/\s+/)
    .filter(Boolean);
}

function collectTokens(...sources) {
  const tokens = [];
  for (const source of sources) {
    tokens.push(...tokenize(source));
  }
  return tokens.filter((token) => !GENERIC_TOKENS.has(token));
}

function resolveTargetName({ category, proposed, filename, notes }) {
  const options = TARGET_OPTIONS[category];
  if (!options || options.length === 0) {
    return proposed;
  }

  if (options.includes(proposed)) {
    return proposed;
  }

  if (options.length === 1) {
    return options[0];
  }

  const tokenPool = new Set(collectTokens(proposed, filename, notes));

  let best = options[0];
  let bestScore = 0;

  for (const option of options) {
    const optionTokens = collectTokens(option);
    let score = 0;
    for (const token of optionTokens) {
      if (tokenPool.has(token)) {
        score += 2;
      }
    }

    if (score > bestScore) {
      best = option;
      bestScore = score;
    }
  }

  return best;
}

function markDuplicateAssignments(entries) {
  const primaryByTarget = new Map();
  const duplicates = [];

  for (const entry of entries) {
    if (!entry.target_name) continue;
    const existing = primaryByTarget.get(entry.target_name);
    if (!existing) {
      primaryByTarget.set(entry.target_name, entry);
      entry.is_primary = true;
    } else {
      entry.is_primary = false;
      entry.duplicate_of = existing.src;
      if (entry.notes) {
        entry.notes = `${entry.notes} | duplicate of ${existing.src}`;
      } else {
        entry.notes = `duplicate of ${existing.src}`;
      }
      duplicates.push(entry);
    }
  }

  return duplicates;
}

async function readManifest() {
  try {
    const raw = await fs.readFile(MANIFEST_PATH, 'utf8');
    const data = JSON.parse(raw);
    if (!Array.isArray(data)) {
      throw new Error('Manifest must be an array.');
    }
    return data;
  } catch (error) {
    if (error.code === 'ENOENT') {
      return [];
    }
    throw error;
  }
}

async function writeManifest(manifest) {
  const sorted = [...manifest].sort((a, b) => a.src.localeCompare(b.src));
  await fs.writeFile(MANIFEST_PATH, `${JSON.stringify(sorted, null, 2)}\n`);
}

async function hashFile(filePath) {
  const buffer = await fs.readFile(filePath);
  return {
    hash: createHash('md5').update(buffer).digest('hex'),
    buffer
  };
}

function toDataUrl(filename, buffer) {
  const ext = path.extname(filename).toLowerCase();
  const mime =
    ext === '.svg' ? 'image/svg+xml' : ext === '.webp' ? 'image/webp' : 'image/png';
  return `data:${mime};base64,${buffer.toString('base64')}`;
}

async function collectFiles() {
  const entries = await fg(['*.png', '*.svg', '*.webp'], {
    cwd: INBOX_DIR,
    absolute: true,
    dot: false,
    caseSensitiveMatch: false
  });
  entries.sort();
  return entries;
}

function buildSchemaConfig() {
  return {
    name: 'artwork_classification',
    strict: false,
    type: 'json_schema',
    schema: {
      type: 'object',
      additionalProperties: false,
      properties: {
        category: {
          type: 'string',
          enum: [
            'zodiac',
            'planet_line',
            'planet_fill',
            'aspect',
            'transit',
            'symbol',
            'archetype',
            'oracle_hero',
            'oracle_icon',
            'horoscope_bg',
            'insights_corner_tl',
            'insights_corner_br',
            'empty_journal',
            'onboarding',
            'loading_sprite',
            'loading_static',
            'pattern_stargrid_tile',
            'pattern_gradientnoise_tile',
            'bg_nebula_full',
            'lock_screen_illustration',
            'pdf_header',
            'pdf_footer',
            'pdf_watermark',
            'tab_icon',
            'appicon_primary_1024',
            'appicon_primary_2048',
            'appicon_variant_lilac_1024'
          ]
        },
        target_name: { type: 'string' },
        notes: { type: 'string' }
      },
      required: ['category', 'target_name']
    }
  };
}

async function classifyWithRetry({ client, buffer, filename, attempt = 0 }) {
  const MAX_ATTEMPTS = 4;
  const backoffMs = Math.min(1000 * 2 ** attempt, 8000);
  try {
    const response = await client.responses.create({
      model: process.env.OPENAI_ART_CLASSIFIER_MODEL ?? 'gpt-4.1-mini',
      temperature: 0,
      input: [
        {
          role: 'user',
          content: [
            { type: 'input_text', text: CLASSIFICATION_INSTRUCTIONS },
            { type: 'input_text', text: `Filename: ${filename}` },
            {
              type: 'input_image',
              detail: 'high',
              image_url: toDataUrl(filename, buffer)
            }
          ]
        }
      ],
      text: {
        format: buildSchemaConfig()
      }
    });

    const text = response.output_text?.trim();
    if (!text) {
      throw new Error('Empty response from model');
    }
    return JSON.parse(text);
  } catch (error) {
    if (attempt + 1 < MAX_ATTEMPTS) {
      const delay = backoffMs + Math.floor(Math.random() * 250);
      console.warn(`Classification failed for ${filename} (${error.message}). Retrying in ${delay}ms...`);
      await new Promise((resolve) => setTimeout(resolve, delay));
      return classifyWithRetry({ client, buffer, filename, attempt: attempt + 1 });
    }
    throw error;
  }
}

async function main() {
  if (!requireEnv('OPENAI_API_KEY')) {
    return;
  }

  const rawApiKey = process.env.OPENAI_API_KEY;
  const apiKey = sanitizeApiKey(rawApiKey);
  if (!validateApiKey(apiKey)) {
    return;
  }

  const files = await collectFiles();
  if (!files.length) {
    console.log('No artwork files found in Artwork_Inbox.');
    return;
  }

  const client = new OpenAI({ apiKey });
  const manifest = await readManifest();
  const manifestBySrc = new Map(manifest.map((entry) => [entry.src, entry]));

  const currentFileSet = new Set(
    files.map((filePath) => path.relative(repoRoot, filePath).split(path.sep).join(path.posix.sep))
  );

  const retained = manifest.filter((entry) => currentFileSet.has(entry.src));
  const retainedBySrc = new Map(retained.map((entry) => [entry.src, entry]));

  const updates = [];

  for (const filePath of files) {
    const relPath = path.relative(repoRoot, filePath).split(path.sep).join(path.posix.sep);
    const filename = path.basename(filePath);
    const { hash, buffer } = await hashFile(filePath);
    const existing = retainedBySrc.get(relPath);

    if (existing && existing.md5 === hash) {
      console.log(`Skipping ${filename} (cached).`);
      updates.push(existing);
      continue;
    }

    console.log(`Classifying ${filename}...`);
    const result = await classifyWithRetry({ client, buffer, filename });
    const rawTarget = result.target_name?.trim() ?? '';
    const normalizedTarget = rawTarget
      .toLowerCase()
      .replace(/\s+/g, '_')
      .replace(/[^a-z0-9_]/g, '_')
      .replace(/_+/g, '_')
      .replace(/^_|_$/g, '');
    const resolvedTarget = resolveTargetName({
      category: result.category,
      proposed: normalizedTarget || rawTarget.toLowerCase(),
      filename,
      notes: result.notes
    });

    if (TARGET_OPTIONS[result.category] && !ALL_TARGET_NAMES.has(resolvedTarget)) {
      console.warn(
        `Resolved target "${resolvedTarget}" for category "${result.category}" is not in canonical list.`
      );
    }

    const entry = {
      src: relPath,
      md5: hash,
      category: result.category,
      target_name: resolvedTarget,
      notes: result.notes ?? undefined,
      classified_at: new Date().toISOString(),
      original_filename: filename
    };
    if (normalizedTarget && normalizedTarget !== resolvedTarget) {
      entry.notes = entry.notes
        ? `${entry.notes} | coerced target to ${resolvedTarget}`
        : `coerced target to ${resolvedTarget}`;
    }
    if (!entry.notes) {
      delete entry.notes;
    }
    updates.push(entry);
  }

  const duplicates = markDuplicateAssignments(updates);
  if (duplicates.length) {
    console.log(
      `Detected ${duplicates.length} additional asset(s) targeting an already assigned canonical name. Keeping the first occurrence per target.`
    );
  }

  await writeManifest(updates);
  console.log(`Wrote manifest to ${MANIFEST_PATH}`);

  if (!duplicates.length) {
    console.log('No duplicate target assignments detected.');
  }
}

main().catch((error) => {
  console.error('Failed to classify artwork.');
  console.error(error);
  process.exitCode = 1;
});


