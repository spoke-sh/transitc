# Toolchain

`flake.nix` and `flake.lock` use Transit's nixpkgs and zig-overlay pins at
`c1f2680d9353175e58ad503e750e7b4da76a84c5`. Those toolchain locks are unchanged.
The `transit-baseline` input remains frozen at
`e7434306334e3692c6f3e123cba0d278fa412196` for comparison. The `transit` input
pins the compatible compiled-case test host at `5d13883116f5d9b8ef748625b47108a7ef9b3212`. Transit is upstream and does not
import this compiler or workspace.
`zig.nix`, `zig-dynamic-linker.patch`, and `verify-zig-download.sh` were copied
from the original basis. The inherited derivation name `transit-zig` identifies
the same toolchain; it is not a runtime dependency.

On Linux the wrapper chooses the matching Nix ELF loader for native builds.
The patch preserves loader arguments across build-step and dependency lifetimes.
Explicit cross targets retain upstream behavior. Archive verification retries
pinned mirrors without accepting a different content hash. Darwin uses the
locked overlay compiler directly.

The default shell includes Zig, docs tooling, Python, and
the current test-host executable on PATH. The frozen comparison binary is
available only through `TRANSIT_UPSTREAM_BIN`. Both inputs'
nixpkgs and zig-overlay inputs follow this repository's pins. The shell exports
`TRANSIT_UPSTREAM_BIN` as the absolute store executable and
`TRANSIT_UPSTREAM_REVISION` as the input revision, so integration tests cannot
silently select another `transit` from PATH. `TRANSIT_TEST_RUNTIME` selects the
compatible compiled-case host; `TRANSIT_TEST_SOURCE` supplies upstream process/installation helpers. SQL grammar verification uses the frozen baseline.

`.#docs` omits Transit, Python, Zig, and the C toolchain. `.#toolchain` supplies
only Zig, Just, Python and nixfmt (plus the native C environment); `.#docs-browser`
adds Nix Chromium to the documentation tools for local Linux browser checks.
Git comes from the host and is not added to any development shell.
Compiler and documentation shells are defined
for x86_64/aarch64 Linux and Darwin; local validation establishes only the host
platform's result. A first default-shell invocation may build the upstream runtime
and its frontend assets if they are not cached.

`transitc.nix` builds the CLI artifact with that same toolchain. The default
package and `transitc` package expose only the installed executable, so consumers
can use it in `mkShellNoCC` without inheriting the compiler development shell.
Installation checks exercise help/version, actual source checking and rejection
of unknown commands, plus a real isolated application suite. Package checks run
compiler/workspace tests;
flake checks add exact upstream parity and independent grammar/type verification.
The standalone shared frontend is pinned separately from the upstream runtime
fixture. Compiler clients consume the same pinned upstream modules.
The separate `checks.<system>.integration` runs the seven-case baseline from
`just test::integration` against the frozen upstream package in the Nix sandbox.
It has no dependency on a sibling checkout, downloads, or a running Transit service.
See [integration checks](../tests/integration/README.md) for coverage and pin updates.

When changing Zig, update the lock, version assertion in `flake.nix`, assertion
in `zig.nix`, and `build.zig.zon` together. Review the patch against the new
compiler sources and execute `nix flake check`. Do not track moving `master`
without the reviewed lockfile. The comparison executable is an integration
dependency. The packaged CLI retains
the compatible test host in its runtime closure, while Zig remains build-only.
Kubernetes and external database/SDK tooling are not required for local tests.
