const decompressGzip = async (base64) => {
  const byteCharacters = atob(base64);
  const byteNumbers = new Array(byteCharacters.length);

  for (let i = 0; i < byteCharacters.length; i++)
    byteNumbers[i] = byteCharacters.charCodeAt(i);

  const decompressedStream = new Blob([new Uint8Array(byteNumbers)])
    .stream()
    .pipeThrough(new DecompressionStream("gzip"));

  return await new Response(decompressedStream).text();
};

export const GzipDecompressTransform = {
  name: "gzipd",

  fn: (v) => decompressGzip(v),
};

const compressGzip = async (input) => {
  if (typeof CompressionStream === "undefined") {
    throw new Error(
      "CompressionStream API is not supported in this environment.",
    );
  }

  const encoder = new TextEncoder();
  const encoded = encoder.encode(input);

  const readable = new ReadableStream({
    start(controller) {
      controller.enqueue(encoded);
      controller.close();
    },
  });

  const compressionStream = new CompressionStream("gzip");

  const compressedStream = readable.pipeThrough(compressionStream);

  const reader = compressedStream.getReader();
  const chunks = [];
  let done = false;

  while (!done) {
    const { value, done: doneReading } = await reader.read();
    if (value) {
      chunks.push(value);
    }
    done = doneReading;
  }

  const totalLength = chunks.reduce((acc, chunk) => acc + chunk.length, 0);
  const compressedData = new Uint8Array(totalLength);
  let offset = 0;
  for (const chunk of chunks) {
    compressedData.set(chunk, offset);
    offset += chunk.length;
  }

  const base64String = arrayBufferToBase64(compressedData);

  return base64String;
};

const arrayBufferToBase64 = (buffer) => {
  let binary = "";
  for (let i = 0; i < buffer.length; i++) {
    binary += String.fromCharCode(buffer[i]);
  }
  return btoa(binary);
};

export const GzipCompressTransform = {
  name: "gzipc", // Unique identifier for the transform

  fn: (v) => compressGzip(v),

  options: [], // Add any options if needed
};
