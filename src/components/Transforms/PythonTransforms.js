const pythonToJSON = (pythonStr) => {
  // Validate basic structure first before any replacements
  if (!/^\s*(?:\{[\s\S]*\}|\[[\s\S]*\])\s*$/.test(pythonStr)) {
    throw new Error("Invalid Python dictionary or array format");
  }

  // Perform all replacements in a single pass
  return pythonStr.replace(/('|None\b|True\b|False\b)/g, (match) => {
    switch (match) {
      case "'":
        return '"';
      case "None":
        return "null";
      case "True":
        return "true";
      case "False":
        return "false";
      default:
        return match;
    }
  });
};

export const PythonDictToJSONTransform = {
  name: "py2json",
  fn: async (v) => {
    try {
      // Validate the result is actually valid JSON
      return JSON.stringify(JSON.parse(pythonToJSON(v)));
    } catch {
      throw new Error("Invalid Python dictionary or array format");
    }
  },
};

export const JSONToPythonDictTransform = {
  name: "json2py",
  fn: async (v) => {
    try {
      // Validate and format in one step
      return JSON.stringify(JSON.parse(v), null, 2).replace(
        /("|\bnull\b|\btrue\b|\bfalse\b)/g,
        (match) => {
          switch (match) {
            case '"':
              return "'";
            case "null":
              return "None";
            case "true":
              return "True";
            case "false":
              return "False";
            default:
              return match;
          }
        },
      );
    } catch {
      throw new Error("Invalid JSON format");
    }
  },
};
