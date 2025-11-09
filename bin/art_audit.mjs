import fs from 'fs';
import path from 'path';

const ROOT = process.cwd();

const ASSETS = [
  { group: "AstroZodiac", names: ["zodiac_aries","zodiac_taurus","zodiac_gemini","zodiac_cancer","zodiac_leo","zodiac_virgo","zodiac_libra","zodiac_scorpio","zodiac_sagittarius","zodiac_capricorn","zodiac_aquarius","zodiac_pisces"] },
  { group: "AstroPlanets", names: ["planet_sun_fill","planet_moon_fill","planet_mercury_fill","planet_venus_fill","planet_mars_fill","planet_jupiter_fill","planet_saturn_fill","planet_uranus_fill","planet_neptune_fill","planet_pluto_fill"] },
  { group: "Backgrounds", names: ["bg_horoscope_card"] },
  { group: "Onboarding", names: ["ob_welcome","ob_privacy","ob_birth","ob_notifications","ob_sample","ob_completion"] },
  { group: "Symbols", names: ["symbol_water","symbol_door","symbol_room","symbol_house","symbol_bird","symbol_teeth","symbol_flight","symbol_ocean","symbol_wall","symbol_truck","symbol_car","symbol_road","symbol_building"] }
];

const xc = path.join(ROOT, "Resources", "Assets.xcassets");
const result = [];
for (const set of ASSETS) {
  for (const name of set.names) {
    const p = path.join(xc, set.group, `${name}.imageset`);
    result.push({ name, path: p, exists: fs.existsSync(p) });
  }
}
fs.writeFileSync("asset_audit.json", JSON.stringify(result, null, 2));
const missing = result.filter(r => !r.exists).map(r=>r.name);
console.log(JSON.stringify({ total: result.length, missing: missing.length }, null, 2));
if (missing.length) {
  console.log("Missing:", missing.join(", "));
}
