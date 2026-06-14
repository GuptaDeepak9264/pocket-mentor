import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
class TestTopics:
    async def test_create_topic(self, auth_client: AsyncClient, sample_topic_payload):
        resp = await auth_client.post("/api/v1/topics", json=sample_topic_payload)
        assert resp.status_code == 201
        data = resp.json()
        assert data["title"] == sample_topic_payload["title"]
        assert data["card_count"] == 0
        assert "id" in data

    async def test_list_topics_empty(self, auth_client: AsyncClient):
        resp = await auth_client.get("/api/v1/topics")
        assert resp.status_code == 200
        assert resp.json()["total"] == 0

    async def test_list_topics_with_data(self, auth_client: AsyncClient, sample_topic_payload):
        await auth_client.post("/api/v1/topics", json=sample_topic_payload)
        await auth_client.post("/api/v1/topics", json={**sample_topic_payload, "title": "Topic 2"})
        resp = await auth_client.get("/api/v1/topics")
        assert resp.json()["total"] == 2

    async def test_get_topic(self, auth_client: AsyncClient, sample_topic_payload):
        create_resp = await auth_client.post("/api/v1/topics", json=sample_topic_payload)
        topic_id = create_resp.json()["id"]
        resp = await auth_client.get(f"/api/v1/topics/{topic_id}")
        assert resp.status_code == 200
        assert resp.json()["id"] == topic_id

    async def test_get_topic_not_found(self, auth_client: AsyncClient):
        resp = await auth_client.get("/api/v1/topics/nonexistent-id")
        assert resp.status_code == 404

    async def test_update_topic(self, auth_client: AsyncClient, sample_topic_payload):
        create_resp = await auth_client.post("/api/v1/topics", json=sample_topic_payload)
        topic_id = create_resp.json()["id"]
        resp = await auth_client.patch(f"/api/v1/topics/{topic_id}", json={"title": "Updated Title"})
        assert resp.status_code == 200
        assert resp.json()["title"] == "Updated Title"

    async def test_delete_topic(self, auth_client: AsyncClient, sample_topic_payload):
        create_resp = await auth_client.post("/api/v1/topics", json=sample_topic_payload)
        topic_id = create_resp.json()["id"]
        resp = await auth_client.delete(f"/api/v1/topics/{topic_id}")
        assert resp.status_code == 200
        get_resp = await auth_client.get(f"/api/v1/topics/{topic_id}")
        assert get_resp.status_code == 404

    async def test_cannot_access_other_users_topic(self, client: AsyncClient, sample_topic_payload):
        # Register user A and create topic
        await client.post("/api/v1/auth/register", json={
            "email": "usera@example.com", "password": "passwordA123", "display_name": "User A"
        })
        login_a = await client.post("/api/v1/auth/login", json={
            "email": "usera@example.com", "password": "passwordA123"
        })
        client.headers["Authorization"] = f"Bearer {login_a.json()['access_token']}"
        create_resp = await client.post("/api/v1/topics", json=sample_topic_payload)
        topic_id = create_resp.json()["id"]

        # Register user B and try to access topic
        await client.post("/api/v1/auth/register", json={
            "email": "userb@example.com", "password": "passwordB123", "display_name": "User B"
        })
        login_b = await client.post("/api/v1/auth/login", json={
            "email": "userb@example.com", "password": "passwordB123"
        })
        client.headers["Authorization"] = f"Bearer {login_b.json()['access_token']}"
        resp = await client.get(f"/api/v1/topics/{topic_id}")
        assert resp.status_code == 403
