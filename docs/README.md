# Documentation

The [handbook](handbook/guides/introduction.md) describes this repository's current
behavior and the compiler's source basis. The [roadmap](roadmap/README.md) owns
planned extraction work, decisions, status, and acceptance criteria.

| Location | Owner |
| --- | --- |
| `handbook/guides/` | Task-oriented user and contributor workflows |
| `handbook/reference/` | Current CLI, language source basis, diagnostics, and artifacts |
| `handbook/internals/` | Architecture, invariants, and implementation reasoning |
| `roadmap/` | Numbered delivery milestones and documentation coverage gates |
| App/package READMEs | Component scope, usage, and extraction destination |
| Future `contracts/`, `tests/`, `examples/` | Exact contracts, executable evidence, and runnable examples, added with extraction |

This adopts Transit's documentation ownership structure, with a smaller
Docusaurus project in `handbook/`. It does not copy unrelated database/runtime
guides or mark Transit's roadmap as completed here. Read the
[site guide](handbook/README.md) to develop the docs and the
[documentation coverage plan](roadmap/04-documentation-and-qualification.md) for
the user guides needed before a standalone compiler release.
