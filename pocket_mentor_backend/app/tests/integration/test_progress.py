import pytest
from datetime import datetime
from httpx import AsyncClient


@pytest.mark.asyncio
class TestProgress:
    async def test_progress_summary(self, auth_client: AsyncClient):
        resp = await auth_client.get("/api/v1/progress/summary")
        assert resp.status_code == 200
        data = resp.json()
        assert "streak" in data
        assert "today_cards_reviewed" in data
        assert "today_goal" in data
        assert "topic_progress" in data

    async def test_create_session(self, auth_client: AsyncClient):
        now = datetime.utcnow().isoformat()
        resp = await auth_client.post("/api/v1/progress/sessions", json={
            "mode": "learn",
            "cards_reviewed": 15,
            "cards_known": 10,
            "cards_unknown": 5,
            "duration_seconds": 300,
            "started_at": now,
        })
        assert resp.status_code == 201
        data = resp.json()
        assert data["cards_reviewed"] == 15
        assert data["accuracy_percent"] == pytest.approx(66.7, 0.1)

    async def test_list_sessions(self, auth_client: AsyncClient):
        now = datetime.utcnow().isoformat()
        for mode in ["learn", "revision", "interview"]:
            await auth_client.post("/api/v1/progress/sessions", json={
                "mode": mode,
                "cards_reviewed": 5,
                "cards_known": 3,
                "cards_unknown": 2,
                "duration_seconds": 120,
                "started_at": now,
            })
        resp = await auth_client.get("/api/v1/progress/sessions")
        assert resp.status_code == 200
        assert resp.json()["total"] == 3

    async def test_streak_starts_at_zero(self, auth_client: AsyncClient):
        resp = await auth_client.get("/api/v1/progress/streak")
        assert resp.status_code == 200
        data = resp.json()
        assert data["current_streak"] == 0

    async def test_streak_increments_after_session(self, auth_client: AsyncClient):
        now = datetime.utcnow().isoformat()
        await auth_client.post("/api/v1/progress/sessions", json={
            "mode": "learn",
            "cards_reviewed": 10,
            "cards_known": 8,
            "cards_unknown": 2,
            "duration_seconds": 200,
            "started_at": now,
        })
        resp = await auth_client.get("/api/v1/progress/streak")
        assert resp.json()["current_streak"] == 1
        assert resp.json()["total_cards_reviewed"] == 10

    async def test_heatmap_returns_entries(self, auth_client: AsyncClient):
        now = datetime.utcnow().isoformat()
        await auth_client.post("/api/v1/progress/sessions", json={
            "mode": "learn",
            "cards_reviewed": 5,
            "cards_known": 5,
            "cards_unknown": 0,
            "duration_seconds": 100,
            "started_at": now,
        })
        resp = await auth_client.get("/api/v1/progress/heatmap?days=30")
        assert resp.status_code == 200
        data = resp.json()
        assert "entries" in data
        assert len(data["entries"]) >= 1
