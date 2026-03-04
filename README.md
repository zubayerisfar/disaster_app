# Prantik — Disaster Management App (Bangladesh)

Prantik is a Flutter-based disaster support app designed for Bangladesh context.  
It combines weather risk signals, shelter discovery, emergency contacts, disaster guidelines, volunteer support, notifications, and safety-focused tools in one place.

---

## What this app does

- Shows live weather status and warning signals
- Provides 7-day forecast for user location/district
- Finds nearest shelters with map + list view
- Offers emergency contact lookup (division → district → upazila)
- Includes disaster preparedness guidelines (cyclone, flood, fire, etc.)
- Supports volunteer registration and volunteer-added shelter entries
- Sends local emergency notifications based on warning level
- Includes women & children safety support flows
- Includes agriculture/plant disease support module

---

## Tech stack

- **Framework:** Flutter (Dart)
- **State management:** Provider
- **Maps:** flutter_map + OpenStreetMap tiles
- **Location:** geolocator
- **Local storage:** shared_preferences
- **Networking:** http
- **Media:** video_player, audioplayers
- **Notifications:** flutter_local_notifications

---

## Project structure (important folders)

```text
lib/
	main.dart                 # App entry + provider wiring + page shell
	home_page.dart            # Main dashboard
	shelter_page.dart         # Shelter map/list
	contacts_page.dart        # Emergency contacts
	guidelines_page.dart      # Preparedness and response guidance
	volunteer_page.dart       # Volunteer features
	women_safety_page.dart    # Women & children safety module
	krishok_page.dart         # Agriculture / plant disease module
	notifications_page.dart   # Admin/user notification feed
	settings_page.dart        # Settings
	profile_page.dart         # Family profile
	providers/                # UI state controllers
	services/                 # API, storage, and platform logic
	models/                   # Data entities
	widgets/                  # Reusable UI components
```

---

## Getting started (local setup)

### 1) Prerequisites

- Flutter SDK installed
- Android Studio / VS Code setup for Flutter
- A device/emulator

Check installation:

```bash
flutter doctor
```

### 2) Install packages

```bash
flutter pub get
```

### 3) Run app

```bash
flutter run
```

---

## Configuration notes

### API key setup

Weather/API secrets are managed from:

- `lib/config/secrets.dart`

If weather API key is missing/invalid, app may fallback to demo/offline-style data in some flows.

### Windows note (if Flutter commands fail)

If you see plugin/symlink issues on Windows, enable **Developer Mode**:

```powershell
start ms-settings:developers
```

---

## Build and quality checks

```bash
flutter analyze
flutter test
```

> If no tests exist yet for some modules, `flutter test` may run minimal/default test suites.

---

## Design and language

- Primary UI language is Bangla for user-facing text.
- UX is focused on fast access during emergencies.
- Navigation combines bottom bar + drawer for quick feature reach.

---

## Current status

This is an actively developed multi-feature disaster app.  
The codebase includes both core disaster-response features and extended domain modules (women safety, agriculture support).

---

## Contribution

If you are contributing:

1. Keep feature logic separated in `providers/` and `services/`
2. Avoid hardcoding sensitive values in UI code
3. Prefer small, focused pull requests
4. Update documentation when adding/changing features

---

## License

No license file is currently defined in this repository.
If you plan to distribute this project publicly, add a proper `LICENSE` file.
