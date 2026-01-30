// @ts-check
// `@type` JSDoc annotations allow editor autocompletion and type checking
// (when paired with `@ts-check`).
// There are various equivalent ways to declare your Docusaurus config.
// See: https://docusaurus.io/docs/api/docusaurus-config

import {themes as prismThemes} from 'prism-react-renderer';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'AWS Utilities - Lightweight AWS Automation Tools',
  tagline: 'Collection of reusable utilities designed to make working with AWS easier, faster, and more consistent.',
  favicon: 'img/favicon.ico',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: 'https://awsutils.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'awsutils', // Usually your GitHub org/user name.
  projectName: 'awsutils.github.io', // Usually your repo name.
  deploymentBranch: 'gh-pages',
  trailingSlash: false,

  onBrokenLinks: 'throw',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/awsutils/awsutils.github.io',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
        sitemap: {
          changefreq: 'weekly',
          priority: 0.5,
          ignorePatterns: ['/tags/**'],
          filename: 'sitemap.xml',
        },
        gtag: {
          trackingID: 'G-XXXXXXXXXX', // Replace with your Google Analytics ID
          anonymizeIP: true,
        },
      }),
    ],
  ],

  plugins: [
    [
      '@docusaurus/plugin-pwa',
      {
        debug: true,
        offlineModeActivationStrategies: [
          'appInstalled',
          'standalone',
          'queryString',
        ],
        pwaHead: [
          {
            tagName: 'link',
            rel: 'icon',
            href: '/img/logo.png',
          },
          {
            tagName: 'link',
            rel: 'manifest',
            href: '/manifest.json',
          },
          {
            tagName: 'meta',
            name: 'theme-color',
            content: '#ff9900',
          },
        ],
      },
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // SEO metadata
      metadata: [
        {name: 'keywords', content: 'AWS, utilities, automation, DevOps, cloud, scripts, EKS, Kubernetes, helm, kubectl'},
        {name: 'description', content: 'Lightweight AWS utilities for automation and operational efficiency. Includes tools for EKS, Kubernetes, and cloud resource management.'},
        {property: 'og:type', content: 'website'},
        {property: 'og:title', content: 'AWS Utilities - Lightweight AWS Automation Tools'},
        {property: 'og:description', content: 'Collection of reusable utilities designed to make working with AWS easier, faster, and more consistent.'},
        {property: 'og:image', content: 'https://awsutils.github.io/img/logo.svg'},
        {name: 'twitter:card', content: 'summary_large_image'},
        {name: 'twitter:title', content: 'AWS Utilities - Lightweight AWS Automation Tools'},
        {name: 'twitter:description', content: 'Collection of reusable utilities designed to make working with AWS easier, faster, and more consistent.'},
      ],
      colorMode: {
        defaultMode: "dark",
        disableSwitch: true
      },
      navbar: {
        title: 'AWS Utilities',
        logo: {
          alt: 'AWS Utilities Logo',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'docs',
            position: 'left',
            label: 'Docs',
          },
          {
            to: '/tools',
            label: 'Tools',
            position: 'left',
          },
          {
            type: 'docSidebar',
            sidebarId: 'scripts',
            position: 'left',
            label: 'Scripts',
          },
          {
            href: 'https://github.com/awsutils/awsutils.github.io',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        links: [
          {
            title: "Community",
            items: [
              {
                label: "GitHub",
                href: "https://github.com/awsutils/awsutils.github.io",
              },
            ],
          },
          {
            title: "Other",
            items: [
              {
                label: "Site Terms",
                href: "https://aws.amazon.com/terms/",
              },
              {
                label: "Privacy",
                href: "https://aws.amazon.com/privacy/",
              },
            ],
          },
        ],
        copyright: `© ${new Date().getFullYear()}, Amazon Web Services, Inc. or its affiliates. All rights reserved.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
      },
    }),
};

export default config;
