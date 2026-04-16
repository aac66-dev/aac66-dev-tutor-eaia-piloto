#!/usr/bin/env python3
"""
Seed dos 9 curriculos do Ambito Canonico Opcao 2.

Fixado em 2026-04-16:
  - Portugues 7.o, 8.o, 9.o, 10.o, 11.o, 12.o (6 curriculos, espinha dorsal)
  - Matematica 9.o, Ciencias Naturais 9.o, Fisico-Quimica 9.o (3, transversais)

Popula 3 tabelas da Camada A:
  - curricula       (9 linhas)
  - curriculum_units  (dominios pedagogicos)
  - curriculum_topics (Aprendizagens Essenciais)

Conecta via pooler Supabase Ireland:
  aws-0-eu-west-1.pooler.supabase.com:6543
  user: postgres.<project_ref>
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import psycopg2

# ------------------------------------------------------------
# 0. Contexto do projeto
# ------------------------------------------------------------
PROJECT_ROOT = Path(
    "/sessions/bold-focused-rubin/mnt/AAC-SabAI4Edu/06_Tutor_EAIA"
)
ENV_FILE = PROJECT_ROOT / "codigo" / ".env.local"
DKM_DIR = PROJECT_ROOT / "curriculum-dkm"

# Ambito canonico, 9 curriculos
SCOPE = [
    # slug             dir              discipline             code  year level              order
    ("portugues-7",  "7ano",           "Portugues",            "PT", "7",  "ensino_basico",      1),
    ("portugues-8",  "8ano",           "Portugues",            "PT", "8",  "ensino_basico",      2),
    ("portugues-9",  "9ano",           "Portugues",            "PT", "9",  "ensino_basico",      3),
    ("portugues-10", "10ano",          "Portugues",            "PT", "10", "ensino_secundario",  4),
    ("portugues-11", "11ano",          "Portugues",            "PT", "11", "ensino_secundario",  5),
    ("portugues-12", "12ano",          "Portugues",            "PT", "12", "ensino_secundario",  6),
    ("matematica-9", "9ano-matematica","Matematica",           "MAT","9",  "ensino_basico",      7),
    ("ciencias-naturais-9", "9ano-cn", "Ciencias Naturais",    "CN", "9",  "ensino_basico",      8),
    ("fisico-quimica-9", "9ano-fq",    "Fisico-Quimica",       "FQ", "9",  "ensino_basico",      9),
]


# ------------------------------------------------------------
# 1. Utils
# ------------------------------------------------------------
def load_env(path: Path) -> dict:
    env = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def find_json(folder: Path) -> Path:
    for p in folder.glob("AE_*_estruturado.json"):
        return p
    raise FileNotFoundError(f"JSON AE nao encontrado em {folder}")


def truncate(txt: str, max_len: int = 200) -> str:
    if len(txt) <= max_len:
        return txt
    return txt[: max_len - 1] + "\u2026"


def iter_ae(dominio: dict):
    """
    Devolve lista de (ae_code, ae_descricao, subdominio_code_ou_None).
    Trata dominios com ou sem subdominios.
    """
    out = []
    if dominio.get("subdominios"):
        for sub in dominio["subdominios"]:
            sub_code = sub.get("codigo") or sub.get("nome")
            for ae in sub.get("aprendizagens_essenciais", []):
                out.append((ae.get("codigo") or "", ae.get("descricao") or "", sub_code))
    for ae in dominio.get("aprendizagens_essenciais", []) or []:
        out.append((ae.get("codigo") or "", ae.get("descricao") or "", None))
    return out


# ------------------------------------------------------------
# 2. Seed
# ------------------------------------------------------------
def seed_curriculum(cur, slug, dir_name, discipline, disc_code, year, level, order):
    folder = DKM_DIR / dir_name
    json_path = find_json(folder)
    data = json.loads(json_path.read_text(encoding="utf-8"))

    title = f"{discipline} {year}.\u00ba ano"
    source_url = (
        "https://www.dge.mec.pt/aprendizagens-essenciais-ensino-basico"
        if level == "ensino_basico"
        else "https://www.dge.mec.pt/aprendizagens-essenciais-ensino-secundario"
    )

    # upsert curriculum
    cur.execute(
        """
        INSERT INTO public.curricula
            (slug, title, education_level, source_url, version, notes,
             discipline, school_year, discipline_code, display_order,
             pedagogical_domain)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (slug) DO UPDATE SET
            title = EXCLUDED.title,
            education_level = EXCLUDED.education_level,
            discipline = EXCLUDED.discipline,
            school_year = EXCLUDED.school_year,
            discipline_code = EXCLUDED.discipline_code,
            display_order = EXCLUDED.display_order,
            pedagogical_domain = EXCLUDED.pedagogical_domain
        RETURNING id;
        """,
        (
            slug,
            title,
            level,
            source_url,
            data.get("despacho") or data.get("documento") or "",
            f"Seed Opcao 2, ficheiro {json_path.name}",
            discipline,
            year,
            disc_code,
            order,
            "ensino_basico_secundario",
        ),
    )
    curriculum_id = cur.fetchone()[0]

    # purge unidades anteriores (cascata apaga topicos)
    cur.execute(
        "DELETE FROM public.curriculum_units WHERE curriculum_id = %s",
        (curriculum_id,),
    )

    unit_count = 0
    topic_count = 0
    for i, dom in enumerate(data.get("dominios", []), start=1):
        unit_code = dom.get("codigo") or ""
        unit_title = dom.get("nome") or f"Dominio {i}"

        cur.execute(
            """
            INSERT INTO public.curriculum_units
                (curriculum_id, code, title, period, order_index)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id;
            """,
            (curriculum_id, unit_code, unit_title, f"{year}.\u00ba ano", i),
        )
        unit_id = cur.fetchone()[0]
        unit_count += 1

        aes = iter_ae(dom)
        for j, (ae_code, ae_desc, sub_code) in enumerate(aes, start=1):
            topic_title = truncate(ae_desc, 200) or ae_code or f"AE {j}"
            subinfo = f"[{sub_code}] " if sub_code else ""
            cur.execute(
                """
                INSERT INTO public.curriculum_topics
                    (unit_id, code, title, description, learning_objectives, order_index)
                VALUES (%s, %s, %s, %s, %s, %s);
                """,
                (
                    unit_id,
                    ae_code,
                    topic_title,
                    subinfo + ae_desc,
                    ae_desc,
                    j,
                ),
            )
            topic_count += 1

    return curriculum_id, unit_count, topic_count


# ------------------------------------------------------------
# 3. Main
# ------------------------------------------------------------
def main() -> int:
    env = load_env(ENV_FILE)
    ref = env["SUPABASE_PROJECT_REF"]
    pw = env["SUPABASE_DB_PASSWORD"]

    dsn = (
        f"postgresql://postgres.{ref}:{pw}"
        f"@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
    )
    print(f"==> A ligar ao pooler eu-west-1, projeto {ref}\n")

    conn = psycopg2.connect(dsn)
    conn.autocommit = False
    cur = conn.cursor()

    total_units = 0
    total_topics = 0
    try:
        for slug, dir_name, disc, code, year, level, order in SCOPE:
            cid, uc, tc = seed_curriculum(
                cur, slug, dir_name, disc, code, year, level, order
            )
            total_units += uc
            total_topics += tc
            print(f"  [{order}] {slug:25s} {uc:3d} unidades, {tc:3d} AE")

        conn.commit()
    except Exception as exc:
        conn.rollback()
        print(f"\nFALHA, rollback executado: {exc}", file=sys.stderr)
        return 1
    finally:
        cur.close()
        conn.close()

    print(f"\nTotal: 9 curriculos, {total_units} unidades, {total_topics} AE")
    print("Seed concluido com sucesso.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
