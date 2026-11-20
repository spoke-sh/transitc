# Handbook tooling

This Docusaurus project follows Transit's `guides/`, `reference/`, and `internals/`
structure, strict TypeScript configuration, CommonMark rendering, and broken-link
gates. It reuses the pinned Docusaurus/React versions and handbook palette.
Roadmap files and tooling READMEs stay repository-only.

From the repository root:

```sh
nix develop .#docs
just docs::install
just docs::dev
```

The development URL is `http://localhost:3000/transitc/`. `just docs::check`
typechecks configuration/navigation and builds into `docs/handbook/dist`.
`npm run docs:serve` previews that output. The root npm workspace/lockfile is
independent of Transit's Vite+, Board, generated APIs, and SDK catalog.

The root manifest pins patched transitive versions of `tinypool`,
`serialize-javascript`, and SockJS's `uuid` dependency because the inherited
Docusaurus ranges select versions flagged by `npm audit`. Keep these overrides
until upstream ranges include the fixes; validate both production builds and the
development server when updating them. See the upstream
[Tinypool advisory](https://github.com/tinylibs/tinypool/security/advisories/GHSA-85c8-ppgw-ccpr),
[serialization advisory](https://github.com/yahoo/serialize-javascript/security/advisories/GHSA-m5mm-p8h7-m29v),
and [UUID advisory](https://github.com/advisories/GHSA-w5hq-g745-h8pq).

## Content and navigation

The docs plugin reads the owning Markdown files directly. `sidebars.ts` lists all
published pages. The introduction has the root route; other routes follow their
file paths. Keep Markdown links relative between included pages. Link to GitHub
for files outside the published tree. Do not copy package documentation into a
second maintained location.

Guides must distinguish commands supported here from behavior inspected in
Transit. No compiler syntax tutorial is complete until its examples execute with
the extracted compiler. Search, generated contract pages, and release downloads
are future documentation work; the bootstrap supplies navigation only.

## Hosting configuration

`TRANSITC_DOCS_URL` defaults to `https://spoke-sh.github.io` and
`TRANSITC_DOCS_BASE_URL` to `/transitc/`. These are build settings, not a claim
that a website has been published. To validate a root deployment:

```sh
TRANSITC_DOCS_BASE_URL=/ npm run docs:build
```

Both builds reject broken page links, Markdown links/images, and anchors. CI
runs both path configurations. No deployment workflow is configured. Before
publishing, inspect navigation, code blocks, mobile layout, and light/dark themes
at the chosen path. Docusaurus's
[docs plugin options](https://docusaurus.io/docs/api/plugins/@docusaurus/plugin-content-docs)
and [site configuration](https://docusaurus.io/docs/api/docusaurus-config) describe
the underlying routing controls.
