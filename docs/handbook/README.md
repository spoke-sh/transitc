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
the extracted compiler. `just test::documentation` checks reader-task coverage,
CLI options and automation/dependency examples; `just test::examples` checks exact
source and runtime outcomes. Search and generated contract pages remain future
work; the sidebar and references cover the current handbook's fourteen pages.

Run `nix develop .#docs-browser --command just docs::browser` on Linux to exercise
all pages with Chromium, keyboard controls, mobile/desktop viewports and both
themes. Prefix/root results are separate in `.cache/handbook-report-*` and
`.cache/handbook-browser-*`; CI retains reports, screenshots and failure traces.
Prism's light/dark palettes and focusable tables are checked for accessible
contrast and keyboard scrolling. Keep Playwright and `playwright-core` aligned
through the root override so the accessibility adapter uses the same browser API.

## Hosting configuration

`TRANSITC_DOCS_URL` defaults to `https://spoke-sh.github.io` and
`TRANSITC_DOCS_BASE_URL` to `/transitc/`, the GitHub Pages publication path.
To validate a root deployment:

```sh
TRANSITC_DOCS_BASE_URL=/ just docs::build
```

Both builds reject broken page links, Markdown links/images, and anchors.
[CI](../../.github/workflows/ci.yml) runs both path configurations. Inspect
navigation, code blocks, mobile layout, and light/dark themes when changing the
site. Docusaurus's
[docs plugin options](https://docusaurus.io/docs/api/plugins/@docusaurus/plugin-content-docs)
and [site configuration](https://docusaurus.io/docs/api/docusaurus-config) describe
the underlying routing controls.

## GitHub Pages publication

[Publish handbook](../../.github/workflows/handbook.yml) follows Transit's
publication workflow. It builds pull requests, every push to `main`, and manual
runs using the pinned Nix docs shell, `just docs::install`, and `just docs::check`.
Only `docs/handbook/dist/` is uploaded as the `github-pages` artifact, retained for
14 days. Local build and preview commands do not deploy.

Only the current `main` revision can deploy. Deployments use the `github-pages`
environment and run one at a time; superseded builds and old reruns are skipped
after checking the latest `main` commit. The deploy job alone receives
`pages: write` and `id-token: write`. Pull requests build with read-only repository
permissions. Failed builds leave the previous site in place.

In repository **Settings → Pages → Build and deployment**, set **Source** to
**GitHub Actions**, and restrict the `github-pages` environment to the `main`
branch. The publication URL is [the handbook](https://spoke-sh.github.io/transitc/).
The workflow records the deployed commit and URL and checks the public homepage,
getting-started guide, CLI reference, and architecture page over HTTPS.

To republish current `main`, select **Actions → Publish handbook → Run workflow**
with branch `main`, or run `gh workflow run handbook.yml --ref main`. To roll back,
revert the content change and push the new revision to `main`; rerunning an older
commit will not replace the current site.
