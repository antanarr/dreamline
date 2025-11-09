export const HoroscopeSchema = {
  name: "horoscope_structured",
  schema: {
    type: "object",
    properties: {
      headline: { type: "string" },
      summary:  { type: "string" },
      areas: {
        type: "array",
        items: {
          type: "object",
          properties: {
            id: { type: "string", enum: ["relationships","work_money","home_body","creativity_learning","spirituality","routine_habits"] },
            title: { type: "string" },
            score: { type: "number" },
            bullets: { type: "array", items: { type:"string" }, minItems:2, maxItems:4 },
            actions: {
              type: "object",
              properties: {
                "do":   { type: "array", items: { type:"string" }, minItems:1, maxItems:3 },
                "dont": { type: "array", items: { type:"string" }, minItems:1, maxItems:3 }
              },
              required: ["do","dont"],
              additionalProperties: false
            }
          },
          required: ["id","title","score","bullets"],
          additionalProperties: false
        }
      }
    },
    required: ["headline","summary","areas"],
    additionalProperties: false
  }
};

