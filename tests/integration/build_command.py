"""Compile source here, then execute SQL through the exactly pinned Transit runtime."""
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]

def main():
    compiler = Path(sys.argv[1] if len(sys.argv) > 1 else 'zig-out/bin/transitc').resolve()
    source = Path(os.environ['TRANSIT_TEST_SOURCE']).resolve()
    sys.path.insert(0, str(source / 'tests'))
    from harness import phases
    recorder = phases.Recorder(ROOT)
    phases.recorder = lambda: recorder
    from integration import application_build
    sys.argv = [str(ROOT / 'tests/integration/application_build.py'), str(compiler)]
    application_build.main()

if __name__ == '__main__':
    main()
