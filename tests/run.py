#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "tests" / "package_test.p").read_text()
EXPECTED = (
    "3\nAda\ncomma, quote \"ok\"\n1\nline one\nline two\n1\n1\n1\n1\n1\n"
    "0\n1\n1\n1\n3\n1\n2\nname\nname\n1\nAda\nLovelace\n7\n"
    "3\nline one\nline two\n2\n2\n2\n2\n2\n1\n3\n1000\n值-999\n"
)


def run(command, cwd, env):
    return subprocess.run(command, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--strut", default=os.environ.get("STRUT_BIN", "strut"))
    args = parser.parse_args()
    compiler = str(Path(args.strut).resolve()) if Path(args.strut).exists() else args.strut

    with tempfile.TemporaryDirectory(prefix="strut-csv-test-") as temporary:
        root = Path(temporary)
        app = root / "app"
        app.mkdir()
        (app / "main.p").write_text(SOURCE)
        (app / "header.csv").write_bytes(b"\xef\xbb\xbfname;name\r\nAda;Lovelace\r\n")
        (app / "large.csv").write_text("".join(f"{index},值-{index}\n" for index in range(1000)))
        (app / "strut.json").write_text(json.dumps({
            "name": "csv-package-test",
            "version": "0.1.0",
            "entry": "main.p",
            "dependencies": {},
        }) + "\n")
        env = os.environ.copy()
        env["STRUT_HOME"] = str(root / "strut-home")

        for command in (
            [compiler, "init"],
            [compiler, "add", str(ROOT)],
            [compiler, "install", "--offline"],
            [compiler, "packages", "--json"],
        ):
            result = run(command, app, env)
            if result.returncode:
                print(result.stdout, end="")
                print(result.stderr, end="", file=os.sys.stderr)
                return result.returncode

        output = app / ("csv-test.exe" if os.name == "nt" else "csv-test")
        result = run([compiler, "main.p", "-o", str(output)], app, env)
        if result.returncode:
            print(result.stdout, end="")
            print(result.stderr, end="", file=os.sys.stderr)
            return result.returncode
        result = run([str(output)], app, env)
        if result.returncode or result.stdout != EXPECTED:
            print("unexpected result", file=os.sys.stderr)
            print("stdout:", repr(result.stdout), file=os.sys.stderr)
            print("stderr:", repr(result.stderr), file=os.sys.stderr)
            return 1

    print("csv package test: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
