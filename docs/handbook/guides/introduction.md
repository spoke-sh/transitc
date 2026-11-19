---
slug: /
title: Introduction
---

# The Transit language compiler

transitc compiles typed `.transit` modules into ordinary SQL, with source mappings
and provenance. It captures source and verifies dependencies locally. Compilation,
publication of build artifacts, applying SQL and runtime execution are separate.

Start with [getting started](getting-started.md), then
[compose modules and dependencies](source-workflow.md). The [CLI reference](../reference/cli.md)
lists every supported option. [Artifacts](../reference/artifacts.md) explains
identity and migration history; [diagnostics](../reference/diagnostics.md) explains
errors. [Run application tests](testing.md) against isolated real database instances.
Applications embedding the pure API use the [embedding guide](embedding.md).

The standalone CLI supports build, check and explicit dependency fetch through
`transitc build`, and complete test-suite compilation and execution through
`transitc test`. The pure library only produces compiled test products. The CLI
runs those products through a separately pinned Transit host with fresh private
state for each case.
