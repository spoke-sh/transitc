import type { SidebarsConfig } from "@docusaurus/plugin-content-docs";

const sidebars: SidebarsConfig = {
  handbook: [
    {
      type: "category",
      label: "Guides",
      collapsed: false,
      items: ["guides/introduction", "guides/getting-started", "guides/source-workflow"],
    },
    {
      type: "category",
      label: "Reference",
      items: ["reference/cli", "reference/language", "reference/diagnostics", "reference/artifacts"],
    },
    { type: "category", label: "Internals", items: ["internals/architecture"] },
  ],
};

export default sidebars;
