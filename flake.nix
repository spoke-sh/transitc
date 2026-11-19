{
  description = "transitc compiler development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, zig-overlay, ... }:
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
          transitc = pkgs.callPackage ./nix/transitc.nix { inherit zig; };
        in
        assert pkgs.lib.assertMsg (
          zig.version == "0.17.0-dev.2267+48abf1a34"
        ) "Update the Zig manifest and review nix/zig.nix patches with the toolchain pin.";
        {
          inherit pkgs zig transitc;
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
          inherit (toolchains.${system}) pkgs zig;
          common = [
            pkgs.git
            pkgs.just
          ];
        in
        {
          default = pkgs.mkShell {
            packages = common ++ [
              zig
              pkgs.nixfmt
              pkgs.nodejs_24
            ];
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
          inherit (toolchains.${system}) pkgs zig transitc;
        in
        {
          bootstrap =
            pkgs.runCommand "transitc-bootstrap-check"
              {
                nativeBuildInputs = [
                  zig
                  transitc
                ];
              }
              ''
                cp -r ${./build.zig} build.zig
                cp -r ${./build.zig.zon} build.zig.zon
                cp -r ${./apps} apps
                export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
                zig fmt --check build.zig build.zig.zon apps
                transitc --help
                transitc --version
                touch "$out"
              '';
        }
      );

      formatter = forAllSystems (system: toolchains.${system}.pkgs.nixfmt);
    };
}
