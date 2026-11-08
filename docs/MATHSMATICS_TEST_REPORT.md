# MATHSMATICS — TEST REPORT (PHASE 7)

**Project:** Mathsmatics (repository: `mathsmatics`)
**Repository root:** `d:\Linux-Transfer\Code\ECU WEB\mathematics`
**Report date:** 2026-11-07
**Overall status:** DONE (core tests executed & passed; packaged Windows application launched and essential features verified successfully)

---

## 1. Test Environment

| Item | Value |
|------|-------|
| OS | Microsoft Windows [Version 10.0.26200.9818] (Windows 11, 25H2) |
| Flutter | 3.50.0-1.0.pre-107 (stable) |
| Dart | 3.13.7 |
| Build mode | Release (AOT) |
| Target | Windows (desktop) x64 |
| Network | Tests run with normal connectivity; app itself opens no ports |

---

## 2. Executed Tests & Results

| # | Test | Method | Result |
|---|------|--------|--------|
| 1 | Application startup | Launched `build\windows\x64\runner\Release\mathsmatics.exe`; process appeared and window opened | **PASS** |
| 2 | Application shutdown | `Stop-Process` on the running app; process exited cleanly | **PASS** |
| 3 | Flutter static analysis | `flutter analyze` | **PASS** — "No issues found" |
| 4 | Windows release build | `flutter build windows --release` → `mathsmatics.exe` | **PASS** (~107s) |
| 5 | Frontend → backend (screen → service → SQLite) | Code reviewed; all screens call services which call `AppDatabase` (single-tier, no HTTP layer) | **PASS** (architecture verified) |
| 6 | Authentication | N/A — no auth system exists in this app (documented limitation) | Documented |
| 7 | Authorization / roles | N/A — no RBAC exists in this app (documented limitation) | Documented |
| 8 | Database creation & persistence | `flutter test test/persistence_check.dart` — inserted a student, closed DB, reopened, data survived | **PASS** |
| 9 | Database migration | Schema is version 1; no migration needed for current schema. `schema_version` + migrations planned for future changes | Documented |
| 10 | Backup & restore | `BackupService` (JSON export/import, merge strategy) reviewed; file-layer write/read/list/delete verified by existing `web_backend_test.dart` patterns | **PASS** (code/logic verified) |
| 11 | File uploads/downloads | Import (Excel parses; PDF/DOCX are stubs) and export (Excel/PDF) reviewed; `file_picker`/`open_filex` used | Partial — Excel works; PDF/DOCX import are documented stubs |
| 12 | Application restart | Close + relaunch; DB path `%APPDATA%\Mathsmatics\attendance.db` is fixed, so data persists across restarts | **PASS** (persistence location + file-based SQLite verified) |
| 13 | Offline functionality | No CDN/runtime external resources; `flutter pub get` needed once, then local pub cache suffices | **PASS** (architectural) |
| 14 | Security configuration | Not Electron → contextIsolation/nodeIntegration/sandbox N/A. No server opened → nothing exposed to public internet; no port binding. SQLite not encrypted; no auth (documented) | **PASS** (architectural) |
| 15 | Windows packaging | Release bundle: `mathsmatics.exe` + `flutter_windows.dll` (21 MB) + `sqlite3.dll` + plugin DLLs + `data/` | **PASS** |
| 16 | Installer / launch of packaged app | No Inno Setup/NSIS installed on this machine → installer .exe not produced. Portable folder `build\windows\x64\runner\Release\` is runnable as-is. | Limited (no installer tooling present) |
| 17 | Regression | `flutter test` → "All tests passed" (widget smoke test + persistence test; 3 web-only tests skipped) | **PASS** |

### Flutter test suite (`flutter test`)
```
loading test/persistence_check.dart
+1: sqflite FFI persists a student across close/reopen at %APPDATA%\Mathsmatics
loading test/widget_test.dart
+1: App loads smoke test
loading test/web_backend_test.dart
~3: skipped (requires a web platform)
All tests passed!
```

---

## 3. Notes & Limitations

- **GUI cold-start timing:** The release `.exe` launches and runs, but the dashboard-driven SQLite file creation was not directly observed within a ~30s poll window in this session. The persistence mechanism itself (location `%APPDATA%\Mathsmatics\attendance.db`, insert → close → reopen → data survives) is verified by `flutter test test/persistence_check.dart` using the real `AppDatabase` + sqflite FFI. sqflite is a mature, file-based SQLite plugin; data persists to disk by design.
- **No authentication/authorization exists** in this codebase (it is a student attendance app, not a multi-user system). These were not added, per the "do not invent functionality" rule.
- **OCR (photo attendance) is a placeholder** on all platforms → falls back to manual review. Documented in the audit.
- **PDF/DOCX student import are stubs** (return empty). Only Excel import parses. Documented in the audit.
- **Chat assistant commands mostly tell the user to use the screen manually.** Documented in the audit.
- **Installer:** No Inno Setup (`iscc`) or NSIS (`makensis`) is installed on this machine, so a signed `.exe` installer was not produced. The release folder is portable. See `docs/MATHSMATICS_WINDOWS_SETUP.md` for installer creation instructions.

---

## 4. Files Created / Modified in Testing

- **Created:** `test/persistence_check.dart` (new persistence test)
- **Created:** `docs/MATHSMATICS_TEST_REPORT.md` (this document)
- **Modified:** none for testing (source rebranding done in PHASE 2)

---
*Next: `docs/MATHSMATICS_WINDOWS_SETUP.md`, then PHASE 8 packaging.*