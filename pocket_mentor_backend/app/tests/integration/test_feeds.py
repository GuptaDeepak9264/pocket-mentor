import pytest
from httpx import AsyncClient


async def _setup_topic_and_cards(client: AsyncClient) -> str:
    topic_resp = await client.post("/api/v1/topics", json={
        "title": "Feed Test Topic", "color_tag": "#6366F1", "icon": "book"
    })
    topic_id = topic_resp.json()["id"]
    for i in range(5):
        await client.post(f"/api/v1/topics/{topic_id}/cards", json={
            "question": f"Question {i}?",
            "answer": f"Answer {i}",
            "difficulty": (i % 5) + 1,
            "card_type": "learn",
        })
    return topic_id


@pytest.mark.asyncio
class TestFeeds:
    async def test_learn_feed_returns_cards(self, auth_client: AsyncClient):
        await _setup_topic_and_cards(auth_client)
        resp = await auth_client.get("/api/v1/feed/learn")
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] == 5
        assert len(data["cards"]) == 5

    async def test_learn_feed_topic_filter(self, auth_client: AsyncClient):
        topic_id = await _setup_topic_and_cards(auth_client)
        other_topic = await auth_client.post("/api/v1/topics", json={
            "title": "Other", "color_tag": "#FF0000", "icon": "star"
        })
        resp = await auth_client.get(f"/api/v1/feed/learn?topic_id={topic_id}")
        assert resp.status_code == 200
        assert resp.json()["total"] == 5

    async def test_learn_feed_limit(self, auth_client: AsyncClient):
        await _setup_topic_and_cards(auth_client)
        resp = await auth_client.get("/api/v1/feed/learn?limit=3")
        assert resp.status_code == 200
        assert len(resp.json()["cards"]) == 3

    async def test_revision_feed_empty_initially(self, auth_client: AsyncClient):
        resp = await auth_client.get("/api/v1/feed/revision")
        assert resp.status_code == 200
        # No cards reviewed yet → due_today should reflect new cards available
        data = resp.json()
        assert "due_today" in data
        assert "overdue" in data

    async def test_interview_feed_empty_without_interview_cards(self, auth_client: AsyncClient):
        await _setup_topic_and_cards(auth_client)  # These are "learn" type cards
        resp = await auth_client.get("/api/v1/feed/interview")
        assert resp.status_code == 200
        # No interview-type cards were created
        assert resp.json()["total"] == 0

    async def test_interview_feed_with_interview_cards(self, auth_client: AsyncClient):
        topic_resp = await auth_client.post("/api/v1/topics", json={
            "title": "Interview", "color_tag": "#6366F1", "icon": "briefcase"
        })
        topic_id = topic_resp.json()["id"]
        for i in range(3):
            await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json={
                "question": f"Interview Q{i}?",
                "answer": f"Answer {i}",
                "difficulty": 3,
                "card_type": "interview",
            })
        resp = await auth_client.get("/api/v1/feed/interview")
        assert resp.status_code == 200
        assert resp.json()["total"] == 3
