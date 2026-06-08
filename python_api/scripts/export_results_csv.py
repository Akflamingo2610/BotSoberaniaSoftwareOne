#!/usr/bin/env python3
"""
Exporta os resultados de um ou todos os assessments para CSV.

Uso (na pasta python_api, com as variaveis de ambiente do banco):

  # Exportar TODOS os assessments (um arquivo por empresa)
  python scripts/export_results_csv.py

  # Exportar apenas um assessment especifico
  python scripts/export_results_csv.py --assessment-id 5

  # Escolher pasta de saida
  python scripts/export_results_csv.py --output-dir C:\\relatorios

Exemplos rapidos:
  python scripts/export_results_csv.py --list
  python scripts/export_results_csv.py --assessment-id 1 --output-dir .
"""

from __future__ import annotations

import argparse
import csv
import os
import sys
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Garante que o pacote `app` seja encontrado mesmo rodando direto da pasta
# scripts/ ou da raiz python_api/
# ---------------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from dotenv import load_dotenv  # type: ignore

load_dotenv(BASE_DIR / ".env.dev")   # carrega .env.dev por padrao; troque se necessario

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://{user}:{pw}@localhost:5432/{db}".format(
        user=os.getenv("POSTGRES_USER", "bot_soberania"),
        pw=os.getenv("POSTGRES_PASSWORD", "bot_soberania"),
        db=os.getenv("POSTGRES_DB", "bot_soberania"),
    ),
)

# ---------------------------------------------------------------------------
# Mapeamento de score (texto) -> porcentagem
# ---------------------------------------------------------------------------
SCORE_TO_PCT: dict[str, int] = {
    "Não alinhado":           0,
    "Pouco alinhado":        25,
    "Parcialmente alinhado": 50,
    "Bem alinhado":          75,
    "Totalmente alinhado":  100,
}

# ---------------------------------------------------------------------------
# SQL
# ---------------------------------------------------------------------------
SQL_LIST_ASSESSMENTS = """
SELECT
    a.id          AS assessment_id,
    c.name        AS empresa,
    c.cnpj,
    u.name || ' ' || COALESCE(u.last_name, '') AS responsavel,
    u.email,
    a.status,
    ROUND(CAST(a.progress_percent AS NUMERIC), 1) AS progresso_percent,
    a.created_at
FROM assessments a
LEFT JOIN users       u ON a.created_by  = u.id
LEFT JOIN companies   c ON u.company_id  = c.id
ORDER BY a.id DESC;
"""

SQL_RESULTS = """
SELECT
    c.name                                           AS empresa,
    c.cnpj,
    c.segment                                        AS segmento,
    u.name || ' ' || COALESCE(u.last_name, '')       AS responsavel,
    u.email,
    u.phone                                          AS telefone,
    a.id                                             AS assessment_id,
    a.status                                         AS status_assessment,
    ROUND(CAST(a.progress_percent AS NUMERIC), 1)    AS progresso_percent,
    a.created_at                                     AS data_inicio,
    q.question_code                                  AS codigo_pergunta,
    q.pilar,
    q.dominio,
    q.pilar_tecnico,
    q.phase                                          AS fase,
    q.recommendation                                 AS pergunta,
    q.aws_service                                    AS servicos_aws_recomendados,
    q.norms                                          AS normas_e_leis,
    ans.score                                        AS nivel_maturidade,
    ans.justification                                AS justificativa,
    ans.evidence                                     AS evidencia,
    ans.updated_at                                   AS data_resposta
FROM answers         ans
LEFT JOIN questions   q   ON ans.question_id   = q.id
LEFT JOIN assessments a   ON ans.assessment_id = a.id
LEFT JOIN users       u   ON a.created_by      = u.id
LEFT JOIN companies   c   ON u.company_id      = c.id
WHERE ans.assessment_id = :assessment_id
ORDER BY q.pilar ASC, q.dominio ASC, q.order_index ASC;
"""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def slugify(text: str) -> str:
    """Converte texto em nome de arquivo seguro."""
    import unicodedata, re
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    text = re.sub(r"[^\w\s-]", "", text).strip().lower()
    return re.sub(r"[\s-]+", "_", text)


def connect():
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)
    Session = sessionmaker(bind=engine)
    return Session()


def list_assessments(db) -> list[dict]:
    rows = db.execute(text(SQL_LIST_ASSESSMENTS)).mappings().all()
    return [dict(r) for r in rows]


def fetch_results(db, assessment_id: int) -> list[dict]:
    rows = db.execute(text(SQL_RESULTS), {"assessment_id": assessment_id}).mappings().all()
    result = []
    for r in rows:
        row = dict(r)
        # Adiciona coluna de % numerica para facilitar analise na IA
        row["maturidade_pct"] = SCORE_TO_PCT.get(row.get("nivel_maturidade") or "", "")
        result.append(row)
    return result


def export_csv(rows: list[dict], filepath: Path) -> None:
    if not rows:
        print(f"  [AVISO] Nenhuma resposta encontrada, arquivo nao gerado.")
        return
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with open(filepath, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f"  [OK] {filepath}  ({len(rows)} linhas)")


def print_assessments_table(assessments: list[dict]) -> None:
    print(f"\n{'ID':>4}  {'Empresa':<35} {'Responsavel':<30} {'Status':<12} {'Progresso':>9}  {'Data'}")
    print("-" * 105)
    for a in assessments:
        data = str(a.get("created_at") or "")[:10]
        print(
            f"{a['assessment_id']:>4}  "
            f"{str(a.get('empresa') or ''):<35} "
            f"{str(a.get('responsavel') or ''):<30} "
            f"{str(a.get('status') or ''):<12} "
            f"{str(a.get('progresso_percent') or ''):>8}%  "
            f"{data}"
        )
    print()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Exporta resultados do assessment para CSV")
    parser.add_argument("--assessment-id", type=int, default=None,
                        help="ID do assessment (omita para exportar todos)")
    parser.add_argument("--output-dir", default="exports",
                        help="Pasta de saida (padrao: ./exports)")
    parser.add_argument("--list", action="store_true",
                        help="Lista os assessments disponiveis e sai")
    args = parser.parse_args()

    print(f"\n=== Export CSV — Bot Soberania ===")
    print(f"Banco: {DATABASE_URL}\n")

    try:
        db = connect()
    except Exception as e:
        print(f"[ERRO] Nao foi possivel conectar ao banco: {e}")
        print("       Verifique se o Docker esta rodando: docker compose up -d db")
        sys.exit(1)

    assessments = list_assessments(db)

    if args.list or not assessments:
        print_assessments_table(assessments)
        if not assessments:
            print("[AVISO] Nenhum assessment encontrado no banco.")
        sys.exit(0)

    output_dir = Path(args.output_dir)
    timestamp  = datetime.now().strftime("%Y%m%d_%H%M")

    if args.assessment_id:
        targets = [a for a in assessments if a["assessment_id"] == args.assessment_id]
        if not targets:
            print(f"[ERRO] Assessment ID {args.assessment_id} nao encontrado.")
            print_assessments_table(assessments)
            sys.exit(1)
    else:
        targets = assessments

    print(f"Exportando {len(targets)} assessment(s) para: {output_dir.resolve()}\n")

    for a in targets:
        aid      = a["assessment_id"]
        empresa  = slugify(str(a.get("empresa") or f"assessment_{aid}"))
        filename = f"{timestamp}_assessment_{aid}_{empresa}.csv"
        filepath = output_dir / filename

        print(f"  Assessment #{aid} — {a.get('empresa')} ({a.get('responsavel')})")
        rows = fetch_results(db, aid)
        export_csv(rows, filepath)

    db.close()
    print(f"\nPronto! Arquivos salvos em: {output_dir.resolve()}")


if __name__ == "__main__":
    main()
