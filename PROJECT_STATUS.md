# Project Status

Last reviewed: 2026-06-15

## Completion

Current completion: 92%

The app is complete enough for a class presentation, local use, and backend-backed development runs. The remaining work is not feature code. It is mostly release ownership: production credentials, signing files, deployment target, and live social-login console setup.

## Done

- Flutter recommendation flow from profile, conditions, matching, result review, save, list, rename, and delete
- Local storage mode and backend storage mode
- NestJS auth, social sign-in verification, user profile sync, timetable persistence, and ownership checks
- Prisma schema and migrations for users, sessions, and saved timetables
- Launcher scripts for local backend + Flutter runs
- Release validation scripts for API URL, signing, native social-login config, and backend env checks
- GitHub Actions CI for Flutter and backend checks
- CodeQL, Dependency Review, and Dependabot configuration
- App launcher icons for Android and iOS

## Not Done

- Production API deployment and HTTPS domain
- `backend/.env.production` with real database and CORS values
- `android/key.properties` and real release keystore
- Real Google, Kakao, and Apple console credentials
- Store-side Android/iOS release validation
- Long-term course data refresh process for future semesters

## Known Risk

- `npm audit --omit=dev` reports a moderate Prisma development-dependency issue through `@hono/node-server`.
- The suggested automatic fix downgrades Prisma to `6.19.3`, so it is not applied here.
- Dependabot is configured to surface the next safe Prisma update.

## Quality Gates

Run these before a release branch is cut:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
cd backend
npm run build
npm run test:e2e
```

For release builds, also run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\validate_release_config.ps1 `
  -ApiBaseUrl https://api.example.com `
  -Target appbundle
```
