export const Base64DecodeTransform = {
  name: "base64d",
  fn: async (v) => atob(v),
};

export const Base64EncodeTransform = {
  name: "base64e",
  fn: async (v) => btoa(v),
};
