import pytest
from httpx import AsyncClient


async def _create_topic(client: AsyncClient) -> str:
    resp = await client.post("/api/v1/topics", json={
        "title": "Test Topic",
        "color_tag": "#6366F1",
        "icon": "book",
    })
    return resp.json()["id"]


@pytest.mark.asyncio
class TestCards:
    async def test_create_card(self, auth_client: AsyncClient, sample_card_payload):
        topic_id = await _create_topic(auth_client)
        resp = await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json=sample_card_payload)
        assert resp.status_code == 201
        data = resp.json()
        assert data["question"] == sample_card_payload["question"]
        assert data["source"] == "manual"
        assert data["srs_info"] is not None
        assert data["srs_info"]["repetitions"] == 0

    async def test_list_cards(self, auth_client: AsyncClient, sample_card_payload):
        topic_id = await _create_topic(auth_client)
        await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json=sample_card_payload)
        await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json={
            **sample_card_payload, "question": "What is a tuple?"
        })
        resp = await auth_client.get(f"/api/v1/topics/{topic_id}/cards")
        assert resp.status_code == 200
        assert resp.json()["total"] == 2

    async def test_get_card(self, auth_client: AsyncClient, sample_card_payload):
        topic_id = await _create_topic(auth_client)
        create_resp = await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json=sample_card_payload)
        card_id = create_resp.json()["id"]
        resp = await auth_client.get(f"/api/v1/cards/{card_id}")
        assert resp.status_code == 200
        assert resp.json()["id"] == card_id

    async def test_update_card(self, auth_client: AsyncClient, sample_card_payload):
        topic_id = await _create_topic(auth_client)
        create_resp = await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json=sample_card_payload)
        card_id = create_resp.json()["id"]
        resp = await auth_client.patch(f"/api/v1/cards/{card_id}", json={"difficulty": 5})
        assert resp.status_code == 200
        assert resp.json()["difficulty"] == 5

    async def test_delete_card(self, auth_client: AsyncClient, sample_card_payload):
        topic_id = await _create_topic(auth_client)
        create_resp = await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json=sample_card_payload)
        card_id = create_resp.json()["id"]
        resp = await auth_client.delete(f"/api/v1/cards/{card_id}")
        assert resp.status_code == 200
        get_resp = await auth_client.get(f"/api/v1/cards/{card_id}")
        assert get_resp.status_code == 404

    async def test_submit_know_response(self, auth_client: AsyncClient, sample_card_payload):
        topic_id = await _create_topic(auth_client)
        create_resp = await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json=sample_card_payload)
        card_id = create_resp.json()["id"]
        resp = await auth_client.post(f"/api/v1/cards/{card_id}/response", json={"result": "know"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["result"] == "know"
        assert data["interval_days"] >= 1

    async def test_submit_dont_know_response(self, auth_client: AsyncClient, sample_card_payload):
        topic_id = await _create_topic(auth_client)
        create_resp = await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json=sample_card_payload)
        card_id = create_resp.json()["id"]
        resp = await auth_client.post(f"/api/v1/cards/{card_id}/response", json={"result": "dont_know"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["result"] == "dont_know"
        assert data["interval_days"] == 1

    async def test_srs_updates_after_multiple_responses(self, auth_client: AsyncClient, sample_card_payload):
        topic_id = await _create_topic(auth_client)
        create_resp = await auth_client.post(f"/api/v1/topics/{topic_id}/cards", json=sample_card_payload)
        card_id = create_resp.json()["id"]

        # Three consecutive "know" responses
        r1 = await auth_client.post(f"/api/v1/cards/{card_id}/response", json={"result": "know"})
        r2 = await auth_client.post(f"/api/v1/cards/{card_id}/response", json={"result": "know"})
        r3 = await auth_client.post(f"/api/v1/cards/{card_id}/response", json={"result": "know"})

        assert r3.json()["interval_days"] > r1.json()["interval_days"]
