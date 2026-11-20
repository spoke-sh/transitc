# Install, preview, and validate the handbook.
mod docs 'tasks/docs.just'

# Run compiler, workspace, and upstream integration suites.
mod test 'tasks/test.just'

[default]
_default:
    @just --list

# Build transitc with the selected Transit test host.
build:
    zig build "-Dtest-runtime=${TRANSIT_TEST_RUNTIME:-transit}"

# Check formatting, dependency ownership, and compilation.
check:
    zig fmt --check build.zig build.zig.zon apps packages examples tests/query/application_source/driver.zig
    python3 -B tests/dependencies/check.py
    python3 -B tests/runner/launch.py tests/dependencies/diagnostic_inventory.py
    python3 -B tests/runner/launch.py tests/dependencies/diagnostic_mappings.py
    zig build check
    nixfmt --check flake.nix nix/*.nix
