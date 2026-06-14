import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

from app.main import app
from app.db.base import Base
from app.db.session import get_db

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)


async def override_get_db():
    async with TestSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


@pytest_asyncio.fixture(scope="function", autouse=True)
async def setup_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def client():
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def auth_client(client: AsyncClient):
    """Returns an authenticated client with a registered user."""
    resp = await client.post("/api/v1/auth/register", json={
        "email": "test@example.com",
        "password": "testpassword123",
        "display_name": "Test User",
    })
    assert resp.status_code == 201
    tokens = resp.json()
    client.headers["Authorization"] = f"Bearer {tokens['access_token']}"
    return client


@pytest.fixture
def sample_topic_payload():
    return {
        "title": "Python Basics",
        "description": "Core Python concepts",
        "color_tag": "#6366F1",
        "icon": "code",
        "is_public": False,
    }


@pytest.fixture
def sample_card_payload():
    return {
        "question": "What is a Python list?",
        "answer": "A mutable, ordered sequence of elements.",
        "hint": "Think of a dynamic array",
        "difficulty": 2,
        "card_type": "learn",
    }
