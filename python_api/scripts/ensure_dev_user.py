"""Cria ou atualiza usuario local de desenvolvimento."""
from __future__ import annotations

import os
import sys
from datetime import datetime
from pathlib import Path

from passlib.context import CryptContext
from sqlalchemy import create_engine, text

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app.database import DATABASE_URL  # noqa: E402

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

EMAIL = os.getenv("DEV_USER_EMAIL", "miguelparazzi@gmail.com").lower()
PASSWORD = os.getenv("DEV_USER_PASSWORD", "miguelparazzi18")
NAME = os.getenv("DEV_USER_NAME", EMAIL.split("@")[0])
ROLE = os.getenv("DEV_USER_ROLE", "admin")


def main() -> None:
    engine = create_engine(DATABASE_URL)
    password_hash = pwd_context.hash(PASSWORD)
    with engine.begin() as conn:
        row = conn.execute(
            text("SELECT id FROM users WHERE email = :email"),
            {"email": EMAIL},
        ).fetchone()
        if row:
            conn.execute(
                text(
                    "UPDATE users SET password_hash = :hash, role = :role, name = :name "
                    "WHERE email = :email"
                ),
                {
                    "hash": password_hash,
                    "role": ROLE,
                    "name": NAME,
                    "email": EMAIL,
                },
            )
            print(f"Senha atualizada para {EMAIL}")
        else:
            conn.execute(
                text(
                    "INSERT INTO users (name, email, password_hash, role, created_at) "
                    "VALUES (:name, :email, :hash, :role, :created_at)"
                ),
                {
                    "name": NAME,
                    "email": EMAIL,
                    "hash": password_hash,
                    "role": ROLE,
                    "created_at": datetime.utcnow(),
                },
            )
            print(f"Usuario criado: {EMAIL} ({ROLE})")


if __name__ == "__main__":
    main()
