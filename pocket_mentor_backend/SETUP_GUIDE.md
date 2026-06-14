# Pocket Mentor — Complete Setup Guide

> Assumes you are starting from a fresh machine with the ZIP downloaded.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Python | 3.11+ | https://python.org |
| Flutter SDK | 3.2+ | https://docs.flutter.dev/get-started/install |
| Android Studio | Hedgehog+ | https://developer.android.com/studio |
| Android SDK | API 33+ | Via Android Studio SDK Manager |
| Java (JDK) | 17+ | Bundled with Android Studio |
| Git | Any | https://git-scm.com |

---

## Part 1 — Backend Setup

### Step 1.1 — Extract and enter the project

```bash
unzip pocket_mentor_backend.zip
cd pocket_mentor_backend
```

### Step 1.2 — Create Python virtual environment

```bash
# Create venv
python3 -m venv venv

# Activate (Mac/Linux)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Verify Python version
python --version   # must be 3.11+
```

### Step 1.3 — Install dependencies

```bash
pip install -r requirements.txt
```

Expected output ends with: `Successfully installed ...`

> **Note:** If you see a `greenlet` version conflict warning with `playwright`, ignore it.
> The app does not use playwright. The conflict does not affect runtime behaviour.

### Step 1.4 — Configure environment

A `.env` file is already included with safe development defaults. For production, change `SECRET_KEY`:

```bash
# The included .env has:
# SECRET_KEY=super-secret-dev-key-change-in-production-32chars
# DATABASE_URL=sqlite+aiosqlite:///./pocket_mentor.db
# DEBUG=true

# For production — generate a real secret:
python3 -c "import secrets; print(secrets.token_hex(32))"
# Paste the output as SECRET_KEY in .env
```

### Step 1.5 — Run the server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Expected startup output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000
✅  Pocket Mentor v1.0.0 started
INFO:     Application startup complete.
```

The server auto-creates `pocket_mentor.db` and all tables on first boot.

### Step 1.6 — Verify the API

Open in browser: http://localhost:8000/docs

You should see the Swagger UI with all endpoints grouped by tag.

Also check: http://localhost:8000/health → `{"status": "ok"}`

### Step 1.7 — Run the test suite (optional)

```bash
pytest -v
# Expected: 56 passed
```

---

## Part 2 — Flutter App Setup

### Step 2.1 — Extract and enter the project

```bash
unzip pocket_mentor_flutter.zip
cd pocket_mentor_flutter
```

### Step 2.2 — Configure `local.properties`

Flutter requires this file to locate your Android SDK. It is **not** included in the ZIP (by design — paths differ per machine).

```bash
# Create android/local.properties
# Replace paths with YOUR actual paths

# Mac example:
cat > android/local.properties << EOF
sdk.dir=/Users/YOUR_NAME/Library/Android/sdk
flutter.sdk=/Users/YOUR_NAME/development/flutter
flutter.versionName=1.0.0
flutter.versionCode=1
flutter.buildMode=debug
EOF

# Linux example:
cat > android/local.properties << EOF
sdk.dir=/home/YOUR_NAME/Android/Sdk
flutter.sdk=/home/YOUR_NAME/flutter
flutter.versionName=1.0.0
flutter.versionCode=1
flutter.buildMode=debug
EOF

# Windows example (use forward slashes):
# sdk.dir=C:/Users/YOUR_NAME/AppData/Local/Android/Sdk
# flutter.sdk=C:/src/flutter
```

> **Tip:** Find your Flutter SDK path with: `flutter doctor -v | grep "Flutter"`
> Find your Android SDK path in Android Studio → SDK Manager → Android SDK Location

### Step 2.3 — Configure the API URL

Edit `lib/utils/constants.dart`:

```dart
// For Android Emulator (default — works out of the box):
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// For physical Android device on same Wi-Fi:
// Find your machine's LAN IP: ifconfig (Mac/Linux) or ipconfig (Windows)
static const String baseUrl = 'http://192.168.1.X:8000/api/v1';

// For production:
static const String baseUrl = 'https://api.yourapp.com/api/v1';
```

### Step 2.4 — Install Flutter dependencies

```bash
flutter pub get
```

### Step 2.5 — Verify Flutter setup

```bash
flutter doctor
```

All checkboxes should be green. Key items:
- `[✓] Flutter (Channel stable, 3.x.x)`
- `[✓] Android toolchain`
- `[✓] Android Studio`
- `[✓] Connected device` (emulator or physical device)

If Android toolchain has issues:
```bash
flutter doctor --android-licenses
# Accept all licenses with 'y'
```

### Step 2.6 — Start an Android emulator

In Android Studio: **Device Manager** → **Create Device** → Pixel 6 API 33 → Start

Or from terminal:
```bash
# List available emulators
emulator -list-avds

# Start one
emulator -avd Pixel_6_API_33
```

### Step 2.7 — Run the app

```bash
# Make sure the backend is running (Part 1 Step 1.5)
# Make sure your emulator is running

flutter run
```

**Expected output:**
```
Launching lib/main.dart on Pixel 6 API 33 in debug mode...
✓  Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk...
Syncing files to device Pixel 6 API 33...

Flutter run key commands.
r Hot reload.
R Hot restart.
```

The Pocket Mentor splash screen appears, then redirects to the Login screen.

---

## Part 3 — First Run Walkthrough

1. **Register** — tap "Sign Up", create an account
2. **Create a topic** — tap "+ New" on the dashboard, e.g. "Python Basics"
3. **Add cards manually** — tap the topic → add question/answer cards
4. **Learn** — tap "Learn" on the dashboard to start flashcard session
5. **Upload notes** — tap "Notes" tab → upload a `.pdf` or `.txt` file → wait for card generation
6. **Revise** — after studying cards, the "Revision" mode shows SM-2 scheduled cards
7. **Interview** — tap "Interview" → select topic + difficulty → practice mode
8. **Profile** — view streak, heatmap, session history

---

## Part 4 — Running Both Together (Development)

Keep two terminal windows open:

**Terminal 1 — Backend:**
```bash
cd pocket_mentor_backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Terminal 2 — Flutter:**
```bash
cd pocket_mentor_flutter
flutter run
```

---

## Part 5 — Troubleshooting

### "Connection refused" / Network errors in app
- Confirm backend is running: `curl http://localhost:8000/health`
- For emulator: URL must be `http://10.0.2.2:8000` (not `localhost`)
- For physical device: use your machine's actual LAN IP, and ensure both are on the same network
- Ensure `android/app/src/debug/AndroidManifest.xml` has `usesCleartextTraffic="true"`

### "Gradle build failed"
- Ensure `android/local.properties` exists with correct `sdk.dir` and `flutter.sdk` paths
- Run `flutter clean && flutter pub get` then retry
- Check Java version: `java -version` — must be 17+
- In Android Studio: File → Project Structure → SDK Location — verify paths

### "flutter.sdk not set in local.properties"
- The `local.properties` file is missing or has wrong path
- Re-do Step 2.2 with the correct path to your Flutter SDK

### "SDK location not found"
- `sdk.dir` in `local.properties` points to wrong location
- Find it: Android Studio → Settings → Android SDK → Android SDK Location

### Backend import errors
- Ensure venv is activated: `source venv/bin/activate`
- Ensure you ran `pip install -r requirements.txt`
- Python version must be 3.11+: `python --version`

### "Table already exists" on restart
- Normal behaviour — SQLAlchemy `create_all` is idempotent and skips existing tables
- To reset: `rm pocket_mentor.db` then restart server

### File upload not working
- Check `uploads/` directory exists: `mkdir -p uploads`
- The server creates it automatically on startup
- Check the upload size is under 20 MB

### Cards not generating from upload
- Check backend logs — the background task prints errors to stdout
- Text extraction requires the file to contain selectable text (not scanned images)
- For PDFs: ensure they are text-based, not image-only scans

---

## Part 6 — Build Release APK

```bash
cd pocket_mentor_flutter

# Debug APK (for testing)
flutter build apk --debug

# Release APK (optimised)
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

Install on a connected device:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Part 7 — Database Migrations (Production)

When you change models and need to update the schema in production:

```bash
cd pocket_mentor_backend
source venv/bin/activate

# Generate a migration
alembic revision --autogenerate -m "describe your change"

# Apply migrations
alembic upgrade head

# Roll back one step
alembic downgrade -1
```

> **Note:** For development, the server auto-creates tables via `create_all` on startup.
> Only use Alembic for production schema changes.
