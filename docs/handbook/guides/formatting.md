# Formatting source

Run `transitc fmt` in your project to format its `.transit` files in place.
Like `go fmt`, it uses one style without configuration and prints only paths
whose contents changed. A second run is silent.

```sh
transitc fmt
transitc fmt build.transit modules/ tests/
```

Directories are searched recursively. Overlapping paths are deduplicated and
files are processed in sorted path order. Discovery skips hidden files and
directories, `node_modules`, `zig-out`, `zig-pkg`, and symbolic links. You can
name a hidden file or directory explicitly. Use `--` before paths beginning
with a dash, for example `transitc fmt -- -example.transit`.

The style uses uppercase keywords, two spaces per block level, a statement per
line, consistent punctuation spacing, and a final newline for nonempty source.
Existing blank lines between statements are reduced to at most one.
Identifier spelling, quoted names, string and numeric literals, comments, and
expression parentheses are preserved. Statements and declarations stay in their
original order. Expressions and parameter lists stay compact; the formatter
does not wrap them to a configurable line width.

For example:

```sql
create target default as begin create public table items(id bigint,label text);select * from items;end;
```

becomes:

```sql
CREATE TARGET default AS BEGIN
  CREATE PUBLIC TABLE items (id BIGINT, label TEXT);
  SELECT * FROM items;
END;
```

Comments keep their text and order. Standalone comments remain on their own
lines; trailing comments remain beside the preceding statement. Whitespace
inside comments and literals is retained, including embedded newlines.

## Check formatting in CI

```sh
transitc fmt --check
```

Check mode prints paths needing formatting to stdout and exits with status 1
when any differ. It never writes files. Status 0 means every selected file is
already formatted; status 1 also covers syntax or filesystem failures, reported
on stderr. Invalid command options exit with status 2.

Formatting validates syntax with the production parser. It does not resolve
imports, fetch dependencies, require a lockfile, start Transit, or execute SQL.
Follow formatting with `transitc build --check` and `transitc test` to validate
types and behavior.

## Use from an editor

```sh
transitc fmt --stdin < build.transit
```

`--stdin` reads one source buffer and writes formatted source to stdout. On
invalid input it writes no source output. It cannot be combined with paths or
`--check`. Editors should replace their buffer only after exit status 0.

## File updates and limits

Each changed file is replaced atomically after formatting and reparsing succeed.
Ordinary permission bits are preserved; unchanged files keep their modification times.
A syntax error leaves that file untouched while other selected files continue
to be processed. This is a per-file operation, not a transaction over a tree.
Formatting changes source digests and locations; rebuild artifacts afterward.

Explicit symbolic links, paths through symbolic-link directories, and special
files reject. Changed files with multiple hard links or no write permission bits
also reject. Avoid editing a file concurrently with formatting: edits detected
before replacement cause a failure, but the formatter does not lock editors out.
Atomic replacement creates a new inode; extended attributes and other filesystem
metadata beyond permission bits are not copied.

The source and formatted result each have a 1 MiB limit. A command accepts up to
256 explicit paths, discovers at most 4,096 source files and 16,384 directory
entries, and bounds traversal depth at 64 and tooling allocations at 256 MiB.
