# Compile a first application

Use a checkout of transitc with Nix and Git installed. From the repository root,
follow the [development/install commands](https://github.com/spoke-sh/transitc/blob/main/CONTRIBUTING.md)
to build `zig-out/bin/transitc`, or build the Nix package. No sibling checkout or
running Transit service is needed. The pinned compiler is Zig
`0.17.0-dev.2267+48abf1a34`; consumers of the executable need no Zig installation.

Put the executable on your PATH and run `transitc --version`. Create an empty
working directory containing this `build.transit`:

```sql
CREATE TARGET default AS BEGIN
  CREATE PUBLIC TABLE items (id BIGINT PRIMARY KEY, label TEXT);
  INSERT INTO items VALUES (7, 'ready');
  SELECT * FROM items;
END;
```

Check the complete source without publishing:

```sh
transitc build --check --format json
```

The JSON report has `ok: true`, `action: "check"` and `statements: 3`. It includes
SQL and input digests; their exact values depend on the source and compiler.
Build into a new directory:

```sh
transitc build --out reviewed
```

Inspect `reviewed/application.sql` and `reviewed/provenance.json`. SQL statements
remain ordered and executable through ordinary Transit SQL owners. This command
has not applied them. See [artifacts](../reference/artifacts.md) before migration
or deployment. An existing explicit output directory refuses publication; choose
a new directory. Without `--out`, intact content-addressed artifacts can be reused.

If the entry is missing, create `build.transit` or select another file with
`-f FILE`. A syntax error returns status 1 and a bounded source diagnostic; fix the
reported source before rebuilding. Unknown options return status 2.

The flake defines x86_64/aarch64 Linux and Darwin packages. Executed extraction
evidence currently identifies its host separately; a package definition alone
is not a successful native-host qualification. There are no signed standalone
release archives or updater yet. Pin the Git revision when consuming the flake.
