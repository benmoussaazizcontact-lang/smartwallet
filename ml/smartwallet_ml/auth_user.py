"""Bind an inference request to the Supabase user who presented the token."""

from __future__ import annotations

import json
import os
import urllib.request


class AuthError(Exception):
    def __init__(self, status: int, detail: str) -> None:
        super().__init__(detail)
        self.status = status
        self.detail = detail


def verify_supabase_user(authorization: str | None) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise AuthError(401, "Authentication required")
    token = authorization.removeprefix("Bearer ").strip()
    if not token or token.startswith("sb_secret") or "service_role" in token:
        raise AuthError(401, "Privileged credentials are not accepted")
    base = os.environ.get("SUPABASE_URL", "").rstrip("/")
    anon = os.environ.get("SUPABASE_ANON_KEY", "").strip()
    if not base.startswith("https://") or not anon:
        raise AuthError(503, "Supabase user verification is not configured")
    request = urllib.request.Request(
        f"{base}/auth/v1/user",
        headers={"Authorization": f"Bearer {token}", "apikey": anon},
    )
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except Exception as error:  # noqa: BLE001 - network and HTTP errors become 401
        raise AuthError(401, "Authentication required") from error
    user_id = str(payload.get("id") or "")
    if not user_id:
        raise AuthError(401, "Authentication required")
    return user_id


def require_same_user(authenticated_user: str, requested_user: str) -> None:
    if not requested_user or requested_user != authenticated_user:
        raise AuthError(403, "Cross-user inference is refused")
