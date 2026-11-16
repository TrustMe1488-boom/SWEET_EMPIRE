"""Fail-closed classification of a completed Godot invocation. Standard library only."""
from pathlib import Path
import re

CRITICAL = re.compile(
    r"\b(?:SCRIPT\s+ERROR|ERROR|FATAL(?:\s+ERROR)?|Parse\s+Error|Compile\s+Error)\s*:"
    r"|Failed to (?:load|open|instantiate)\b"
    r"|\b(?:CrashHandler|Segmentation fault|Unhandled exception)\b"
    r"|(?:^|\s)FAIL(?:\s|:|$)", re.IGNORECASE
)
RESULT_TOKEN = re.compile(r"\b[A-Z0-9_]*RESULT\b")


def classify(*, stdout_path, stderr_path, log_path, marker, format="counts",
             started_ns, exit_code, timed_out=False, launch_error=""):
    reasons = []
    if launch_error:
        reasons.append(f"Launch error: {launch_error}")
    if timed_out:
        reasons.append("Process timed out")
    if type(exit_code) is not int or exit_code != 0:
        reasons.append(f"Invalid/nonzero exit code: {exit_code!r}")
    if type(started_ns) is not int or started_ns <= 0:
        reasons.append("Invalid start timestamp")
    valid_config = isinstance(marker, str) and re.fullmatch(r"[A-Z0-9_]*RESULT", marker)
    if not valid_config or format not in ("counts", "checks"):
        reasons.append("Invalid marker/format configuration")
    texts = {}
    for name, path in (("stdout", stdout_path), ("stderr", stderr_path), ("godot", log_path)):
        try:
            file = Path(path)
            if file.is_symlink() or not file.is_file():
                raise ValueError("Not a regular artifact")
            if type(started_ns) is int and file.stat().st_mtime_ns < started_ns:
                reasons.append(f"Stale artifact: {name}")
            texts[name] = file.read_text(encoding="utf-8-sig", errors="strict")
        except (OSError, ValueError, UnicodeError, TypeError) as error:
            reasons.append(f"Missing/unreadable artifact {name}: {error}")
            texts[name] = ""
        for line in texts[name].splitlines():
            if CRITICAL.search(line):
                reasons.append(f"Critical {name}: {line}")
    if not texts["godot"].strip():
        reasons.append("Empty Godot log")
    escaped = re.escape(marker) if isinstance(marker, str) else "INVALID"
    pattern = (rf"{escaped}: (?P<passed>[0-9]+) passed, (?P<failed>[0-9]+) failed"
               if format == "counts" else
               rf"{escaped}: checks=(?P<total>[0-9]+) failed=(?P<failed>[0-9]+)")
    canonical = None
    for name, text in texts.items():
        lines = [line for line in text.splitlines() if RESULT_TOKEN.search(line)]
        if name == "stdout" and len(lines) != 1:
            reasons.append("Expected exactly one stdout RESULT")
        if name != "stdout" and len(lines) > 1:
            reasons.append(f"Duplicate RESULT in {name}")
        if name == "stderr" and lines:
            reasons.append("Unexpected RESULT on stderr")
        for line in lines:
            match = re.fullmatch(pattern, line)
            if not match:
                reasons.append(f"Malformed/unexpected RESULT in {name}: {line}")
                continue
            try:
                failed = int(match["failed"])
                passed = int(match["passed"]) if format == "counts" else int(match["total"]) - failed
                if failed != 0 or passed <= 0:
                    reasons.append(f"Failed/empty checks in {name}")
            except ValueError:
                reasons.append(f"Invalid RESULT numbers in {name}")
            if name == "stdout":
                canonical = line
            elif name == "godot" and line != canonical:
                reasons.append("Godot RESULT differs from stdout")
    return {"passed": not reasons, "reasons": reasons, "result": canonical}
