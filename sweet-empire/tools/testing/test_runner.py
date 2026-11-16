"""Static checks and synthetic classifier tests. Never launches external processes."""
import ast
import hashlib
import json
import os
from pathlib import Path
import sys
import time
import unittest
import uuid

PROJECT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
ARTIFACTS = None
CASES = json.loads((PROJECT / "tests/harness_fixtures/cases.json").read_text(encoding="utf-8-sig"))


def static_checks():
    for name in ("run_godot_tests.py", "test_godot_result.py", "test_runner.py", "owned_process.py", "test_boot_persistence.py"):
        tree = ast.parse((HERE / name).read_text(encoding="utf-8"), filename=name)
        compile(tree, name, "exec")  # Compile only, do not execute.
        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                for kw in node.keywords:
                    if kw.arg == "shell" and not (isinstance(kw.value, ast.Constant) and kw.value.value is False):
                        raise AssertionError(f"Unsafe shell parameter: {name}")
        print(f"STATIC PASS: {name}", flush=True)
    if len(CASES) != 29 or len({c["name"] for c in CASES}) != 29:
        raise AssertionError("Expected 29 unique fixtures")
    from run_godot_tests import load_suites, select_suites
    entries = load_suites()
    for entry in entries:
        source = (PROJECT / entry["script"]).read_text(encoding="utf-8-sig")
        if entry["enabled"] and entry["marker"] not in source:
            raise AssertionError(f"Marker not in source: {entry['id']}")
        if entry["mode"] == "headless":
            for forbidden in ("bridge.start(", "OS.create_process(", "OS.execute("):
                if forbidden in source:
                    raise AssertionError(f"External process call in {entry['id']}")
    for mode in ("ipc", "camera"):
        try:
            select_suites(entries, mode, [])
        except ValueError:
            pass
        else:
            raise AssertionError(f"Forbidden mode accepted: {mode}")
    for mode, names in (("gpu", []), ("headless", ["unknown"]),
                        ("headless", ["run_tests", "run_tests"]),
                        ("gpu", ["render_check"]), ("headless", ["stage55_ipc_tests"])):
        try:
            select_suites(entries, mode, names)
        except ValueError:
            pass
        else:
            raise AssertionError(f"Unsafe selection accepted: {mode} {names}")
    assert len(select_suites(entries, "headless", [])) >= 13
    print(f"STATIC PASS: manifest ({len(entries)} suites); mode/allowlist guards", flush=True)


class ClassifierFixtures(unittest.TestCase):
    pass


def fixture_test(case):
    def test(self):
        from test_godot_result import classify
        directory = ARTIFACTS / case["name"]
        directory.mkdir()
        paths = {name: directory / f"{name}.log" for name in ("stdout", "stderr", "godot")}
        started = time.time_ns()
        contents = {"stdout": case["stdout"], "stderr": case.get("stderr", ""),
                    "godot": case.get("log", "Godot Engine synthetic fixture")}
        missing = {"stdout": "missingStdout", "stderr": "missingStderr", "godot": "missingLog"}
        for name, path in paths.items():
            if not case.get(missing[name], False):
                path.write_text(contents[name], encoding="utf-8")
                # Deterministic fresh timestamps; avoids filesystem time rounding.
                stamp = started + 1_000_000_000
                if name == "godot" and case.get("stale"):
                    stamp = started - 86_400_000_000_000
                os.utime(path, ns=(stamp, stamp))
        verdict = classify(stdout_path=paths["stdout"], stderr_path=paths["stderr"],
                           log_path=paths["godot"], marker="FIXTURE_RESULT",
                           format=case.get("format", "counts"), started_ns=started,
                           exit_code=None if case.get("nullExit") else case.get("exit", 0),
                           timed_out=case.get("timeout", False), launch_error=case.get("launchError", ""))
        (directory / "result.json").write_text(json.dumps(verdict, indent=2), encoding="utf-8")
        self.assertEqual(verdict["passed"], case["pass"], verdict["reasons"])
        if not case["pass"]:
            self.assertTrue(verdict["reasons"], "FAIL must explain its cause")
    return test


for fixture in CASES:
    setattr(ClassifierFixtures, "test_" + fixture["name"].replace("-", "_"), fixture_test(fixture))


def main():
    global ARTIFACTS
    static_checks()
    if sys.argv[1:] == ["--static-only"]:
        return 0
    if sys.argv[1:]:
        raise ValueError("Only --static-only is supported")
    # Hash tracked gameplay/suites and preserved PS sources before/after testing.
    watched = [p for folder in ("scripts", "scenes", "assets", "tests")
               for p in (PROJECT / folder).rglob("*") if p.is_file()]
    watched += list(HERE.glob("*.ps1")) + [HERE / "suites.json"]
    before = {p: hashlib.sha256(p.read_bytes()).hexdigest() for p in watched}
    ARTIFACTS = PROJECT / ".local/testing/classifier-python" / uuid.uuid4().hex
    ARTIFACTS.mkdir(parents=True)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ClassifierFixtures)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    unchanged = all(hashlib.sha256(p.read_bytes()).hexdigest() == digest for p, digest in before.items())
    summary = {"cases": result.testsRun, "failures": len(result.failures),
               "errors": len(result.errors), "watched_files_unchanged": unchanged,
               "expected_pass": sum(c["pass"] for c in CASES),
               "expected_fail": sum(not c["pass"] for c in CASES)}
    (ARTIFACTS / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"Artifacts: {ARTIFACTS}")
    print(json.dumps(summary))
    return 0 if result.wasSuccessful() and unchanged else 1


if __name__ == "__main__":
    raise SystemExit(main())
