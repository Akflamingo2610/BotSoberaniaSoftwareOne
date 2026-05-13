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
    UpdateUserProfileRequest,
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
        "user": {
            "id": user.id,
            "name": display_name,
            "email": user.email,
            "role": user.role or "user",
        },
        "admin_name": display_name,
        "name": display_name,
        "role": user.role or "user",
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
            "pilar_tecnico": q.pilar_tecnico,
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


def _require_admin(current_user: User) -> User:
    if (current_user.role or "").lower() != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user


@app.get("/admin/users")
def admin_list_users(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)
    users = db.scalars(select(User).order_by(User.created_at.desc())).all()
    result = []
    for u in users:
        company = db.get(Company, u.company_id) if u.company_id else None
        assessment = db.scalar(
            select(Assessment)
            .where(Assessment.created_by == u.id)
            .order_by(Assessment.id.desc())
        )
        answered_count = 0
        if assessment:
            answered_count = db.scalar(
                select(Answer).where(Answer.assessment_id == assessment.id)
                .__class__.count()
                if False else
                select(Answer.id).where(Answer.assessment_id == assessment.id)
            )
            answered_count = len(
                db.scalars(
                    select(Answer.id).where(Answer.assessment_id == assessment.id)
                ).all()
            )
        result.append({
            "id": u.id,
            "name": u.name,
            "last_name": u.last_name,
            "email": u.email,
            "role": u.role or "user",
            "phone": u.phone,
            "created_at": u.created_at.isoformat() if u.created_at else None,
            "company": {
                "id": company.id,
                "name": company.name,
                "cnpj": company.cnpj,
                "segment": company.segment,
            } if company else None,
            "assessment": {
                "id": assessment.id,
                "status": assessment.status,
                "current_phase": assessment.current_phase,
                "progress_percent": assessment.progress_percent,
                "answered_count": answered_count,
            } if assessment else None,
        })
    return result


@app.get("/admin/users/{user_id}/progress")
def admin_user_progress(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    assessments = db.scalars(
        select(Assessment)
        .where(Assessment.created_by == user_id)
        .order_by(Assessment.id.desc())
    ).all()

    result = []
    for assessment in assessments:
        answers = db.scalars(
            select(Answer).where(Answer.assessment_id == assessment.id)
        ).all()
        answer_details = []
        for a in answers:
            q = db.get(Question, a.question_id)
            answer_details.append({
                "question_id": a.question_id,
                "question_code": q.question_code if q else None,
                "pilar": q.pilar if q else None,
                "dominio": q.dominio if q else None,
                "pilar_tecnico": q.pilar_tecnico if q else None,
                "recommendation": q.recommendation if q else None,
                "aws_service": q.aws_service if q else None,
                "norms": q.norms if q else None,
                "score": a.score,
                "justification": a.justification,
                "evidence": a.evidence,
            })
        result.append({
            "id": assessment.id,
            "status": assessment.status,
            "current_phase": assessment.current_phase,
            "progress_percent": assessment.progress_percent,
            "created_at": assessment.created_at.isoformat() if assessment.created_at else None,
            "answers": answer_details,
        })

    company = db.get(Company, user.company_id) if user.company_id else None
    return {
        "user": {
            "id": user.id,
            "name": user.name,
            "last_name": user.last_name,
            "email": user.email,
            "role": user.role or "user",
            "phone": user.phone,
            "created_at": user.created_at.isoformat() if user.created_at else None,
            "company": {
                "id": company.id,
                "name": company.name,
                "cnpj": company.cnpj,
                "segment": company.segment,
                "status": company.status,
            } if company else None,
        },
        "assessments": result,
    }


def _clean_optional_str(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    stripped = value.strip()
    return stripped if stripped else None


@app.put("/admin/users/{user_id}")
def admin_update_user(
    user_id: int,
    payload: UpdateUserProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_admin(current_user)
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    new_name = _clean_optional_str(payload.name)
    new_last = _clean_optional_str(payload.last_name)
    new_phone = _clean_optional_str(payload.phone)
    new_role = _clean_optional_str(payload.role)
    new_company_name = _clean_optional_str(payload.company_name)
    new_cnpj = _clean_optional_str(payload.cnpj)
    new_segment = _clean_optional_str(payload.segment)

    if new_name is not None:
        user.name = new_name
    if new_last is not None:
        user.last_name = new_last
    if new_phone is not None:
        user.phone = new_phone
    if new_role is not None:
        user.role = new_role

    if user.created_at is None:
        user.created_at = datetime.utcnow()

    company = db.get(Company, user.company_id) if user.company_id else None
    has_company_data = any(
        v is not None for v in (new_company_name, new_cnpj, new_segment)
    )
    if has_company_data:
        if company is None:
            company = Company(
                name=new_company_name or "",
                cnpj=new_cnpj,
                segment=new_segment,
                status="ACTIVE",
                created_at=datetime.utcnow(),
            )
            db.add(company)
            db.flush()
            user.company_id = company.id
        else:
            if new_company_name is not None:
                company.name = new_company_name
            if new_cnpj is not None:
                company.cnpj = new_cnpj
            if new_segment is not None:
                company.segment = new_segment
            company.updated_at = datetime.utcnow()
            db.add(company)

    db.add(user)
    db.commit()
    db.refresh(user)
    company = db.get(Company, user.company_id) if user.company_id else None

    return {
        "ok": True,
        "user": {
            "id": user.id,
            "name": user.name,
            "last_name": user.last_name,
            "email": user.email,
            "role": user.role or "user",
            "phone": user.phone,
            "created_at": user.created_at.isoformat() if user.created_at else None,
            "company": {
                "id": company.id,
                "name": company.name,
                "cnpj": company.cnpj,
                "segment": company.segment,
                "status": company.status,
            } if company else None,
        },
    }


TOTAL_QUESTIONS = 72


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

    db.flush()

    assessment = db.get(Assessment, payload.assessment_id)
    if assessment is not None:
        answered_total = len(
            db.scalars(
                select(Answer.id).where(Answer.assessment_id == payload.assessment_id)
            ).all()
        )
        if answered_total >= TOTAL_QUESTIONS:
            assessment.status = "COMPLETED"
            assessment.progress_percent = 100.0
        else:
            assessment.status = "IN_PROGRESS"
            assessment.progress_percent = round(
                (answered_total / TOTAL_QUESTIONS) * 100, 2
            )
        assessment.updated_at = datetime.utcnow()
        db.add(assessment)

    db.commit()
    return {"ok": True, "saved": saved}
