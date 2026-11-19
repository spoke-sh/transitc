default:
    @just --list

build:
    zig build

check:
    zig fmt --check build.zig build.zig.zon apps packages examples tests/query/application_source/driver.zig
    python3 -B tests/dependencies/check.py
    zig build check
    nixfmt --check flake.nix nix/*.nix

test:
    zig build test

test-workspace: build
    python3 -B tests/runner/launch.py tests/workspace/build.py zig-out/bin/transitc

test-examples: build
    python3 -B tests/examples.py zig-out/bin/transitc

test-grammar:
    zig build source-probe
    python3 -B tests/runner/launch.py tests/query/application_source/verify.py zig-out/bin/transitc-source-probe

test-types:
    zig build source-probe
    python3 -B tests/runner/launch.py tests/query/application_source/types.py zig-out/bin/transitc-source-probe

test-integration: build
    python3 -B tests/integration/upstream_transit.py
    python3 -B tests/integration/parity.py
    python3 -B tests/integration/execute_sql.py

docs-install:
    npm ci

docs-dev:
    npm run docs:dev

docs-build:
    npm run docs:build

docs-check:
    npm run docs:check
