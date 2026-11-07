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
- `lib/screens/dashboard.dart`, `student_list.dart`, `take_attendance.dart`, `import_students.dart`, `reports.dart`, `backup.dart`, `chat.dart
