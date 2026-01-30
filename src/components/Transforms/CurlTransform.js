export const CurlTransform = {
  name: "curle",
  fn: async (v) => {
    // Split the input into sections using blank lines as delimiters.
    // The first section contains the request line and headers,
    // and the remaining section(s) (if any) form the body.
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

    // The first line is expected to be the request line, e.g., "POST https://test.example.com"
    const [method, url] = headerLines[0].split(" ");
    const curlParts = [`curl -X ${method.toUpperCase()} ${url}`];

    // Process each header line (if any exist)
    for (let i = 1; i < headerLines.length; i++) {
      const line = headerLines[i];
      // Find the first colon to split header name and value.
      const colonIndex = line.indexOf(":");
      if (colonIndex === -1) continue; // Skip any lines that are not valid headers
      const headerName = line.substring(0, colonIndex).trim();
      const headerValue = line.substring(colonIndex + 1).trim();
      curlParts.push(`  -H "${headerName}: ${headerValue}"`);
    }

    // Process the body if one is provided (all sections after the first)
    if (sections.length > 1) {
      // Join remaining sections (in case there are multiple blank-line separations)
      const body = sections.slice(1).join("\n\n").trim();
      if (body) {
        curlParts.push(`  -d '${body}'`);
      }
    }

    // Join the parts using backslashes to create a multi-line curl command.
    return curlParts.join(" \\\n");
  },
};
