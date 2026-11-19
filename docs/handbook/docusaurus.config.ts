import type { Config } from "@docusaurus/types";
import type { Options, ThemeConfig } from "@docusaurus/preset-classic";

const baseUrl = process.env.TRANSITC_DOCS_BASE_URL ?? "/transitc/";
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
    footer: { style: "light", copyright: "transitc · The Transit language compiler" },
    colorMode: { respectPrefersColorScheme: true },
    tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 },
    prism: { additionalLanguages: ["bash", "json", "sql", "zig", "nix"] },
  } satisfies ThemeConfig,
};

export default config;
