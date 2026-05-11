from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from app.database import Base, SessionLocal, engine
from app.models import Answer, Assessment, AuthToken, Company, Question, User


def _as_int(value: str) -> Optional[int]:
    value = (value or "").strip()
    if not value:
        return None
    return int(value)


def _as_float(value: str) -> Optional[float]:
    value = (value or "").strip()
    if not value:
        return None
    return float(value)


def _as_dt_ms(value: str) -> Optional[datetime]:
    raw = _as_int(value)
    if raw is None:
        return None
    return datetime.fromtimestamp(raw / 1000, tz=timezone.utc).replace(tzinfo=None)


def _iter_rows(path: Path):
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            yield {k.strip(): (v or "") for k, v in row.items()}


def import_all(
    user_csv: Path,
    company_csv: Path,
    assessment_csv: Path,
    question_csv: Path,
    answer_csv: Path,
) -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # limpa em ordem de dependencias
        db.query(AuthToken).delete()
        db.query(Answer).delete()
        db.query(Assessment).delete()
        db.query(User).delete()
        db.query(Company).delete()
        db.query(Question).delete()
        db.commit()

        company_ids: set[int] = set()
        user_ids: set[int] = set()
        assessment_ids: set[int] = set()
        question_ids: set[int] = set()
        users_with_missing_company = 0
        assessments_with_missing_refs = 0
        answers_skipped_missing_refs = 0

        for row in _iter_rows(company_csv):
            company_id = _as_int(row["id"])
            if company_id is None:
                continue
            db.add(
                Company(
                    id=company_id,
                    created_at=_as_dt_ms(row.get("created_at", "")),
                    updated_at=_as_dt_ms(row.get("updated_at", "")),
                    name=row.get("name", ""),
                    cnpj=row.get("cnpj") or None,
                    segment=row.get("segment") or None,
                    status=row.get("status") or None,
                )
            )
            company_ids.add(company_id)
        db.commit()

        for row in _iter_rows(user_csv):
            user_id = _as_int(row["id"])
            if user_id is None:
                continue
            company_id = _as_int(row.get("company", ""))
            if company_id is not None and company_id not in company_ids:
                company_id = None
                users_with_missing_company += 1
            db.add(
                User(
                    id=user_id,
                    created_at=_as_dt_ms(row.get("created_at", "")),
                    name=row.get("name", ""),
                    email=(row.get("email", "") or "").lower(),
                    password_hash=None,
                    legacy_password_hash=row.get("password") or None,
                    account_id=row.get("account_id") or None,
                    role=row.get("role") or None,
                    password_reset=row.get("password_reset") or None,
                    company_id=company_id,
                    last_name=row.get("last_name") or None,
                    phone=row.get("phone") or None,
                )
            )
            user_ids.add(user_id)
        db.commit()

        for row in _iter_rows(assessment_csv):
            assessment_id = _as_int(row["id"])
            if assessment_id is None:
                continue
            company_id = _as_int(row.get("company", ""))
            created_by = _as_int(row.get("created_by", ""))
            had_missing_ref = False
            if company_id is not None and company_id not in company_ids:
                company_id = None
                had_missing_ref = True
            if created_by is not None and created_by not in user_ids:
                created_by = None
                had_missing_ref = True
            if had_missing_ref:
                assessments_with_missing_refs += 1
            db.add(
                Assessment(
                    id=assessment_id,
                    created_at=_as_dt_ms(row.get("created_at", "")),
                    updated_at=_as_dt_ms(row.get("updated_at", "")),
                    company_id=company_id,
                    status=row.get("status") or None,
                    current_phase=row.get("current_phase") or None,
                    last_question=_as_int(row.get("last_question", "")),
                    progress_percent=_as_float(row.get("progress_percent", "")),
                    created_by=created_by,
                )
            )
            assessment_ids.add(assessment_id)
        db.commit()

        for row in _iter_rows(question_csv):
            question_id = _as_int(row["id"])
            if question_id is None:
                continue
            db.add(
                Question(
                    id=question_id,
                    created_at=_as_dt_ms(row.get("created_at", "")),
                    phase=row.get("phase", ""),
                    pilar=row.get("pilar", ""),
                    recommendation=row.get("recommendation", ""),
                    weight=_as_float(row.get("weight", "")),
                    order_index=_as_int(row.get("order_index", "")),
                    question_code=row.get("question_code") or None,
                    dominio=row.get("dominio") or None,
                    recommendation_en=row.get("recommendation_en") or None,
                    recommendation_es=row.get("recommendation_es") or None,
                )
            )
            question_ids.add(question_id)
        db.commit()

        for row in _iter_rows(answer_csv):
            answer_id = _as_int(row["id"])
            if answer_id is None:
                continue
            assessment_id = _as_int(row.get("assessment", ""))
            question_id = _as_int(row.get("question", ""))
            if (
                assessment_id is None
                or question_id is None
                or assessment_id not in assessment_ids
                or question_id not in question_ids
            ):
                answers_skipped_missing_refs += 1
                continue
            db.add(
                Answer(
                    id=answer_id,
                    created_at=_as_dt_ms(row.get("created_at", "")),
                    updated_at=_as_dt_ms(row.get("updated_at", "")),
                    assessment_id=assessment_id,
                    question_id=question_id,
                    selected_label=row.get("selected_label") or None,
                    score=row.get("score") or None,
                    justification=row.get("justification") or None,
                    evidence=row.get("evidence") or None,
                )
            )
        db.commit()
        print(
            "Importacao concluida com ajustes de integridade: "
            f"users_sem_company={users_with_missing_company}, "
            f"assessments_refs_ajustadas={assessments_with_missing_refs}, "
            f"answers_ignoradas={answers_skipped_missing_refs}"
        )
    finally:
        db.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Importa CSVs exportados do Xano para PostgreSQL/SQLite")
    parser.add_argument("--user-csv", required=True)
    parser.add_argument("--company-csv", required=True)
    parser.add_argument("--assessment-csv", required=True)
    parser.add_argument("--question-csv", required=True)
    parser.add_argument("--answer-csv", required=True)
    args = parser.parse_args()

    import_all(
        user_csv=Path(args.user_csv),
        company_csv=Path(args.company_csv),
        assessment_csv=Path(args.assessment_csv),
        question_csv=Path(args.question_csv),
        answer_csv=Path(args.answer_csv),
    )


if __name__ == "__main__":
    main()

