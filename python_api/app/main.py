from __future__ import annotations

from datetime import datetime
import json
import logging
import os
import re
import secrets
import time
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request, status
from fastapi.middleware.cors import CORSMiddleware
from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import Base, SessionLocal, engine
from .models import Answer, Assessment, AuthToken, Company, Question, User
from .schemas import (
    ForgotPasswordRequest,
    LoginRequest,
    ResetPasswordRequest,
    SaveAssessmentRequest,
    SignupCompanyRequest,
)


app = FastAPI(title="Bot Soberania Python API", version="0.2.0")
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
logger = logging.getLogger("bot_soberania_api")

AUTO_CREATE_SCHEMA = os.getenv("AUTO_CREATE_SCHEMA", "1") == "1"
TOKEN_TTL_MINUTES = int(os.getenv("TOKEN_TTL_MINUTES", "1440"))  # 24h
PASSWORD_MIN_LENGTH = int(os.getenv("PASSWORD_MIN_LENGTH", "8"))
RATE_LIMIT_WINDOW_SECONDS = int(os.getenv("RATE_LIMIT_WINDOW_SECONDS", "60"))
RATE_LIMIT_MAX_ATTEMPTS = int(os.getenv("RATE_LIMIT_MAX_ATTEMPTS", "15"))
RATE_LIMITED_PATHS = {"/login", "/forgot_password", "/reset_password", "/signup_company"}
ALLOWED_ORIGIN_REGEX = os.getenv(
    "ALLOWED_ORIGIN_REGEX",
    r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
)

# key: "<ip>:<path>" -> [timestamps]
RATE_LIMIT_BUCKETS: dict[str, list[float]] = {}

app.add_middleware(
    CORSMiddleware,
    allow_origins=[],
    allow_origin_regex=ALLOWED_ORIGIN_REGEX,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup() -> None:
    # Mantem compatibilidade local. Em ambientes com Alembic, use AUTO_CREATE_SCHEMA=0.
    if AUTO_CREATE_SCHEMA:
        Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _validate_password_policy(password: str) -> None:
    if len(password) < PASSWORD_MIN_LENGTH:
        raise HTTPException(
            status_code=400,
            detail=f"Password must have at least {PASSWORD_MIN_LENGTH} characters",
        )
    if not re.search(r"[A-Za-z]", password) or not re.search(r"\d", password):
        raise HTTPException(
            status_code=400,
            detail="Password must contain at least one letter and one number",
        )


def _apply_rate_limit(request: Request) -> None:
    path = request.url.path
    if path not in RATE_LIMITED_PATHS:
        return
    ip = request.client.host if request.client else "unknown"
    key = f"{ip}:{path}"
    now = time.time()
    window_start = now - RATE_LIMIT_WINDOW_SECONDS
    timestamps = [t for t in RATE_LIMIT_BUCKETS.get(key, []) if t >= window_start]
    if len(timestamps) >= RATE_LIMIT_MAX_ATTEMPTS:
        raise HTTPException(
            status_code=429,
            detail="Too many attempts. Please try again later.",
        )
    timestamps.append(now)
    RATE_LIMIT_BUCKETS[key] = timestamps


def _generate_token() -> str:
    exp_ts = int(time.time() + TOKEN_TTL_MINUTES * 60)
    nonce = secrets.token_urlsafe(24)
    return f"v1.{exp_ts}.{nonce}"


def _token_is_expired(token_value: str) -> bool:
    parts = token_value.split(".")
    if len(parts) < 3 or parts[0] != "v1":
        return True
    try:
        exp_ts = int(parts[1])
    except ValueError:
        return True
    return time.time() > exp_ts


def _extract_bearer(authorization: Optional[str]) -> str:
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    prefix = "Bearer "
    if not authorization.startswith(prefix):
        raise HTTPException(status_code=401, detail="Invalid Authorization header format")
    token = authorization[len(prefix) :].strip()
    if not token:
        raise HTTPException(status_code=401, detail="Invalid Authorization token")
    return token


def get_current_user(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
) -> User:
    token_value = _extract_bearer(authorization)
    if _token_is_expired(token_value):
        # limpeza defensiva do token expirado
        token_obj = db.get(AuthToken, token_value)
        if token_obj:
            db.delete(token_obj)
            db.commit()
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    token = db.get(AuthToken, token_value)
    if not token:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    user = db.get(User, token.user_id)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user


@app.get("/health")
def health():
    return {
        "ok": True,
        "service": "python_api",
        "db": "connected",
        "security": {
            "token_ttl_minutes": TOKEN_TTL_MINUTES,
            "password_min_length": PASSWORD_MIN_LENGTH,
            "rate_limit_window_seconds": RATE_LIMIT_WINDOW_SECONDS,
            "rate_limit_max_attempts": RATE_LIMIT_MAX_ATTEMPTS,
        },
    }


@app.post("/forgot_password")
def forgot_password(
    payload: ForgotPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    _apply_rate_limit(request)
    user = db.scalar(select(User).where(User.email == payload.email.lower()))
    if user:
        reset = {"token": secrets.token_hex(16), "expiration": None, "used": False}
        user.password_reset = json.dumps(reset, ensure_ascii=False)
        db.add(user)
        db.commit()
    return {"ok": True, "email": payload.email}


@app.post("/reset_password")
def reset_password(
    payload: ResetPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    _apply_rate_limit(request)
    _validate_password_policy(payload.new_password)
    user = db.scalar(select(User).where(User.email == payload.email.lower()))
    if user:
        user.password_hash = pwd_context.hash(payload.new_password)
        user.legacy_password_hash = None
        user.password_reset = json.dumps(
            {"token": payload.token, "expiration": None, "used": True},
            ensure_ascii=False,
        )
        db.add(user)
        db.commit()
    return {"ok": True}


@app.post("/login")
def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)):
    _apply_rate_limit(request)
    email = payload.email.lower()
    user = db.scalar(select(User).where(User.email == email))
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    valid = False
    if user.password_hash:
        valid = pwd_context.verify(payload.password, user.password_hash)

    if not valid:
        logger.warning("Invalid login attempt for email=%s", email)
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = _generate_token()
    db.add(AuthToken(token=token, user_id=user.id))
    db.commit()

    display_name = user.name or email.split("@")[0]
    return {
        "authToken": token,
        "user": {"id": user.id, "name": display_name, "email": user.email},
        "admin_name": display_name,
        "name": display_name,
    }


@app.post("/signup_company")
def signup_company(
    payload: SignupCompanyRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    _apply_rate_limit(request)
    _validate_password_policy(payload.password)
    email = payload.email.lower()
    existing = db.scalar(select(User).where(User.email == email))
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    company = Company(
        name=payload.company_name.strip(),
        cnpj=payload.cnpj,
        segment=payload.segment,
        status="ACTIVE",
        created_at=datetime.utcnow(),
    )
    db.add(company)
    db.flush()

    user = User(
        name=payload.name.strip(),
        email=email,
        password_hash=pwd_context.hash(payload.password),
        role=payload.role,
        company_id=company.id,
        last_name=payload.last_name,
        phone=payload.phone,
        created_at=datetime.utcnow(),
    )
    db.add(user)
    db.flush()

    token = _generate_token()
    db.add(AuthToken(token=token, user_id=user.id))
    db.commit()

    return {
        "authToken": token,
        "user": {"id": user.id, "name": user.name, "email": user.email},
        "admin_name": payload.admin_name,
        "name": user.name,
    }


@app.post("/assessment/resume")
def assessment_resume(_: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    assessment = db.scalar(
        select(Assessment)
        .where(Assessment.created_by == current_user.id)
        .order_by(Assessment.id.desc())
    )
    if not assessment:
        assessment = Assessment(
            company_id=current_user.company_id,
            status="IN_PROGRESS",
            current_phase="QUICK_WINS",
            last_question=0,
            progress_percent=0,
            created_by=current_user.id,
            created_at=datetime.utcnow(),
        )
        db.add(assessment)
        db.commit()
        db.refresh(assessment)
    return {"id": assessment.id}


@app.get("/questions")
def list_questions(
    phase: str = Query(...),
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = db.scalars(select(Question).where(Question.phase == phase).order_by(Question.order_index.asc())).all()
    return [
        {
            "id": q.id,
            "phase": q.phase,
            "pilar": q.pilar,
            "dominio": q.dominio,
            "recommendation": q.recommendation,
            "recommendation_en": q.recommendation_en,
            "recommendation_es": q.recommendation_es,
            "guidance": q.guidance,
            "how_to_check": q.how_to_check,
            "order_index": q.order_index or 0,
            "question_code": q.question_code,
            "aws_service": q.aws_service,
        }
        for q in rows
    ]


@app.get("/progress/assessment")
def get_progress(
    assessment_id: int = Query(...),
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = db.scalars(
        select(Answer).where(Answer.assessment_id == assessment_id).order_by(Answer.id.asc())
    ).all()
    return {
        "assessment_id": assessment_id,
        "answers": [
            {
                "id": a.id,
                "question": a.question_id,
                "score": a.score,
                "justification": a.justification,
                "evidence": a.evidence,
            }
            for a in rows
        ],
    }


@app.post("/assessment/save")
def save_assessment(
    payload: SaveAssessmentRequest,
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    saved = 0
    for item in payload.answers:
        row = db.scalar(
            select(Answer).where(
                Answer.assessment_id == payload.assessment_id,
                Answer.question_id == item.question_id,
            )
        )
        if not row:
            row = Answer(
                assessment_id=payload.assessment_id,
                question_id=item.question_id,
                created_at=datetime.utcnow(),
            )
        row.score = item.score
        row.justification = item.justification or ""
        row.evidence = item.evidence or ""
        row.updated_at = datetime.utcnow()
        db.add(row)
        saved += 1

    db.commit()
    return {"ok": True, "saved": saved}
