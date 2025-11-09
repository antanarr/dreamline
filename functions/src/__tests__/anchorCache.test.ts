import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { anchorKeyFor } from "../anchors.js";

describe("anchor keys are stable", () => {
  it("day anchor is yyyy-MM-dd", () => {
    const d = new Date("2025-11-06T12:00:00Z");
    assert.equal(anchorKeyFor("day", d), "2025-11-06");
  });

  it("month anchor is yyyy-MM", () => {
    const d = new Date("2025-11-06T12:00:00Z");
    assert.equal(anchorKeyFor("month", d), "2025-11");
  });

  it("year anchor is yyyy", () => {
    const d = new Date("2025-11-06T12:00:00Z");
    assert.equal(anchorKeyFor("year", d), "2025");
  });

  it("week anchor is ISO week format", () => {
    const d = new Date("2025-11-06T12:00:00Z");
    const weekKey = anchorKeyFor("week", d);
    assert.ok(weekKey.match(/^\d{4}-W\d{2}$/), `Expected ISO week format, got: ${weekKey}`);
  });
});

