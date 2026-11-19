default:
    @just --list

build:
    zig build

check:
    zig fmt --check build.zig build.zig.zon apps
    zig build check
    nixfmt --check flake.nix nix/*.nix

test-integration:
    python3 -B tests/integration/upstream_transit.py

docs-install:
    npm ci

docs-dev:
    npm run docs:dev

docs-build:
    npm run docs:build

docs-check:
    npm run docs:check
