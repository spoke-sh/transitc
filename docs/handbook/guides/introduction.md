---
slug: /
title: Introduction
---

# The Transit language compiler

transitc will provide a standalone compiler for Transit application source.
Its source implementation in Transit composes typed `.transit` modules and emits
ordinary SQL with source mappings and provenance. Applying that SQL and executing
tests require runtime owners outside pure compilation.

This checkout currently provides a pinned development environment, a buildable
CLI with help/version, and documentation. It does not yet parse or compile
`.transit` files. The reserved packages describe the intended extraction boundaries.

Start with [getting started](getting-started.md) to build the scaffold, then read
the [CLI reference](../reference/cli.md). The
[source workflow](source-workflow.md) explains the existing compiler's stages
without presenting them as available commands in transitc.

The [language source basis](../reference/language.md),
[diagnostics](../reference/diagnostics.md), and
[artifacts](../reference/artifacts.md) identify the contracts that extraction
must preserve. [Architecture](../internals/architecture.md) explains the boundary
between compiler values and I/O adapters.
