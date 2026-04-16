#!/usr/bin/env python3
"""
Verifica a integridade do seed Opcao 2 no projeto tutor-eaia-pt (Irlanda).
Usa o .env.local do projeto Tutor EAIA, NAO o do AEP Rita.
"""

from pathlib import Path
import psycopg2

ENV_FILE = Path(
    "/sessions/bold-focused-rubin/mnt/AAC-SabAI4Edu/06_Tutor_EAIA/codigo/.env.local"
)


def load_env(path: Path) -> dict:
    env = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def main() -> int:
    env = load_env(ENV_FILE)
    ref = env["SUPABASE_PROJECT_REF"]
    pw = env["SUPABASE_DB_PASSWORD"]
    dsn = (
        f"postgresql://postgres.{ref}:{pw}"
        f"@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
    )

    conn = psycopg2.connect(dsn)
    cur = conn.cursor()

    print(f"==> Projeto Supabase: {ref} (Irlanda, eu-west-1)\n")

    cur.execute(
        """
        SELECT display_order, slug, title, discipline, school_year,
               discipline_code, education_level
        FROM public.curricula
        ORDER BY display_order, slug;
        """
    )
    curs = cur.fetchall()
    print(f"Curriculos ({len(curs)}):")
    for ord_, slug, title, disc, year, code, level in curs:
        print(
            f"  [{ord_}] {slug:25s} "
            f"{disc:20s} {year:3s} {code:5s} {level}"
        )

    cur.execute(
        """
        SELECT c.slug,
               count(distinct u.id) AS units,
               count(t.id)          AS topics
        FROM public.curricula c
        LEFT JOIN public.curriculum_units u ON u.curriculum_id = c.id
        LEFT JOIN public.curriculum_topics t ON t.unit_id = u.id
        GROUP BY c.slug, c.display_order
        ORDER BY c.display_order;
        """
    )
    print("\nUnidades e AE por curriculo:")
    total_u, total_t = 0, 0
    for slug, u, t in cur.fetchall():
        print(f"  {slug:25s} {u:3d} unidades, {t:4d} AE")
        total_u += u
        total_t += t
    print(f"  {'TOTAL':25s} {total_u:3d} unidades, {total_t:4d} AE")

    cur.execute("SELECT scope_key, description FROM public.pilot_scope;")
    print("\nMeta pilot_scope:")
    for key, desc in cur.fetchall():
        print(f"  {key}")
        print(f"    {desc}")

    expected = {
        "curricula": 9,
        "units >= 30": total_u >= 30,
        "topics >= 350": total_t >= 350,
    }
    ok = True
    print("\nVerificacao minima:")
    for k, v in expected.items():
        if isinstance(v, bool):
            status = "OK" if v else "FALHA"
            if not v:
                ok = False
        else:
            actual = len(curs)
            status = "OK" if actual == v else f"FALHA (actual={actual})"
            if actual != v:
                ok = False
        print(f"  {k:25s} {status}")

    cur.close()
    conn.close()
    return 0 if ok else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
