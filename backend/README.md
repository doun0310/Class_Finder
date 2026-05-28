# Class Finder Backend

NestJS + Prisma + PostgreSQL backend for timetable persistence.

## What is included

- `POST /auth/signup`
- `POST /auth/signin`
- `POST /auth/social-signin`
- `POST /auth/password-reset`
- `POST /auth/signout`
- `GET /auth/me`
- `PATCH /auth/me`
- `POST /users/sync`
- `GET /users/:userId/timetables`
- `POST /users/:userId/timetables`
- `PATCH /users/:userId/timetables/:id`
- `DELETE /users/:userId/timetables/:id`
- Prisma schema and initial SQL migration

## Local setup

1. Install dependencies.

```bash
npm install
```

2. Copy the sample env file if needed.

```bash
copy .env.example .env
```

3. Start PostgreSQL.

```bash
docker compose up -d
```

4. Apply the migration.

```bash
npx prisma migrate deploy
```

5. Start the API server.

```bash
npm run start:dev
```

The API listens on `http://localhost:3001` by default.

## Auto Start With Flutter

From the repository root, you can start the backend and Flutter together with:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\run_with_backend.ps1
```

For Android emulator runs:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\run_with_backend.ps1 -DeviceId emulator-5554
```

The launcher now performs these steps automatically before `main.dart` starts:

1. `npx prisma migrate deploy`
2. `npm run start:dev`

If PostgreSQL is not running yet, it first tries `docker compose up -d`.

## Flutter connection

Run the Flutter app with `API_BASE_URL` so the timetable repository uses the backend.

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3001
```

For Android emulator, use:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

If `API_BASE_URL` is omitted, the app falls back to local `SharedPreferences` storage.
If `API_BASE_URL` is provided, sign-up, sign-in, session restore, profile update, and timetable persistence all use the backend.
