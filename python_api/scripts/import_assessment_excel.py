#!/usr/bin/env python3
"""
Importa perguntas do Excel Assessment_OTIMIZADO_* para a tabela `questions`.

Regras:
- Importa somente linhas com coluna "Visualizar Soberania" = ok (case-insensitive).
- Pilar: coluna "Pilar 3Cs" (Compliance | Continuity | Control).
- Fase (coluna Origem do Excel -> phase do banco, alinhado ao app Flutter):
    Original        -> Quick_Wins
    Lens Soberania  -> Foundational
    Sec Assessment  -> Efficient

ATENCAO: por padrao este script APAGA todas as respostas (`answers`) e todas as
perguntas (`questions`) antes de inserir, para evitar FK quebrada e duplicata.
Use --dry-run para validar sem gravar.

Uso (na pasta python_api, com as mesmas variaveis de ambiente da API, ex. .env.dev):

  python scripts/import_assessment_excel.py --dry-run
  python scripts/import_assessment_excel.py --apply

Opcional:

  python scripts/import_assessment_excel.py --apply --xlsx "C:\\caminho\\arquivo.xlsx"
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime
from pathlib import Path

# Permite rodar sem instalar o pacote app
_ROOT = Path(__file__).resolve().parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from sqlalchemy import delete, func, select

from app.models import Answer, Question
from app.question_catalog import load_rows_from_excel


DEFAULT_XLSX = _ROOT.parent / "Assessment_OTIMIZADO_176_Perguntas_v4 1.xlsx"


def main() -> None:
    ap = argparse.ArgumentParser(description="Importa perguntas do Excel (Visualizar Soberania=ok).")
    ap.add_argument(
        "--xlsx",
        type=Path,
        default=DEFAULT_XLSX,
        help="Caminho do .xlsx",
    )
    ap.add_argument("--dry-run", action="store_true", help="So le e imprime resumo, sem gravar.")
    ap.add_argument(
        "--apply",
        action="store_true",
        help="Apaga answers+questions e insere (DESTRUTIVO).",
    )
    args = ap.parse_args()

    if not args.dry_run and not args.apply:
        ap.error("Informe --dry-run ou --apply")

    path: Path = args.xlsx
    if not path.is_file():
        raise SystemExit(f"Arquivo nao encontrado: {path}")

    rows = load_rows_from_excel(path)
    print(f"Lidas {len(rows)} perguntas (Visualizar Soberania=ok).")
    from collections import Counter

    c_phase = Counter(r["phase"] for r in rows)
    c_pilar = Counter(r["pilar"] for r in rows)
    print("Por fase:", dict(c_phase))
    print("Por pilar:", dict(c_pilar))

    if args.dry_run:
        print("Dry-run: nenhuma alteracao no banco.")
        for r in rows[:3]:
            print("  exemplo:", r["question_code"], r["phase"], r["pilar"], r["recommendation"][:60] + "...")
        return

    from app.database import SessionLocal

    now = datetime.utcnow()
    with SessionLocal() as db:
        n_ans = int(db.scalar(select(func.count()).select_from(Answer)) or 0)
        n_q = int(db.scalar(select(func.count()).select_from(Question)) or 0)
        print(f"Antes: {n_ans} respostas, {n_q} perguntas. Apagando...")
        db.execute(delete(Answer))
        db.execute(delete(Question))
        db.flush()
        for i, r in enumerate(rows, start=1):
            db.add(
                Question(
                    created_at=now,
                    phase=r["phase"],
                    pilar=r["pilar"],
                    recommendation=r["recommendation"],
                    weight=None,
                    order_index=i,
                    question_code=r["question_code"],
                    dominio=r["dominio"],
                    recommendation_en=None,
                    recommendation_es=None,
                    guidance=None,
                    how_to_check=None,
                    aws_service=r["aws_service"],
                    pilar_tecnico=r["pilar_tecnico"],
                    norms=r["norms"],
                )
            )
        db.commit()
        nq2 = int(db.scalar(select(func.count()).select_from(Question)) or 0)
        print(f"OK: inseridas {nq2} perguntas (respostas anteriores removidas).")


if __name__ == "__main__":
    main()
