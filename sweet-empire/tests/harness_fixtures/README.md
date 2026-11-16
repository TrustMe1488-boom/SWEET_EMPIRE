# Safe harness fixtures

`cases.json` contains synthetic text only: no runnable GDScript, Python or camera code.
Test-Runner.ps1 materializes stdout/stderr/Godot log files in a unique directory
under the project's ignored `.local/testing/classifier/`. It never launches a process.
Artifacts and per-case reasons remain available for inspection. A stale timestamp is
set only on the synthetic log belonging to the current case.

Names such as syntax-error and runtime-error describe simulated diagnostic text.
They do not prove Godot emits that text or returns a particular exit code. Actual
engine negative fixtures in an isolated temporary project belong to Phase 2B and
require separate authorization. Never put intentionally broken `.gd` files here.
