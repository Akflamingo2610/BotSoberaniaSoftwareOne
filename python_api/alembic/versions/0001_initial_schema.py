"""initial schema

Revision ID: 0001_initial_schema
Revises:
Create Date: 2026-04-07 15:30:00
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "0001_initial_schema"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "companies",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("cnpj", sa.String(length=32), nullable=True),
        sa.Column("segment", sa.String(length=120), nullable=True),
        sa.Column("status", sa.String(length=40), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "questions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("phase", sa.String(length=80), nullable=False),
        sa.Column("pilar", sa.String(length=80), nullable=False),
        sa.Column("recommendation", sa.Text(), nullable=False),
        sa.Column("weight", sa.Float(), nullable=True),
        sa.Column("order_index", sa.Integer(), nullable=True),
        sa.Column("question_code", sa.String(length=80), nullable=True),
        sa.Column("dominio", sa.String(length=120), nullable=True),
        sa.Column("recommendation_en", sa.Text(), nullable=True),
        sa.Column("recommendation_es", sa.Text(), nullable=True),
        sa.Column("guidance", sa.Text(), nullable=True),
        sa.Column("how_to_check", sa.Text(), nullable=True),
        sa.Column("aws_service", sa.String(length=120), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_questions_phase", "questions", ["phase"], unique=False)
    op.create_index("ix_questions_pilar", "questions", ["pilar"], unique=False)

    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=True),
        sa.Column("legacy_password_hash", sa.Text(), nullable=True),
        sa.Column("account_id", sa.String(length=80), nullable=True),
        sa.Column("role", sa.String(length=120), nullable=True),
        sa.Column("password_reset", sa.Text(), nullable=True),
        sa.Column("company_id", sa.Integer(), nullable=True),
        sa.Column("last_name", sa.String(length=255), nullable=True),
        sa.Column("phone", sa.String(length=32), nullable=True),
        sa.ForeignKeyConstraint(["company_id"], ["companies.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "assessments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.Column("company_id", sa.Integer(), nullable=True),
        sa.Column("status", sa.String(length=40), nullable=True),
        sa.Column("current_phase", sa.String(length=80), nullable=True),
        sa.Column("last_question", sa.Integer(), nullable=True),
        sa.Column("progress_percent", sa.Float(), nullable=True),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["company_id"], ["companies.id"]),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "auth_tokens",
        sa.Column("token", sa.String(length=255), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("token"),
    )
    op.create_index("ix_auth_tokens_user_id", "auth_tokens", ["user_id"], unique=False)

    op.create_table(
        "answers",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.Column("assessment_id", sa.Integer(), nullable=False),
        sa.Column("question_id", sa.Integer(), nullable=False),
        sa.Column("selected_label", sa.String(length=255), nullable=True),
        sa.Column("score", sa.String(length=80), nullable=True),
        sa.Column("justification", sa.Text(), nullable=True),
        sa.Column("evidence", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["assessment_id"], ["assessments.id"]),
        sa.ForeignKeyConstraint(["question_id"], ["questions.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("assessment_id", "question_id", name="uq_answer_assessment_question"),
    )
    op.create_index("ix_answers_assessment_id", "answers", ["assessment_id"], unique=False)
    op.create_index("ix_answers_question_id", "answers", ["question_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_answers_question_id", table_name="answers")
    op.drop_index("ix_answers_assessment_id", table_name="answers")
    op.drop_table("answers")

    op.drop_index("ix_auth_tokens_user_id", table_name="auth_tokens")
    op.drop_table("auth_tokens")

    op.drop_table("assessments")

    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")

    op.drop_index("ix_questions_pilar", table_name="questions")
    op.drop_index("ix_questions_phase", table_name="questions")
    op.drop_table("questions")

    op.drop_table("companies")
