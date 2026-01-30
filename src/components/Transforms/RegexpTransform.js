export const RegexpTransform = {
  name: "regexp",
  fn: async (v) => {
    const [expression, samples] = v.split("\n\n");
    const regexp = new RegExp(expression);

    const parsedSamples = samples
      .split("\n")
      .map((sample) => regexp.exec(sample))
      .map((sample, i) =>
        `${i + 3}(${sample === null ? "x" : "o"}) ${JSON.stringify(sample?.groups) ?? ""}`.trimEnd(),
      )
      .join("\n");

    return [expression, samples, parsedSamples].join("\n\n");
  },
};
