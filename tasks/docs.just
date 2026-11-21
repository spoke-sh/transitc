set working-directory := ".."

[default]
_default:
    @just --list docs

# Install the handbook's locked dependencies.
install:
    npm ci

# Start the handbook development server.
dev:
    npm run docs:dev

# Build the production handbook.
build:
    npm run docs:build

# Typecheck and build the handbook.
check:
    npm run docs:check

# Check the built site in Chromium; use the docs-browser Nix shell locally.
browser: build
    npm run browser --workspace @transitc/handbook
