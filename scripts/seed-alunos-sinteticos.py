#!/usr/bin/env python3
"""
Seed dos 3 alunos sinteticos do piloto Tutor EAIA.

Perfis canonicos:
  - Maria Silva     (Fraco): mastery media 0.25
  - Joao Ferreira   (Medio): mastery media 0.55
  - Sofia Almeida   (Forte): mastery media 0.80

Operacoes:
  A. Espelha curriculum_topics como dkm_concepts (codigo unico com prefixo disciplina-ano).
  B. Cria 3 alunos sinteticos em students.
  C. Inscreve cada aluno nos 9 curriculos (student_enrollments).
  D. Popula student_mastery para cada (aluno, conceito) com distribuicao realista.
  E. Gera 3-5 tutor_sessions por aluno para mostrar atividade historica.

Idempotente: pode correr varias vezes sem duplicar dados.
"""

from __future__ import annotations

import json
import random
from datetime import datetime, timedelta
from pathlib import Path

import psycopg2
import psycopg2.extras

ENV_FILE = Path(
    "/sessions/bold-focused-rubin/mnt/AAC-SabAI4Edu/06_Tutor_EAIA/codigo/.env.local"
)

RANDOM_SEED = 2026041601
random.seed(RANDOM_SEED)

# ------------------------------------------------------------
# Perfis sinteticos
# ------------------------------------------------------------
PROFILES = [
    {
        "nickname": "Maria",
        "full_name": "Maria Silva (perfil Fraco)",
        "gender": "F",
        "education_level": "ensino_basico",
        "institution": "Escola E.B. 2,3 Sinteticos",
        "current_period": "9.\u00ba ano, 2.\u00ba periodo",
        "notes": "Perfil sintetico Fraco, mestria media 0.25. Uso exclusivo piloto.",
        "mastery_mu": 0.25,
        "mastery_sigma": 0.10,
        "attempts_range": (2, 8),
    },
    {
        "nickname": "Joao",
        "full_name": "Joao Ferreira (perfil Medio)",
        "gender": "M",
        "education_level": "ensino_basico",
        "institution": "Escola E.B. 2,3 Sinteticos",
        "current_period": "9.\u00ba ano, 2.\u00ba periodo",
        "notes": "Perfil sintetico Medio, mestria media 0.55. Uso exclusivo piloto.",
        "mastery_mu": 0.55,
        "mastery_sigma": 0.12,
        "attempts_range": (4, 12),
    },
    {
        "nickname": "Sofia",
        "full_name": "Sofia Almeida (perfil Forte)",
        "gender": "F",
        "education_level": "ensino_basico",
        "institution": "Escola E.B. 2,3 Sinteticos",
        "current_period": "9.\u00ba ano, 2.\u00ba periodo",
        "notes": "Perfil sintetico Forte, mestria media 0.80. Uso exclusivo piloto.",
        "mastery_mu": 0.80,
        "mastery_sigma": 0.10,
        "attempts_range": (6, 15),
    },
]


# ------------------------------------------------------------
# Utils
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


def connect(env: dict):
    dsn = (
        f"postgresql://postgres.{env['SUPABASE_PROJECT_REF']}"
        f":{env['SUPABASE_DB_PASSWORD']}"
        f"@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
    )
    return psycopg2.connect(dsn)


def clamp(x: float, lo: float = 0.01, hi: float = 0.99) -> float:
    return max(lo, min(hi, x))


# ------------------------------------------------------------
# Etapa A, espelhar topicos em dkm_concepts
# ------------------------------------------------------------
def seed_concepts_from_topics(cur) -> dict:
    """
    Para cada topic, criar um dkm_concept com codigo unico.
    Devolve dict {topic_id: concept_id}.
    """
    cur.execute(
        """
        SELECT c.discipline_code, c.school_year, t.id, t.code, t.title, t.description
        FROM public.curriculum_topics t
        JOIN public.curriculum_units u ON u.id = t.unit_id
        JOIN public.curricula c        ON c.id = u.curriculum_id
        ORDER BY c.display_order, u.order_index, t.order_index;
        """
    )
    rows = cur.fetchall()

    topic_to_concept = {}
    created = 0
    reused = 0
    for disc_code, year, topic_id, t_code, t_title, t_desc in rows:
        concept_code = f"{disc_code}-{year}-{(t_code or str(topic_id))[:60]}"
        cur.execute(
            """
            INSERT INTO public.dkm_concepts (code, title, summary, bloom_level, difficulty_baseline)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (code) DO UPDATE SET
                title = EXCLUDED.title,
                summary = EXCLUDED.summary
            RETURNING id, (xmax = 0) AS inserted;
            """,
            (
                concept_code,
                t_title[:200],
                (t_desc or "")[:2000],
                "aplicar",
                0.5,
            ),
        )
        concept_id, inserted = cur.fetchone()
        topic_to_concept[topic_id] = concept_id
        if inserted:
            created += 1
        else:
            reused += 1

    print(f"  dkm_concepts: {created} novos, {reused} atualizados")
    return topic_to_concept


# ------------------------------------------------------------
# Etapa B, criar students
# ------------------------------------------------------------
def seed_students(cur) -> list[tuple[str, dict]]:
    """Devolve [(student_id, profile), ...]"""
    out = []
    for p in PROFILES:
        cur.execute(
            """
            INSERT INTO public.students
                (full_name, nickname, education_level, institution, current_period,
                 notes, gender, preferred_language)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'pt-PT')
            ON CONFLICT DO NOTHING
            RETURNING id;
            """,
            (
                p["full_name"],
                p["nickname"],
                p["education_level"],
                p["institution"],
                p["current_period"],
                p["notes"],
                p["gender"],
            ),
        )
        res = cur.fetchone()
        if res is None:
            cur.execute(
                "SELECT id FROM public.students WHERE full_name = %s LIMIT 1;",
                (p["full_name"],),
            )
            res = cur.fetchone()
        student_id = res[0]
        out.append((student_id, p))
        print(f"  student: {p['nickname']:6s} {student_id}")
    return out


# ------------------------------------------------------------
# Etapa C, inscricoes em todos os curriculos
# ------------------------------------------------------------
def seed_enrollments(cur, students: list[tuple[str, dict]]) -> None:
    cur.execute("SELECT id, slug FROM public.curricula ORDER BY display_order;")
    curricula = cur.fetchall()

    today = datetime.now().date()
    start = today - timedelta(days=60)

    for student_id, _p in students:
        for c_id, slug in curricula:
            cur.execute(
                """
                INSERT INTO public.student_enrollments
                    (student_id, curriculum_id, active, start_date)
                VALUES (%s, %s, true, %s)
                ON CONFLICT DO NOTHING;
                """,
                (student_id, c_id, start),
            )
    print(f"  enrollments: {len(students)} x {len(curricula)} = {len(students) * len(curricula)} linhas")


# ------------------------------------------------------------
# Etapa D, student_mastery por aluno x concept
# ------------------------------------------------------------
def seed_mastery(cur, students: list[tuple[str, dict]], topic_to_concept: dict) -> None:
    concept_ids = list(set(topic_to_concept.values()))

    for student_id, p in students:
        mu = p["mastery_mu"]
        sigma = p["mastery_sigma"]
        a_lo, a_hi = p["attempts_range"]

        data = []
        for c_id in concept_ids:
            p_mastery = clamp(random.gauss(mu, sigma))
            attempts = random.randint(a_lo, a_hi)
            correct = round(attempts * p_mastery)
            last = datetime.now() - timedelta(days=random.randint(0, 30))
            data.append(
                (
                    student_id,
                    c_id,
                    round(p_mastery, 3),
                    0.1,
                    0.1,
                    0.2,
                    attempts,
                    correct,
                    last,
                )
            )

        psycopg2.extras.execute_values(
            cur,
            """
            INSERT INTO public.student_mastery
                (student_id, concept_id, p_mastery, p_transit, p_slip, p_guess,
                 attempts, correct_attempts, last_attempted_at)
            VALUES %s
            ON CONFLICT (student_id, concept_id) DO UPDATE SET
                p_mastery = EXCLUDED.p_mastery,
                attempts = EXCLUDED.attempts,
                correct_attempts = EXCLUDED.correct_attempts,
                last_attempted_at = EXCLUDED.last_attempted_at,
                updated_at = now();
            """,
            data,
            page_size=500,
        )
        print(f"  mastery {p['nickname']:6s}: {len(data)} conceitos (mu={mu})")


# ------------------------------------------------------------
# Etapa E, historico de tutor_sessions
# ------------------------------------------------------------
def seed_tutor_sessions(cur, students: list[tuple[str, dict]]) -> None:
    cur.execute(
        """
        SELECT c.id, c.slug, u.id, t.id
        FROM public.curricula c
        JOIN public.curriculum_units u ON u.curriculum_id = c.id
        JOIN public.curriculum_topics t ON t.unit_id = u.id
        ORDER BY c.display_order, u.order_index, t.order_index
        LIMIT 50;
        """
    )
    pool = cur.fetchall()

    session_types = ["explicacao", "revisao", "quiz", "resumo"]
    total = 0
    for student_id, p in students:
        n_sessions = {"Maria": 3, "Joao": 5, "Sofia": 7}[p["nickname"]]
        for i in range(n_sessions):
            _, _, unit_id, topic_id = random.choice(pool)
            stype = random.choice(session_types)
            created = datetime.now() - timedelta(days=random.randint(0, 45))
            cur.execute(
                """
                INSERT INTO public.tutor_sessions
                    (student_id, unit_id, topic_id, session_type, model,
                     prompt_template, prompt_rendered, response,
                     input_tokens, output_tokens, cost_usd,
                     feedback_clarity, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
                """,
                (
                    student_id,
                    unit_id,
                    topic_id,
                    stype,
                    "claude-sonnet-4-5-20250929",
                    f"tutor.{stype}.v1",
                    f"[SINTETICO] Prompt {stype} gerado para perfil {p['nickname']}.",
                    f"[SINTETICO] Resposta pedagogica {stype} adaptada ao perfil.",
                    random.randint(500, 2500),
                    random.randint(200, 1500),
                    round(random.uniform(0.002, 0.018), 6),
                    random.randint(3, 5),
                    created,
                ),
            )
            total += 1
    print(f"  tutor_sessions: {total} linhas")


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
def main() -> int:
    env = load_env(ENV_FILE)
    conn = connect(env)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        print("==> Etapa 0, alargar check de students.education_level para ambito K-12")
        cur.execute(
            """
            ALTER TABLE public.students
              DROP CONSTRAINT IF EXISTS students_education_level_check;
            ALTER TABLE public.students
              ADD CONSTRAINT students_education_level_check
              CHECK (education_level = ANY (ARRAY[
                'ensino_basico', 'secundario',
                'ensino_superior_politecnico', 'cteSP'
              ]));
            """
        )

        print("\n==> Etapa A, dkm_concepts a partir de curriculum_topics")
        topic_to_concept = seed_concepts_from_topics(cur)

        print("\n==> Etapa B, alunos sinteticos")
        students = seed_students(cur)

        print("\n==> Etapa C, inscricoes")
        seed_enrollments(cur, students)

        print("\n==> Etapa D, student_mastery")
        seed_mastery(cur, students, topic_to_concept)

        print("\n==> Etapa E, historico tutor_sessions")
        seed_tutor_sessions(cur, students)

        conn.commit()
    except Exception as exc:
        conn.rollback()
        print(f"\nFALHA, rollback executado: {exc}")
        import traceback
        traceback.print_exc()
        return 1
    finally:
        cur.close()
        conn.close()

    print("\nSeed dos 3 alunos sinteticos concluido com sucesso.")
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
