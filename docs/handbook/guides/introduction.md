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
errors. Applications embedding the pure API use the [embedding guide](embedding.md).

The standalone CLI supports build, check and explicit dependency fetch through
`transitc build`. Runtime test hosting remains in Transit. The library can compile
test products; it does not execute them. There is no `transitc test` command.
