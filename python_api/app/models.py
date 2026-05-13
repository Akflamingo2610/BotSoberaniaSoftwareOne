from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base


class Company(Base):
    __tablename__ = "companies"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    name: Mapped[str] = mapped_column(String(255))
    cnpj: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)
    segment: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    status: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    name: Mapped[str] = mapped_column(String(255))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    # Campo legado apenas para migracao/importacao. Nao usar para autenticacao.
    legacy_password_hash: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    account_id: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    role: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    password_reset: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    company_id: Mapped[Optional[int]] = mapped_column(ForeignKey("companies.id"), nullable=True)
    last_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)


class Assessment(Base):
    __tablename__ = "assessments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    company_id: Mapped[Optional[int]] = mapped_column(ForeignKey("companies.id"), nullable=True)
    status: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)
    current_phase: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    last_question: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    progress_percent: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    created_by: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), nullable=True)


class Question(Base):
    __tablename__ = "questions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    phase: Mapped[str] = mapped_column(String(80), index=True)
    pilar: Mapped[str] = mapped_column(String(80), index=True)
    recommendation: Mapped[str] = mapped_column(Text)
    weight: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    order_index: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    question_code: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    dominio: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    recommendation_en: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    recommendation_es: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    guidance: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    how_to_check: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    aws_service: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    pilar_tecnico: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    norms: Mapped[Optional[str]] = mapped_column(Text, nullable=True)


class Answer(Base):
    __tablename__ = "answers"
    __table_args__ = (
        UniqueConstraint("assessment_id", "question_id", name="uq_answer_assessment_question"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    assessment_id: Mapped[int] = mapped_column(ForeignKey("assessments.id"), index=True)
    question_id: Mapped[int] = mapped_column(ForeignKey("questions.id"), index=True)
    selected_label: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    score: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    justification: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    evidence: Mapped[Optional[str]] = mapped_column(Text, nullable=True)


class AuthToken(Base):
    __tablename__ = "auth_tokens"

    token: Mapped[str] = mapped_column(String(255), primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

