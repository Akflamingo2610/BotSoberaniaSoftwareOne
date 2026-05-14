#!/usr/bin/env python3
"""Lê um CSV (protótipo ou matriz oficial) e gera Dart com correlação AWS → normas/leis."""

from __future__ import annotations

import argparse
import csv
import re
from collections import defaultdict
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]  # BotSoberaniaSoftwareOne/
DEFAULT_CSV = _REPO / "Prototipo_Assessment_Tool_Maturidade_Soberania_v1_with_order_index.csv"
OUT_PATH = _REPO / "soberania_app" / "lib" / "data" / "aws_norm_correlation.g.dart"


def split_norms(s: str) -> list[str]:
    if not s:
        return []
    s = s.replace("\n", " ")
    parts = re.split(r"[;]", s)
    out: list[str] = []
    for x in parts:
        x = x.strip().strip('"').strip()
        if x and x not in out:
            out.append(x)
    return out


def split_aws_keys(aws: str) -> list[str]:
    aws = aws.replace("\n", " ").strip()
    if not aws or aws == "-":
        return []
    parts = re.split(r"\s*/\s*|\s*,\s*|\s+or\s+", aws, flags=re.I)
    return [p.strip() for p in parts if p.strip()]


def main() -> None:
    ap = argparse.ArgumentParser(description="Gera aws_norm_correlation.g.dart a partir do CSV.")
    ap.add_argument(
        "--csv",
        type=Path,
        default=DEFAULT_CSV,
        help="CSV com colunas iguais ao protótipo (col. 5 = serviço AWS, 12-15 = normas).",
    )
    args = ap.parse_args()
    csv_path: Path = args.csv.resolve()
    if not csv_path.is_file():
        raise SystemExit(f"CSV não encontrado: {csv_path}")

    rows = list(
        csv.reader(csv_path.open(encoding="utf-8", errors="replace", newline=""), delimiter=";")
    )
    expanded: dict[str, set[str]] = defaultdict(set)
    for row in rows[1:]:
        if len(row) < 16:
            continue
        aws_cell = row[5] or ""
        norms: list[str] = []
        for j in (12, 13, 14, 15):
            norms.extend(split_norms(row[j] if j < len(row) else ""))
        for key in split_aws_keys(aws_cell):
            for n in norms:
                if len(n) <= 160:
                    expanded[key].add(n)

    keys_sorted = sorted(expanded.keys(), key=lambda k: (-len(k), k.lower()))
    try:
        rel = csv_path.relative_to(_REPO)
    except ValueError:
        rel = csv_path
    lines = [
        "// Gerado por python_api/scripts/gen_aws_norm_map.py — não editar à mão.",
        f"// Fonte CSV: {rel.as_posix()}",
        "",
        "/// Normas/leis correlacionadas ao texto do serviço AWS (matriz CSV).",
        "const Map<String, List<String>> kAwsServiceNormCorrelation = {",
    ]
    for k in keys_sorted:
        norms = sorted(expanded[k])
        esc = k.replace("\\", "\\\\").replace("'", "\\'")
        norms_dart = ", ".join("'" + n.replace("\\", "\\\\").replace("'", "\\'") + "'" for n in norms)
        lines.append(f"  '{esc}': [{norms_dart}],")
    lines.append("};")
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"OK: {len(keys_sorted)} chaves -> {OUT_PATH}")


if __name__ == "__main__":
    main()
