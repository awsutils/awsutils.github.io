import React from "react";
import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import Head from "@docusaurus/Head";

import styles from "./index.module.css";
import HomepageFeatures from "../components/HomepageFeatures";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--primary", styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/docs/introduction"
          >
            Get Started!
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  
  const structuredData = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    "name": "awsutils",
    "description": "awsutils is a collection of reusable utilities designed to make working with AWS easier, faster, and more consistent for DevOps and platform teams.",
    "url": "https://awsutils.github.io",
    "applicationCategory": "DeveloperApplication",
    "operatingSystem": "Linux, macOS, Windows",
    "offers": {
      "@type": "Offer",
      "price": "0",
      "priceCurrency": "USD"
    },
    "author": {
      "@type": "Organization",
      "name": "awsutils"
    }
  };

  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": [
      {
        "@type": "Question",
        "name": "What is awsutils?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "awsutils is a curated set of lightweight tools, scripts, and browser utilities that simplify everyday AWS and Kubernetes tasks such as EKS management, manifest generation, and data format conversions."
        }
      },
      {
        "@type": "Question",
        "name": "Who should use awsutils?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "Cloud engineers, DevOps practitioners, and SREs who need quick, repeatable helpers for AWS operations, YAML/JSON editing, encoding/decoding, and CI-friendly automation."
        }
      },
      {
        "@type": "Question",
        "name": "Is awsutils free to use?",
        "acceptedAnswer": {
          "@type": "Answer",
          "text": "Yes. awsutils is open and free to use. The site provides ready-to-run browser tools and documentation for command-line scripts without any sign-up."
        }
      }
    ]
  };

  return (
    <Layout
      title="awsutils - Lightweight AWS Automation Tools"
      description="Collection of reusable utilities designed to make working with AWS easier, faster, and more consistent. Includes tools for EKS, Kubernetes, and cloud resource management."
    >
      <Head>
        <script type="application/ld+json">
          {JSON.stringify(structuredData)}
        </script>
        <script type="application/ld+json">
          {JSON.stringify(faqSchema)}
        </script>
        <meta name="robots" content="index, follow" />
        <meta
          name="keywords"
          content="awsutils, AWS utilities, DevOps tools, EKS, Kubernetes, cloud automation scripts, YAML to JSON, base64, gzip, regex tester"
        />
        <link rel="canonical" href="https://awsutils.github.io/" />
      </Head>
      <HomepageHeader />
      <main>
        <HomepageFeatures />
        <section className={styles.seoCopy}>
          <div className="container">
            <h2>Why awsutils?</h2>
            <p>
              awsutils brings together lean, production-ready helpers that shorten the distance between an AWS task
              and a reliable outcome. From EKS manifest tweaks to encoding, decoding, and linting cloud configs, each
              tool is optimized for speed, clarity, and repeatability.
            </p>
            <p>
              The toolkit is built for engineers who live in terminals and CI pipelines. You will find pragmatic defaults,
              copy-paste ready snippets, and browser-based transforms that avoid vendor lock-in while aligning with AWS
              best practices.
            </p>
          </div>
        </section>
      </main>
    </Layout>
  );
}
