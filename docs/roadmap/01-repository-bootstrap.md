# 1. Repository bootstrap

Status: Completed

Prerequisites: none.

## Scope

Create `apps/transitc-cli` and direct `packages/*` destinations, pin the source
toolchain, establish a runnable CLI scaffold, and adapt the handbook/roadmap
structure. Keep the source repository unchanged and avoid pulling compiler or
runtime implementation into the bootstrap.

## Acceptance

- The flake carries Transit's reviewed Zig and Nix pins and Linux loader support.
- The scaffold builds from this checkout alone; help/version describe its limits,
  and unavailable commands fail.
- Package READMEs map proposed responsibilities to source files and name unresolved
  dependencies without presenting empty libraries as implemented APIs.
- A locked Docusaurus project publishes guides/reference/internals, with roadmap
  and tooling sources excluded. Both root and project-prefix builds validate links.
- CI runs the bootstrap and docs checks without publishing a site.
- Contributor setup and extraction sequencing are documented.

## Validation

Executed on 2026-11-18 on x86_64 Linux, with the pinned Zig compiler and Node 24:

| Check | Result |
| --- | --- |
| `nix develop --command just check` | Passed Zig/Nix formatting and CLI compilation |
| `nix build .#checks.x86_64-linux.bootstrap --no-link --print-build-logs` | Passed sandboxed build, help/version, and rejection of an unavailable command |
| `nix flake check --print-build-logs` | Passed host checks; other systems were not executed |
| `nix develop .#docs --command just docs-install` | Passed locked installation; audit reported zero vulnerabilities after documented transitive overrides |
| `nix develop .#docs --command just docs-check` | Passed strict types and production build at `/transitc/` |
| `TRANSITC_DOCS_BASE_URL=/ npm run docs:build` in the docs shell | Passed root-path production build |
| Browser smoke with local Chromium/Playwright | Root production preview and prefixed development server loaded, CLI navigation worked, mobile navigation opened, and no page errors occurred in light/dark contexts |
| Local Markdown file links, `actionlint`, and `git diff HEAD --check` | Passed |

The browser smoke used locally available browser tooling, not a repository-owned
browser suite or a live deployment. ARM/Darwin execution and comprehensive
accessibility checks remain unverified. These results qualify repository
preparation only, not language compilation or runtime compatibility.
