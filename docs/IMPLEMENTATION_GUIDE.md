# Feature Implementation Guide

Detailed implementation guide with code samples for all core features.

---

## 1. Project Initialization

### 1.1 Create Flutter Project

```bash
cd /workspaces
flutter create teleprompter --org com.yourteam --platforms ios,android

cd teleprompter
```

### 1.2 Update pubspec.yaml

```yaml
name: teleprompter
description: Team-based teleprompter for content creators
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # JSON Serialization
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # UI Components
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1
  flutter_svg: ^2.0.9
  
  # Utilities
  intl: ^0.18.1
  uuid: ^4.3.3
  connectivity_plus: ^5.0.2
  permission_handler: ^11.2.0
  
  # Auth
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^5.0.0
  
  # Voice Recognition
  speech_to_text: ^6.5.1
  
  # Camera/Recording
  camera: ^0.10.5+9
  video_player: ^2.8.2
  path_provider: ^2.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  
  # Code Generation
  build_runner: ^2.4.8
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.9
  hive_generator: ^2.0.1
  
  # Testing
  mockito: ^5.4.4

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
  
  fonts:
    - family: PrompterMono
      fonts:
        - asset: assets/fonts/RobotoMono-Regular.ttf
        - asset: assets/fonts/RobotoMono-Bold.ttf
          weight: 700
```

### 1.3 Run Code Generation

```bash
# Install dependencies
flutter pub get

# Run build runner
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 2. Feature: Authentication

### 2.1 Auth Repository

```dart
// lib/features/auth/repositories/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  
  AuthRepository(
    this._firebaseAuth,
    this._googleSignIn,
  );
  
  // Auth state stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  // Current user
  User? get currentUser => _firebaseAuth.currentUser;
  
  // Email/Password Sign In
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Email/Password Sign Up
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(displayName);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }
  
  // Apple Sign In
  Future<UserCredential> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      
      return await _firebaseAuth.signInWithCredential(oauthCredential);
    } catch (e) {
      throw Exception('Apple sign in failed: $e');
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
  
  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    GoogleSignIn(),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
```

### 2.2 Login Screen

```dart
// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Icon(
                    Icons.play_circle_outline,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Team Teleprompter',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Sign in button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Google sign in
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Sign in with Google'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sign up link
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/signup');
                    },
                    child: const Text('Don\'t have an account? Sign up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 3. Feature: Script Management

### 3.1 Scripts Provider

```dart
// lib/features/scripts/providers/scripts_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scripts_provider.g.dart';

// Watch all team scripts
@riverpod
Stream<List<Script>> teamScripts(TeamScriptsRef ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  
  final repository = ref.watch(scriptsRepositoryProvider);
  return repository.watchTeamScripts(user.teamId);
}

// Watch single script
@riverpod
Stream<Script?> script(ScriptRef ref, String scriptId) {
  final repository = ref.watch(scriptsRepositoryProvider);
  return repository.watchScript(scriptId);
}

// Filter scripts
@riverpod
List<Script> filteredScripts(FilteredScriptsRef ref) {
  final scripts = ref.watch(teamScriptsProvider).value ?? [];
  final filter = ref.watch(scriptFilterProvider);
  final searchQuery = ref.watch(scriptSearchQueryProvider);
  
  var filtered = scripts;
  
  // Filter by status
  if (filter != ScriptFilter.all) {
    filtered = filtered.where((s) {
      switch (filter) {
        case ScriptFilter.published:
          return s.status == ScriptStatus.published;
        case ScriptFilter.drafts:
          return s.status == ScriptStatus.draft;
        case ScriptFilter.mine:
          final currentUserId = ref.read(authStateProvider).value?.uid;
          return s.createdBy == currentUserId;
        default:
          return true;
      }
    }).toList();
  }
  
  // Filter by search query
  if (searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    filtered = filtered.where((s) {
      return s.title.toLowerCase().contains(query) ||
             s.content.toLowerCase().contains(query) ||
             s.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }
  
  return filtered;
}

// Script filter state
enum ScriptFilter { all, published, drafts, mine }

final scriptFilterProvider = StateProvider<ScriptFilter>((ref) {
  return ScriptFilter.all;
});

final scriptSearchQueryProvider = StateProvider<String>((ref) => '');

// Script actions
@riverpod
class ScriptActions extends _$ScriptActions {
  @override
  FutureOr<void> build() {}
  
  Future<String> createScript(Script script) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(scriptsRepositoryProvider);
      final id = await repository.createScript(script);
      
      state = const AsyncData(null);
      return id;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
  
  Future<void> updateScript(String scriptId, Script script) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(scriptsRepositoryProvider);
      await repository.updateScript(scriptId, script);
      
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
  
  Future<void> publishScript(String scriptId) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(scriptsRepositoryProvider);
      final userId = ref.read(authStateProvider).value!.uid;
      await repository.publishScript(scriptId, userId);
      
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
  
  Future<void> deleteScript(String scriptId) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(scriptsRepositoryProvider);
      await repository.deleteScript(scriptId);
      
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}
```

### 3.2 Script Library Screen

```dart
// lib/features/scripts/screens/scripts_library_screen.dart

class ScriptsLibraryScreen extends ConsumerWidget {
  const ScriptsLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scriptsAsync = ref.watch(teamScriptsProvider);
    final filter = ref.watch(scriptFilterProvider);
    final searchQuery = ref.watch(scriptSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scripts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search scripts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(scriptSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(scriptSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ScriptFilter.values.map((f) {
                final isSelected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getFilterLabel(f)),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(scriptFilterProvider.notifier).state = f;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Scripts list
          Expanded(
            child: scriptsAsync.when(
              data: (scripts) {
                final filtered = ref.watch(filteredScriptsProvider);
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No scripts found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first script to get started',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final script = filtered[index];
                    return ScriptCard(
                      script: script,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/script-detail',
                          arguments: script.id,
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/script-editor'),
        icon: const Icon(Icons.add),
        label: const Text('New Script'),
      ),
    );
  }

  String _getFilterLabel(ScriptFilter filter) {
    switch (filter) {
      case ScriptFilter.all:
        return 'All';
      case ScriptFilter.published:
        return 'Published';
      case ScriptFilter.drafts:
        return 'Drafts';
      case ScriptFilter.mine:
        return 'My Scripts';
    }
  }
}
```

---

## 4. Feature: Teleprompter

### 4.1 Prompter Provider

```dart
// lib/features/prompter/providers/prompter_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prompter_provider.g.dart';

@freezed
class PrompterState with _$PrompterState {
  const factory PrompterState({
    required String scriptId,
    required double scrollPosition,
    required double scrollSpeed,
    required bool isPlaying,
    required bool voiceEnabled,
    required bool isRecording,
    String? sessionId,
    String? controlledBy,
  }) = _PrompterState;
  
  factory PrompterState.initial(String scriptId) => PrompterState(
        scriptId: scriptId,
        scrollPosition: 0,
        scrollSpeed: 1.0,
        isPlaying: false,
        voiceEnabled: false,
        isRecording: false,
      );
}

@riverpod
class Prompter extends _$Prompter {
  @override
  PrompterState build(String scriptId) {
    return PrompterState.initial(scriptId);
  }
  
  void play() {
    state = state.copyWith(isPlaying: true);
  }
  
  void pause() {
    state = state.copyWith(isPlaying: false);
  }
  
  void setScrollSpeed(double speed) {
    state = state.copyWith(scrollSpeed: speed);
  }
  
  void setScrollPosition(double position) {
    state = state.copyWith(scrollPosition: position);
  }
  
  void toggleVoiceMode() {
    state = state.copyWith(voiceEnabled: !state.voiceEnabled);
  }
  
  void jumpToStart() {
    state = state.copyWith(scrollPosition: 0);
  }
  
  void jumpToEnd(double maxScroll) {
    state = state.copyWith(scrollPosition: maxScroll);
  }
  
  void startRecording() {
    state = state.copyWith(isRecording: true, isPlaying: true);
  }
  
  void stopRecording() {
    state = state.copyWith(isRecording: false, isPlaying: false);
  }
}
```

### 4.2 Prompter Screen

```dart
// lib/features/prompter/screens/prompter_screen.dart

class PrompterScreen extends ConsumerStatefulWidget {
  final String scriptId;

  const PrompterScreen({super.key, required this.scriptId});

  @override
  ConsumerState<PrompterScreen> createState() => _PrompterScreenState();
}

class _PrompterScreenState extends ConsumerState<PrompterScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _startAutoScroll(double speed) {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(
      const Duration(milliseconds: 16), // 60 FPS
      (timer) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.offset;
          
          if (currentScroll >= maxScroll) {
            timer.cancel();
            ref.read(prompterProvider(widget.scriptId).notifier).pause();
            return;
          }
          
          final newPosition = currentScroll + (speed * 0.5);
          _scrollController.jumpTo(newPosition);
          
          ref
              .read(prompterProvider(widget.scriptId).notifier)
              .setScrollPosition(newPosition);
        }
      },
    );
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final scriptAsync = ref.watch(scriptProvider(widget.scriptId));
    final prompterState = ref.watch(prompterProvider(widget.scriptId));

    // Listen to play/pause changes
    ref.listen(
      prompterProvider(widget.scriptId).select((s) => s.isPlaying),
      (previous, isPlaying) {
        if (isPlaying) {
          _startAutoScroll(prompterState.scrollSpeed);
        } else {
          _stopAutoScroll();
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: scriptAsync.when(
        data: (script) {
          if (script == null) {
            return const Center(child: Text('Script not found'));
          }

          return Stack(
            children: [
              // Main prompter text
              GestureDetector(
                onTap: () {
                  // Toggle play/pause on tap
                  if (prompterState.isPlaying) {
                    ref.read(prompterProvider(widget.scriptId).notifier).pause();
                  } else {
                    ref.read(prompterProvider(widget.scriptId).notifier).play();
                  }
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: Text(
                    script.content,
                    style: GoogleFonts.robotoMono(
                      fontSize: script.metadata.fontSize,
                      height: script.metadata.lineHeight,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Center guide line
              Positioned(
                top: MediaQuery.of(context).size.height * 0.5,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              
              // Floating controls
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: PrompterControls(
                  scriptId: widget.scriptId,
                  onSpeedChanged: (speed) {
                    ref
                        .read(prompterProvider(widget.scriptId).notifier)
                        .setScrollSpeed(speed);
                  },
                ),
              ),
              
              // Recording indicator
              if (prompterState.isRecording)
                Positioned(
                  top: 48,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'REC',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Close button
              Positioned(
                top: 48,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

### 4.3 Prompter Controls Widget

```dart
// lib/features/prompter/widgets/prompter_controls.dart

class PrompterControls extends ConsumerWidget {
  final String scriptId;
  final ValueChanged<double> onSpeedChanged;

  const PrompterControls({
    super.key,
    required this.scriptId,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prompterProvider(scriptId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed slider
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: state.scrollSpeed,
                  min: 0.1,
                  max: 3.0,
                  divisions: 29,
                  label: '${state.scrollSpeed.toStringAsFixed(1)}x',
                  onChanged: onSpeedChanged,
                ),
              ),
              Text(
                '${state.scrollSpeed.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Jump to start
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: () {
                  ref.read(prompterProvider(scriptId).notifier).jumpToStart();
                },
              ),
              
              // Play/Pause
              IconButton(
                icon: Icon(
                  state.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
                onPressed: () {
                  if (state.isPlaying) {
                    ref.read(prompterProvider(scriptId).notifier).pause();
                  } else {
                    ref.read(prompterProvider(scriptId).notifier).play();
                  }
                },
              ),
              
              // Voice mode toggle
              IconButton(
                icon: Icon(
                  state.voiceEnabled ? Icons.mic : Icons.mic_off,
                  color: state.voiceEnabled ? Colors.green : Colors.white,
                ),
                onPressed: () {
                  ref.read(prompterProvider(scriptId).notifier).toggleVoiceMode();
                },
              ),
              
              // Settings
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => PrompterSettingsSheet(scriptId: scriptId),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Feature: Voice Recognition

### 5.1 Voice Recognition Service

```dart
// lib/features/prompter/services/voice_recognition_service.dart

import 'package:speech_to_text/speech_to_text.dart';

class VoiceRecognitionService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    
    return _isInitialized;
  }
  
  Stream<String> startListening() async* {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isInitialized) {
      throw Exception('Speech recognition not available');
    }
    
    final controller = StreamController<String>();
    
    await _speech.listen(
      onResult: (result) {
        controller.add(result.recognizedWords);
      },
      listenFor: const Duration(hours: 1), // Continuous
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
    
    yield* controller.stream;
  }
  
  Future<void> stopListening() async {
    await _speech.stop();
  }
  
  bool get isListening => _speech.isListening;
}

final voiceRecognitionServiceProvider = Provider<VoiceRecognitionService>((ref) {
  return VoiceRecognitionService();
});
```

---

## 6. Feature: Remote Control

### 6.1 Remote Control Provider

```dart
// lib/features/remote_control/providers/remote_control_provider.dart

@riverpod
class RemoteControl extends _$RemoteControl {
  StreamSubscription? _sessionSubscription;
  
  @override
  Future<ControlSession?> build(String sessionId) async {
    final syncService = ref.read(remoteSyncServiceProvider);
    
    // Listen to session updates
    _sessionSubscription = syncService.listenToSession(sessionId).listen(
      (session) {
        state = AsyncData(session);
      },
      onError: (error, stack) {
        state = AsyncError(error, stack);
      },
    );
    
    ref.onDispose(() {
      _sessionSubscription?.cancel();
    });
    
    return null;
  }
  
  Future<void> sendCommand(ControlCommand command) async {
    final sessionId = state.value?.id;
    if (sessionId == null) return;
    
    final syncService = ref.read(remoteSyncServiceProvider);
    await syncService.sendCommand(sessionId, command);
  }
  
  Future<void> setScrollSpeed(double speed) async {
    await sendCommand(ControlCommand.setSpeed(speed));
  }
  
  Future<void> pause() async {
    await sendCommand(const ControlCommand.pause());
  }
  
  Future<void> play() async {
    await sendCommand(const ControlCommand.play());
  }
  
  Future<void> jumpTo(double position) async {
    await sendCommand(ControlCommand.jumpTo(position));
  }
}
```

---

## 7. Next Implementation Steps

1. ✅ Set up project structure
2. ✅ Implement authentication
3. ✅ Implement script management
4. ✅ Implement core prompter
5. ⬜ Implement voice recognition
6. ⬜ Implement remote control
7. ⬜ Implement recording
8. ⬜ Add offline mode
9. ⬜ Polish UI/UX
10. ⬜ Test and debug

See BUILD_TIMELINE.md for detailed weekly schedule.
