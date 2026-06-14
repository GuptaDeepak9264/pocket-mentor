import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
class TestAuthRegister:
    async def test_register_success(self, client: AsyncClient):
        resp = await client.post("/api/v1/auth/register", json={
            "email": "newuser@example.com",
            "password": "securepass123",
            "display_name": "New User",
        })
        assert resp.status_code == 201
        data = resp.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"

    async def test_register_duplicate_email(self, client: AsyncClient):
        payload = {
            "email": "dup@example.com",
            "password": "securepass123",
            "display_name": "User",
        }
        await client.post("/api/v1/auth/register", json=payload)
        resp = await client.post("/api/v1/auth/register", json=payload)
        assert resp.status_code == 409

    async def test_register_short_password(self, client: AsyncClient):
        resp = await client.post("/api/v1/auth/register", json={
            "email": "short@example.com",
            "password": "abc",
            "display_name": "User",
        })
        assert resp.status_code == 422

    async def test_register_invalid_email(self, client: AsyncClient):
        resp = await client.post("/api/v1/auth/register", json={
            "email": "not-an-email",
            "password": "securepass123",
            "display_name": "User",
        })
        assert resp.status_code == 422


@pytest.mark.asyncio
class TestAuthLogin:
    async def test_login_success(self, client: AsyncClient):
        await client.post("/api/v1/auth/register", json={
            "email": "login@example.com",
            "password": "loginpass123",
            "display_name": "Login User",
        })
        resp = await client.post("/api/v1/auth/login", json={
            "email": "login@example.com",
            "password": "loginpass123",
        })
        assert resp.status_code == 200
        assert "access_token" in resp.json()

    async def test_login_wrong_password(self, client: AsyncClient):
        await client.post("/api/v1/auth/register", json={
            "email": "wrongpw@example.com",
            "password": "correctpass123",
            "display_name": "User",
        })
        resp = await client.post("/api/v1/auth/login", json={
            "email": "wrongpw@example.com",
            "password": "wrongpassword",
        })
        assert resp.status_code == 401

    async def test_login_unknown_email(self, client: AsyncClient):
        resp = await client.post("/api/v1/auth/login", json={
            "email": "ghost@example.com",
            "password": "anypassword123",
        })
        assert resp.status_code == 401


@pytest.mark.asyncio
class TestAuthMe:
    async def test_get_me(self, auth_client: AsyncClient):
        resp = await auth_client.get("/api/v1/auth/me")
        assert resp.status_code == 200
        data = resp.json()
        assert data["email"] == "test@example.com"
        assert data["display_name"] == "Test User"

    async def test_get_me_unauthenticated(self, client: AsyncClient):
        resp = await client.get("/api/v1/auth/me")
        assert resp.status_code == 403

    async def test_update_me(self, auth_client: AsyncClient):
        resp = await auth_client.patch("/api/v1/auth/me", json={
            "display_name": "Updated Name"
        })
        assert resp.status_code == 200
        assert resp.json()["display_name"] == "Updated Name"


@pytest.mark.asyncio
class TestRefreshToken:
    async def test_refresh_token_success(self, client: AsyncClient):
        reg = await client.post("/api/v1/auth/register", json={
            "email": "refresh@example.com",
            "password": "refreshpass123",
            "display_name": "Refresh User",
        })
        refresh_token = reg.json()["refresh_token"]

        resp = await client.post("/api/v1/auth/refresh", json={
            "refresh_token": refresh_token
        })
        assert resp.status_code == 200
        new_data = resp.json()
        assert "access_token" in new_data
        assert new_data["refresh_token"] != refresh_token  # new token issued

    async def test_refresh_with_invalid_token(self, client: AsyncClient):
        resp = await client.post("/api/v1/auth/refresh", json={
            "refresh_token": "invalid.token.here"
        })
        assert resp.status_code == 401
