export const IWRETransform = {
  name: "iwre",
  fn: async (v) => {
    // Split the input into sections using blank lines as delimiters.
    const sections = v
      .split(/\n\s*\n/)
      .map((s) => s.trim())
      .filter(Boolean);
    if (sections.length === 0) return "";

    // Process the first section (request line and headers)
    const headerLines = sections[0]
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean);
    if (headerLines.length === 0) return "";

    // The first line should be something like "POST https://test.example.com"
    const [method, url] = headerLines[0].split(" ");
    const psParts = [
      `Invoke-WebRequest -Uri "${url}" -Method ${method.toUpperCase()}`,
    ];

    // Build a headers object
    const headers = {};
    for (let i = 1; i < headerLines.length; i++) {
      const line = headerLines[i];
      const colonIndex = line.indexOf(":");
      if (colonIndex === -1) continue; // Skip lines that aren't valid headers
      const headerName = line.substring(0, colonIndex).trim();
      const headerValue = line.substring(colonIndex + 1).trim();
      headers[headerName] = headerValue;
    }

    if (Object.keys(headers).length > 0) {
      // Build the header hashtable string for PowerShell using actual newlines.
      const headerStr = Object.entries(headers)
        .map(([key, value]) => `    "${key}" = "${value}"`)
        .join("\n");
      psParts.push(`-Headers @{\n${headerStr}\n}`);
    }

    // Process the body (if any)
    if (sections.length > 1) {
      const body = sections.slice(1).join("\n\n").trim();
      if (body) {
        // Escape single quotes by doubling them.
        const escapedBody = body.replace(/'/g, "''");
        psParts.push(`-Body '${escapedBody}'`);
      }
    }

    // Join parts with PowerShell's line continuation character (backtick) and an actual newline.
    return psParts.join(" `\n");
  },
};
