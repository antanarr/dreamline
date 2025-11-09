import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { clinicalVoiceIssues, findBannedTerms, voiceGuardConstants } from "../style/voiceGuards.js";

describe("voice guard heuristics", () => {
  it("detects banned phrasing", () => {
    const text = "Feeling lucky? Today you will manifest auras and vibes galore.";
    const hits = findBannedTerms(text);

    assert.ok(hits.includes("lucky"));
    assert.ok(hits.includes("today you will"));
    assert.ok(clinicalVoiceIssues(text).some((issue) => issue.startsWith("banned terms")));
  });

  it("accepts clinical-poetic texture", () => {
    const text = "Chart the breath-field like a quiet lab report; follow each pulse of memory as data.";
    const issues = clinicalVoiceIssues(text);

    assert.deepEqual(issues, []);
  });

  it("flags missing imagery", () => {
    const bland = "You are calm and everything is fine. Remain positive throughout the day.";
    const issues = clinicalVoiceIssues(bland);

    assert.ok(issues.includes("missing tactile/clinical imagery"));
  });

  it("publishes guard constants for downstream checks", () => {
    assert.ok(voiceGuardConstants.BANNED_TERMS.length > 0);
    assert.ok(voiceGuardConstants.REQUIRED_IMAGERY.length > 0);
  });
});
