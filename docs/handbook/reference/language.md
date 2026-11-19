# Language source basis

No language parser is implemented in this checkout. Until extraction, the
authoritative source snapshot is Transit's
[application source contract](https://github.com/spoke-sh/transit/blob/c1f2680d9353175e58ad503e750e7b4da76a84c5/contracts/APPLICATION_SOURCE_V1.md)
and [independent grammar](https://github.com/spoke-sh/transit/blob/c1f2680d9353175e58ad503e750e7b4da76a84c5/contracts/application-source/TransitSource.g4).
Pin examples and comparisons to that revision rather than a moving branch.

The existing compiler includes module composition, typed values and resource
interfaces, selected build targets, embedded SQL templates, helper programs,
explicit-basis Table migration synthesis, and test-suite products. Its
[package account](https://github.com/spoke-sh/transit/blob/c1f2680d9353175e58ad503e750e7b4da76a84c5/packages/zig/transit-compiler/README.md)
states the supported subsets and exclusions. This list is an extraction inventory,
not an independent language specification or a transitc support promise.

Parsing, type checking, SQL validation, emission, and runtime execution are
different stages. A grammar production alone does not establish successful
compilation or execution. The extracted reference will need exact syntax,
visibility, type identity, supported statements, limits, and failure behavior,
backed by the moved grammar corpus and executable examples.
