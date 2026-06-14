from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.db.models.user import User
from app.db.models.refresh_token import RefreshToken
from app.db.models.streak import UserStreak
from app.db.base import generate_uuid
from app.core.security import (
    hash_password, verify_password,
    create_access_token, create_refresh_token, decode_token,
)
from app.core.dependencies import get_current_active_user
from app.core.exceptions import ConflictException, UnauthorizedException, BadRequestException
from app.schemas.auth import (
    RegisterRequest, LoginRequest, TokenResponse,
    RefreshRequest, UserResponse, UserUpdate, MessageResponse,
)
from app.config import settings

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    # Check duplicate email
    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise ConflictException("Email already registered")

    user = User(
        id=generate_uuid(),
        email=body.email,
        password_hash=hash_password(body.password),
        display_name=body.display_name,
    )
    db.add(user)
    await db.flush()

    # Create a default streak record
    streak = UserStreak(id=generate_uuid(), user_id=user.id)
    db.add(streak)

    access_token = create_access_token(user.id)
    refresh_token_str, expires_at = create_refresh_token(user.id)

    rt = RefreshToken(
        id=generate_uuid(),
        user_id=user.id,
        token=refresh_token_str,
        expires_at=expires_at,
    )
    db.add(rt)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token_str,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated",
        )

    access_token = create_access_token(user.id)
    refresh_token_str, expires_at = create_refresh_token(user.id)

    rt = RefreshToken(
        id=generate_uuid(),
        user_id=user.id,
        token=refresh_token_str,
        expires_at=expires_at,
    )
    db.add(rt)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token_str,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    from datetime import datetime

    result = await db.execute(
        select(RefreshToken).where(RefreshToken.token == body.refresh_token)
    )
    rt = result.scalar_one_or_none()

    if not rt:
        raise UnauthorizedException("Invalid refresh token")

    if rt.is_revoked:
        raise UnauthorizedException("Refresh token has been revoked")

    if rt.expires_at < datetime.utcnow():
        raise UnauthorizedException("Refresh token has expired")

    payload = decode_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise UnauthorizedException("Invalid refresh token")

    # Revoke old token
    rt.is_revoked = True

    # Issue new pair
    new_access = create_access_token(rt.user_id)
    new_refresh_str, new_expires = create_refresh_token(rt.user_id)

    new_rt = RefreshToken(
        id=generate_uuid(),
        user_id=rt.user_id,
        token=new_refresh_str,
        expires_at=new_expires,
    )
    db.add(new_rt)

    return TokenResponse(
        access_token=new_access,
        refresh_token=new_refresh_str,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.delete("/logout", response_model=MessageResponse)
async def logout(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(RefreshToken)
        .where(RefreshToken.token == body.refresh_token)
        .where(RefreshToken.user_id == current_user.id)
    )
    rt = result.scalar_one_or_none()
    if rt:
        rt.is_revoked = True
    return MessageResponse(message="Logged out successfully")


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_active_user)):
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_me(
    body: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if body.display_name is not None:
        current_user.display_name = body.display_name
    if body.avatar_url is not None:
        current_user.avatar_url = body.avatar_url
    if body.settings is not None:
        merged = {**current_user.settings, **body.settings}
        current_user.settings = merged
    return current_user


@router.delete("/me", response_model=MessageResponse)
async def delete_account(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    current_user.is_active = False
    return MessageResponse(message="Account deactivated successfully")
