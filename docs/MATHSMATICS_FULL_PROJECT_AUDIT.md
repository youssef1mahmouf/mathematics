# MATHSMATICS — FULL PROJECT AUDIT (PHASE 0)

**Project:** Mathsmatics (repository name: `mathematics`)
**Repository root:** `d:\Linux-Transfer\Code\ECU WEB\mathematics`
**Audit date:** 2026-11-07
**Auditor:** Cline (AI coding agent)
**Overall audit status:** COMPLETE (audit only — no destructive changes made)

---

## 1. Executive Summary & Critical Finding (Stack Mismatch)

This repository is **not** a JavaScript / Node.js / Express full-stack web application. It is a **Flutter (Dart) desktop application** titled "Student Attendance Management System - Arabic RTL Flutter App" (`pubspec.yaml` name: `mathematics`, version `1.0.0+1`).

The task brief repeatedly assumes:
- separate frontend + backend,
- API routes, controllers, middleware,
- user registration/login, sessions, role-based permissions,
- an Electron wrapper binding a local backend to `127.0.0.1`.

**None of that exists here.** There is:
- **No backend server** (no Node/Express/Python backend, no API routes, no controllers).
- **No authentication system** (no registration, no login, no sessions/tokens, no role-based access control).
- **No email service** and **no notification service**.
- **No public/internet-facing component** — it already runs as a native Windows desktop executable with local SQLite data.

**Recommendation: Do NOT port this to Electron.** Flutter already compiles to a native Windows x64 executable (a `windows/` C++ runner already exists), stores data locally in SQLite, needs no browser tab, no public server, and no domain. Forcing an Electron rewrite would be destructive and unnecessary. The correct rebuild path is to keep Flutter, fix branding to "Mathsmatics", ensure a stable Windows release build, harden persistence/backup, and package an installer.

## 2. Project Identity

| Field | Value |
|-------|-------|
| Repository root | `d:\Linux-Transfer\Code\ECU WEB\mathematics` |
| pubspec project name | `mathematics` |
| Display / task name | Mathsmatics |
| Description | "Student Attendance Management System - Arabic RTL Flutter App" |
| Version | 1.0.0+1 |
| SDK constraint | `sdk: ^3.13.4` |
| Installed toolchain | Flutter 3.50.0-1.0.pre-107 (stable), Dart 3.13.7, Visual Studio 2026 |
| Detected devices | Windows (desktop) x64, Chrome, Edge |
| Primary target per audit | Windows 10/11 x64 desktop |
| UI language | Arabic (RTL), locale `ar-EG`, with `en-US` support |
| Database | SQLite via `sqflite`, file at `%APPDATA%\ECU Attendance\attendance.db` (Windows) |

## 3. Repository Structure (source files only — build/pub-cache artifacts excluded)

Top-level:
- `lib/` — all Dart application source (UI, models, services, database, platform)
- `windows/` — native Windows C++ runner + CMake (produces the `.exe`)
- `web/` — web build assets (only relevant to the Chrome/Edge web target)
- `android/` — Android project (not a target for this Windows rebuild)
- `test/` — `widget_test.dart` (smoke test), `web_backend_test.dart` (web-only)
- `pubspec.yaml`, `pubspec.lock` — dependencies
- `analysis_options.yaml`, `.gitignore`, `README.md`, `.metadata`
- `.tmp_pkg/` — pub cache/temp folder (generated, NOT source — ignore)
- `build/` — generated build artifacts (NOT source)

All `lib/` source files:
- `lib/main.dart` — app entry point, `AttendanceApp`, global `appDatabase`
- `lib/database/app_database.dart` — singleton DB access + all CRUD for students/sessions/attendance
- `lib/database/database_setup.dart` — conditional export (io vs web)
- `lib/database/database_setup_io.dart` — native factory; DB path `%APPDATA%\ECU Attendance\<file>` on Windows
- `lib/database/database_setup_web.dart` — IndexedDB-backed factory for web only
- `lib/models/student.dart`, `session.dart`, `attendance_record.dart`, `import_duplicate.dart`
- `lib/platform/platform_files.dart` (+ `_io`, `_web`) — file seam (app folders, read/write/list/open/share)
- `lib/services/session_service.dart` — attendance-session business logic
- `lib/services/backup_service.dart` — JSON backup/restore/history
- `lib/services/report_service.dart` — Excel + PDF session reports
- `lib/services/import_service.dart` — Excel/PDF/DOCX import parsing
- `lib/services/matching_service.dart` — OCR-text → student matching
- `lib/services/ocr_engine.dart` (+ `_factory`, `_selector_io`, `_selector_web`, `_mobile`, `_windows`, `_web`) — OCR abstraction
- `lib/services/chat_service.dart` — Arabic command parser
- `lib/screens/dashboard.dart`, `student_list.dart`, `take_attendance.dart`, `import_students.dart`, `reports.dart`, `backup.dart`, `chat.dart`

## 4. Feature Inventory (frontend ↔ backend connection)

This is a **single-tier** app: each Flutter screen calls a Dart service directly, which calls `AppDatabase` (SQLite). There is **no HTTP layer, no API, no backend server**.

| # | Feature | Frontend (screen) | Service / backend | DB table | Status | Local or remote |
|---|---------|-------------------|-------------------|----------|--------|-----------------|
| 1 | Dashboard / statistics | `dashboard.dart` | `AppDatabase` directly | students, sessions, attendance_records | Complete | Local |
| 2 | Student list (search + group filter) | `student_list.dart` | `AppDatabase.getStudents` | students | Complete (group picklist hardcoded) | Local |
| 3 | Import students | `import_students.dart` | `ImportService` | students | Partial — Excel works; PDF & DOCX return empty (stubs) | Local file picker |
| 4 | Take attendance | `take_attendance.dart` | `MatchingService` + OCR engine + `SessionService` | sessions, attendance_records | Partial — OCR engines return empty on all platforms (placeholder → forces "needs review"); image pick + manual match + save work | Local |
| 5 | Reports (Excel / PDF export) | `reports.dart` | `ReportService` | sessions, attendance_records | Complete | Local |
| 6 | Backup / restore | `backup.dart` | `BackupService` | all tables | Complete (JSON export/import; merge strategy) | Local |
| 7 | Arabic chat assistant | `chat.dart` | `ChatService` | sessions | Stub — most commands tell user to "do it manually from the screen" | Local |

**Features required by the task brief that are ABSENT from this codebase** (not part of this app's scope; documented, not invented unless explicitly requested):
- User registration / login
- Authentication & sessions (beyond attendance sessions)
- Role-based permissions / admin users
- Admin dashboard (existing "dashboard" is statistics only)
- Groups management UI (groups are free-text strings; hardcoded picklists in two screens)
- Library / file management (beyond import/export of attendance files)
- Notifications service
- Email functionality

## 5. Data Model & Persistence

**Database:** SQLite via `sqflite: ^2.3.0`. Schema version 1 (no migration table or migration strategy exists).

**Tables:**
- `students(id TEXT PK, student_id TEXT, name TEXT, group_name TEXT, source_file TEXT, source_list TEXT, created_at TEXT, status INTEGER DEFAULT 0, UNIQUE(student_id, source_list))`
- `sessions(id TEXT PK, name TEXT, subject TEXT, group_name TEXT, date TEXT, created_at TEXT, status INTEGER DEFAULT 0, image_path TEXT, notes TEXT)`
- `attendance_records(id TEXT PK, session_id TEXT FK→sessions(id), student_id TEXT, student_name TEXT, student_group TEXT, status INTEGER DEFAULT 2, check_in_time TEXT, time_manually_edited INTEGER, time_edited_at TEXT, matched_by TEXT, match_confidence REAL, needs_review INTEGER, review_notes TEXT, created_at TEXT, updated_at TEXT)`

**Persistence location (Windows):**
- Database: `%APPDATA%\ECU Attendance\attendance.db`
- Backups: `%APPDATA%\ECU Attendance\backups\`

## 8. Broken / Incomplete / Duplicated / Obsolete Code

1. **OCR is a placeholder on every platform** — `ocr_engine_windows.dart`, `ocr_engine_mobile.dart`, `ocr_engine_web.dart` all return `OcrResult(text: '', blocks: [], confidence: 0.0)`. Photo-based attendance always falls back to "needs review" manual entry. `ocr_engine_selector_io.dart` imports `ocr_engine_web.dart` unnecessarily.
2. **PDF and DOCX import are stubs** — `_parsePdf()` and `_parseWord()` return empty lists (comment: "we can't run Python here"). Only Excel import (`_parseExcel`) actually parses.
3. **Chat service is mostly stubs** — `copy_attendance`, `cancel_session`, `show_absent` return "do it manually from the screen" messages.
4. **No database migration strategy** — schema is hardcoded at version 1 with no migration path.
5. **`restoreFromBackup` merges without clearing** — repeated restores can duplicate students/sessions; no deduplication beyond `UNIQUE(student_id, source_list)`.
6. **Hardcoded group picklists** in `student_list.dart` and `take_attendance.dart` (GA-1..GA-12, GB-1..GB-8) — not driven by the DB.
7. **`.tmp_pkg/`** — a pub cache temp folder present in the repo; not source, should be gitignored/excluded.
8. **`build/`** — generated build artifacts present in the repo; already in `.gitignore` as `/build/`.
9. App branding is `mathematics` / "نظام حضور الطلاب" — not yet "Mathsmatics" with a unified identity.
10. Test suite is minimal: one widget smoke test + one web-only file test. No Windows desktop, persistence, backup/restore, or regression tests.

## 9. Windows-Specific Observations

- `windows/runner/` C++ host (`main.cpp`, `flutter_window.cpp`, `win32_window.cpp`, `utils.cpp`) builds `mathematics.exe` via CMake.
- `windows/runner/Runner.rc` already references `resources\\app_icon.ico` and sets version info `ProductName = "mathematics"`.
- `windows/CMakeLists.txt` sets `BINARY_NAME "mathematics"`.
- Database and file storage use `%APPDATA%\ECU Attendance\...` on Windows — a suitable persistent user-data location (not temp).
- `flutter doctor` confirms Windows desktop + Visual Studio 2026 are ready to build.

## 10. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Task brief assumes Electron / Node backend; actual stack is Flutter | Plan mismatch documented | Keep Flutter; document why Electron is not used |
| No authentication / authorization | Any local user can access/modify attendance data | Document as out-of-scope; add only if requested |
| OCR + PDF/DOCX import non-functional | "Take attendance from photo" and bulk import degraded | Document limitations; Excel import + manual attendance work |
| No DB migration strategy | Future schema changes risk data loss | Add migration logic before any schema change |
| Backup restore merges (no clear) | Duplicate records on repeated restore | Add optional "replace all" with explicit confirmation |
| Branding inconsistent (`mathematics` vs `Mathsmatics`) | Deliverable naming doesn't match task | Rename app/icon/binary/resources to Mathsmatics |
| `.tmp_pkg/` and `build/` tracked in repo | Repo clutter | Gitignore them (do not delete source) |

## 11. Files Created / Modified / Replaced / Deleted (PHASE 0)

- **Created:** `docs/MATHSMATICS_FULL_PROJECT_AUDIT.md` (this document)
- **Planned:** `docs/MATHSMATICS_WINDOWS_REBUILD_PLAN.md`
- **Modified / Deleted:** none. No source code changed in PHASE 0.

## 12. Proposed Rebuild Direction (summary — full detail in the rebuild plan)

1. Keep Flutter (do not adopt Electron).
2. Rebrand to Mathsmatics (app name, window title, binary, version resources, icon).
3. Verify a clean Windows release build (`flutter build windows`).
4. Confirm persistence location; test backup/restore + data survival across restart.
5. Document OCR/PDF/DOCX/chat limitations; keep existing features working.
6. Package a Windows installer (.exe) + optional portable build; ensure the installer does not erase user data on update.
7. Write `docs/MATHSMATICS_WINDOWS_SETUP.md` and `docs/MATHSMATICS_TEST_REPORT.md` with executed results.

---
*End of audit. Next: `docs/MATHSMATICS_WINDOWS_REBUILD_PLAN.md`.*
- Reports: `%APPDATA%\ECU Attendance\reports\`
- Source: `database_setup_io.dart` and `platform_files_io.dart` resolve `Platform.environment['APPDATA']` + `ECU Attendance`. This is a suitable persistent user-data directory (not temp).

**Backup format:** single JSON file containing `students` + `sessions` arrays (attendance count computed but not stored). Restore merges via `insertStudent`/`insertSession` (conflict = replace); existing data is **not cleared** — deliberate to avoid accidental loss, but repeated restores can duplicate records.

## 6. External Dependencies, CDN & Offline Suitability

All dependencies come from `pub.dev` (hosted). Internet is required **once** for `flutter pub get` / first build; after that the local pub cache satisfies builds. **No CDN fonts, scripts, or stylesheets are loaded at runtime.**

Notable dependencies:
- `sqflite`, `sqflite_common`, `sqflite_common_ffi_web` — SQLite. The `*_web` packages + `web/sqlite3.wasm` + `web/sqflite_sw.js` are **web-only**; Windows desktop uses the native `sqflite` plugin.
- `path_provider`, `path` — file locations.
- `file_picker`, `image_picker`, `open_filex`, `share_plus` — file/image handling.
- `pdf`, `excel` — report generation (pure Dart, offline).
- `google_ml_kit: ^0.13.0` — OCR, **Android-only**; declared but the Windows OCR engine is a placeholder returning empty results. Not used on Windows.
- `intl`, `uuid`, `collection`, `web` — utilities.
- Theme references `fontFamily: 'Cairo'` but **no Cairo font asset is bundled** — falls back to system font (cosmetic).

**Offline verdict:** Core Windows desktop functionality works fully offline after the first `flutter pub get`. No GitHub/Vercel/Render/hosting required. OCR and PDF/DOCX import are non-functional stubs regardless of network.

## 7. Security Configuration

- **Not Electron** → `contextIsolation`, `nodeIntegration`, `sandbox`, `contextBridge`, restricted IPC are N/A (no webview, no Node.js exposed to the UI).
- No network server is opened → **nothing exposed to the public internet**; no localhost port binding exists.
- Local SQLite file is **not encrypted** and there is **no authentication** — any local PC user can read the attendance DB.
- File paths come from `file_picker` (user-selected); no arbitrary path traversal from untrusted input identified in current code.
- No input-sanitization issues beyond the absence of auth.