# awsutils

`awsutils` is a Docusaurus site that publishes lightweight AWS helper scripts, documentation, and a small browser-based transform toolbox.

## What Is In This Repo

- `docs/` for documentation content
- `static/` for published shell scripts and static assets
- `src/` for the Docusaurus site and custom React pages

Scripts placed in `static/` are served directly from `https://awsutils.github.io/<script>.sh`.

## Local Development

```bash
npm install
npm start
```

Other useful commands:

```bash
npm run build
npm run serve
```

## Contributing

Contributions are welcome, especially for:

- new scripts in `static/`
- matching documentation in `docs/scripts/`
- improvements to the docs site or `/tools` page

When adding or changing a script, keep its documentation in sync.

## License

This project is licensed under the MIT-0 License. See `LICENSE`.
