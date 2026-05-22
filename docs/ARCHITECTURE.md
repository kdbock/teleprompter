# Flutter Architecture & Project Structure

Complete technical architecture for the Team Teleprompter app.

---

## 1. Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Flutter Apps                           │
│              (iOS, Android, Web*)                       │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Prompter UI │  │  Editor UI   │  │  Control UI  │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                  │                  │          │
│  ┌──────┴──────────────────┴──────────────────┴──────┐ │
│  │         State Management (Riverpod)                │ │
│  └──────┬──────────────────────────────────────┬─────┘ │
│         │                                       │        │
│  ┌──────┴───────────┐              ┌──────────┴─────┐ │
│  │  Business Logic  │              │  Local Storage │ │
│  │   (Services)     │              │    (Hive)      │ │
│  └──────┬───────────┘              └────────────────┘ │
│         │                                               │
└─────────┼───────────────────────────────────────────────┘
          │
   ┌──────┴──────┐
   │   Firebase   │
   ├─────────────┤
   │ Auth        │
   │ Firestore   │
   │ Storage     │
   │ Functions   │
   └─────────────┘
```

### 1.2 Architecture Principles

1. **Offline-First:** App works fully offline, syncs when online
2. **Reactive State:** UI rebuilds automatically on data changes
3. **Separation of Concerns:** Clear boundaries between UI, logic, and data
4. **Testable:** Business logic isolated from UI and Firebase
5. **Performance:** Lazy loading, pagination, efficient rebuilds

---

## 2. Flutter Project Structure

```
teleprompter/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── route_constants.dart
│   │   │   └── style_constants.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── prompter_theme.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   └── utils/
│   │       ├── logger.dart
│   │       ├── validators.dart
│   │       └── formatters.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── signup_screen.dart
│   │   │   └── widgets/
│   │   │       └── auth_form.dart
│   │   │
│   │   ├── scripts/
│   │   │   ├── models/
│   │   │   │   ├── script_model.dart
│   │   │   │   └── script_version_model.dart
│   │   │   ├── providers/
│   │   │   │   ├── scripts_provider.dart
│   │   │   │   └── script_editor_provider.dart
│   │   │   ├── repositories/
│   │   │   │   └── scripts_repository.dart
│   │   │   ├── screens/
│   │   │   │   ├── scripts_library_screen.dart
│   │   │   │   ├── script_editor_screen.dart
│   │   │   │   └── script_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── script_card.dart
│   │   │       ├── script_search_bar.dart
│   │   │       └── version_history_list.dart
│   │   │
│   │   ├── prompter/
│   │   │   ├── models/
│   │   │   │   └── prompter_settings_model.dart
│   │   │   ├── providers/
│   │   │   │   ├── prompter_provider.dart
│   │   │   │   └── scroll_controller_provider.dart
│   │   │   ├── services/
│   │   │   │   ├── voice_recognition_service.dart
│   │   │   │   └── scroll_engine.dart
│   │   │   ├── screens/
│   │   │   │   ├── prompter_screen.dart
│   │   │   │   └── prompter_settings_screen.dart
│   │   │   └── widgets/
│   │   │       ├── prompter_text_display.dart
│   │   │       ├── prompter_controls.dart
│   │   │       └── speed_slider.dart
│   │   │
│   │   ├── remote_control/
│   │   │   ├── models/
│   │   │   │   └── control_session_model.dart
│   │   │   ├── providers/
│   │   │   │   └── remote_control_provider.dart
│   │   │   ├── services/
│   │   │   │   └── remote_sync_service.dart
│   │   │   ├── screens/
│   │   │   │   ├── control_panel_screen.dart
│   │   │   │   └── active_sessions_screen.dart
│   │   │   └── widgets/
│   │   │       └── remote_control_widget.dart
│   │   │
│   │   ├── recording/
│   │   │   ├── models/
│   │   │   │   └── recording_model.dart
│   │   │   ├── providers/
│   │   │   │   └── recording_provider.dart
│   │   │   ├── services/
│   │   │   │   └── camera_service.dart
│   │   │   ├── screens/
│   │   │   │   └── recording_screen.dart
│   │   │   └── widgets/
│   │   │       └── recording_controls.dart
│   │   │
│   │   └── team/
│   │       ├── models/
│   │       │   ├── team_model.dart
│   │       │   └── team_member_model.dart
│   │       ├── providers/
│   │       │   └── team_provider.dart
│   │       ├── repositories/
│   │       │   └── team_repository.dart
│   │       ├── screens/
│   │       │   ├── team_settings_screen.dart
│   │       │   └── team_members_screen.dart
│   │       └── widgets/
│   │           └── member_card.dart
│   │
│   └── shared/
│       ├── models/
│       │   └── base_model.dart
│       ├── widgets/
│       │   ├── loading_indicator.dart
│       │   ├── error_view.dart
│       │   └── empty_state.dart
│       └── services/
│           ├── local_storage_service.dart
│           ├── sync_service.dart
│           └── notification_service.dart
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── assets/
│   ├── images/
│   ├── fonts/
│   └── icons/
│
├── firebase/
│   ├── firestore.rules
│   ├── storage.rules
│   └── firestore.indexes.json
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 3. State Management with Riverpod

### 3.1 Why Riverpod?

- **Compile-safe:** Catches errors at compile time
- **Testable:** Easy to mock providers
- **No BuildContext:** Access providers anywhere
- **Auto-dispose:** Cleans up unused state
- **DevTools:** Great debugging support

### 3.2 Provider Types Used

```dart
// Simple state
final counterProvider = StateProvider<int>((ref) => 0);

// Async data from Firebase
final scriptsProvider = StreamProvider<List<Script>>((ref) {
  final repo = ref.watch(scriptsRepositoryProvider);
  return repo.watchScripts();
});

// Stateful logic
final prompterProvider = StateNotifierProvider<PrompterNotifier, PrompterState>((ref) {
  return PrompterNotifier();
});

// Computed state
final filteredScriptsProvider = Provider<List<Script>>((ref) {
  final scripts = ref.watch(scriptsProvider).value ?? [];
  final filter = ref.watch(scriptFilterProvider);
  return scripts.where((s) => s.status == filter).toList();
});
```

### 3.3 Example: Auth Provider

```dart
// lib/features/auth/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Current user provider
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  
  if (authState.value == null) {
    yield null;
    return;
  }
  
  final userId = authState.value!.uid;
  final userRepo = ref.watch(userRepositoryProvider);
  
  yield* userRepo.watchUser(userId);
});

// Is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});
```

---

## 4. Data Models

### 4.1 Base Model with JSON Serialization

```dart
// lib/shared/models/base_model.dart

abstract class BaseModel {
  String get id;
  DateTime get createdAt;
  DateTime get updatedAt;
  
  Map<String, dynamic> toJson();
  
  BaseModel copyWith();
}
```

### 4.2 Script Model

```dart
// lib/features/scripts/models/script_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'script_model.freezed.dart';
part 'script_model.g.dart';

@freezed
class Script with _$Script {
  const factory Script({
    required String id,
    required String teamId,
    required String title,
    required String content,
    required ScriptStatus status,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? publishedBy,
    DateTime? publishedAt,
    @Default([]) List<String> tags,
    String? category,
    @Default(1) int version,
    @Default(0) int estimatedDuration,
    @Default(0) int wordCount,
    @Default(ScriptMetadata()) ScriptMetadata metadata,
  }) = _Script;
  
  factory Script.fromJson(Map<String, dynamic> json) => _$ScriptFromJson(json);
  
  factory Script.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Script.fromJson({...data, 'id': doc.id});
  }
  
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document
    return json;
  }
}

@freezed
class ScriptMetadata with _$ScriptMetadata {
  const factory ScriptMetadata({
    @Default(24.0) double fontSize,
    @Default(1.0) double scrollSpeed,
    @Default(false) bool voiceEnabled,
    @Default(1.5) double lineHeight,
  }) = _ScriptMetadata;
  
  factory ScriptMetadata.fromJson(Map<String, dynamic> json) =>
      _$ScriptMetadataFromJson(json);
}

enum ScriptStatus {
  draft,
  published,
  archived,
}
```

### 4.3 User Model

```dart
// lib/features/auth/models/user_model.dart

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String displayName,
    required UserRole role,
    required String teamId,
    String? avatarUrl,
    required DateTime createdAt,
    required DateTime lastActive,
  }) = _UserModel;
  
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

enum UserRole {
  publisher,
  editor,
  creator,
}
```

---

## 5. Repository Pattern

### 5.1 Base Repository

```dart
// lib/shared/repositories/base_repository.dart

abstract class BaseRepository<T> {
  // Read operations
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Stream<T?> watchById(String id);
  Stream<List<T>> watchAll();
  
  // Write operations
  Future<String> create(T item);
  Future<void> update(String id, T item);
  Future<void> delete(String id);
}
```

### 5.2 Scripts Repository

```dart
// lib/features/scripts/repositories/scripts_repository.dart

class ScriptsRepository implements BaseRepository<Script> {
  final FirebaseFirestore _firestore;
  final String _collection = 'scripts';
  
  ScriptsRepository(this._firestore);
  
  CollectionReference<Script> get _scriptsRef {
    return _firestore.collection(_collection).withConverter<Script>(
      fromFirestore: (snapshot, _) => Script.fromFirestore(snapshot),
      toFirestore: (script, _) => script.toFirestore(),
    );
  }
  
  // Watch all scripts for a team
  Stream<List<Script>> watchTeamScripts(String teamId) {
    return _scriptsRef
        .where('teamId', isEqualTo: teamId)
        .where('status', whereIn: [ScriptStatus.draft, ScriptStatus.published])
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  
  // Watch single script
  Stream<Script?> watchScript(String scriptId) {
    return _scriptsRef
        .doc(scriptId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
  
  // Create new script
  Future<String> createScript(Script script) async {
    final docRef = await _scriptsRef.add(script);
    return docRef.id;
  }
  
  // Update script
  Future<void> updateScript(String scriptId, Script script) async {
    await _scriptsRef.doc(scriptId).update(script.toFirestore());
  }
  
  // Publish script
  Future<void> publishScript(String scriptId, String userId) async {
    await _scriptsRef.doc(scriptId).update({
      'status': ScriptStatus.published.name,
      'publishedBy': userId,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Search scripts
  Future<List<Script>> searchScripts(String teamId, String query) async {
    // Note: For full-text search, consider Algolia or Typesense
    // This is a simple contains search
    final snapshot = await _scriptsRef
        .where('teamId', isEqualTo: teamId)
        .get();
    
    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => doc.data())
        .where((script) =>
            script.title.toLowerCase().contains(lowerQuery) ||
            script.content.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

// Provider
final scriptsRepositoryProvider = Provider<ScriptsRepository>((ref) {
  return ScriptsRepository(FirebaseFirestore.instance);
});
```

---

## 6. Offline-First Architecture

### 6.1 Local Storage with Hive

```dart
// lib/shared/services/local_storage_service.dart

import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const String _scriptsBox = 'scripts';
  static const String _settingsBox = 'settings';
  
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(ScriptAdapter());
    Hive.registerAdapter(PrompterSettingsAdapter());
    
    // Open boxes
    await Hive.openBox<Script>(_scriptsBox);
    await Hive.openBox(_settingsBox);
  }
  
  // Scripts cache
  Box<Script> get scriptsBox => Hive.box<Script>(_scriptsBox);
  
  Future<void> cacheScript(Script script) async {
    await scriptsBox.put(script.id, script);
  }
  
  Script? getCachedScript(String id) {
    return scriptsBox.get(id);
  }
  
  List<Script> getAllCachedScripts() {
    return scriptsBox.values.toList();
  }
}

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});
```

### 6.2 Sync Service

```dart
// lib/shared/services/sync_service.dart

class SyncService {
  final ScriptsRepository _repository;
  final LocalStorageService _localStorage;
  
  SyncService(this._repository, this._localStorage);
  
  // Sync scripts from Firebase to local
  Future<void> syncScripts(String teamId) async {
    try {
      final scripts = await _repository.getTeamScripts(teamId);
      
      for (final script in scripts) {
        await _localStorage.cacheScript(script);
      }
    } catch (e) {
      // Handle offline
      print('Sync failed, using cached data');
    }
  }
  
  // Push local changes to Firebase
  Future<void> pushPendingChanges() async {
    // Implementation for offline-first sync
  }
}
```

---

## 7. Real-Time Sync

### 7.1 Remote Control Service

```dart
// lib/features/remote_control/services/remote_sync_service.dart

class RemoteSyncService {
  final FirebaseFirestore _firestore;
  StreamSubscription? _sessionSubscription;
  
  RemoteSyncService(this._firestore);
  
  // Start listening to control commands
  Stream<ControlCommand> listenToCommands(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          return ControlCommand.fromJson(data?['latestCommand'] ?? {});
        });
  }
  
  // Send control command
  Future<void> sendCommand(String sessionId, ControlCommand command) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'latestCommand': command.toJson(),
      'commandTimestamp': FieldValue.serverTimestamp(),
    });
  }
  
  // Update scroll position (from prompter)
  Future<void> updateScrollPosition(String sessionId, double position) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'scrollPosition': position,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }
}
```

---

## 8. Performance Optimization

### 8.1 Pagination

```dart
// Paginated scripts provider
final paginatedScriptsProvider = StateNotifierProvider<PaginatedScriptsNotifier, PaginatedScriptsState>((ref) {
  final repository = ref.watch(scriptsRepositoryProvider);
  return PaginatedScriptsNotifier(repository);
});

class PaginatedScriptsNotifier extends StateNotifier<PaginatedScriptsState> {
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  
  PaginatedScriptsNotifier(this._repository) : super(PaginatedScriptsState.initial());
  
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final scripts = await _repository.getScriptsPaginated(
        pageSize: _pageSize,
        startAfter: _lastDocument,
      );
      
      state = state.copyWith(
        scripts: [...state.scripts, ...scripts],
        isLoading: false,
        hasMore: scripts.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

### 8.2 Image Caching

```dart
// Use cached_network_image for avatars and thumbnails
CachedNetworkImage(
  imageUrl: user.avatarUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.person),
  cacheKey: user.id,
  memCacheHeight: 200,
  memCacheWidth: 200,
)
```

---

## 9. Error Handling

### 9.1 Global Error Handler

```dart
// lib/core/utils/error_handler.dart

class AppError {
  final String message;
  final String? code;
  final dynamic originalError;
  
  AppError(this.message, {this.code, this.originalError});
  
  static AppError fromFirebaseException(FirebaseException e) {
    return AppError(
      _getFirebaseErrorMessage(e.code),
      code: e.code,
      originalError: e,
    );
  }
  
  static String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You don\'t have permission to access this resource';
      case 'not-found':
        return 'Resource not found';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
```

---

## 10. Testing Strategy

### 10.1 Unit Tests

```dart
// test/unit/scripts_repository_test.dart

void main() {
  late ScriptsRepository repository;
  late MockFirebaseFirestore mockFirestore;
  
  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    repository = ScriptsRepository(mockFirestore);
  });
  
  test('createScript returns script ID', () async {
    final script = Script(...);
    final id = await repository.createScript(script);
    
    expect(id, isNotEmpty);
  });
}
```

### 10.2 Widget Tests

```dart
// test/widget/script_card_test.dart

void main() {
  testWidgets('ScriptCard displays title and updated time', (tester) async {
    final script = Script(title: 'Test Script', ...);
    
    await tester.pumpWidget(
      MaterialApp(
        home: ScriptCard(script: script),
      ),
    );
    
    expect(find.text('Test Script'), findsOneWidget);
  });
}
```

---

## 11. Build & Deployment

### 11.1 Build Commands

```bash
# Development build
flutter run --flavor dev

# Production build iOS
flutter build ipa --release --flavor prod

# Production build Android
flutter build appbundle --release --flavor prod
```

### 11.2 CI/CD with GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build and Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test
      
  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
```

---

## Next Steps

1. Initialize Flutter project
2. Set up dependencies and Riverpod
3. Implement core data models
4. Build repository layer
5. Create first feature (Auth)
