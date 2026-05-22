# Team Teleprompter

A professional teleprompter app for content creation teams built with Flutter and Firebase.

## Project Status

✅ Week 1 Setup Complete  
✅ Week 2 Authentication Complete

🟨 Week 3 Script Management In Progress

**Latest Milestone:** Full authentication system with team management

- Flutter project initialized
- Firebase configured for iOS, Android, and Web
- All dependencies installed
- Complete auth flow (email, Google, Apple)
- User and team management
- Riverpod state management
- Navigation with Go Router
- Script feature modules scaffolded (providers, repositories, screens)
- Code generation restored for Freezed/JSON models

**See:** [WEEK2_COMPLETE.md](WEEK2_COMPLETE.md) for detailed implementation summary

### Health Snapshot (May 21, 2026)
- `flutter analyze`: 0 errors, 0 warnings, 0 info
- Remaining production work is feature completeness (Weeks 3-10), not compile stability

## Quick Start

### Run the App

```bash
flutter run
```

### Test Firebase Connection

The app currently displays a welcome screen that confirms Firebase initialization.

## Project Structure

```
team_teleprompter/
├── docs/                      # Complete documentation
│   ├── PRODUCT_SPEC.md        # Product requirements
│   ├── FIREBASE_SETUP.md      # Firebase configuration guide
│   ├── ARCHITECTURE.md        # Technical architecture
│   ├── IMPLEMENTATION_GUIDE.md # Code samples and implementation
│   └── BUILD_TIMELINE.md      # 10-week development plan
├── lib/                       # Flutter application code
│   ├── main.dart              # App entry point with Firebase init
│   └── firebase_options.dart  # Firebase configuration
├── android/                   # Android platform code
├── ios/                       # iOS platform code
├── web/                       # Web platform code
├── assets/                    # Images, icons, fonts
└── test/                      # Test files
```

## Firebase Configuration

**Project ID:** team-teleprompter  
**Bundle ID:** com.wordnerd.teamteleprompter  
**Project URL:** https://console.firebase.google.com/u/0/project/team-teleprompter

### Services Enabled
- ✅ Authentication (Email/Password, Google, Apple Sign-In)
- ✅ Cloud Firestore
- ✅ Cloud Storage
- 🔲 Cloud Functions (will enable in Phase 2)

## Development

### Week 1: Foundation ✅
- [x] Firebase project setup
- [x] Flutter project initialization
- [x] Dependencies installed
- [x] Basic app structure

### Week 2: Authentication ✅
- [x] Implement authentication flow
- [x] Create user and team models
- [x] Build login/signup screens
- [x] Set up team management
- [x] Riverpod state management
- [x] Navigation with Go Router

### Next Steps (Week 3)
- [x] Create script repository
- [x] Build script editor screen
- [x] Implement script list view
- [~] Add offline support with Hive (services present, needs full validation)
- [ ] Real-time script sync

## Tech Stack

- **Framework:** Flutter 3.44.0
- **Language:** Dart 3.12.0
- **Backend:** Firebase
- **State Management:** Riverpod
- **Local Storage:** Hive
- **Authentication:** Firebase Auth (Email, Google, Apple)

## Team Roles

- **Publisher:** Manages and publishes scripts
- **Editor:** Writes and edits scripts
- **Creator:** Records content with teleprompter

## Key Features (Planned)

1. **Centralized Script Library** - All team scripts in one place
2. **Real-Time Collaboration** - Live script updates across devices
3. **Professional Teleprompter** - Smooth 60 FPS scrolling
4. **Voice Auto-Scroll** - Follows your voice automatically
5. **Remote Control** - Producer controls creator's prompter
6. **Recording Integration** - Record while reading

## Documentation

All comprehensive documentation is in the `/docs` folder:

- **[Product Specification](docs/PRODUCT_SPEC.md)** - Full feature list and requirements
- **[Firebase Setup](docs/FIREBASE_SETUP.md)** - Detailed Firebase configuration
- **[Architecture](docs/ARCHITECTURE.md)** - Technical design and patterns
- **[Implementation Guide](docs/IMPLEMENTATION_GUIDE.md)** - Code samples and examples
- **[Build Timeline](docs/BUILD_TIMELINE.md)** - 10-week development schedule

## Commands

```bash
# Run app
flutter run

# Run tests
flutter test

# Build for production
flutter build apk            # Android
flutter build ipa            # iOS
flutter build web            # Web

# Code generation (when adding models)
flutter pub run build_runner build --delete-conflicting-outputs

# Check for outdated packages
flutter pub outdated

# Update dependencies
flutter pub upgrade
```

## Environment

This project is set up in a GitHub Codespace with:
- Flutter SDK installed at `/workspaces/flutter`
- PATH configured automatically
- All development tools ready

## Getting Help

- **Flutter Documentation:** https://docs.flutter.dev
- **Firebase Documentation:** https://firebase.google.com/docs
- **Riverpod Documentation:** https://riverpod.dev

## License

Private project - All rights reserved

---

**Ready to build!** 🚀 Follow the [Build Timeline](docs/BUILD_TIMELINE.md) for the next steps.

A teleprompting app for news and events
