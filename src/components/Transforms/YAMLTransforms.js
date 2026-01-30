import YAML from "yaml";
import JSON5 from "json5";

export const YAML2JSONTransform = {
  name: "yaml2json",

  fn: async (v) => JSON.stringify(YAML.parse(v)),
};

export const JSON2YAMLTransform = {
  name: "json2yaml",

  fn: async (v) => YAML.stringify(JSON5.parse(v)),
};
