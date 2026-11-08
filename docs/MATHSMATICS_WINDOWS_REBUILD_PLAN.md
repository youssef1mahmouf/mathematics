# MATHSMATICS — WINDOWS REBUILD PLAN (PHASE 1)

**Project:** Mathsmatics (repository: `mathematics`)
**Repository root:** `d:\Linux-Transfer\Code\ECU WEB\mathematics`
**Plan date:** 2026-11-07
**Status:** PROPOSED (awaiting alignment before any major changes)
**Depends on:** `docs/MATHSMATICS_FULL_PROJECT_AUDIT.md` (PHASE 0 — complete)

---

## 0. Guiding Decision — Keep Flutter, Do Not Adopt Electron

The PHASE 0 audit established that this is a **Flutter (Dart) desktop application**, not a JavaScript/Node.js web app. It already:
- compiles to a native Windows x64 executable (`windows/` C++ runner),
- stores data locally in SQLite (`%APPDATA%\ECU Attendance\attendance.db`),
- needs no browser tab, no public server, no domain, no localhost port binding,
- works offline after the first `flutter pub get`.

**Decision:** Do NOT port to Electron. The task Electron/`127.0.0.1`/preload/IPC requirements are N/A for this stack. Flutter already satisfies the "native Windows desktop, local data, offline, standalone executable" goal. The rebuild means: rebrand, harden, build, test, package — within Flutter — not a rewrite.

## 1. Target Deliverables

| Deliverable | Detail |
|-------------|--------|
| Application name | Mathsmatics (display), window title Mathsmatics |
| Binary | `Mathsmatics.exe` (Windows x64) |
| Build modes | Release (AOT) for shipping; Debug for development |
| Packaging | Windows installer (`.exe`) via Inno Setup / NSIS / WiX + optional portable folder |
| Application icon | `Mathsmatics` icon (replace `windows/runner/resources/app_icon.ico`) |
| Data directory | `%APPDATA%\Mathsmatics\` (DB, backups, reports) — persistent across updates |
| Installer behavior | Must NOT erase existing user data on update |

## 2. Phase-by-Phase Execution Plan

| Phase | Goal | Key actions | Exit criterion |
|-------|------|-------------|----------------|
| PHASE 0 | Full project audit | Complete — audit doc written | Audit doc delivered |
| PHASE 1 | Architecture & migration plan | This document; decide stack, data dir, branding | Plan aligned |
| PHASE 2 | Windows desktop foundation | Rebrand to Mathsmatics; app icon; version resources; verify `flutter build windows` | Release `.exe` launches |
| PHASE 3 | Integrate existing frontend/backend | No separate backend exists; keep single-tier Flutter; wire screens→services→SQLite | All existing screens navigate |
| PHASE 4 | Local database & persistence | Confirm SQLite location; add schema migration support; backup/restore + restart persistence tests | Data survives restart; backup/restore verified |
| PHASE 5 | Restore & verify existing features | Dashboard, student list, import (Excel), take attendance, reports, backup, chat | Feature inventory verified |
| PHASE 6 | Offline & security verification | Disconnect network; confirm app runs; confirm nothing listens on network | Offline run OK; no network exposure |
| PHASE 7 | Comprehensive testing & regression | Execute test plan; fix bugs | Test report with executed results |
| PHASE 8 | Windows installer & final delivery | Build installer; verify install/launch/update preserves data; write setup doc | Installer delivered; setup doc written |

## 3. Architecture (retained)

```
[ User ]
   |
[ Mathsmatics.exe ]  <-- Flutter Windows desktop (single process, native Win32 window)
   |
[ lib/screens ]  (UI: dashboard, student list, import, take attendance, reports, backup, chat)
   |
[ lib/services ]  (session, backup, report, import, matching, OCR, chat)
   |
[ lib/database/app_database.dart ]  <-- SQLite (sqflite)
   |
[ %APPDATA%\Mathsmatics\mathsmatics.db ]  (single local file)
```

- Single process: the Flutter executable IS the app; no separate backend to start/stop.
- No network sockets opened; nothing bound to `127.0.0.1` or any port.
- Data persisted in a single SQLite file under `%APPDATA%\Mathsmatics\`.

## 4. Data Persistence & Migration Plan

- **Database:** SQLite via `sqflite`, file `%APPDATA%\Mathsmatics\mathsmatics.db`.
- **Existing schema** (students, sessions, attendance_records) preserved verbatim; no data migration needed for current schema (version 1).
- **Migration support to add:** a `schema_version` table + migration functions so future schema changes do not wipe data.
- **Backup/restore:** existing JSON backup (`BackupService`) kept, pointed at `%APPDATA%\Mathsmatics\backups\`. Restore keeps the merge strategy (no clearing) but an explicit "replace all" option added with confirmation.
- **Never silently overwrite/delete data:** restores require explicit user confirmation; installer updates preserve `%APPDATA%\Mathsmatics\`.

## 5. Rebranding (mathematics → Mathsmatics)

- `pubspec.yaml`: `name: mathsmatics`, description updated.
- `windows/CMakeLists.txt`: `BINARY_NAME "mathsmatics"`.
- `windows/runner/Runner.rc`: `FileDescription`/`InternalName`/`ProductName`/`OriginalFilename` → `mathsmatics`; copyright updated.
- `lib/main.dart`: `title: Mathsmatics` (Arabic UI locale retained).
- `windows/runner/resources/app_icon.ico`: replace with Mathsmatics icon.
- Window title → Mathsmatics.

## 6. Offline & External Dependency Handling

- `flutter pub get` once (needs internet); thereafter builds use the local pub cache — offline capable.
- No CDN/runtime external resources.
- `google_ml_kit` (Android OCR) kept as a declared dependency; Windows OCR remains a placeholder → documented limitation (OCR/photo attendance falls back to manual entry).
- PDF/DOCX import stubs documented as limitations; Excel import works.
- Web-only assets (`web/sqlite3.wasm`, `web/sqflite_sw.js`) are NOT used by the Windows desktop build.

## 7. Security Posture (desktop, no Electron)

- N/A: `contextIsolation`, `nodeIntegration`, `sandbox`, `contextBridge`, IPC (no webview, no Node).
- No server → nothing exposed to public internet; no port binding.
- Local SQLite not encrypted; no authentication — documented. Any local PC user can read the DB. (Add auth only if explicitly requested.)
- File paths from `file_picker` only (user-selected).

## 8. Packaging & Installer

- Build: `flutter build windows --release` → `build/windows/x64/release/` containing `mathsmatics.exe` + `flutter_assets/` + DLLs.
- Installer: wrap the release folder into a Windows `.exe` installer (e.g., Inno Setup) that:
  - installs program files to `Program Files\Mathsmatics`,
  - creates Start Menu + desktop shortcut,
  - writes user data to `%APPDATA%\Mathsmatics\` (NOT inside Program Files),
  - on update, does NOT touch `%APPDATA%\Mathsmatics\` (preserves DB/backups/reports).
- Optional portable build: a folder containing the release `.exe` + assets + a writable `data/` next to the exe.

## 9. Testing Plan (executed in PHASE 7)

1. Application startup (launch `Mathsmatics.exe`).
2. Application shutdown (close window → process exits).
3. Frontend → backend (screen → service → SQLite) for each feature.
4. Authentication — N/A (none exists); document.
5. Authorization/roles — N/A (none exists); document.
6. Database creation & persistence (data survives restart).
7. Database migration (schema_version table).
8. Backup & restore (create, restore, verify counts).
9. File uploads/downloads (import Excel, export Excel/PDF reports, open file).
10. Application restart (reopen after close).
11. Offline (disconnect network; app runs).
12. Security (no listening ports; no remote load).
13. Windows packaging (installer install / launch / update preserving data).
14. Regression (all existing features still work).

## 10. Known Limitations (documented, not fixed unless requested)

- No user registration/login, authentication, or role-based permissions.
- No admin dashboard (dashboard = statistics only).
- No groups management UI (groups are free-text strings).
- No email or notifications service.
- OCR/photo attendance returns empty → manual review flow (all platforms).
- PDF/DOCX import returns empty → only Excel import parses.
- Chat commands mostly stubs → manual screen use.
- SQLite not encrypted; no auth.
- Cairo font not bundled (system fallback).

## 11. Files Planned to Change (no deletions of original source)

- `pubspec.yaml` (name/description)
- `lib/main.dart` (title)
- `windows/CMakeLists.txt` (BINARY_NAME)
- `windows/runner/Runner.rc` (version info)
- `windows/runner/main.cpp` (window title)
- `windows/runner/resources/app_icon.ico` (replace icon)
- `lib/database/app_database.dart` (add schema_version + migrations; new data dir)
- `lib/database/database_setup_io.dart` (new data dir `%APPDATA%\Mathsmatics`)
- `lib/platform/platform_files_io.dart` (new data dir)
- `lib/services/backup_service.dart` (new backup dir)
- `lib/services/report_service.dart` (new reports dir)
- NEW: `docs/MATHSMATICS_WINDOWS_SETUP.md`, `docs/MATHSMATICS_TEST_REPORT.md`

**Original project is preserved** (no `git reset --hard`, `git clean -fd`, or bulk deletion). Replacement happens only after the existing implementation is verified.

## 12. Build & Run Commands (development)

```powershell
# Get dependencies (internet needed once)
flutter pub get

# Analyze
flutter analyze

# Run on Windows desktop (Debug)
flutter run -d windows

# Build release Windows x64
flutter build windows --release
# Output: build\windows\x64\release\mathsmatics.exe + assets
```

## 13. Exact Run Location (after build)

- Release executable: `d:\Linux-Transfer\Code\ECU WEB\mathematics\build\windows\x64\release\mathsmatics.exe`
- User data: `%APPDATA%\Mathsmatics\mathsmatics.db`

---

*Next step (pending alignment): proceed to PHASE 2 — rebrand and verify the Windows release build.*

