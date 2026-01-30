import Layout from "@theme/Layout";
import Head from "@docusaurus/Head";
import { Editor as MonacoEditor } from "@monaco-editor/react";
import { useRef, useState } from "react";
import style from "./tools.module.css";
import { TransformGridItem } from "../components/TransformGridItem";
import { transforms, wrapTransform } from "../components/Transforms/Transform";

export default function Tools() {
  const [value, setValue] = useState("");
  const ref = useRef();

  return (
    <Layout
      title="Tools"
      description="PTools-inspired utilities: JSON, encoding, dates, gzip, Python/JSON, regex and more."
    >
      <Head>
        <meta name="robots" content="index, follow" />
        <link rel="canonical" href="https://awsutils.github.io/tools" />
      </Head>

      <main className={style.container}>
        <MonacoEditor
          loading={<></>}
          value={value}
          language="yaml"
          onMount={(v) => (ref.current = v)}
          onChange={(v) => setValue(v.replaceAll("\r\n", "\n") ?? "")}
          options={{
            automaticLayout: true,
            lineNumbersMinChars: 3,
            minimap: { enabled: false },
            theme: "vs-dark",
            fontSize: 24,
            fontFamily: "JetBrains Mono Variable",
            fontLigatures: true,
            wordWrap: "on",
            mouseWheelZoom: true,
            smoothScrolling: true,
            cursorSmoothCaretAnimation: "on",
            cursorBlinking: "smooth",
            cursorStyle: "line",
          }}
          theme="vs-dark"
        />

        <ul className={style.grid}>
          {transforms.map((transform, i) => (
            <li
              key={i}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: i * 0.1 + 1.5 }}
            >
              <TransformGridItem
                transform={wrapTransform(transform)}
                value={value}
                setValue={setValue}
              />
            </li>
          ))}
        </ul>
      </main>
    </Layout>
  );
}
