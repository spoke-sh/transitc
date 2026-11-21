"""Formatter command contract: fixed style, preservation, discovery and safe writes."""
from pathlib import Path
import os
import shutil
import stat
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
BIN = Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / "zig-out/bin/transitc").resolve()
MESSY = b"create target default as begin create public table items(id bigint,label text);select * from items;end;"
FORMATTED = (b"CREATE TARGET default AS BEGIN\n"
             b"  CREATE PUBLIC TABLE items (id BIGINT, label TEXT);\n"
             b"  SELECT * FROM items;\nEND;\n")


def run(cwd, *args, data=None, status=0):
    env = {**os.environ, "PATH": "/unavailable", "TRANSIT_TEST_RUNTIME": "/unavailable"}
    result = subprocess.run([BIN, "fmt", *args], cwd=cwd, input=data, capture_output=True,
                            timeout=20, env=env)
    assert result.returncode == status, (args, result.returncode, result.stdout, result.stderr)
    if status == 0:
        assert result.stderr == b"", (args, result.stderr)
    return result


def snapshot(path):
    info = path.stat()
    return path.read_bytes(), info.st_ino, info.st_mtime_ns, stat.S_IMODE(info.st_mode)


def main():
    with tempfile.TemporaryDirectory(prefix="transitc-fmt-") as directory:
        root = Path(directory).resolve()
        assert b"--check" in run(root, "--help").stdout
        for args in [("--unknown",), ("--stdin", "--check"), ("--stdin", "."), ("",)]:
            result = run(root, *args, status=2)
            assert result.stdout == b"" and b"error:" in result.stderr
        assert run(root, "--stdin", data=MESSY).stdout == FORMATTED
        assert run(root, "--stdin", data=FORMATTED).stdout == FORMATTED
        assert run(root, "--stdin", data=b" \r\n\t").stdout == b""
        # Formatting needs neither resolvable imports nor an installed host/Git.
        unresolved = b"import rows from 'missing.transit';\ncreate target default as begin use rows.Rows();end;"
        result = run(root, "--stdin", data=unresolved).stdout
        assert b"IMPORT rows FROM 'missing.transit';" in result and b"USE rows.Rows();" in result

        comments = (b"-- heading\r\ncreate /* inline */ target default as begin -- body\r\n"
                    b"/* outer /* nested */ kept */\r\n"
                    b"create public table \"CaseName\"(id bigint, label text); -- columns\r\n"
                    b"insert into \"CaseName\" values(7,'a  b\n''quoted''');\r\nend; -- tail")
        expected = (b"-- heading\nCREATE /* inline */ TARGET default AS BEGIN -- body\n"
                    b"  /* outer /* nested */ kept */\n"
                    b"  CREATE PUBLIC TABLE \"CaseName\" (id BIGINT, label TEXT); -- columns\n"
                    b"  INSERT INTO \"CaseName\" VALUES (7, 'a  b\n''quoted''');\nEND; -- tail\n")
        output = run(root, "--stdin", data=comments).stdout
        assert output == expected, output
        assert run(root, "--stdin", data=output).stdout == output
        # Numeric spelling and multi-byte operators must remain intact.
        lexical = b"create function cat() returns text as begin return 'a'||'b';end;create target default as begin create public table t(v float64);insert into t values(1.25e-2);select * from t where v!=2;end;"
        output = run(root, "--stdin", data=lexical).stdout
        assert b"1.25e-2" in output and b"'a' || 'b'" in output and b"v != 2" in output
        assert run(root, "--stdin", data=output).stdout == output

        nested = b"create module m(n bigint) as begin if n>0 then use a(n=>n);else if n=0 then end if;end if;end;"
        expected = (b"CREATE MODULE m(n BIGINT) AS BEGIN\n  IF n > 0 THEN\n    USE a(n => n);\n"
                    b"  ELSE\n    IF n = 0 THEN\n    END IF;\n  END IF;\nEND;\n")
        assert run(root, "--stdin", data=nested).stdout == expected

        a = root / "a.transit"
        a.write_bytes(MESSY)
        a.chmod(0o640)
        before = snapshot(a)
        check = run(root, "--check", status=1)
        assert check.stdout == b"a.transit\n" and check.stderr == b""
        assert snapshot(a) == before
        assert run(root).stdout == b"a.transit\n"
        after = snapshot(a)
        assert after[0] == FORMATTED and after[3] == 0o640 and before[1] != after[1]
        assert run(root).stdout == b"" and snapshot(a) == after
        assert run(root, "--check").stdout == b"" and snapshot(a) == after

        # Recursive discovery is deterministic, unique, and excludes generated/hidden trees.
        for name in ["z.transit", "nested/b.transit", "nested/c.transit", "notes.txt",
                     ".git/ignored.transit", ".transit/ignored.transit", ".hidden.transit",
                     "node_modules/ignored.transit", "zig-out/ignored.transit", "zig-pkg/ignored.transit"]:
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(MESSY)
        assert run(root, ".", "nested", "z.transit").stdout == b"nested/b.transit\nnested/c.transit\nz.transit\n"
        assert (root / "notes.txt").read_bytes() == MESSY
        assert (root / ".git/ignored.transit").read_bytes() == MESSY
        assert run(root, ".hidden.transit").stdout == b".hidden.transit\n"
        (root / "-file.transit").write_bytes(MESSY)
        assert run(root, "--", "-file.transit").stdout == b"-file.transit\n"
        (root / "a space.transit").write_bytes(MESSY)
        assert run(root, "a space.transit").stdout == b"a space.transit\n"

        for data in [b"CREATE TARGET broken AS BEGIN", b"\xff", b"x" * (1024 * 1024 + 1)]:
            bad = root / "bad.transit"
            bad.write_bytes(data)
            before = snapshot(bad)
            result = run(root, "bad.transit", status=1)
            assert result.stdout == b"" and b"bad.transit:" in result.stderr
            assert snapshot(bad) == before
            stdin = run(root, "--stdin", data=data, status=1)
            assert stdin.stdout == b"" and b"<stdin>:" in stdin.stderr
        a.write_bytes(MESSY)
        result = run(root, "bad.transit", "a.transit", status=1)
        assert result.stdout == b"a.transit\n" and a.read_bytes() == FORMATTED
        (root / "bad.transit").unlink()
        assert b"path does not exist" in run(root, "missing.transit", status=1).stderr
        assert b"expected a .transit" in run(root, "notes.txt", status=1).stderr

        a.write_bytes(MESSY)
        a.chmod(0o444)
        before = snapshot(a)
        assert run(root, "--check", "a.transit", status=1).stdout == b"a.transit\n"
        assert b"permission denied" in run(root, "a.transit", status=1).stderr
        assert snapshot(a) == before
        a.chmod(0o640)
        os.link(a, root / "linked.transit")
        assert b"multiple hard links" in run(root, "a.transit", status=1).stderr
        assert a.read_bytes() == MESSY
        (root / "linked.transit").unlink()
        (root / "link.transit").symlink_to(a)
        (root / "linkdir").symlink_to(root / "nested", target_is_directory=True)
        assert b"regular .transit file" in run(root, "link.transit", status=1).stderr
        assert run(root, "linkdir/b.transit", status=1).stdout == b""
        assert run(root).stdout == b"a.transit\n"  # Discovered symlinks are skipped.
        if hasattr(os, "mkfifo"):
            os.mkfifo(root / "pipe.transit")
            assert run(root, "pipe.transit", status=1).stdout == b""
            (root / "pipe.transit").unlink()
        assert not list(root.glob("*.tmp")), "temporary replacement leaked"

    # Exercise every real source fixture; second formatting must be byte-identical.
    count = 0
    with tempfile.TemporaryDirectory(prefix="transitc-fmt-fixtures-") as directory:
        root = Path(directory).resolve()
        for base in [ROOT / "examples", ROOT / "tests/fixtures", ROOT / "tests/integration/fixtures"]:
            for source in sorted(base.rglob("*.transit")):
                path = root / f"{count}.transit"
                shutil.copyfile(source, path)
                count += 1
        run(root)
        assert run(root, "--check").stdout == b""
    print(f"PASS formatter command, preservation and filesystem checks; {count} source fixtures")


if __name__ == "__main__":
    main()
