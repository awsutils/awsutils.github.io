---
sidebar_position: 3
---

# Getting Started

awsutils is a Docusaurus site that publishes lightweight AWS helper scripts and a small browser-based transform toolbox.

## What You Need First

- An AWS account and credentials for any script that calls AWS APIs
- Node.js 20+ if you want to run the site locally
- Standard shell tools like `curl`, `wget`, `tar`, and `sudo` for installer scripts

## Use Hosted Scripts

Published scripts come from `static/` and are available at the site root.

```bash
curl -fsSLO https://awsutils.github.io/eksctl.sh
chmod +x eksctl.sh
sudo ./eksctl.sh
```

You can browse the full list in [Scripts Overview](../scripts/intro.md).

## Configure AWS Access

For scripts that interact with AWS, confirm your CLI setup first:

```bash
aws sts get-caller-identity
aws configure get region
```

Named profiles work as expected:

```bash
AWS_PROFILE=production aws sts get-caller-identity
```

## Run the Site Locally

```bash
npm install
npm start
```

Useful commands:

```bash
npm run build
npm run serve
```

## Repo Layout

```text
awsutils.github.io/
|- docs/
|  |- docs/        # General documentation
|  `- scripts/     # Script-specific documentation
|- src/            # Docusaurus pages and React components
|- static/         # Published shell scripts and static assets
|- docusaurus.config.js
`- package.json
```

## Good First Places to Look

- `docs/scripts/intro.md` for the published scripts
- `static/` for the actual shell script implementations
- `src/pages/tools.js` for the in-browser tools page
- `docusaurus.config.js` for site configuration

## Next Steps

- Read [Introduction](introduction.md)
- Browse [Scripts Overview](../scripts/intro.md)
- Check [How To](howto.md) for common usage patterns
