"""Explicit allowlist runner. Merely importing this module never launches Godot."""
import argparse
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import re
import subprocess
import time
import uuid

from test_godot_result import classify
from owned_process import OwnedProcess

PROJECT = Path(__file__).resolve().parents[2]
GODOT = Path(r"C:\Users\timoxa\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe")


def load_suites():
    catalog = json.loads((Path(__file__).parent / "suites.json").read_text(encoding="utf-8-sig"))
    if catalog.get("schemaVersion") != 1:
        raise ValueError("Unsupported manifest schema")
    entries = catalog["suites"]
    ids = set()
    for entry in entries:
        name = entry["id"]
        if (not re.fullmatch(r"[a-zA-Z0-9_]+", name) or name in ids
                or entry["script"] != f"tests/{name}.gd"
                or entry["mode"] not in ("headless", "gpu", "ipc", "camera")
                or type(entry["enabled"]) is not bool
                or entry["format"] not in ("counts", "checks")
                or not re.fullmatch(r"[A-Z0-9_]*RESULT", entry["marker"])
                or type(entry["timeoutSeconds"]) is not int
                or not 1 <= entry["timeoutSeconds"] <= 3600
                or not (PROJECT / entry["script"]).is_file()):
            raise ValueError(f"Invalid manifest entry: {name}")
        ids.add(name)
    return entries


def select_suites(entries, mode, names):
    if mode not in ("headless", "gpu"):
        raise ValueError("IPC and camera suites are prohibited in this runner")
    if mode != "headless" and not names:
        raise ValueError("GPU requires explicit --suite selection")
    if len(names) != len(set(names)):
        raise ValueError("Duplicate suite selection")
    selected = ([next((e for e in entries if e["id"] == name and e["mode"] == mode), None)
                 for name in names] if names else
                [e for e in entries if e["mode"] == mode and e["enabled"]])
    if not selected or any(e is None for e in selected):
        raise ValueError("Unknown suite/mode or empty selection")
    for entry in selected:
        if not entry["enabled"]:
            raise ValueError(f"Blocked suite: {entry['id']}: {entry['reason']}")
    return selected


def ensure_no_godot():
    """Read Windows process inventory through the OS API, without helper executables."""
    if os.name != "nt":
        raise RuntimeError("Runner supports Windows only")
    class ProcessEntry(ctypes.Structure):
        _fields_ = [("size", wintypes.DWORD), ("usage", wintypes.DWORD),
                    ("pid", wintypes.DWORD), ("heap", ctypes.c_size_t),
                    ("module", wintypes.DWORD), ("threads", wintypes.DWORD),
                    ("parent", wintypes.DWORD), ("priority", wintypes.LONG),
                    ("flags", wintypes.DWORD), ("exe", wintypes.WCHAR * 260)]
    api = ctypes.WinDLL("kernel32", use_last_error=True)
    api.CreateToolhelp32Snapshot.argtypes = [wintypes.DWORD, wintypes.DWORD]
    api.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
    for name in ("Process32FirstW", "Process32NextW"):
        method = getattr(api, name)
        method.argtypes = [wintypes.HANDLE, ctypes.POINTER(ProcessEntry)]
        method.restype = wintypes.BOOL
    api.CloseHandle.argtypes = [wintypes.HANDLE]
    api.CloseHandle.restype = wintypes.BOOL
    handle = api.CreateToolhelp32Snapshot(2, 0)
    if handle == ctypes.c_void_p(-1).value:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        row = ProcessEntry()
        row.size = ctypes.sizeof(row)
        ok = api.Process32FirstW(handle, ctypes.byref(row))
        if not ok:
            raise ctypes.WinError(ctypes.get_last_error())
        while ok:
            if row.exe.lower().startswith("godot"):
                raise RuntimeError("Close all Godot processes before running")
            ok = api.Process32NextW(handle, ctypes.byref(row))
        if ctypes.get_last_error() != 18:  # ERROR_NO_MORE_FILES
            raise ctypes.WinError(ctypes.get_last_error())
    finally:
        api.CloseHandle(handle)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False), encoding="utf-8")


def run_one(entry, directory, *, fixture_project=None):
    project = PROJECT
    if fixture_project is not None:
        project = fixture_project.resolve()
        if not project.is_relative_to(PROJECT / '.local/testing/python'):
            raise ValueError('Fixture project outside isolated runner workspace')
    directory.mkdir()
    paths = {name: directory / f"{name}.log" for name in ("stdout", "stderr", "godot")}
    started = time.time_ns()
    code, timed_out, error = None, False, ""
    args = [str(GODOT), "--path", str(project), "--log-file", str(paths["godot"]),
            "--script", entry["script"]]
    if entry["mode"] == "headless":
        args.insert(1, "--headless")
    process = None
    ownership = None
    try:
        # Exclusive creation in a new UUID run directory prevents reuse of old logs.
        with paths["stdout"].open("xb") as stdout, paths["stderr"].open("xb") as stderr:
            environment = os.environ.copy()
            environment['APPDATA'] = str(directory / 'AppData')
            environment['LOCALAPPDATA'] = str(directory / 'LocalAppData')
            process = subprocess.Popen(args, cwd=project, stdout=stdout, stderr=stderr,
                                       stdin=subprocess.DEVNULL, shell=False,
                                       env=environment,
                                       creationflags=subprocess.CREATE_NO_WINDOW | 4)  # CREATE_SUSPENDED
            ownership = OwnedProcess(process)
            try:
                code = process.wait(timeout=entry["timeoutSeconds"])
            except subprocess.TimeoutExpired:
                timed_out = True
                ownership.terminate()  # Only this launcher's job, including its engine child.
                code = process.wait(timeout=5)
    except Exception as exc:
        error = f"{type(exc).__name__}: {exc}"
    finally:
        if ownership is not None:
            ownership.close()
        if process is not None and process.poll() is None:
            process.kill()
            process.wait(timeout=5)
    verdict = classify(stdout_path=paths["stdout"], stderr_path=paths["stderr"],
                       log_path=paths["godot"], marker=entry["marker"], format=entry["format"],
                       started_ns=started, exit_code=code, timed_out=timed_out, launch_error=error)
    row = dict(suite=entry["id"], mode=entry["mode"], exit_code=code, timed_out=timed_out,
               started_ns=started, command=args, artifacts=str(directory), **verdict)
    write_json(directory / "result.json", row)
    if process is not None and process.poll() is None:
        raise RuntimeError("Godot still running; no further suite may launch")
    return row


def self_test(run_dir):
    version = subprocess.run([str(GODOT), '--version'], cwd=run_dir,
                             capture_output=True, timeout=10, shell=False,
                             creationflags=subprocess.CREATE_NO_WINDOW)
    (run_dir / 'version.stdout.log').write_bytes(version.stdout)
    (run_dir / 'version.stderr.log').write_bytes(version.stderr)
    version_text = version.stdout.decode('utf-8', errors='strict').strip()
    if version.returncode != 0 or not re.fullmatch(r'4\.[0-9]+.*', version_text):
        raise RuntimeError(f'Godot 4 version check failed: {version_text!r}')
    print(f'Godot version: {version_text}', flush=True)
    result = 'print("FIXTURE_RESULT: 1 passed, 0 failed")'
    # Runtime failure happens in a helper so the caller still reaches quit(0).
    bad_call = 'func broken():\n var value = null\n value.missing_method()\n'
    fixtures = [
        ('success', f'extends SceneTree\nfunc _initialize():\n {result}\n quit(0)\n', True, None),
        ('syntax', 'extends SceneTree\nfunc _initialize(:\n quit(0)\n', False, 'Parse Error'),
        ('runtime', f'extends SceneTree\n{bad_call}func _initialize():\n broken()\n {result}\n quit(0)\n', False, 'SCRIPT ERROR: Invalid call'),
        ('after_result', f'extends SceneTree\n{bad_call}func _initialize():\n {result}\n broken()\n quit(0)\n', False, 'SCRIPT ERROR: Invalid call'),
        ('missing_result', 'extends SceneTree\nfunc _initialize():\n print("Fixture ran")\n quit(0)\n', False, 'Expected exactly one stdout RESULT'),
        ('nonzero_exit', f'extends SceneTree\nfunc _initialize():\n {result}\n quit(7)\n', False, 'Invalid/nonzero exit code: 7'),
    ]
    results = []
    for name, script, expected, required_reason in fixtures:
        ensure_no_godot()
        project = run_dir / ('project_' + name)
        project.mkdir()
        (project / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Harness Fixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
        (project / 'fixture.gd').write_text(script, encoding='utf-8')
        entry = dict(id=name, mode='headless', script='fixture.gd', marker='FIXTURE_RESULT', format='counts', timeoutSeconds=10)
        row = run_one(entry, run_dir / name, fixture_project=project)
        reasons = row['reasons']
        launched = (not row['timed_out'] and type(row['exit_code']) is int
                    and not any(r.startswith(('Launch error:', 'Missing/unreadable', 'Stale artifact:', 'Empty Godot log')) for r in reasons))
        correct = launched and row['passed'] == expected and (required_reason is None or any(required_reason in r for r in reasons))
        if name in ('runtime', 'after_result', 'missing_result'):
            correct = correct and row['exit_code'] == 0
        row.update(expected_pass=expected, required_reason=required_reason, verified=correct)
        results.append(row)
        write_json(run_dir / 'self-test-summary.json', results)
        print(f"SELF-TEST {name}: {'VERIFIED' if correct else 'FAILED'}; classifier={'PASS' if row['passed'] else 'FAIL'}; exit={row['exit_code']}", flush=True)
        for reason in reasons:
            print(f'  {reason}', flush=True)
    print(f'Artifacts: {run_dir}', flush=True)
    return 0 if all(r['verified'] for r in results) and len(results) == 6 else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("headless", "gpu"), default="headless")
    parser.add_argument("--suite", action="append", default=[])
    parser.add_argument("--list", action="store_true", help="List manifest only; no executable launched")
    parser.add_argument('--self-test', action='store_true', help='Run six fixed isolated headless fixtures')
    args = parser.parse_args(argv)
    run_dir = None
    try:
        if args.self_test and (args.list or args.suite or args.mode != 'headless'):
            raise ValueError('--self-test cannot be combined with suite/list/GPU selection')
        entries = load_suites()
        if args.list:
            for e in entries:
                state = "blocked by Python runner" if e["mode"] in ("ipc", "camera") else ("enabled" if e["enabled"] else "blocked: " + e["reason"])
                print(f"{e['id']}: {e['mode']}: {state}")
            return 0
        selected = [] if args.self_test else select_suites(entries, args.mode, args.suite)
        if not GODOT.is_file() or GODOT.is_symlink():
            raise RuntimeError(f"Agreed Godot executable missing: {GODOT}")
        root = PROJECT / ".local/testing/python"
        root.mkdir(parents=True, exist_ok=True)
        # Windows byte-range lock is released by the OS on exit, including crashes.
        import msvcrt
        with (root / "runner.lock").open("a+b") as lock:
            if lock.tell() == 0:
                lock.write(b"0")
                lock.flush()
            lock.seek(0)
            msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
            try:
                ensure_no_godot()
                run_dir = root / uuid.uuid4().hex
                run_dir.mkdir()
                if args.self_test:
                    return self_test(run_dir)
                results = []
                for entry in selected:
                    ensure_no_godot()
                    result = run_one(entry, run_dir / entry["id"])
                    results.append(result)
                    write_json(run_dir / "summary.json", results)
                    print(f"{entry['id']}: {'PASS' if result['passed'] else 'FAIL'}")
                    for reason in result["reasons"]:
                        print(f"  {reason}")
                print(f"Artifacts: {run_dir}")
                return 0 if results and all(r["passed"] for r in results) else 1
            finally:
                lock.seek(0)
                msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)
    except Exception as exc:
        message = f"RUNNER FAIL: {type(exc).__name__}: {exc}"
        print(message)
        if run_dir is not None:
            (run_dir / "runner-error.txt").write_text(message, encoding="utf-8")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
