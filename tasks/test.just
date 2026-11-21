set working-directory := ".."

[default]
_default:
    @just --list test

# Run compiler/workspace unit tests, including allocation failures.
unit:
    zig build test

# Build a source copy with empty dependency and compiler caches (requires host Git).
clean-build:
    python3 -B tests/clean_build.py

# Check source formatting, comment preservation, and atomic file updates.
fmt: _build
    python3 -B tests/integration/format_command.py zig-out/bin/transitc

# Check dependency resolution, publication, and workspace failures.
workspace: _build
    python3 -B tests/runner/launch.py tests/workspace/build.py zig-out/bin/transitc

# Compile and execute the handbook examples.
examples: _build
    python3 -B tests/examples.py zig-out/bin/transitc

# Check documentation coverage, CLI parity and automation/dependency examples.
documentation: _build
    python3 -B tests/documentation.py zig-out/bin/transitc

# Check release promotion identity and corruption refusals.
release:
    python3 -B tests/release.py

# Exercise transitc build and its application/migration fixtures.
build-command: _build
    python3 -B tests/runner/launch.py tests/integration/build_command.py zig-out/bin/transitc

# Exercise transitc test and the compiled-case host boundary.
command: _build
    python3 -B tests/runner/launch.py tests/integration/test_host_boundary.py zig-out/bin/transitc
    python3 -B tests/runner/launch.py tests/integration/test_command.py zig-out/bin/transitc

# Verify independent source grammar and formatting correspondence.
grammar: _source-probe
    python3 -B tests/runner/launch.py tests/query/application_source/verify.py zig-out/bin/transitc-source-probe

# Verify bounded typed/program correspondence.
types: _source-probe
    python3 -B tests/runner/launch.py tests/query/application_source/types.py zig-out/bin/transitc-source-probe

# Check upstream smoke tests, compiler parity, and emitted SQL execution.
integration: _build
    python3 -B tests/integration/upstream_transit.py
    python3 -B tests/integration/parity.py
    python3 -B tests/integration/execute_sql.py
    python3 -B tests/runner/launch.py tests/integration/typed_composition.py zig-out/bin/transitc
    python3 -B tests/runner/launch.py tests/integration/scalar_surfaces.py zig-out/bin/transitc
    python3 -B tests/runner/launch.py tests/integration/cardinality.py zig-out/bin/transitc
    python3 -B tests/runner/launch.py tests/integration/sql_scalars.py zig-out/bin/transitc
    python3 -B tests/runner/launch.py tests/integration/refinements.py zig-out/bin/transitc
    python3 -B tests/runner/launch.py tests/integration/callables.py zig-out/bin/transitc

# Share the root build recipe and run it once per invocation of these suites.
_build:
    @just build

_source-probe:
    zig build source-probe
