import React, { type ComponentProps } from "react";
import MDXComponents from "@theme-original/MDXComponents";

export default {
  ...MDXComponents,
  // Narrow viewports scroll wide tables; keyboard users need the same access.
  table: (props: ComponentProps<"table">) => <table tabIndex={0} {...props} />,
};
