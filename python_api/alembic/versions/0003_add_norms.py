"""add norms column to questions

Revision ID: 0003_add_norms
Revises: 0002_add_pilar_tecnico
Create Date: 2026-05-13 11:45:00
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "0003_add_norms"
down_revision = "0002_add_pilar_tecnico"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("questions") as batch_op:
        batch_op.add_column(sa.Column("norms", sa.Text(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("questions") as batch_op:
        batch_op.drop_column("norms")
