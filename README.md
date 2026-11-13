# AgendaWise

AgendaWise is an offline-first Android app that combines alarms, tasks and a calendar. Its alarms are hard to snooze by reflex.

- **Linked planning:** a task with a due date automatically creates a calendar event and, if you want one, a linked alarm.
- **Snooze protection:** an alarm can have an optional snooze limit and one of four challenges (maths, memory, phrase or shake). Stop only works once the challenge is solved.
- **Adaptive difficulty:** challenges get harder or easier from level 1 to 5, based on your last 10 attempts.
- **Voice input:** speech is parsed on the device into a task, alarm or event, and nothing is saved until you confirm it.
- **Privacy:** all planner data stays in a local SQLite database. Optional Firebase accounts are used only for sign-in and a content-free activity log.

## Tech stack

Flutter (Dart ^3.9), Material 3, Riverpod, go_router, Drift (SQLite), alarm, flutter_local_notifications, speech_to_text, sensors_plus, Firebase Auth and Cloud Firestore.

The app targets Android 7.0 or later (minSdk 24).

## Project structure

```
lib/
  core/       database, router, theme, platform services, cloud
  shared/     reusable widgets
  features/   alarms, challenges, difficulty, tasks, calendar, categories,
              integration, voice, account, admin, backup, profile, settings
test/         unit and integration tests (in-memory SQLite)
android/      Android project, including Kotlin MethodChannels
```

## Getting started

### Prerequisites

- The Flutter SDK (stable channel) and the Android SDK
- An Android phone or emulator
- Optional, only for online accounts: a Firebase project with Email/Password sign-in turned on and a Firestore database

### Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates the Drift code
```

### Firebase (optional)

```bash
flutterfire configure --platforms=android    # creates lib/firebase_options.dart and google-services.json
firebase deploy --only firestore             # deploys firestore.rules and firestore.indexes.json
```

The first superadmin is created by hand in the Firebase console. Add a document at `config/superadmin` with the fields `uid` (string) and `lastActiveAt` (timestamp).

### Run and test

```bash
flutter run        # on a connected device
flutter analyze
flutter test
```

## Permissions

On first use the app asks for exact alarms, notifications and the microphone, each after a short explanation. For reliable alarms, also allow full-screen alarms and "Display over other apps", and exclude AgendaWise from battery optimisation. The Profile screen shows a reliability checklist for all of these.

## Notes

- Everything except creating an account and signing in works without internet.
- Backing up and restoring data (a JSON file) requires being signed in.
- This is an academic project (BSc IT, 3rd year).
