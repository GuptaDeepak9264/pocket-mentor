# Pocket Mentor — ZIP-Ready Project Checklist

Use this checklist before distributing or deploying either project.

---

## ✅ Backend Checklist (`pocket_mentor_backend.zip`)

### Files present
- [x] `.env` — development environment variables included
- [x] `.env.example` — template for production setup
- [x] `.gitignore` — prevents committing secrets and build artefacts
- [x] `requirements.txt` — all dependencies (no unused packages)
- [x] `alembic.ini` — database migration configuration
- [x] `pytest.ini` — test runner configuration
- [x] `README.md` — project documentation
- [x] `QA_REPORT.md` — this audit report
- [x] `SETUP_GUIDE.md` — step-by-step setup instructions
- [x] `app/main.py` — FastAPI application entry point
- [x] `app/config.py` — pydantic-settings configuration
- [x] `app/db/base.py` — SQLAlchemy declarative base
- [x] `app/db/session.py` — async engine + session factory
- [x] `app/db/models/` — 8 ORM models (User, Topic, Card, SRSRecord, UploadedFile, StudySession, UserStreak, RefreshToken)
- [x] `app/core/security.py` — JWT + bcrypt (passlib removed)
- [x] `app/core/dependencies.py` — FastAPI dependency injection
- [x] `app/core/exceptions.py` — custom HTTP exceptions
- [x] `app/schemas/` — 7 Pydantic schema files
- [x] `app/services/` — 6 service files (SRS, feed, file, AI, analytics, sync)
- [x] `app/api/v1/` — 7 route files + router aggregator
- [x] `app/workers/__init__.py` — package marker (was missing)
- [x] `app/workers/tasks/__init__.py` — package marker (was missing)
- [x] `migrations/alembic/env.py` — async Alembic environment
- [x] `migrations/alembic/script.py.mako` — migration template (was missing)
- [x] `migrations/alembic/versions/.gitkeep` — keeps versions dir in git
- [x] `app/tests/` — 56 passing tests across 9 files

### Code quality
- [x] All 28 modules import without errors
- [x] 56/56 tests pass
- [x] `StaticFiles` unused import removed from `main.py`
- [x] `passlib` removed from `requirements.txt`
- [x] `uploads.py` uses `BackgroundTasks` + own session (not `asyncio.create_task`)
- [x] No syntax errors in any Python file

### Runtime safety
- [x] JWT tokens include `jti` (unique ID) — prevents token collision
- [x] Refresh tokens stored in DB with revocation support
- [x] File upload validates type (pdf/docx/txt) and size (≤20 MB)
- [x] All API endpoints require authentication except `/auth/register` and `/auth/login`
- [x] CORS restricted to `*` in DEBUG mode, configurable for production

---

## ✅ Flutter Checklist (`pocket_mentor_flutter.zip`)

### Core Flutter files
- [x] `lib/main.dart` — MultiProvider setup, auth gate, splash screen
- [x] `pubspec.yaml` — 7 unused dependencies removed, broken font declarations removed
- [x] `analysis_options.yaml` — lint rules
- [x] `.gitignore` — excludes build/, .dart_tool/, local.properties

### Dart source files (33 total)
- [x] `lib/theme/app_theme.dart` — complete Material 3 dark theme
- [x] `lib/utils/constants.dart` — routes, API URL, storage keys
- [x] `lib/utils/extensions.dart` — DateTime, String, int, BuildContext helpers
- [x] `lib/models/` — 6 model files (user, topic, card, feed, progress, upload)
- [x] `lib/services/api_service.dart` — Dio client + JWT interceptor + auto-refresh
- [x] `lib/services/storage_service.dart` — SharedPreferences wrapper
- [x] `lib/providers/auth_provider.dart` — login, register, logout, profile update
- [x] `lib/providers/topic_provider.dart` — topic CRUD
- [x] `lib/providers/feed_provider.dart` — learn + revision + interview feeds + session tracking
- [x] `lib/providers/progress_provider.dart` — summary, heatmap, sessions
- [x] `lib/providers/upload_provider.dart` — file upload + polling + generated cards
- [x] `lib/router/app_router.dart` — route generation + AuthGuard
- [x] `lib/screens/auth/login_screen.dart`
- [x] `lib/screens/auth/register_screen.dart`
- [x] `lib/screens/home/home_screen.dart` — dashboard + bottom nav + topic list
- [x] `lib/screens/learn/learn_feed_screen.dart`
- [x] `lib/screens/revision/revision_screen.dart`
- [x] `lib/screens/interview/interview_screen.dart` — setup screen + card session
- [x] `lib/screens/notes/notes_screen.dart` — upload + progress + history
- [x] `lib/screens/profile/profile_screen.dart` — stats + heatmap + sessions + settings
- [x] `lib/widgets/cards/flashcard_widget.dart` — 3D flip animation
- [x] `lib/widgets/cards/response_bar.dart` — Know / Don't Know buttons
- [x] `lib/widgets/common/loading_widget.dart` — shimmer + spinner
- [x] `lib/widgets/common/empty_state_widget.dart`
- [x] `lib/widgets/common/error_widget.dart`
- [x] `lib/widgets/common/pm_app_bar.dart`
- [x] `lib/widgets/feed/session_summary_widget.dart` — Expanded bug fixed

### Android build files
- [x] `android/settings.gradle` — AGP 8.1 plugin management
- [x] `android/build.gradle` — root build config
- [x] `android/app/build.gradle` — app build config (namespace, minSdk 21, multidex)
- [x] `android/gradle.properties` — AndroidX + Jetifier enabled
- [x] `android/gradle/wrapper/gradle-wrapper.properties` — Gradle 8.0
- [x] `android/app/src/main/AndroidManifest.xml` — permissions + activity
- [x] `android/app/src/main/kotlin/com/pocketmentor/MainActivity.kt`
- [x] `android/app/src/main/res/values/styles.xml` — LaunchTheme + NormalTheme
- [x] `android/app/src/main/res/values/colors.xml`
- [x] `android/app/src/main/res/drawable/launch_background.xml`
- [x] `android/app/src/debug/AndroidManifest.xml` — HTTP cleartext for dev
- [x] `android/app/src/profile/AndroidManifest.xml` — HTTP cleartext for profiling
- [x] `android/local.properties.template` — developer setup guide

### Assets
- [x] `assets/images/.gitkeep` — directory exists (pubspec.yaml requires it)
- [x] `assets/animations/.gitkeep` — directory exists

### Code quality
- [x] All 33 Dart file imports resolve to existing files
- [x] `_StatCard` double-Expanded bug fixed
- [x] `loadSessions()` added to HomeScreen initState
- [x] Unused `user` variable removed from `_buildAppBar`
- [x] All screens handle loading / empty / error states

---

## ⚠️ Manual Steps Required After Download

These cannot be automated as they depend on your local machine:

### Backend
1. **`SECRET_KEY`** — Change in `.env` before any non-local deployment:
   ```bash
   python3 -c "import secrets; print(secrets.token_hex(32))"
   ```

2. **Virtual environment** — Must create and activate before running:
   ```bash
   python3 -m venv venv && source venv/bin/activate
   pip install -r requirements.txt
   ```

### Flutter
3. **`android/local.properties`** — Must create with your machine's SDK paths:
   ```
   sdk.dir=/path/to/Android/Sdk
   flutter.sdk=/path/to/flutter
   flutter.versionName=1.0.0
   flutter.versionCode=1
   ```

4. **API URL** — Update `lib/utils/constants.dart` if not using Android emulator:
   ```dart
   // Emulator (default): http://10.0.2.2:8000/api/v1
   // Physical device: http://YOUR_LAN_IP:8000/api/v1
   ```

5. **`flutter pub get`** — Must run to fetch packages

---

## 🚀 Quick Start (30 seconds)

```bash
# Terminal 1 — Backend
cd pocket_mentor_backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 2 — Flutter (after creating local.properties)
cd pocket_mentor_flutter
flutter pub get
flutter run
```

---

## 📋 Known Limitations (Phase 2 Items)

| Item | Status | Notes |
|------|--------|-------|
| `datetime.utcnow()` deprecation | Low priority | Runs fine on Python 3.11/3.12, deprecation warning only |
| Offline sync (SQLite → server) | Not implemented | Architecture designed, providers ready, DB layer pending |
| Push notifications | Not implemented | Backend task scaffold exists in `workers/` |
| LLM-based card generation | Phase 2 | `ai_service.py` interface ready; plug in API key to activate |
| iOS support | Not in scope | Android only per requirements |
| Vector search | Phase 3 | Qdrant/Pinecone integration planned |
