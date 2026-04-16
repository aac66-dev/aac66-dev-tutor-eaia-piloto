#!/usr/bin/env python3
"""
Verifica a integridade do seed da Rita no Supabase.
Contabiliza registos nas tabelas chave da Camada A, B e C e
reporta pares minimos esperados do piloto.
"""

import json
import os
import sys
import urllib.request
from pathlib import Path

ENV_FILE = Path(
    "/sessions/bold-focused-rubin/mnt/04_Familia/AEP_Assistente_Educativo_Personalizado/04_Codigo/aep-app/.env.local"
)


def load_env() -> dict:
    env = {}
    for line in ENV_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def rest(env: dict, table: str, select: str = "id", extra: str = "") -> list:
    url = f"{env['NEXT_PUBLIC_SUPABASE_URL']}/rest/v1/{table}?select={select}"
    if extra:
        url += "&" + extra
    req = urllib.request.Request(
        url,
        headers={
            "apikey": env["SUPABASE_SERVICE_ROLE_KEY"],
            "Authorization": f"Bearer {env['SUPABASE_SERVICE_ROLE_KEY']}",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode())


def count(env: dict, table: str, extra: str = "") -> int:
    rows = rest(env, table, select="id", extra=extra)
    return len(rows)


def main() -> int:
    env = load_env()
    print(f"==> Supabase: {env['NEXT_PUBLIC_SUPABASE_URL']}")
    print()

    print("Camada A, curriculo")
    curricula = rest(env, "curricula", "id,slug,title")
    print(f"  curricula           : {len(curricula)}")
    for c in curricula:
        print(f"    - {c['slug']}  {c['title']}")
    unit_count = count(env, "curriculum_units")
    topic_count = count(env, "curriculum_topics")
    print(f"  curriculum_units    : {unit_count}")
    print(f"  curriculum_topics   : {topic_count}")
    print()

    print("Camada B, contexto do professor")
    teacher_count = count(env, "teacher_context")
    print(f"  teacher_context     : {teacher_count}")
    print()

    print("Camada C, estado do aluno")
    students = rest(env, "students", "id,full_name,nickname")
    print(f"  students            : {len(students)}")
    for s in students:
        print(f"    - {s['nickname'] or s['full_name']}")
    enroll = count(env, "student_enrollments", "active=eq.true")
    sessions = count(env, "sessions")
    doubts = count(env, "doubts")
    materials = count(env, "materials")
    tutor = count(env, "tutor_sessions")
    review = count(env, "review_items")
    print(f"  student_enrollments : {enroll} (activas)")
    print(f"  sessions            : {sessions}")
    print(f"  doubts              : {doubts}")
    print(f"  materials           : {materials}")
    print(f"  tutor_sessions      : {tutor}")
    print(f"  review_items        : {review}")
    print()

    expected = {
        "curricula": 1,
        "students": 1,
        "student_enrollments": 1,
        "curriculum_units >= 6": unit_count >= 6,
        "curriculum_topics >= 6": topic_count >= 6,
        "sessions >= 33": sessions >= 33,
    }

    ok = True
    print("Verificacao minima do piloto 1")
    for key, value in expected.items():
        if isinstance(value, bool):
            status = "OK" if value else "FALHA"
            if not value:
                ok = False
        else:
            actual = {
                "curricula": len(curricula),
                "students": len(students),
                "student_enrollments": enroll,
            }[key]
            status = "OK" if actual == value else "FALHA"
            if actual != value:
                ok = False
        print(f"  {key:30s} {status}")

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
