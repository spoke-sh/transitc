import { themes } from "prism-react-renderer";
import { execFileSync } from "node:child_process";
import handbook from "./package.json";
import type { Config } from "@docusaurus/types";
import type { Options, ThemeConfig } from "@docusaurus/preset-classic";

const baseUrl = process.env.TRANSITC_DOCS_BASE_URL ?? "/transitc/";
let revision = "development";
try {
  const value = process.env.GITHUB_SHA ?? execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim();
  if (/^[0-9a-f]{40}$/.test(value)) revision = value;
} catch {
  // An exported source tree can still build documentation without Git metadata.
}
if (!/^\/(?:[A-Za-z0-9_-]+\/)*$/.test(baseUrl)) {
  throw new Error("TRANSITC_DOCS_BASE_URL must start and end with / and contain path segments only");
}

const config: Config = {
  title: "transitc",
  tagline: "The Transit language compiler",
  url: process.env.TRANSITC_DOCS_URL ?? "https://spoke-sh.github.io",
  baseUrl,
  trailingSlash: false,
  onBrokenLinks: "throw",
  onBrokenAnchors: "throw",
  markdown: {
    format: "md",
    hooks: { onBrokenMarkdownLinks: "throw", onBrokenMarkdownImages: "throw" },
  },
  presets: [
    [
      "classic",
      {
        docs: {
          path: ".",
          include: ["guides/**/*.md", "reference/**/*.md", "internals/**/*.md"],
          routeBasePath: "/",
          sidebarPath: "./sidebars.ts",
          editUrl: "https://github.com/spoke-sh/transitc/edit/main/docs/handbook/",
        },
        blog: false,
        pages: false,
        theme: { customCss: "./src/css/custom.css" },
      } satisfies Options,
    ],
  ],
  themeConfig: {
    navbar: {
      title: "transitc",
      items: [
        { to: "/", label: "Handbook", position: "left" },
        { to: "/reference/cli", label: "CLI", position: "left" },
        { to: "/internals/architecture", label: "Internals", position: "left" },
        { href: "https://github.com/spoke-sh/transitc", label: "GitHub", position: "right" },
      ],
    },
    footer: {
      style: "light",
      copyright: `transitc ${handbook.version} · ${revision === "development" ? revision : `<a href="https://github.com/spoke-sh/transitc/tree/${revision}">Source ${revision.slice(0, 12)}</a>`}`,
    },
    colorMode: { respectPrefersColorScheme: true },
    tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 },
    prism: {
      theme: {
        plain: { color: "#282b29", backgroundColor: "#f7f4ed" },
        styles: [
          { types: ["comment", "prolog", "doctype", "cdata"], style: { color: "#586069" } },
          { types: ["keyword", "operator", "boolean", "number"], style: { color: "#783a93" } },
          { types: ["string", "char", "attr-value"], style: { color: "#9c1a4b" } },
          { types: ["function", "class-name", "builtin"], style: { color: "#125e79" } },
          { types: ["variable", "parameter", "property"], style: { color: "#166765" } },
        ],
      },
      darkTheme: {
        ...themes.dracula,
        styles: [...themes.dracula.styles, {
          types: ["comment", "prolog", "doctype", "cdata"],
          style: { color: "#adb5ce" },
        }],
      },
      additionalLanguages: ["bash", "json", "sql", "zig", "nix"],
    },
  } satisfies ThemeConfig,
};

export default config;
