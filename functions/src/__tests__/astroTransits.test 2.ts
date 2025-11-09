import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { buildTransitRange } from "../astro/transitEngine.js";

const birthISO = "1990-03-20T05:15:00.000Z";
const startISO = "2024-10-01T00:00:00.000Z";
const endISO = "2024-10-03T00:00:00.000Z";

describe("astroTransitsRange engine", () => {
  const sample = buildTransitRange({ birthISO, startISO, endISO });

  it("produces deterministic daily snapshots", () => {
    const snapshot = sample.map((item) => ({
      dateISO: item.dateISO,
      headline: item.headline,
      intensityScore: item.intensityScore,
      bullets: item.bullets
    }));

    assert.deepEqual(snapshot, [
      {
        dateISO: "2024-10-01T12:00:00.000Z",
        headline: "Mars sextile Mercury",
        intensityScore: 1,
        bullets: [
          "Mars sextile Mercury · opens practice rooms · orb 0.1° · 84%",
          "Moon square Uranus · pressurizes growth · orb 2.4° · 63%",
          "Saturn trine Pluto · lets patterns flow · orb 0.7° · 53%",
          "Saturn sextile Saturn · opens practice rooms · orb 1.7° · 50%"
        ]
      },
      {
        dateISO: "2024-10-02T12:00:00.000Z",
        headline: "Mars sextile Mercury",
        intensityScore: 1,
        bullets: [
          "Mars sextile Mercury · opens practice rooms · orb 0.6° · 76%",
          "Moon square Neptune · pressurizes growth · orb 2.8° · 59%",
          "Venus square Moon · pressurizes growth · orb 1.8° · 58%",
          "Mercury square Jupiter · pressurizes growth · orb 1.4° · 57%"
        ]
      },
      {
        dateISO: "2024-10-03T12:00:00.000Z",
        headline: "Venus square Sun",
        intensityScore: 1,
        bullets: [
          "Venus square Sun · pressurizes growth · orb 0.0° · 75%",
          "Venus square Moon · pressurizes growth · orb 0.2° · 73%",
          "Moon square Neptune · pressurizes growth · orb 1.8° · 70%",
          "Mars sextile Mercury · opens practice rooms · orb 1.1° · 69%"
        ]
      }
    ]);
  });

  it("orders aspects by intensity and clamps values", () => {
    for (const day of sample) {
      for (let i = 0; i < day.aspects.length - 1; i += 1) {
        assert.ok(day.aspects[i].score >= day.aspects[i + 1].score - 1e-6);
      }
      assert.ok(day.intensityScore >= 0 && day.intensityScore <= 1);
      assert.ok(day.bullets.length > 0);
    }
  });
});
