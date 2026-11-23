{
  description = "transitc compiler development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    transit = {
      url = "github:spoke-sh/transit/73ae483f9073c30b89b3ec90dc67595467a60f44";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zig-overlay.follows = "zig-overlay";
    };
    transit-baseline = {
      url = "github:spoke-sh/transit/e7434306334e3692c6f3e123cba0d278fa412196";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zig-overlay.follows = "zig-overlay";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zig-overlay,
      transit,
      transit-baseline,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      toolchains = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          zig = pkgs.callPackage ./nix/zig.nix {
            upstream = zig-overlay.packages.${system}.master;
          };
          transitc = pkgs.callPackage ./nix/transitc.nix {
            inherit zig testRuntime;
            sourceRevision = self.rev or self.dirtyRev or "development";
          };
          upstreamTransit = transit-baseline.packages.${system}.transit;
          testRuntime = transit.packages.${system}.transit;
        in
        assert pkgs.lib.assertMsg (
          zig.version == "0.17.0-dev.2267+48abf1a34"
        ) "Update the Zig manifest and review nix/zig.nix patches with the toolchain pin.";
        {
          inherit
            pkgs
            zig
            transitc
            upstreamTransit
            testRuntime
            ;
        }
      );
    in
    {
      packages = forAllSystems (system: {
        inherit (toolchains.${system}) transitc;
        default = toolchains.${system}.transitc;
      });

      devShells = forAllSystems (
        system:
        let
          inherit (toolchains.${system})
            pkgs
            zig
            upstreamTransit
            testRuntime
            ;
          common = [ pkgs.just ];
        in
        {
          toolchain = pkgs.mkShell {
            packages = common ++ [
              zig
              pkgs.python3
              pkgs.nixfmt
            ];
            buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.libc ];
          };
          docs-browser = pkgs.mkShellNoCC {
            packages = common ++ [
              pkgs.nodejs_24
              pkgs.chromium
            ];
            CHROMIUM_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
          };
          default = pkgs.mkShell {
            packages = common ++ [
              zig
              pkgs.nixfmt
              pkgs.nodejs_24
              (pkgs.python3.withPackages (ps: [ ps.antlr4-python3-runtime ]))
              pkgs.antlr4
              pkgs.lean4
              testRuntime
            ];
            TRANSIT_UPSTREAM_BIN = "${upstreamTransit}/bin/transit";
            TRANSIT_UPSTREAM_REVISION = transit-baseline.rev;
            TRANSIT_UPSTREAM_SOURCE = "${transit-baseline}";
            TRANSIT_TEST_RUNTIME = "${testRuntime}/bin/transit";
            TRANSIT_TEST_SOURCE = "${transit}";
            TRANSIT_SQL_GRAMMAR_DIR = "${transit-baseline}/contracts/sql";
            buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.libc ];
          };
          docs = pkgs.mkShellNoCC {
            packages = common ++ [ pkgs.nodejs_24 ];
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          inherit (toolchains.${system})
            pkgs
            zig
            transitc
            upstreamTransit
            testRuntime
            ;
        in
        {
          integration =
            pkgs.runCommand "transitc-upstream-integration"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                python3 -B ${./tests/integration/upstream_transit.py} \
                  --transit ${upstreamTransit}/bin/transit \
                  --expected-revision ${transit-baseline.rev} \
                  --fixtures ${./tests/integration/fixtures}
                touch "$out"
              '';
          compiler = transitc;
          parity = pkgs.runCommand "transitc-parity" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            cp -r ${./tests} tests
            chmod -R u+w tests
            python3 -B tests/integration/parity.py --transit ${upstreamTransit}/bin/transit --transitc ${transitc}/bin/transitc
            touch "$out"
          '';
          source =
            pkgs.runCommand "transitc-source-verification"
              {
                nativeBuildInputs = [
                  zig
                  pkgs.git
                  pkgs.antlr4
                  pkgs.lean4
                  (pkgs.python3.withPackages (ps: [ ps.antlr4-python3-runtime ]))
                ];
              }
              ''
                cp -r ${self} source
                chmod -R u+w source
                cd source
                export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
                export ZIG_LOCAL_PKG_DIR="zig-pkg"
                export TRANSIT_SQL_GRAMMAR_DIR="${transit-baseline}/contracts/sql"
                mkdir -p "$ZIG_LOCAL_PKG_DIR"
                cp -r ${transitc.dependencies}/. "$ZIG_LOCAL_PKG_DIR/"
                chmod -R u+w "$ZIG_LOCAL_PKG_DIR"
                zig fmt --check build.zig build.zig.zon apps packages examples tests/query/application_source/driver.zig
                python3 -B tests/dependencies/check.py
                zig build source-probe -Doptimize=ReleaseSafe
                python3 -B tests/runner/launch.py tests/query/application_source/verify.py zig-out/bin/transitc-source-probe
                python3 -B tests/runner/launch.py tests/query/application_source/types.py zig-out/bin/transitc-source-probe
                mkdir -p "$out"
                cp -r .cache/verification/. "$out/"
                printf '%s\n' '${self.rev or self.dirtyRev or "development"}' > "$out/source-revision"
              '';
        }
      );

      formatter = forAllSystems (system: toolchains.${system}.pkgs.nixfmt);
    };
}
