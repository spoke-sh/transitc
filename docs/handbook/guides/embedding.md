# Embed the compiler

Use the pinned Zig toolchain and add transitc at an exact Git revision/content
hash to your package manifest. The root build exports `transitc_compiler` and
`transitc_workspace`. Both consume the same pinned upstream shared modules.
Use the compiler package's direct protocol module for diagnostic types; avoid
constructing a second copy of shared Zig modules. This API is for applications
that compile source. Transit remains an upstream dependency and does not embed it.

The library call is:

```zig
var diagnostic: ?protocol.Diagnostic = null;
const product = try compiler.compile(allocator, sources, .{
    .compiler_revision = "your-exact-build-revision",
}, &diagnostic);
defer product.deinit();
```

Each source has `package` (default `root`), `path` and `text`. Capture files before
calling the compiler. On success, the product owns SQL, maps, digests and compiled
test cases independently of input lifetime. On error there is no product; inspect
the bounded diagnostic. Provide a `SourceDiagnostic.Report` for richer context.
Never retain pointers into freed products or a temporary diagnostic copy.

Use `.mode = .test_suite` to compile a declared test target. This returns test
products without executing SQL. `CatalogDiff` likewise synthesizes migration
proposals from explicit supplied history. Neither API opens a service or grants
rights. Workspace APIs add I/O explicitly and are unnecessary for in-memory use.

The repository's compiler unit tests exercise allocation failures and independent
product ownership. The private grammar probe consumes this same public API and
projects types/products for independent comparisons; it is not an alternate parser.
