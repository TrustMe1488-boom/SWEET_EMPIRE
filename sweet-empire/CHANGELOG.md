# 1.0.0-dev.1 (unreleased)

- Added versioned world/profile saves, SHA-256 integrity, verified pending writes,
  previous-state recovery, autosave and continuation after restarting the process.
- Restored campaign, equipment, stock, customers, pedestrians, Rush checkpoint,
  reward/debit ledgers, cosmetic ownership/equipment and sound/control settings.
- Validated campaign and nested quest/event data before committing a load.
- Corrected gesture UI input to use local viewport coordinates.
- Bounded demand telemetry and removed repeated AI weight calculations.
- Added sales, expenses and profit to the compact dashboard.
- Added strict Python runner, Windows job ownership, isolated test user directories,
  persistence restart tests and UI resolution checks.
- Added Windows x64 export preset. No Windows build is available yet: templates
  are missing and mandatory release checks remain blocked/failing.
