# Diagnostics

Use `transitc build --format json` in automation. Compilation and input/output
failures produce a current-v1 diagnostic envelope with a stable source failure
family, stage, cause and bounded facts. Local failures remain `not_submitted` with
`local_before_dispatch` evidence. No compilation failure implies SQL execution.

Human reports identify the target, failed stage, source location and correction.
Source coordinates refer to captured bytes; expansion diagnostics retain definition
and call locations. Filesystem errors carry escaped path facts without invented
line numbers. Terminal controls and invalid bytes are rendered inert. Error
values do not include arbitrary operand payloads or unknown argument values.

Use `--color off` for plain logs. Automatic color respects the terminal,
`NO_COLOR` and `TERM=dumb`. JSON output has no terminal styling. Paths and spans
have explicit bounds; truncation is marked.

| Failure | Correction |
| --- | --- |
| Missing entry/import | Create the declared file or correct `-f` / import |
| Unknown target or name | Select an exported declaration with its exact interface |
| Type/schema/reference error | Correct the operand or binding; reference exports cannot grant more access |
| Missing/mismatched lock/cache | Review pins and explicitly fetch their exact content |
| Existing/corrupted output | Preserve evidence and select a new explicit output directory |
| Budget limit | Reduce source/work/output within the documented profile |

The shared envelope belongs to Transit's protocol package. Source-specific codes
and context belong to `transitc-compiler/SourceDiagnostic`; human rendering belongs
to the workspace package. See the
[contract](https://github.com/spoke-sh/transitc/blob/main/contracts/APPLICATION_SOURCE_V1.md#cli-and-diagnostics)
for exact code and coordinate rules.
