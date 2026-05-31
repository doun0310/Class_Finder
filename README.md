# Class Finder

Flutter timetable recommendation app with a local NestJS backend for saved timetables.

## Quick Start

For ordinary Flutter-only runs:

```bash
flutter run
```

For local development with the backend started automatically:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\run_with_backend.ps1
```

If you are using an Android emulator:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\run_with_backend.ps1 -DeviceId emulator-5554
```

The script starts the NestJS server if it is not already running, waits for `http://127.0.0.1:3001/health`, then launches `lib/main.dart` with `API_BASE_URL`.
When `API_BASE_URL` is set, authentication and saved timetables use the backend instead of local-only storage.
Before Flutter starts, the launcher also runs `npx prisma migrate deploy` and then starts the backend. If PostgreSQL is not up, it first tries `docker compose up -d` inside `backend`.

For release validation and builds:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\validate_release_config.ps1 -ApiBaseUrl https://api.example.com
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_release.ps1 -ApiBaseUrl https://api.example.com -Target appbundle
```

Production Android builds also require `android/key.properties`. Start from `android/key.properties.example` and point `storeFile` to your real upload keystore.

If you only need a local smoke build before the release keystore is ready, add `-AllowDebugSigning`. That option should not be used for store distribution.

If you need to generate native social-login callback settings without building yet:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\configure_social_login.ps1
```

## Storage Modes

- `flutter run`
  - Local storage mode
  - Sign-in and saved timetables stay on the current device only
- `tool/run_with_backend.ps1` or `API_BASE_URL`
  - Backend storage mode
  - Sign-in and saved timetables use the NestJS API and PostgreSQL

The login and sign-up screens also show the current mode so you can see immediately whether the app is running in local-only mode or server-backed mode.

## VS Code

VS Code launch profiles are included in `.vscode/launch.json`.

- `Flutter main.dart + Backend (Localhost)`
- `Flutter main.dart + Backend (Android Emulator)`

Both profiles start the backend first through `.vscode/tasks.json`.
That pre-launch step now includes Prisma migration deployment automatically.

## Verification

Flutter:

```bash
flutter analyze
flutter test
```

Backend:

```bash
cd backend
npm run build
npm run test:e2e
```

GitHub Actions runs the same checks from `.github/workflows/ci.yml`.

More detailed production steps are documented in [RELEASE_CHECKLIST.md](/D:/Class_Finder/RELEASE_CHECKLIST.md) and [SOCIAL_LOGIN_SETUP.md](/D:/Class_Finder/SOCIAL_LOGIN_SETUP.md).

## Limitation

The Flutter app itself cannot reliably spawn a local NestJS process on Android/iOS. That is why the automatic server boot is implemented as a local development launcher script instead of logic inside `main.dart`. For production, the backend should be deployed separately and the app should point to that hosted API.
