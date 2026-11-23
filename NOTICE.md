# Source attribution and extraction basis

Compiler, workspace, source contracts, fixture families, independent grammar/type
comparisons and test capture helpers originate in the
[Transit repository](https://github.com/spoke-sh/transit), commit
`e7434306334e3692c6f3e123cba0d278fa412196`. The transitc repository retains its
existing LICENSE. Original source attribution is preserved here; the Transit
checkout has no root LICENSE file. File movement does not transfer protocol or
SQL authority from Transit. Shared modules are consumed from the exact pin in package manifests.

Extraction changes package wiring, executable identity and the command name.
SQL bytes, mappings and migration formats retain their v1 contracts. Expected
executable provenance differences are `compiler_revision`, `compiler_digest`
and `input_digest`. The shared-package update for offline scalar analysis also
adopts Transit's reviewed Transaction.Origin and committed Queue effect-admission
cutovers: parity requires the exact old `f311e893…` and new `ad3bc9ae…` definitions
in provenance and diagnostics, then compares every remaining field. The frozen comparison
executable remains at the extraction revision above.
Diagnostic correction commands use `transitc build` and `transitc test`.
The dependency envelope's command spelling is an explicit parity exception.
Codes, locations and all other envelope fields remain exact.
The workspace renderer fixes a borrowed-slice lifetime exposed by Debug builds:
text now borrows the caller's diagnostic envelope instead of a callee stack copy.

Formal models retain their premises. Grammar correspondence, bounded Lean laws,
compiler comparisons and runtime integration are separate evidence categories.
No previous Transit run is reported as a transitc result.

The complete build/test command integration drivers, source diagnostic inventory
and semantic mapping checks were moved from the same Transit source lineage.
Their executable owner is now transitc; upstream runtime process fixtures remain
in Transit and are imported only by integration checks from an exact Nix pin.
The neutral compiled-case contract and row/expectation types are Transit-owned
and consumed from the pinned pure package distribution.
