"""Importa as colunas de normas/leis da planilha original do Prototipo
para a coluna `norms` da tabela `questions`.

Uso (a partir de python_api/):
    python -m scripts.import_norms_from_prototipo \
        --csv ../Prototipo_Assessment_Tool_Maturidade_Soberania_v1_with_order_index.csv

A planilha tem 4 colunas de normas:
    - "Normas Técnicas" (ISO, NIST, COBIT, CIS)
    - "Geral (Brasil)" (LGPD, CF, MCI, GSI/PR)
    - "Finanças Públicas (BCB)" (Res. BCB, IN BCB)
    - "Educação" (LGPD, PL ECA Digital, etc.)

O banco usa um conjunto de perguntas reorganizado (72 perguntas em 3 pilares:
Compliance / Continuity / Control), enquanto o CSV é o prototipo original
(74 perguntas com question_codes diferentes). Por isso fazemos a agregação
por `Pilares` (que coincide entre CSV e banco):

    Para cada pilar (Compliance, Control, Continuity):
      norms_do_pilar = união de todas as normas únicas das linhas do CSV
                       cujo "Pilares" == pilar.
    Para cada pergunta do banco com aquele pilar:
      q.norms = norms_do_pilar (string consolidada com " · ")
"""
from __future__ import annotations

import argparse
import csv
from pathlib import Path

from sqlalchemy import select

from app.database import SessionLocal
from app.models import Question

NORM_COLUMNS = [
    "Normas Técnicas",
    "Geral (Brasil)",
    "Finanças Públicas (BCB)",
    "Educação",
]


def _split_norms(raw: str) -> list[str]:
    if not raw:
        return []
    out: list[str] = []
    # Separadores comuns no Excel: ; e , e ·
    tmp = raw.replace(";", ",").replace(" · ", ",").replace("·", ",")
    for chunk in tmp.split(","):
        v = chunk.strip()
        if v and v not in out:
            out.append(v)
    return out


def _consolidate_norms(row: dict[str, str]) -> str:
    seen: list[str] = []
    for col in NORM_COLUMNS:
        for n in _split_norms(row.get(col, "") or ""):
            if n not in seen:
                seen.append(n)
    return " · ".join(seen)


def _open_csv(csv_path: Path):
    # O CSV original está em cp1252 (Windows-1252). Tentamos UTF-8 primeiro
    # para o caso de versões re-salvas, e cai para cp1252 caso contrário.
    for enc in ("utf-8-sig", "cp1252", "latin-1"):
        try:
            with csv_path.open("r", encoding=enc, newline="") as f:
                rows = list(csv.DictReader(f, delimiter=";"))
            # Detecta mojibake: se a coluna esperada tem "T�cnicas",
            # foi decodificado errado e precisamos cair pro próximo encoding.
            if rows and any("�" in k for k in rows[0].keys()):
                continue
            return rows
        except UnicodeDecodeError:
            continue
    raise RuntimeError("Não foi possível decodificar o CSV.")


def import_norms(csv_path: Path) -> None:
    rows = _open_csv(csv_path)

    # 1) Agrega normas por pilar do CSV (Compliance/Control/Continuity).
    norms_by_pilar: dict[str, list[str]] = {}
    for row in rows:
        pilar = (row.get("Pilares") or "").strip()
        if not pilar:
            continue
        for n in _split_norms(_consolidate_norms(row)):
            bucket = norms_by_pilar.setdefault(pilar, [])
            if n not in bucket:
                bucket.append(n)

    print("Normas agregadas por pilar (do CSV original):")
    for pilar, lst in norms_by_pilar.items():
        print(f"  {pilar}: {len(lst)} normas distintas")

    # 2) Atualiza cada pergunta do banco com a string consolidada do seu pilar.
    db = SessionLocal()
    try:
        updated = 0
        skipped = 0
        questions = db.scalars(select(Question)).all()
        for q in questions:
            pilar = (q.pilar or "").strip()
            lst = norms_by_pilar.get(pilar)
            if not lst:
                skipped += 1
                continue
            q.norms = " · ".join(lst)
            db.add(q)
            updated += 1
        db.commit()
        print(f"\nAtualizadas {updated} perguntas com normas. Puladas: {skipped}.")
    finally:
        db.close()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--csv",
        type=Path,
        required=True,
        help="Caminho do CSV do prototipo (com order_index)",
    )
    args = parser.parse_args()
    import_norms(args.csv)


if __name__ == "__main__":
    main()
