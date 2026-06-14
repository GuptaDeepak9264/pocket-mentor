# Pocket Mentor — Flutter Frontend

> Replace mindless scrolling with productive learning.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Android) |
| State Management | Provider 6 (ChangeNotifier) |
| HTTP Client | Dio 5 with JWT interceptor + auto-refresh |
| Local Storage | SharedPreferences (tokens/settings) |
| Animations | flutter_animate |
| Charts | fl_chart |
| File Picking | file_picker |
| Shimmer Loading | shimmer |
| UI Design | Material 3, Dark Theme, Inter font |

---

## Project Structure

```
lib/
├── main.dart                        # App entry point, MultiProvider, routing
├── theme/
│   └── app_theme.dart               # Complete Material 3 dark theme
├── utils/
│   ├── constants.dart               # Routes, API base URL, keys
│   └── extensions.dart              # DateTime, String, int helpers
├── models/
│   ├── user_model.dart
│   ├── topic_model.dart
│   ├── card_model.dart
│   ├── feed_model.dart
│   ├── progress_model.dart
│   └── upload_model.dart
├── services/
│   ├── api_service.dart             # Dio client, all API calls, JWT interceptor
│   └── storage_service.dart        # SharedPreferences wrapper
├── providers/
│   ├── auth_provider.dart           # Login, register, logout, profile
│   ├── topic_provider.dart          # Topic CRUD
│   ├── feed_provider.dart           # Learn, Revision, Interview feeds + session stats
│   ├── progress_provider.dart       # Summary, heatmap, sessions
│   └── upload_provider.dart         # File upload + polling
├── router/
│   └── app_router.dart              # Route generation, AuthGuard
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart         # Bottom nav shell + dashboard
│   ├── learn/
│   │   └── learn_feed_screen.dart
│   ├── revision/
│   │   └── revision_screen.dart
│   ├── interview/
│   │   └── interview_screen.dart    # Setup screen + feed
│   ├── notes/
│   │   └── notes_screen.dart        # Upload + progress + history
│   └── profile/
│       └── profile_screen.dart      # Stats + heatmap + sessions + settings
└── widgets/
    ├── common/
    │   ├── pm_app_bar.dart
    │   ├── loading_widget.dart      # Shimmer + spinner
    │   ├── empty_state_widget.dart
    │   └── error_widget.dart
    ├── cards/
    │   ├── flashcard_widget.dart    # 3D flip animation
    │   └── response_bar.dart        # Know / Don't Know buttons
    └── feed/
        └── session_summary_widget.dart
```

---

## Quick Start

### Prerequisites
- Flutter SDK ≥ 3.2.0
- Android Studio / VS Code with Flutter plugin
- Android emulator or physical device

### Setup

```bash
# 1. Navigate to project
cd pocket_mentor_flutter

# 2. Install dependencies
flutter pub get

# 3. Configure API URL
# Edit lib/utils/constants.dart:
#   static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
#   (10.0.2.2 is Android emulator's localhost)
#   For physical device: use your machine's LAN IP

# 4. Start the FastAPI backend first
# (see pocket_mentor_backend README)

# 5. Run the app
flutter run
```

---

## Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Splash | `/` | Auth check, loading indicator |
| Login | `/login` | Email + password with animation |
| Register | `/register` | Full registration form |
| Home | `/home` | Dashboard + bottom nav (Home, Notes, Profile) |
| Learn Feed | `/learn` | Flip cards, Know/Don't Know, session summary |
| Revision | `/revision` | SRS-scheduled cards, interval/reps badges |
| Interview | `/interview` | Setup screen → card session → summary |
| Notes | `/notes` | Upload PDF/DOCX/TXT, poll progress, view history |
| Profile | `/profile` | Stats, heatmap, session history, settings |

---

## State Management

Each feature has its own `ChangeNotifier` provider:

```
AuthProvider       → user session, login/register/logout
TopicProvider      → topic list CRUD
LearnFeedProvider  → learn feed cards + session tracking
RevisionFeedProvider → SRS-due cards + session tracking
InterviewFeedProvider → interview cards + session tracking
ProgressProvider   → summary, heatmap, session history
UploadProvider     → file upload, polling, generated cards
```

All providers receive `ApiService` via constructor injection. No global singletons outside `main.dart`.

---

## Key Features

### Flashcard Flip
`FlashCardWidget` uses a `Matrix4.rotateY` animation controller for a true 3D card flip. The front shows the question; the back shows the answer + optional hint.

### JWT Auto-Refresh
`ApiService` uses a Dio interceptor: on any 401 response, it silently calls `/auth/refresh`, saves the new token pair, and retries the original request — invisible to the user.

### Offline-First Storage
Tokens and user settings are persisted in `SharedPreferences`. The app boots and checks auth without a network call if a valid token is stored.

### SM-2 Response Tracking
After each Know/Don't Know tap, `submitCardResponse()` calls `POST /cards/{id}/response`. The backend recalculates the SM-2 schedule. The provider tracks session stats (cards known, unknown, duration) and posts a session record when the queue is exhausted.

### Upload & Poll
`UploadProvider.uploadFile()` posts the file, then polls `GET /uploads/{id}/status` every 2 seconds (max 30 attempts = 60s) until `parse_status == 'done'` or `'failed'`. Progress is shown as a circular indicator.

---

## Configuration

Edit `lib/utils/constants.dart`:

```dart
// Android emulator
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// Physical device on same LAN
static const String baseUrl = 'http://192.168.1.x:8000/api/v1';

// Production
static const String baseUrl = 'https://api.yourapp.com/api/v1';
```

---

## Build for Release

```bash
# Generate release APK
flutter build apk --release

# Generate App Bundle (for Play Store)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Dependencies

```yaml
provider: ^6.1.2          # State management
dio: ^5.4.3               # HTTP client
connectivity_plus: ^6.0.3 # Network status
sqflite: ^2.3.3           # Local DB (prepared for offline sync)
shared_preferences: ^2.2.3 # Token storage
file_picker: ^8.0.7       # Document picker
google_fonts: ^6.2.1      # Inter font
flutter_animate: ^4.5.0   # Animations
fl_chart: ^0.68.0         # Charts
shimmer: ^3.0.0           # Loading skeleton
intl: ^0.19.0             # Date formatting
```
