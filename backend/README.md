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
- `GET /users/:userId/timetables`
- `POST /users/:userId/timetables`
- `PATCH /users/:userId/timetables/:id`
- `DELETE /users/:userId/timetables/:id`
- Prisma schema and initial SQL migration

## Social token verification

`POST /auth/social-signin` verifies provider tokens on the backend before it creates or restores an app session.
The server no longer trusts `email`, `displayName`, or `providerUserId` sent by the Flutter client.

- Google: requires `idToken`; verifies it with Google's token info endpoint. Set `GOOGLE_CLIENT_IDS` to the accepted OAuth client IDs.
- Kakao: requires `accessToken`; verifies it with Kakao's user API.
- Apple: requires `idToken`; verifies the JWT signature against Apple's public keys. Set `APPLE_AUDIENCES` to the accepted Service ID or bundle ID values.

`GOOGLE_SERVER_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`, `APPLE_SERVICE_ID`, and `APPLE_BUNDLE_ID` are also accepted as compatibility aliases.
When `NODE_ENV=production`, Google and Apple sign-in are rejected if the accepted audience values are not configured.

## Local setup

1. Install dependencies.

```bash
npm install
```

2. Copy the sample env file if needed.

```bash
copy .env.example .env
```

For production deployment, start from:

```bash
copy .env.production.example .env.production
```

Then replace the placeholder values with the real production database and frontend origin.
Also fill the social login verification values if Google or Apple login is enabled.

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

## Test

Run the backend API regression tests with:

```bash
npm run test:e2e
```

These tests run against an in-memory Prisma mock, so PostgreSQL does not need to be running.

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
