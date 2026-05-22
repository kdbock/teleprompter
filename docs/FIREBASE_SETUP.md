# Firebase Setup Guide

Complete guide to setting up Firebase for the Team Teleprompter app.

---

## 1. Create Firebase Project

### Step 1: Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Project name: `team-teleprompter` (or your preference)
4. Disable Google Analytics for now (can enable later)
5. Click "Create project"

### Step 2: Add Apps to Project
You'll need to add both iOS and Android apps:

**iOS App:**
1. Click iOS icon
2. Bundle ID: `com.yourteam.teleprompter` (use your own domain)
3. App nickname: `Teleprompter iOS`
4. Download `GoogleService-Info.plist`
5. Save file for later

**Android App:**
1. Click Android icon
2. Package name: `com.yourteam.teleprompter`
3. App nickname: `Teleprompter Android`
4. Download `google-services.json`
5. Save file for later

---

## 2. Enable Firebase Services

### 2.1 Authentication

```bash
# Enable in Firebase Console:
# Authentication → Get Started → Sign-in method
```

**Enable These Sign-In Methods:**
- ✅ **Email/Password** (primary)
- ✅ **Google Sign-In** (optional, recommended)
- ✅ **Apple Sign-In** (required for iOS App Store)

**Settings to Configure:**
```yaml
Email Enumeration Protection: Enabled
Authorized Domains: Add your custom domain if using
```

### 2.2 Firestore Database

```bash
# Firestore → Create Database
```

**Start in Production Mode** (we'll set rules explicitly)

**Location:** Choose closest to your team:
- `us-central1` (Iowa)
- `europe-west1` (Belgium)
- Choose based on your location

### 2.3 Cloud Storage

```bash
# Storage → Get Started
```

**Start in Production Mode**

**Bucket Structure:**
```
team-teleprompter.appspot.com/
├── scripts/
│   └── {scriptId}/
│       └── attachments/
├── recordings/
│   └── {userId}/
│       └── {recordingId}.mp4
└── avatars/
    └── {userId}.jpg
```

### 2.4 Cloud Functions (Optional for Phase 2)

```bash
# Functions → Get Started
```

For now, just enable. We'll deploy functions later for:
- Script version history cleanup
- Notification triggers
- Analytics aggregation

---

## 3. Firestore Data Model

### 3.1 Collections Structure

```
/teams/{teamId}
  name: string
  createdAt: timestamp
  ownerId: string
  plan: string (free, pro)
  settings: map
  
/users/{userId}
  email: string
  displayName: string
  role: string (publisher, editor, creator)
  teamId: string
  avatarUrl: string
  createdAt: timestamp
  lastActive: timestamp

/scripts/{scriptId}
  teamId: string
  title: string
  content: string (full script text)
  status: string (draft, published, archived)
  createdBy: string (userId)
  createdAt: timestamp
  updatedAt: timestamp
  publishedAt: timestamp
  publishedBy: string
  tags: array[string]
  category: string
  version: number
  estimatedDuration: number (seconds)
  wordCount: number
  metadata: map {
    fontSize: number
    scrollSpeed: number
    voiceEnabled: boolean
  }

/scripts/{scriptId}/versions/{versionId}
  content: string
  createdAt: timestamp
  createdBy: string
  changeDescription: string

/sessions/{sessionId}
  scriptId: string
  userId: string (creator)
  teamId: string
  status: string (active, completed)
  startedAt: timestamp
  endedAt: timestamp
  controlledBy: string (userId or null)
  scrollPosition: number
  scrollSpeed: number
  voiceEnabled: boolean
  
/recordings/{recordingId}
  sessionId: string
  scriptId: string
  userId: string
  teamId: string
  duration: number
  recordedAt: timestamp
  storageUrl: string
  thumbnailUrl: string
  metadata: map
```

### 3.2 Firestore Security Rules

Create file: `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isTeamMember(teamId) {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.teamId == teamId;
    }
    
    function hasRole(role) {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
    }
    
    function isPublisher() {
      return hasRole('publisher');
    }
    
    function isEditor() {
      return hasRole('editor') || hasRole('publisher');
    }
    
    // Teams
    match /teams/{teamId} {
      allow read: if isTeamMember(teamId);
      allow write: if isPublisher() && isTeamMember(teamId);
    }
    
    // Users
    match /users/{userId} {
      allow read: if isSignedIn() && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.teamId == 
                     get(/databases/$(database)/documents/users/$(userId)).data.teamId;
      allow write: if isSignedIn() && request.auth.uid == userId;
    }
    
    // Scripts
    match /scripts/{scriptId} {
      allow read: if isTeamMember(resource.data.teamId);
      allow create: if isSignedIn() && isTeamMember(request.resource.data.teamId);
      allow update: if isTeamMember(resource.data.teamId) && 
                       (isEditor() || resource.data.createdBy == request.auth.uid);
      allow delete: if isPublisher() && isTeamMember(resource.data.teamId);
      
      // Script versions
      match /versions/{versionId} {
        allow read: if isTeamMember(get(/databases/$(database)/documents/scripts/$(scriptId)).data.teamId);
        allow write: if false; // Only created via Cloud Function
      }
    }
    
    // Sessions
    match /sessions/{sessionId} {
      allow read: if isTeamMember(resource.data.teamId);
      allow create: if isSignedIn() && isTeamMember(request.resource.data.teamId);
      allow update: if isTeamMember(resource.data.teamId);
      allow delete: if request.auth.uid == resource.data.userId;
    }
    
    // Recordings
    match /recordings/{recordingId} {
      allow read: if isTeamMember(resource.data.teamId);
      allow create: if isSignedIn() && 
                       request.auth.uid == request.resource.data.userId &&
                       isTeamMember(request.resource.data.teamId);
      allow update: if request.auth.uid == resource.data.userId;
      allow delete: if isPublisher() || request.auth.uid == resource.data.userId;
    }
  }
}
```

### 3.3 Storage Security Rules

Create file: `storage.rules`

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function getUserTeam() {
      return firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.teamId;
    }
    
    // Recordings - users can upload their own
    match /recordings/{userId}/{recordingId} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && request.auth.uid == userId;
      allow delete: if isSignedIn() && request.auth.uid == userId;
    }
    
    // Avatars - users can manage their own
    match /avatars/{userId} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && request.auth.uid == userId;
    }
    
    // Script attachments - team members only
    match /scripts/{scriptId}/{fileName} {
      allow read: if isSignedIn();
      allow write: if isSignedIn();
    }
  }
}
```

---

## 4. Firebase CLI Setup

### Install Firebase Tools

```bash
# Install globally
npm install -g firebase-tools

# Login
firebase login

# Initialize project in your Flutter directory
cd /workspaces/teleprompter
firebase init

# Select:
# - Firestore
# - Storage
# - Functions (optional)

# Choose existing project: team-teleprompter
```

### Project Configuration

This creates `firebase.json`:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

### Deploy Rules

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules
```

---

## 5. Firestore Indexes

Create file: `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "scripts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "teamId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "scripts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "teamId", "order": "ASCENDING" },
        { "fieldPath": "createdBy", "order": "ASCENDING" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "scripts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "teamId", "order": "ASCENDING" },
        { "fieldPath": "tags", "arrayConfig": "CONTAINS" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "sessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "teamId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startedAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy indexes:
```bash
firebase deploy --only firestore:indexes
```

---

## 6. Flutter Firebase Configuration

### 6.1 Install FlutterFire CLI

```bash
# Install
dart pub global activate flutterfire_cli

# Configure for your project
flutterfire configure --project=team-teleprompter
```

This automatically:
- Downloads config files
- Places them in correct directories
- Updates Flutter project settings

### 6.2 Add Dependencies

Edit `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # Additional utilities
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^5.0.0
```

### 6.3 Initialize Firebase in Flutter

Edit `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## 7. Environment Variables & Secrets

Create `.env` file (add to `.gitignore`):

```bash
# Firebase Project
FIREBASE_PROJECT_ID=team-teleprompter
FIREBASE_API_KEY=your_api_key_here
FIREBASE_AUTH_DOMAIN=team-teleprompter.firebaseapp.com

# Storage
FIREBASE_STORAGE_BUCKET=team-teleprompter.appspot.com

# Optional: Third-party services
SPEECH_RECOGNITION_API_KEY=your_key_here
```

---

## 8. Testing & Validation

### Test Authentication
```bash
# In Firebase Console:
# Authentication → Users → Add User
# Email: test@yourteam.com
# Password: testpass123
```

### Test Firestore
```dart
// In Flutter
final docRef = FirebaseFirestore.instance
    .collection('teams')
    .doc('test-team');
    
await docRef.set({
  'name': 'Test Team',
  'createdAt': FieldValue.serverTimestamp(),
});

print('Team created successfully!');
```

### Test Storage
```dart
final storageRef = FirebaseStorage.instance
    .ref()
    .child('test/hello.txt');
    
await storageRef.putString('Hello Firebase!');
print('File uploaded successfully!');
```

---

## 9. Monitoring & Quotas

### Free Tier Limits (Spark Plan)
- **Firestore:** 50K reads, 20K writes, 20K deletes per day
- **Storage:** 5 GB storage, 1 GB/day downloads
- **Auth:** Unlimited

### Upgrade to Blaze Plan (Pay-as-you-go)
Recommended once you have > 5 active users:
- **Firestore:** $0.06 per 100K reads, $0.18 per 100K writes
- **Storage:** $0.026 per GB stored, $0.12 per GB downloaded
- **Functions:** 2M invocations free, then $0.40 per million

### Set Budget Alerts
1. Firebase Console → Settings → Usage and billing
2. Set monthly budget: $50 (adjust as needed)
3. Enable email alerts at 50%, 90%, 100%

---

## 10. Production Checklist

Before launching to team:

- [ ] Enable Apple Sign-In (required for iOS App Store)
- [ ] Configure custom email templates (Password reset, etc.)
- [ ] Set up Cloud Functions for cleanup tasks
- [ ] Enable Crashlytics for error monitoring
- [ ] Review and test all security rules
- [ ] Set up automated Firestore backups
- [ ] Configure Performance Monitoring
- [ ] Test offline mode thoroughly
- [ ] Load test with expected team size
- [ ] Document Firebase project access (who has admin rights)

---

## Next Steps

1. Complete Firebase setup following this guide
2. Test authentication flow
3. Create initial team and user documents
4. Move to Flutter implementation
