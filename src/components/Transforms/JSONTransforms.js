import JSON5 from "json5";

export const JSONBeautifyTransform = {
  name: "jsonbtf",

  fn: async (v, o) =>
    o.get("multiline")?.value === true
      ? JSON.stringify(JSON5.parse(v), null, o.get("tab")?.value ?? 2)
      : v
          .split("\n")
          .map((v2) =>
            JSON.stringify(JSON5.parse(v2), null, o.get("tab")?.value ?? 2),
          )
          .join("\n"),

  options: [
    {
      type: "CHECKBOX",
      key: "multiline",
    },
    {
      type: "INTBOX",
      key: "tab",
      value: 2,
    },
  ],
};

export const JSONSimplifyTransform = {
  name: "jsonsmp",

  fn: async (v) => JSON.stringify(JSON5.parse(v)),
};

export const JSONEscapeTransform = {
  name: "jsonesc",

  fn: async (v) => JSON.stringify(v),
};

export const JSONUnescapeTransform = {
  name: "jsonunesc",

  fn: async (v) => {
    const result = JSON5.parse(v);

    if (typeof result !== "string") throw new Error("Not JSON escaped");

    return result;
  },
};
