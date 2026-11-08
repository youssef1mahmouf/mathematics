# MATHSMATICS — WINDOWS SETUP (PHASE 8)

**Project:** Mathsmatics
**Repository root:** `d:\Linux-Transfer\Code\ECU WEB\mathematics`
**Setup doc date:** 2026-11-07

---

## 1. Prerequisites (for building from source)

| Required | Notes |
|----------|-------|
| **Windows 10/11 x64** | Application targets Windows 10/11 (x64). The build toolchain below also requires 64-bit Windows. |
| **Flutter SDK ≥ 3.13** | Installed and on `PATH`. This repo uses SDK `^3.13.4`. |
| **Dart SDK** | Bundled with Flutter. |
| **Visual Studio 2019/2022 (Community OK) with C++ workload** | Provides the MSVC compiler + CMake for the Windows runner. |
| **Internet access** | Needed once to run `flutter pub get` (dependencies). After that, fully offline. |

Verify with:
```powershell
flutter --version
flutter doctor
```

## 2. Clone the repository (if not already local)

```powershell
git clone https://github.com/youssef1mahmouf/mathematics.git "d:\Linux-Transfer\Code\ECU WEB\mathematics"
cd "d:\Linux-Transfer\Code\ECU WEB\mathematics"
```

## 3. Get dependencies (first time only)

```powershell
flutter pub get
```

This downloads packages from pub.dev (or your configured mirror). After the first run, the local pub cache means **`flutter pub get` is a no-op / fast** and the app works fully offline.

## 4. Analyze

```powershell
flutter analyze
```

Clean (no issues) for this repository.

## 5. Run from source (development)

```powershell
flutter run -d windows
```

or, for a faster hot-reload:
```powershell
flutter run -d windows --debug
```

__APPEND_MARKER__

## 6. Build the release Windows application (deliverable)

```powershell
flutter build windows --release
```

Output:
```
build\windows\x64\runner\Release\mathsmatics.exe   (main executable)
build\windows\x64\runner\Release\flutter_windows.dll  (Flutter engine, ~21 MB)
build\windows\x64\runner\Release\sqlite3.dll          (SQLite native lib)
build\windows\x64\runner\Release\...plugin.dll        (plugins: share_plus, file_selector, url_launcher, etc.)
build\windows\x64\runner\Release\data\                (flutter_assets)
```

The release executable is **`build\windows\x64\runner\Release\mathsmatics.exe`**.

## 7. Run the packaged release application

Just double-click **`build\windows\x64\runner\Release\mathsmatics.exe`** (or run it from PowerShell):

```powershell
.\build\windows\x64\runner\Release\mathsmatics.exe
```

The app opens a native Windows window titled **"Mathsmatics"** (Arabic RTL UI).

## 8. Data persistence

All data is stored in a fixed, per-user Windows directory — **not** in `%TEMP%` and not inside the application folder. Data survives closing and reopening the app.

| Data | Location (Windows) |
|------|--------------------|
| SQLite database | `%APPDATA%\Mathsmatics\attendance.db` |
| Backups | `%APPDATA%\Mathsmatics\backups\` |
| Reports | `%APPDATA%\Mathsmatics\reports\` |

To back up the whole application data, copy the `%APPDATA%\Mathsmatics\` folder.

## 9. Windows installer (.exe) — PHASE 8

**Installer tooling note:** No Inno Setup (`iscc`) or NSIS (`makensis`) is installed on this machine, so a pre-built installer `.exe` was not produced during this audit. Two delivery options are supported:

### Option A — Portable build (recommended for immediate use)
No installer needed. The release folder is self-contained and can be copied to any Windows 10/11 x64 machine and run directly:

```powershell
# Copy build\windows\x64\runner\Release folder to e.g. C:\Program Files\Mathsmatics\
cd "C:\Program Files\Mathsmatics"
# (use the mathsmatics.exe inside)
```

User data still goes to `%APPDATA%\Mathsmatics\` (per-user, not bundled).

### Option B — Create a Windows installer (.exe)
1. Install **Inno Setup** (recommended, free): https://jrsoftware.org/isinfo.php
2. Create an `.iss` script such as the one below.
3. Compile with `ISCC /Qp MathsmaticsInstaller.iss`.
4. Run the produced `Setup.exe` to install.

**Sample Inno Setup script** (`MathsmaticsInstaller.iss`):

```ini
[Setup]
AppName=Mathsmatics
AppVersion=1.0.0
DefaultDirName={autopf}\Mathsmatics
DefaultGroupName=Mathsmatics
OutputDir=./dist
OutputBaseFilename=Mathsmatics-Setup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Mathsmatics"; Filename: "{app}\mathsmatics.exe"
Name: "{commondesktop}\Mathsmatics"; Filename: "{app}\mathsmatics.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\mathsmatics.exe"; Description="Launch Mathsmatics"; Flags: nowait postinstall skipifsdoesntexist
```

**Important:** The installer must **not** touch `%APPDATA%\Mathsmatics\` on update, so existing attendance data is preserved. Since the app writes its own data to `%APPDATA%` (not to the install folder), an update/install of the `Mathsmatics` program files cannot overwrite user data. This is guaranteed by the fact that the app reads/writes `%APPDATA%\Mathsmatics\` and the installer only copies the release folder.

## 10. Application identity

| Item | Value |
|------|-------|
| Application name | Mathsmatics |
| Window title | Mathsmatics |
| Binary | `mathsmatics.exe` |
| Icon | `windows\runner\resources\app_icon.ico` (customise to your Mathsmatics icon before building) |
| Current working directory on launch | `%APPDATA%\Mathsmatics\` (data), app folder is read-only assets |

## 11. Offline status

The application is **fully offline-capable** after `flutter pub get`:

- No CDN fonts/scripts/stylesheets loaded at runtime.
- No GitHub, Vercel, Render, or hosting platform required.
- No network sockets are opened at runtime.
- No external domain or browser tab required.
- Local SQLite database (`sqflite`), pure-Dart Excel/PDF report generation, and pure-Dart file handling all work offline.

Network-dependent items (and their status):
- `flutter pub get` / first build: needs internet once.
- `google_ml_kit` (Android OCR): needs the device's ML kit; Windows OCR is a placeholder.
- PDF/DOCX student import: **stubbed** (returns empty) — documented limitation.
- Everything else (dashboard, student list, Excel import, attendance, Excel/PDF reports, backup/restore, chat) works offline.

## 12. Summary of runnable artifacts

| Artifact | Path |
|----------|------|
| Debug (source) | `flutter run -d windows` |
| Release executable | `build\windows\x64\runner\Release\mathsmatics.exe` |
| Portable build | `build\windows\x64\runner\Release\` (copy folder) |
| Installer (if tooling installed) | `Setup.exe` produced by `ISCC MathsmaticsInstaller.iss` |

---
*Produced by PHASE 0–8 of the Mathsmatics Windows rebuild.*