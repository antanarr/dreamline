import fs from 'fs';
import path from 'path';

const ROOT = process.cwd();
const XC = path.join(ROOT, "Resources", "Assets.xcassets");
const AUDIT_PATH = path.join(ROOT, "asset_audit.json");

function ensureDir(p){ fs.mkdirSync(p,{recursive:true}); }

function svgFor(name) {
  const label = name.replace(/_/g," ").toUpperCase();
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="g1" cx="50%" cy="40%" r="70%">
      <stop offset="0%" stop-color="#3b2a6e"/>
      <stop offset="60%" stop-color="#1b1436"/>
      <stop offset="100%" stop-color="#0b0f1a"/>
    </radialGradient>
  </defs>
  <rect width="512" height="512" fill="url(#g1)"/>
  <g fill="#cfc9ff" font-family="SF Pro Display, -apple-system, Helvetica, Arial, sans-serif" text-anchor="middle">
    <text x="256" y="260" font-size="28" opacity="0.92">${label}</text>
  </g>
</svg>`;
}

function contentsJSON(name, isTemplate=false) {
  const base = {
    images: [
      { idiom: "universal", filename: `${name}.svg`, scale: "1x" }
    ],
    info: { version: 1, author: "xcode" },
    properties: { "preserves-vector-representation": true }
  };
  if (isTemplate) {
    base.properties["template-rendering-intent"] = "template";
  }
  return JSON.stringify(base, null, 2);
}

function groupFor(name){
  if (name.startsWith("zodiac_")) return "AstroZodiac";
  if (name.startsWith("planet_")) return "AstroPlanets";
  if (name.startsWith("bg_")) return "Backgrounds";
  if (name.startsWith("ob_")) return "Onboarding";
  if (name.startsWith("tab_")) return "TabIcons";
  if (name.startsWith("symbol_")) return "Symbols";
  return "Misc";
}

function isTemplateIcon(name){
  return name.startsWith("tab_");
}

function writeImageset(name) {
  const group = groupFor(name);
  const dir = path.join(XC, group, `${name}.imageset`);
  ensureDir(dir);
  fs.writeFileSync(path.join(dir, `${name}.svg`), svgFor(name), "utf8");
  fs.writeFileSync(path.join(dir, "Contents.json"), contentsJSON(name, isTemplateIcon(name)), "utf8");
}

(function main(){
  if (!fs.existsSync(AUDIT_PATH)) {
    console.error("asset_audit.json not found. Run: node bin/art_audit.mjs");
    process.exit(1);
  }
  const audit = JSON.parse(fs.readFileSync(AUDIT_PATH, "utf8"));
  const missing = audit.filter(r => !r.exists);
  if (!missing.length) {
    console.log("No missing assets—nothing to generate.");
    return;
  }
  for (const row of missing) {
    writeImageset(row.name);
  }
  console.log(`Generated ${missing.length} SVG placeholders.`);
})();
