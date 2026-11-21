//! Offline command help. Detailed workflows belong in the handbook.

pub const root =
    \\transitc
    \\
    \\Usage: transitc COMMAND [OPTIONS]
    \\
    \\Commands:
    \\  build  Compile Transit source to SQL
    \\  fmt    Format Transit source
    \\  test   Run application tests
    \\
    \\Options:
    \\  --help     Show this help
    \\  --version  Show version
    \\
    \\Run transitc COMMAND --help for command options.
    \\
;

pub const fmt =
    \\Format Transit source in place.
    \\
    \\Usage: transitc fmt [OPTIONS] [PATH...]
    \\
    \\Paths default to the current directory. Directories are searched recursively.
    \\
    \\Options:
    \\  --check  List unformatted files without writing them
    \\  --stdin  Format standard input to standard output
    \\  --help   Show this help
    \\
;

pub const build =
    \\Compile Transit source to SQL.
    \\
    \\Usage: transitc build [OPTIONS]
    \\
    \\Options:
    \\  -f FILE              Entry file (default: build.transit)
    \\  --target NAME        Target (default: entry default or 'default')
    \\  --out DIRECTORY      Publish artifacts to a new directory
    \\  --check              Validate without publishing artifacts
    \\  --fetch              Fetch dependencies and write transit.lock
    \\  --override NAME=DIR  Local dependency override (repeatable)
    \\  --format text|json   Output format (default: text)
    \\  --color auto|off|on  Diagnostic color (default: auto)
    \\  --help               Show this help
    \\
;

pub const test_command =
    \\Run application tests in isolated databases.
    \\
    \\Usage: transitc test [OPTIONS]
    \\
    \\Options:
    \\  -f FILE              Entry file (default: build.transit)
    \\  --target NAME        Target (default: tests or sole test target)
    \\  --override NAME=DIR  Local dependency override (repeatable)
    \\  --runtime FILE       Transit test host executable
    \\  --format text|json   Output format (default: text)
    \\  --color auto|off|on  Diagnostic color (default: auto)
    \\  --help               Show this help
    \\
;
