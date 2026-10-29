from __future__ import annotations

import base64
import hashlib
from typing import Any


def mosquitto_hash(password: str, username: str = "") -> str:
    """Generate deterministic PBKDF2-SHA512 password hash for Mosquitto."""
    if not isinstance(password, str):
        password = str(password)

    if password.startswith("$7$") or password.startswith("$6$"):
        return password

    salt = hashlib.sha512(f"mosquitto:{username}".encode("utf-8")).digest()
    key = hashlib.pbkdf2_hmac("sha512", password.encode("utf-8"), salt, 1000, dklen=64)
    salt_b64 = base64.b64encode(salt).decode("ascii")
    key_b64 = base64.b64encode(key).decode("ascii")
    return f"$7$1000${salt_b64}${key_b64}"


class FilterModule:
    """Mosquitto password hashing filter."""

    def filters(self) -> dict[str, Any]:
        return {
            "mosquitto_hash": mosquitto_hash,
        }
