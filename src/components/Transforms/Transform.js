import {
  Base64DecodeTransform,
  Base64EncodeTransform,
} from "./Base64Transforms";
import { DatetimeTransform } from "./DatetimeTransforms";
import {
  GzipCompressTransform,
  GzipDecompressTransform,
} from "./GzipTransform";
import {
  JSONBeautifyTransform,
  JSONEscapeTransform,
  JSONSimplifyTransform,
  JSONUnescapeTransform,
} from "./JSONTransforms";
import { RegexpTransform } from "./RegexpTransform";
import { URIDecodeTransform, URIEncodeTransform } from "./URITransforms";
import { JSON2YAMLTransform, YAML2JSONTransform } from "./YAMLTransforms";
import {
  PythonDictToJSONTransform,
  JSONToPythonDictTransform,
} from "./PythonTransforms";
import { CurlTransform } from "./CurlTransform";
import { IWRETransform } from "./IWRTransform";

export const wrapTransform = (transform) => ({
  ...transform,

  fn: async (...args) =>
    await transform
      .fn(...args)
      .then((value) => ({ error: false, value: value.toString() }))
      .catch((error) => ({ error: true, value: error.toString() })),

  options: new Map((transform.options ?? []).map((v) => [v.key, v])),
  wrapped: true,
});

export const transforms = [
  RegexpTransform,
  DatetimeTransform,
  Base64DecodeTransform,
  Base64EncodeTransform,
  URIDecodeTransform,
  URIEncodeTransform,
  JSONBeautifyTransform,
  JSONSimplifyTransform,
  JSONEscapeTransform,
  JSONUnescapeTransform,
  JSON2YAMLTransform,
  YAML2JSONTransform,
  PythonDictToJSONTransform,
  JSONToPythonDictTransform,
  GzipCompressTransform,
  GzipDecompressTransform,
  CurlTransform,
  IWRETransform,
];
