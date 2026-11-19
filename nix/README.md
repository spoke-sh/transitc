# Toolchain

`flake.nix` and `flake.lock` use Transit's nixpkgs and zig-overlay pins at
`c1f2680d9353175e58ad503e750e7b4da76a84c5`. The lockfile is copied unchanged.
`zig.nix`, `zig-dynamic-linker.patch`, and `verify-zig-download.sh` are copied
from that revision as well. The inherited derivation name `transit-zig` identifies
the same toolchain; it is not a runtime dependency.

On Linux the wrapper chooses the matching Nix ELF loader for native builds.
The patch preserves loader arguments across build-step and dependency lifetimes.
Explicit cross targets retain upstream behavior. Archive verification retries
pinned mirrors without accepting a different content hash. Darwin uses the
locked overlay compiler directly.

The default shell includes Zig and docs tooling. `.#docs` omits Zig and the C
toolchain. Both support x86_64/aarch64 Linux and Darwin in the flake; local
validation only establishes the host platform's result.

When changing Zig, update the lock, version assertion in `flake.nix`, assertion
in `zig.nix`, and `build.zig.zon` together. Review the patch against the new
compiler sources and execute `nix flake check`. Do not track moving `master`
without the reviewed lockfile. Runtime, Kubernetes, database, and SDK development
tools from Transit are unnecessary for this bootstrap.
