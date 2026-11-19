{
  lib,
  stdenv,
  runCommand,
  fetchgit,
  zig,
  sourceRevision ? "development",
  sharedSource ? fetchgit {
    name = "transitc-shared-source";
    url = "https://github.com/spoke-sh/transit.git";
    rev = "8bbe56e13a839e4485cfa67593f1425ee1594954";
    hash = "sha256-U9Rp4iLV7mQEY1bG7pImMmvjO4m0lYGdNkdki2J2PHo=";
  },
}:
let
  sharedHash = "transit-0.0.1-OBsLdRPCGgWiUe2wuiyo-YLUlj8MOJ6LxD1ZAnP-axfU";
  dependencies = runCommand "transitc-zig-dependencies" { nativeBuildInputs = [ zig ]; } ''
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    tar -czf shared.tar.gz -C ${sharedSource} .
    test "$(zig fetch shared.tar.gz)" = ${lib.escapeShellArg sharedHash}
    mkdir -p "$out/${sharedHash}"
    cp -r ${sharedSource}/. "$out/${sharedHash}/"
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
    zig build -Doptimize=ReleaseSafe -Dcpu=baseline -Drevision=${lib.escapeShellArg sourceRevision} -j$NIX_BUILD_CORES --prefix "$out"
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
    "$out/bin/transitc" build -f tests/integration/fixtures/application/build.transit --check --format json
    status=0
    "$out/bin/transitc" test >unsupported.stdout 2>unsupported.stderr || status=$?
    test "$status" -eq 2
    test ! -s unsupported.stdout
    grep -F 'unsupported command' unsupported.stderr
    runHook postInstallCheck
  '';
  passthru = { inherit dependencies sharedSource; };
  meta = {
    description = "Offline Transit source compiler and workspace tools";
    mainProgram = "transitc";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
