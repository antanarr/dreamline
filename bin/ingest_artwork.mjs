#!/usr/bin/env node

import path from 'node:path';
import fs from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';
import fse from 'fs-extra';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');

const MANIFEST_PATH = path.join(repoRoot, 'artwork_manifest.json');
const CACHE_PATH = path.join(repoRoot, 'artwork_ingest_cache.json');
const REPORT_PATH = path.join(repoRoot, 'artwork_ingest_report.json');
const INBOX_ROOT = path.join(repoRoot, 'Artwork_Inbox');
const ARCHIVE_ROOT = path.join(repoRoot, 'Artwork_Archive');
const ASSETS_ROOT = path.join(repoRoot, 'Resources', 'Assets.xcassets');

const TODAY = new Date().toISOString().slice(0, 10);
const ARCHIVE_DIR = path.join(ARCHIVE_ROOT, TODAY);

const DEFAULT_INFO = { version: 1, author: 'xcode' };

const APP_ICON_SPECS = [
  { idiom: 'iphone', size: 20, scales: [2, 3] },
  { idiom: 'iphone', size: 29, scales: [2, 3] },
  { idiom: 'iphone', size: 40, scales: [2, 3] },
  { idiom: 'iphone', size: 60, scales: [2, 3] },
  { idiom: 'ipad', size: 20, scales: [1, 2] },
  { idiom: 'ipad', size: 29, scales: [1, 2] },
  { idiom: 'ipad', size: 40, scales: [1, 2] },
  { idiom: 'ipad', size: 76, scales: [1, 2] },
  { idiom: 'ipad', size: 83.5, scales: [2] },
  { idiom: 'ios-marketing', size: 1024, scales: [1] }
];

const CATEGORY_FOLDERS = {
  zodiac: 'AstroZodiac',
  planet_fill: 'AstroPlanets',
  planet_line: 'AstroPlanets',
  aspect: 'AstroAspects',
  transit: 'Transit',
  symbol: 'Symbols',
  archetype: 'Archetypes',
  oracle_hero: 'Oracle',
  oracle_icon: 'Oracle',
  horoscope_bg: 'Backgrounds',
  insights_corner_tl: 'Backgrounds',
  insights_corner_br: 'Backgrounds',
  empty_journal: 'Empty',
  onboarding: 'Onboarding',
  loading_sprite: 'Loaders',
  loading_static: 'Loaders',
  pattern_stargrid_tile: 'Backgrounds',
  pattern_gradientnoise_tile: 'Backgrounds',
  bg_nebula_full: 'Backgrounds',
  lock_screen_illustration: 'Brand',
  pdf_header: 'Brand',
  pdf_footer: 'Brand',
  pdf_watermark: 'Brand',
  tab_icon: 'TabIcons'
};

function warned(message) {
  console.warn(`⚠️  ${message}`);
}

function info(message) {
  console.log(`ℹ️  ${message}`);
}

async function readJson(filePath, fallback) {
  try {
    const raw = await fs.readFile(filePath, 'utf8');
    return JSON.parse(raw);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return fallback;
    }
    throw error;
  }
}

async function writeJson(filePath, data) {
  await fs.writeFile(filePath, `${JSON.stringify(data, null, 2)}\n`);
}

async function loadManifest() {
  const manifest = await readJson(MANIFEST_PATH, null);
  if (!Array.isArray(manifest)) {
    throw new Error(`Manifest at ${MANIFEST_PATH} is missing or malformed.`);
  }
  return manifest;
}

async function ensureDir(dirPath) {
  await fse.ensureDir(dirPath);
}

function getImagesetPath(folderName, targetName) {
  return path.join(ASSETS_ROOT, folderName, `${targetName}.imageset`);
}

function resolveTarget(entry) {
  const baseName = entry.target_name;
  switch (entry.category) {
    case 'zodiac':
    case 'planet_fill':
    case 'planet_line':
    case 'aspect':
    case 'transit':
    case 'symbol':
    case 'archetype':
    case 'horoscope_bg':
    case 'insights_corner_tl':
    case 'insights_corner_br':
    case 'empty_journal':
    case 'onboarding':
    case 'pattern_stargrid_tile':
    case 'pattern_gradientnoise_tile':
    case 'bg_nebula_full':
    case 'lock_screen_illustration':
      return {
        kind: 'standard',
        baseName,
        imagesetPath: getImagesetPath(CATEGORY_FOLDERS[entry.category], baseName),
        template: entry.category === 'tab_icon'
      };
    case 'tab_icon':
      return {
        kind: 'standard',
        baseName,
        imagesetPath: getImagesetPath(CATEGORY_FOLDERS[entry.category], baseName),
        template: true
      };
    case 'oracle_hero':
    case 'oracle_icon':
    case 'pdf_header':
    case 'pdf_footer':
    case 'pdf_watermark':
    case 'loading_static':
      return {
        kind: 'vectorPreferred',
        baseName,
        imagesetPath: getImagesetPath(CATEGORY_FOLDERS[entry.category], baseName),
        template: entry.category === 'oracle_icon'
      };
    case 'loading_sprite':
      return {
        kind: 'spriteSheet',
        baseName,
        imagesetPath: getImagesetPath(CATEGORY_FOLDERS[entry.category], baseName)
      };
    case 'appicon_primary_2048':
    case 'appicon_primary_1024':
    case 'appicon_variant_lilac_1024':
      return {
        kind: 'appIcon',
        baseName,
        imagesetPath: null
      };
    default:
      return null;
  }
}

async function archiveFile(srcPath, archiveDir) {
  await ensureDir(archiveDir);
  const baseName = path.basename(srcPath);
  let destination = path.join(archiveDir, baseName);
  let counter = 1;
  while (existsSync(destination)) {
    const parsed = path.parse(baseName);
    destination = path.join(
      archiveDir,
      `${parsed.name}-${counter}${parsed.ext}`
    );
    counter += 1;
  }
  await fse.move(srcPath, destination);
  return destination;
}

function buildImagesArray(baseName, includeScales = [1, 2, 3]) {
  return includeScales.map((scale) => ({
    idiom: 'universal',
    filename: `${baseName}@${scale}x.png`,
    scale: `${scale}x`
  }));
}

async function writeContentsJson(imagesetPath, { images, properties }) {
  const contents = {
    images,
    info: DEFAULT_INFO
  };
  if (properties && Object.keys(properties).length > 0) {
    contents.properties = properties;
  }
  await writeJson(path.join(imagesetPath, 'Contents.json'), contents);
}

async function rasterize(buffer, width, height, scale, destPath) {
  const targetWidth = Math.round(width * scale);
  const targetHeight = Math.round(height * scale);
  await sharp(buffer)
    .resize({
      width: targetWidth,
      height: targetHeight,
      fit: 'fill'
    })
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(destPath);
}

async function inferDimensions(buffer, fallback = 512) {
  try {
    const metadata = await sharp(buffer).metadata();
    const width = metadata.width ?? fallback;
    const height = metadata.height ?? fallback;
    return { width, height };
  } catch {
    return { width: fallback, height: fallback };
  }
}

function computeBaseDimensions(width, height) {
  const minDimension = Math.min(width, height);
  const scale = minDimension < 512 ? 512 / minDimension : 1;
  return {
    width: Math.round(width * scale),
    height: Math.round(height * scale)
  };
}

async function ingestStandardAsset({ imagesetPath, baseName, buffer, template }) {
  await fse.emptyDir(imagesetPath);
  const { width, height } = await inferDimensions(buffer);
  const base = computeBaseDimensions(width, height);
  const images = buildImagesArray(baseName);
  await Promise.all(
    images.map((image) =>
      rasterize(
        buffer,
        base.width,
        base.height,
        Number.parseInt(image.scale, 10),
        path.join(imagesetPath, image.filename)
      )
    )
  );
  const properties = {};
  if (template) {
    properties['template-rendering-intent'] = 'template';
  }
  await writeContentsJson(imagesetPath, { images, properties });
}

async function ingestVectorPreferred({ imagesetPath, baseName, buffer, template }) {
  await fse.emptyDir(imagesetPath);
  const svgName = `${baseName}.svg`;
  await fs.writeFile(path.join(imagesetPath, svgName), buffer);

  const { width, height } = await inferDimensions(buffer);
  const base = computeBaseDimensions(width, height);
  const rasterImages = buildImagesArray(baseName);
  await Promise.all(
    rasterImages.map((image) =>
      rasterize(
        buffer,
        base.width,
        base.height,
        Number.parseInt(image.scale, 10),
        path.join(imagesetPath, image.filename)
      )
    )
  );

  const images = [
    {
      idiom: 'universal',
      filename: svgName
    },
    ...rasterImages
  ];

  const properties = {
    'preserves-vector-representation': true
  };
  if (template) {
    properties['template-rendering-intent'] = 'template';
  }
  await writeContentsJson(imagesetPath, { images, properties });
}

async function ingestSpriteSheet({ imagesetPath, baseName, buffer }) {
  await fse.emptyDir(imagesetPath);
  const filename = `${baseName}.png`;
  await sharp(buffer).png({ compressionLevel: 9 }).toFile(path.join(imagesetPath, filename));
  await writeContentsJson(imagesetPath, {
    images: [
      {
        idiom: 'universal',
        filename,
        scale: '1x'
      }
    ],
    properties: {}
  });
}

async function generateAppIconImages({
  buffer,
  baseFilenamePrefix,
  outputDir
}) {
  await fse.emptyDir(outputDir);
  const images = [];

  for (const spec of APP_ICON_SPECS) {
    for (const scale of spec.scales) {
      const sizeString =
        spec.idiom === 'ios-marketing'
          ? `${spec.size}x${spec.size}`
          : `${spec.size}x${spec.size}`;
      const filename =
        spec.idiom === 'ios-marketing'
          ? `${baseFilenamePrefix}-${spec.size}.png`
          : `${baseFilenamePrefix}-${spec.size}@${scale}x.png`;
      const pixelSize =
        spec.idiom === 'ios-marketing'
          ? spec.size
          : spec.size * scale;
      await sharp(buffer)
        .resize({
          width: Math.round(pixelSize),
          height: Math.round(pixelSize),
          fit: 'cover'
        })
        .png({ compressionLevel: 9, adaptiveFiltering: true })
        .toFile(path.join(outputDir, filename));
      images.push({
        idiom: spec.idiom,
        size: `${spec.size}x${spec.size}`,
        filename,
        scale: `${scale}x`
      });
    }
  }

  await writeContentsJson(outputDir, { images, properties: { 'pre-rendered': true } });
}

async function processAppIcons(appIconSources, cache, report) {
  const now = new Date().toISOString();
  const primarySource = appIconSources.primary ?? appIconSources.primary1024;

  if (primarySource) {
    const appIconSet = path.join(ASSETS_ROOT, 'AppIcon.appiconset');
    await ensureDir(appIconSet);
    await generateAppIconImages({
      buffer: primarySource.buffer,
      baseFilenamePrefix: 'AppIcon',
      outputDir: appIconSet
    });
    if (primarySource.cached) {
      report.updated.push('AppIcon.appiconset');
    } else {
      report.created.push('AppIcon.appiconset');
    }
  }

  const syncCache = (source) => {
    if (!source) return;
    cache.targets[source.cacheKey] = {
      md5: source.entry.md5,
      last_ingested_at: now,
      source: source.entry.original_filename
    };
  };

  syncCache(appIconSources.primary);
  syncCache(appIconSources.primary1024);

  if (appIconSources.variant) {
    const variantDir = path.join(ASSETS_ROOT, 'AppIconVariant.appiconset');
    await ensureDir(variantDir);
    await generateAppIconImages({
      buffer: appIconSources.variant.buffer,
      baseFilenamePrefix: 'AppIconVariant',
      outputDir: variantDir
    });
    if (appIconSources.variant.cached) {
      report.updated.push('AppIconVariant.appiconset');
    } else {
      report.created.push('AppIconVariant.appiconset');
    }
  }

  syncCache(appIconSources.variant);
}

async function main() {
  const manifest = await loadManifest();
  const cache = await readJson(CACHE_PATH, { targets: {} });
  await ensureDir(ARCHIVE_DIR);

  const report = {
    updated: [],
    created: [],
    skipped: [],
    duplicates: [],
    moved: [],
    errors: []
  };

  const appIconSources = {
    primary: null,
    primary1024: null,
    variant: null
  };

  for (const entry of manifest) {
    const sourcePath = path.join(repoRoot, entry.src);
    const relativeSource = path.relative(repoRoot, sourcePath);

    if (!existsSync(sourcePath)) {
      report.errors.push(`Missing source ${relativeSource}`);
      continue;
    }

    const buffer = await fs.readFile(sourcePath);

    const targetInfo = resolveTarget(entry);
    if (!targetInfo) {
      report.errors.push(`Unrecognized category "${entry.category}" for ${relativeSource}`);
      await archiveFile(sourcePath, ARCHIVE_DIR);
      continue;
    }

    if (entry.is_primary === false) {
      report.duplicates.push(relativeSource);
      const archived = await archiveFile(sourcePath, ARCHIVE_DIR);
      report.moved.push({
        src: entry.src,
        archive: path.relative(repoRoot, archived),
        target: null
      });
      continue;
    }

    if (targetInfo.kind === 'appIcon') {
      const cacheKey = entry.target_name;
      const cached = cache.targets[cacheKey];
      if (cached && cached.md5 === entry.md5) {
        report.skipped.push(cacheKey);
        const archived = await archiveFile(sourcePath, ARCHIVE_DIR);
        report.moved.push({
          src: entry.src,
          archive: path.relative(repoRoot, archived),
          target: cacheKey
        });
        continue;
      }

      const archived = await archiveFile(sourcePath, ARCHIVE_DIR);
      report.moved.push({
        src: entry.src,
        archive: path.relative(repoRoot, archived),
        target: cacheKey
      });

      const payload = { buffer, entry, cacheKey, cached };
      if (entry.category === 'appicon_primary_2048') {
        appIconSources.primary = payload;
      } else if (entry.category === 'appicon_primary_1024') {
        appIconSources.primary1024 = payload;
      } else if (entry.category === 'appicon_variant_lilac_1024') {
        appIconSources.variant = payload;
      }
      continue;
    }

    const cacheKey = entry.target_name;
    const cached = cache.targets[cacheKey];
    if (cached && cached.md5 === entry.md5) {
      report.skipped.push(cacheKey);
      const archived = await archiveFile(sourcePath, ARCHIVE_DIR);
      report.moved.push({
        src: entry.src,
        archive: path.relative(repoRoot, archived),
        target: cacheKey
      });
      continue;
    }

    await ensureDir(path.dirname(targetInfo.imagesetPath));

    try {
      switch (targetInfo.kind) {
        case 'standard':
          await ingestStandardAsset({
            imagesetPath: targetInfo.imagesetPath,
            baseName: targetInfo.baseName,
            buffer,
            template: targetInfo.template
          });
          break;
        case 'vectorPreferred':
          await ingestVectorPreferred({
            imagesetPath: targetInfo.imagesetPath,
            baseName: targetInfo.baseName,
            buffer,
            template: targetInfo.template
          });
          break;
        case 'spriteSheet':
          await ingestSpriteSheet({
            imagesetPath: targetInfo.imagesetPath,
            baseName: targetInfo.baseName,
            buffer
          });
          break;
        default:
          throw new Error(`Unhandled asset kind ${targetInfo.kind}`);
      }

      const archived = await archiveFile(sourcePath, ARCHIVE_DIR);
      report.moved.push({
        src: entry.src,
        archive: path.relative(repoRoot, archived),
        target: cacheKey
      });

      cache.targets[cacheKey] = {
        md5: entry.md5,
        last_ingested_at: new Date().toISOString(),
        source: entry.original_filename
      };

      if (cached) {
        report.updated.push(cacheKey);
      } else {
        report.created.push(cacheKey);
      }
    } catch (error) {
      report.errors.push(`Failed ingest for ${cacheKey}: ${error.message}`);
    }
  }

  await processAppIcons(appIconSources, cache, report);

  await writeJson(CACHE_PATH, cache);
  await writeJson(REPORT_PATH, {
    generated_at: new Date().toISOString(),
    report
  });

  info(`Ingest complete. Created ${report.created.length}, updated ${report.updated.length}, skipped ${report.skipped.length}.`);
  if (report.errors.length) {
    warned(`Encountered ${report.errors.length} errors. See ${path.relative(repoRoot, REPORT_PATH)} for details.`);
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error('Artwork ingestion failed.');
  console.error(error);
  process.exitCode = 1;
});


