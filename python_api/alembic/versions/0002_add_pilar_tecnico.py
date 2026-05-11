"""add pilar_tecnico to questions and widen aws_service

Revision ID: 0002_add_pilar_tecnico
Revises: 0001_initial_schema
Create Date: 2026-05-08 16:00:00
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "0002_add_pilar_tecnico"
down_revision = "0001_initial_schema"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("questions") as batch_op:
        batch_op.add_column(sa.Column("pilar_tecnico", sa.String(length=120), nullable=True))
        batch_op.alter_column("aws_service", type_=sa.Text(), existing_nullable=True)


def downgrade() -> None:
    with op.batch_alter_table("questions") as batch_op:
        batch_op.drop_column("pilar_tecnico")
        batch_op.alter_column("aws_service", type_=sa.String(length=120), existing_nullable=True)
