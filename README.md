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

## VS Code

VS Code launch profiles are included in `.vscode/launch.json`.

- `Flutter main.dart + Backend (Localhost)`
- `Flutter main.dart + Backend (Android Emulator)`

Both profiles start the backend first through `.vscode/tasks.json`.
That pre-launch step now includes Prisma migration deployment automatically.

## Limitation

The Flutter app itself cannot reliably spawn a local NestJS process on Android/iOS. That is why the automatic server boot is implemented as a local development launcher script instead of logic inside `main.dart`. For production, the backend should be deployed separately and the app should point to that hosted API.
