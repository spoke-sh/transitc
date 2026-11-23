{
  lib,
  stdenv,
  runCommand,
  fetchurl,
  zig,
  testRuntime,
  sourceRevision ? "development",
  sharedArchive ? fetchurl {
    name = "transit-sql-frontend.tar.gz";
    url = "https://raw.githubusercontent.com/spoke-sh/transit/bfe936ca7cc036f7eebb4046b517db3dee34e3fd/build/artifacts/transit-sql-frontend.tar.gz";
    hash = "sha256-bahP6fqkRg6/yFhJ5MpfsfDQgUlY1gkze6r6MdOaSnE=";
  },
}:
let
  sharedHash = "transit_sql_distribution-0.0.1-t9CQA2cRIwBqqqpd72UY1jZ01USaeMUq_7pGHYqeGlJi";
  dependencies = runCommand "transitc-zig-dependencies" { nativeBuildInputs = [ zig ]; } ''
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    test "$(zig fetch ${sharedArchive})" = ${lib.escapeShellArg sharedHash}
    mkdir -p "$out/${sharedHash}"
    tar -xf ${sharedArchive} -C "$out/${sharedHash}"
  '';
in
stdenv.mkDerivation {
  pname = "transitc";
  version = "0.0.0-dev";
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../build.zig
      ../build.zig.zon
      ../apps
      ../packages
      ../tests
      ../contracts
      ../examples
      ../LICENSE
      ../NOTICE.md
      ../README.md
    ];
  };
  nativeBuildInputs = [ zig ];
  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    export ZIG_LOCAL_PKG_DIR="zig-pkg"
    mkdir -p "$ZIG_LOCAL_PKG_DIR"
    cp -r ${dependencies}/. "$ZIG_LOCAL_PKG_DIR/"
    chmod -R u+w "$ZIG_LOCAL_PKG_DIR"
    zig build -Doptimize=ReleaseSafe -Dcpu=baseline -Drevision=${lib.escapeShellArg sourceRevision} -Dtest-runtime=${testRuntime}/bin/transit -j$NIX_BUILD_CORES --prefix "$out"
    runHook postBuild
  '';
  dontInstall = true;
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    zig build test -Doptimize=ReleaseSafe -Dcpu=baseline -j$NIX_BUILD_CORES
    runHook postCheck
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/transitc" --help
    "$out/bin/transitc" --version
    "$out/bin/transitc" fmt --help
    printf 'create target default as begin end;' >fmt.transit
    "$out/bin/transitc" fmt fmt.transit
    "$out/bin/transitc" fmt --check fmt.transit
    "$out/bin/transitc" build -f tests/integration/fixtures/application/build.transit --check --format json
    status=0
    "$out/bin/transitc" unknown >unsupported.stdout 2>unsupported.stderr || status=$?
    test "$status" -eq 2
    test ! -s unsupported.stdout
    grep -F 'unsupported command' unsupported.stderr
    "$out/bin/transitc" test --help
    "$out/bin/transitc" test -f tests/fixtures/application-tests/build.transit --format json
    runHook postInstallCheck
  '';
  passthru = { inherit dependencies sharedArchive; };
  meta = {
    description = "Offline Transit source compiler and workspace tools";
    mainProgram = "transitc";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
