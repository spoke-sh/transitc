# Toolchain

`flake.nix` and `flake.lock` use Transit's nixpkgs and zig-overlay pins at
`c1f2680d9353175e58ad503e750e7b4da76a84c5`. Those toolchain locks are unchanged.
The upstream `transit` input is pinned separately to
`e7434306334e3692c6f3e123cba0d278fa412196`; its toolchain locks and the support
files below are unchanged from the original basis.
`zig.nix`, `zig-dynamic-linker.patch`, and `verify-zig-download.sh` were copied
from the original basis. The inherited derivation name `transit-zig` identifies
the same toolchain; it is not a runtime dependency.

On Linux the wrapper chooses the matching Nix ELF loader for native builds.
The patch preserves loader arguments across build-step and dependency lifetimes.
Explicit cross targets retain upstream behavior. Archive verification retries
pinned mirrors without accepting a different content hash. Darwin uses the
locked overlay compiler directly.

The default shell includes Zig, docs tooling, Python, and
`transit.packages.<system>.transit` from the pinned upstream flake. Upstream's
nixpkgs and zig-overlay inputs follow this repository's pins. The shell exports
`TRANSIT_UPSTREAM_BIN` as the absolute store executable and
`TRANSIT_UPSTREAM_REVISION` as the input revision, so integration tests cannot
silently select another `transit` from PATH.

`.#docs` omits Transit, Python, Zig, and the C toolchain. Both shells are defined
for x86_64/aarch64 Linux and Darwin; local validation establishes only the host
platform's result. A first default-shell invocation may build the upstream runtime
and its frontend assets if they are not cached.

`transitc.nix` builds the CLI artifact with that same toolchain. The default
package and `transitc` package expose only the installed executable, so consumers
can use it in `mkShellNoCC` without inheriting the compiler development shell.
Installation checks exercise help, the bootstrap version, and rejection of an
unsupported command; the flake's bootstrap check also checks Zig formatting.
The separate `checks.<system>.integration` runs the same Python suite as
`just test-integration` against the pinned upstream package in the Nix sandbox.
It has no dependency on a sibling checkout, downloads, or a running Transit service.
See [integration checks](../tests/integration/README.md) for coverage and pin updates.

When changing Zig, update the lock, version assertion in `flake.nix`, assertion
in `zig.nix`, and `build.zig.zon` together. Review the patch against the new
compiler sources and execute `nix flake check`. Do not track moving `master`
without the reviewed lockfile. The upstream Transit executable is an integration
dependency; Kubernetes and external database/SDK tooling are not required.
