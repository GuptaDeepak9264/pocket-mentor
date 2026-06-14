# Pocket Mentor — FastAPI Backend

> Replace mindless social media scrolling with productive learning.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | FastAPI 0.111 (async) |
| ORM | SQLAlchemy 2.0 (async) |
| Database | SQLite (dev) → PostgreSQL (prod) |
| Auth | JWT (access + refresh tokens) via python-jose |
| Password hashing | bcrypt |
| File parsing | PyPDF2, python-docx |
| SRS Algorithm | SM-2 (Spaced Repetition) |
| Background tasks | asyncio tasks (MVP) → Celery + Redis (prod) |
| Migrations | Alembic |
| Testing | pytest-asyncio + httpx |

---

## Project Structure

```
pocket_mentor_backend/
├── app/
│   ├── main.py                  # FastAPI app, lifespan, routers
│   ├── config.py                # Settings (pydantic-settings)
│   ├── api/v1/
│   │   ├── auth.py              # Register, login, refresh, logout, me
│   │   ├── topics.py            # Topic CRUD
│   │   ├── cards.py             # Card CRUD + SM-2 response submission
│   │   ├── feeds.py             # Learn / Revision / Interview feeds
│   │   ├── uploads.py           # File upload + card generation
│   │   ├── progress.py          # Sessions, streak, heatmap, summary
│   │   └── sync.py              # Offline-first push/pull sync
│   ├── core/
│   │   ├── security.py          # JWT + bcrypt
│   │   ├── dependencies.py      # get_current_user FastAPI dependency
│   │   └── exceptions.py        # Custom HTTP exceptions
│   ├── db/
│   │   ├── base.py              # SQLAlchemy Base + helpers
│   │   ├── session.py           # Async engine + session factory
│   │   └── models/              # ORM models (8 tables)
│   ├── schemas/                 # Pydantic request/response models
│   ├── services/
│   │   ├── srs_service.py       # SM-2 algorithm
│   │   ├── feed_service.py      # Feed assembly queries
│   │   ├── file_service.py      # PDF/DOCX/TXT extraction
│   │   ├── ai_service.py        # Abstracted AI interface + rules-based impl
│   │   ├── analytics_service.py # Streaks, heatmap, progress summary
│   │   └── sync_service.py      # Conflict resolution
│   └── tests/
│       ├── conftest.py          # Shared fixtures (in-memory DB, auth client)
│       ├── unit/                # SRS algorithm, AI service tests
│       └── integration/         # Full HTTP tests for all endpoints
├── migrations/alembic/          # Alembic migration scripts
├── requirements.txt
├── pytest.ini
├── alembic.ini
└── .env.example
```

---

## Quick Start

```bash
# 1. Clone and enter the project
cd pocket_mentor_backend

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
cp .env.example .env
# Edit .env — at minimum, change SECRET_KEY

# 5. Run the server
uvicorn app.main:app --reload --port 8000
```

The server auto-creates all database tables on first startup.

---

## API Documentation

Once running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health check**: http://localhost:8000/health

---

## API Endpoints Summary

### Auth  `POST /api/v1/auth/...`
| Method | Path | Description |
|--------|------|-------------|
| POST | /register | Create account, returns token pair |
| POST | /login | Login, returns token pair |
| POST | /refresh | Rotate refresh token |
| DELETE | /logout | Revoke refresh token |
| GET | /me | Get current user |
| PATCH | /me | Update profile / settings |

### Topics  `/api/v1/topics`
Full CRUD — GET list, POST create, GET by id, PATCH update, DELETE.

### Cards  `/api/v1/topics/{id}/cards` and `/api/v1/cards/{id}`
Full CRUD + `POST /api/v1/cards/{id}/response` — submit Know/Don't Know, triggers SM-2 recalculation.

### Feeds  `/api/v1/feed/...`
| Endpoint | Description |
|----------|-------------|
| GET /feed/learn | Unseen cards first, then least-recently reviewed |
| GET /feed/revision | Cards due today by SM-2 schedule |
| GET /feed/interview | Interview-type cards, filterable by topic/difficulty |

### Uploads  `/api/v1/uploads`
Upload PDF/DOCX/TXT → server parses text → AI generates Q&A cards → poll `/uploads/{id}/status` → retrieve cards at `/uploads/{id}/cards`.

### Progress  `/api/v1/progress/...`
| Endpoint | Description |
|----------|-------------|
| GET /summary | Full overview: streak, today goal, topic progress |
| POST /sessions | Record a study session |
| GET /sessions | Paginated session history |
| GET /streak | Current and longest streak |
| GET /heatmap | Daily activity for last N days |

### Sync  `/api/v1/sync/...`
| Endpoint | Description |
|----------|-------------|
| POST /sync/push | Client pushes batched offline changes |
| GET /sync/pull | Server changes since last sync timestamp |

---

## Running Tests

```bash
# All tests
pytest

# With verbose output
pytest -v

# Unit tests only
pytest app/tests/unit/

# Integration tests only
pytest app/tests/integration/

# Specific file
pytest app/tests/integration/test_cards.py -v
```

**Current coverage: 56 tests, 100% passing.**

---

## Database Models

| Model | Description |
|-------|-------------|
| `User` | Account, settings (daily goal, notifications, theme) |
| `Topic` | Learning topic with color + icon |
| `Card` | Q&A flashcard (learn / revision / interview type) |
| `SRSRecord` | Per-card SM-2 state (ease factor, interval, next review) |
| `UploadedFile` | Uploaded document with parse status |
| `StudySession` | One study session record |
| `UserStreak` | Current and longest streak, total cards reviewed |
| `RefreshToken` | Issued refresh tokens with revocation support |

---

## SM-2 Spaced Repetition Algorithm

On **Know**: interval grows — 1d → 6d → `prev × ease_factor`. Ease factor increases.
On **Don't Know**: interval resets to 1 day, repetitions reset to 0, ease factor decreases (never below 1.3).

---

## AI Service (Phase 1 → Phase 2)

Phase 1 (active): Rules-based extraction — sentence splitting, "X is Y" patterns, colon patterns. No API calls, no cost, fully offline.

Phase 2 (ready to plug in): `ai_service.py` exports an abstract `BaseAIService`. Uncomment the relevant lines in `get_ai_service()` and set `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` in `.env`.

---

## Production Checklist

- [ ] Set a strong `SECRET_KEY` in `.env`
- [ ] Switch `DATABASE_URL` to PostgreSQL
- [ ] Set `DEBUG=false`
- [ ] Run Alembic migrations: `alembic upgrade head`
- [ ] Configure Redis + Celery for file processing workers
- [ ] Set `UPLOAD_DIR` to a persistent volume or S3 bucket
- [ ] Restrict `allow_origins` in CORS middleware

---

## Development Roadmap

| Phase | Status | Focus |
|-------|--------|-------|
| 1 — Foundation | ✅ Complete | Auth, models, SQLite, SRS engine, all APIs |
| 2 — AI Integration | 🔜 Next | LLM Q&A generation, difficulty classifier |
| 3 — Scale | 🔜 Future | PostgreSQL, Redis/Celery, vector search, push notifications |
