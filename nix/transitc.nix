{
  lib,
  stdenv,
  zig,
}:
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
    ];
  };

  nativeBuildInputs = [ zig ];
  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    zig build -Doptimize=ReleaseSafe -Dcpu=baseline -j$NIX_BUILD_CORES --prefix "$out"
    runHook postBuild
  '';
  dontInstall = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/transitc" --help
    test "$("$out/bin/transitc" --version)" = "transitc 0.0.0-dev (bootstrap)"
    status=0
    "$out/bin/transitc" build >unsupported.stdout 2>unsupported.stderr || status=$?
    test "$status" -eq 2
    test ! -s unsupported.stdout
    grep -F 'unsupported arguments' unsupported.stderr
    runHook postInstallCheck
  '';

  meta = {
    description = "Transit language compiler CLI scaffold";
    mainProgram = "transitc";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
