---
sidebar_position: 1
---

# Introduction

`awsutils` is a Docusaurus site for small AWS-focused helper scripts and supporting documentation.

## What It Contains

- Published shell scripts from `static/`
- Script documentation in `docs/scripts/`
- General project docs in `docs/docs/`
- A custom browser-based transform toolbox at `/tools`

## How Scripts Are Delivered

Files in `static/` are served at the root of the site. For example:

- `static/eksctl.sh` is published as `https://awsutils.github.io/eksctl.sh`
- `static/vpce.sh` is published as `https://awsutils.github.io/vpce.sh`

## Project Goals

- Keep common AWS and platform tasks easy to reuse
- Make script behavior transparent through simple hosted files
- Pair every published utility with docs that explain what it really does today

## Local Development

```bash
npm install
npm start
```

## Next Steps

- Start with [Getting Started](getting-started.md)
- Browse [Scripts Overview](../scripts/intro.md)
- Explore the site configuration in `docusaurus.config.js`
