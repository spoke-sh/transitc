"""Build registered source with no inherited Zig packages or build caches."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    files = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
    with tempfile.TemporaryDirectory(prefix="transitc-clean-") as directory:
        root = Path(directory)
        source = root / "source"
        for name in filter(None, files):
            original = ROOT / name
            if not original.is_file():
                continue
            destination = source / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(original, destination)
        env = dict(os.environ, ZIG_GLOBAL_CACHE_DIR=str(root / "global"),
                   ZIG_LOCAL_CACHE_DIR=str(root / "local"), ZIG_LOCAL_PKG_DIR=str(root / "packages"))
        for step in ("check", "test"):
            subprocess.run(["zig", "build", step], cwd=source, env=env, check=True)
    print("PASS clean source build, unit tests and embedding consumer with empty Zig caches")


if __name__ == "__main__":
    main()
