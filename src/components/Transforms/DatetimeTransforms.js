import { strptime } from "strtime";
import moment from "moment";

export const DatetimeTransform = {
  name: "datetime",

  fn: async (v, o) => {
    const [expression, samples] = v.split("\n\n");
    const format = o.get("f")?.value;

    const parsedSamples = samples
      .split("\n")
      .map((sample) => {
        if (format === "c")
          return strptime(sample, expression.replace(/'/g, ""));

        if (format === "java")
          return moment(sample, expression.replace(/'/g, "")).toDate();

        throw new Error("Unknown Format");
      })
      .map((date) =>
        JSON.stringify({
          year: date.getFullYear(),
          month: date.getMonth() + 1,
          date: date.getDate(),
          hour: date.getHours(),
          minute: date.getMinutes(),
          second: date.getSeconds(),
          milli: date.getMilliseconds(),
        }),
      )
      .join("\n");

    return [expression, samples, parsedSamples].join("\n\n");
  },

  options: [
    {
      type: "RADIO",
      key: "f",
      value: "c",
      radios: [{ value: "c" }, { value: "java" }],
    },
  ],
};
