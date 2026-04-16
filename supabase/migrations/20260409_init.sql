-- ============================================================
-- AEP, Assistente Educativo Personalizado
-- Migracao inicial: 20260409_init.sql
-- ============================================================
-- Cria as 11 tabelas principais, indices, foreign keys e
-- politicas de Row Level Security alinhadas com a tres camadas:
--   Camada A. curriculo oficial (curricula, units, topics)
--   Camada B. adaptacao do professor (teacher_context)
--   Camada C. estado do aluno (sessions, doubts, materials,
--             tutor_sessions, review_items)
--
-- Compativel com PostgreSQL 15+ (Supabase Free Tier).
-- Autor: Claude Sonnet 4.6, 9 de abril de 2026.
-- ============================================================

-- Extensoes necessarias.
create extension if not exists "pgcrypto";

-- ============================================================
-- 1. STUDENTS
-- ============================================================
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  nickname text,
  birth_date date,
  education_level text not null check (
    education_level in ('ensino_superior_politecnico', 'cteSP', 'secundario')
  ),
  institution text,
  current_period text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_students_auth_user_id
  on public.students (auth_user_id);

-- ============================================================
-- 2. CURRICULA
-- ============================================================
create table if not exists public.curricula (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  education_level text not null,
  source_url text,
  version text,
  notes text,
  created_at timestamptz default now()
);

-- ============================================================
-- 3. CURRICULUM_UNITS
-- ============================================================
create table if not exists public.curriculum_units (
  id uuid primary key default gen_random_uuid(),
  curriculum_id uuid not null references public.curricula(id) on delete cascade,
  code text,
  title text not null,
  period text,
  ects numeric,
  evaluation_criteria text,
  order_index int default 0,
  created_at timestamptz default now()
);

create index if not exists idx_curriculum_units_curriculum
  on public.curriculum_units (curriculum_id);

-- ============================================================
-- 4. CURRICULUM_TOPICS
-- ============================================================
create table if not exists public.curriculum_topics (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid not null references public.curriculum_units(id) on delete cascade,
  code text,
  title text not null,
  description text,
  learning_objectives text,
  order_index int default 0,
  created_at timestamptz default now()
);

create index if not exists idx_curriculum_topics_unit
  on public.curriculum_topics (unit_id);

-- ============================================================
-- 5. STUDENT_ENROLLMENTS
-- ============================================================
create table if not exists public.student_enrollments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  curriculum_id uuid not null references public.curricula(id),
  active boolean default true,
  start_date date,
  end_date date,
  created_at timestamptz default now()
);

create index if not exists idx_student_enrollments_student
  on public.student_enrollments (student_id);
create index if not exists idx_student_enrollments_active
  on public.student_enrollments (student_id) where active = true;

-- ============================================================
-- 6. TEACHER_CONTEXT (Camada B)
-- ============================================================
create table if not exists public.teacher_context (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  unit_id uuid not null references public.curriculum_units(id) on delete cascade,
  teacher_name text,
  teaching_style text,
  evaluation_notes text,
  bibliography text,
  calendar_notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (student_id, unit_id)
);

create index if not exists idx_teacher_context_student
  on public.teacher_context (student_id);

-- ============================================================
-- 7. SESSIONS (aulas, exercicios, modulos, provas)
-- ============================================================
create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  unit_id uuid references public.curriculum_units(id) on delete set null,
  topic_id uuid references public.curriculum_topics(id) on delete set null,
  session_type text not null check (
    session_type in ('aula', 'exercicio', 'modulo', 'prova')
  ),
  session_date date not null,
  session_time time,
  title text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_sessions_student_date
  on public.sessions (student_id, session_date desc);
create index if not exists idx_sessions_unit
  on public.sessions (unit_id);

-- ============================================================
-- 8. DOUBTS (duvidas captadas em tempo real)
-- ============================================================
create table if not exists public.doubts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  session_id uuid not null references public.sessions(id) on delete cascade,
  topic_id uuid references public.curriculum_topics(id) on delete set null,
  text text not null,
  status text not null default 'open' check (
    status in ('open', 'explained', 'resolved')
  ),
  priority int default 0,
  resolved_at timestamptz,
  created_at timestamptz default now()
);

create index if not exists idx_doubts_student_status
  on public.doubts (student_id, status);
create index if not exists idx_doubts_session
  on public.doubts (session_id);

-- ============================================================
-- 9. MATERIALS (slides, sebentas, fichas, apontamentos)
-- ============================================================
create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  session_id uuid references public.sessions(id) on delete set null,
  unit_id uuid references public.curriculum_units(id) on delete set null,
  topic_id uuid references public.curriculum_topics(id) on delete set null,
  file_name text not null,
  mime_type text,
  size_bytes bigint,
  storage_path text not null,
  extracted_text text,
  source text check (source in ('professor', 'aluno', 'manual')),
  created_at timestamptz default now()
);

create index if not exists idx_materials_student
  on public.materials (student_id);
create index if not exists idx_materials_unit
  on public.materials (unit_id);

-- ============================================================
-- 10. TUTOR_SESSIONS (interacoes auditaveis com o LLM)
-- ============================================================
create table if not exists public.tutor_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  unit_id uuid references public.curriculum_units(id) on delete set null,
  topic_id uuid references public.curriculum_topics(id) on delete set null,
  session_type text not null check (
    session_type in ('explicacao', 'revisao', 'exame', 'resumo', 'quiz')
  ),
  model text not null,
  prompt_template text not null,
  prompt_rendered text not null,
  response text,
  referenced_doubt_ids uuid[],
  referenced_material_ids uuid[],
  input_tokens int,
  output_tokens int,
  cost_usd numeric,
  feedback_clarity int check (feedback_clarity between 1 and 5),
  feedback_notes text,
  created_at timestamptz default now()
);

create index if not exists idx_tutor_sessions_student_date
  on public.tutor_sessions (student_id, created_at desc);

-- ============================================================
-- 11. REVIEW_ITEMS (Spaced Repetition System, SM-2)
-- ============================================================
create table if not exists public.review_items (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  topic_id uuid references public.curriculum_topics(id) on delete set null,
  question text not null,
  answer text not null,
  source_tutor_session_id uuid references public.tutor_sessions(id) on delete set null,
  ease_factor numeric default 2.5,
  interval_days int default 1,
  next_review_date date default current_date,
  last_reviewed_at timestamptz,
  created_at timestamptz default now()
);

create index if not exists idx_review_items_student_due
  on public.review_items (student_id, next_review_date);

-- ============================================================
-- 12. STUDENT_SUPERVISORS (Antero supervisiona os 3 pilotos)
-- ============================================================
create table if not exists public.student_supervisors (
  supervisor_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  role text default 'supervisor' check (role in ('supervisor', 'parent', 'mentor')),
  created_at timestamptz default now(),
  primary key (supervisor_id, student_id)
);

create index if not exists idx_student_supervisors_student
  on public.student_supervisors (student_id);

-- ============================================================
-- TRIGGER: atualizar updated_at automaticamente
-- ============================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_students_updated
  before update on public.students
  for each row execute function public.set_updated_at();

create trigger trg_teacher_context_updated
  before update on public.teacher_context
  for each row execute function public.set_updated_at();

create trigger trg_sessions_updated
  before update on public.sessions
  for each row execute function public.set_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
-- Regra base: cada aluno (auth.uid()) so ve as suas linhas.
-- Supervisores veem os alunos que supervisionam (via
-- student_supervisors).
-- ============================================================

-- Helper: dado student_id, devolve true se o utilizador atual
-- e o proprio aluno OU um supervisor desse aluno.
create or replace function public.user_can_access_student(target_student_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.students s
    where s.id = target_student_id and s.auth_user_id = auth.uid()
  ) or exists (
    select 1 from public.student_supervisors sv
    where sv.student_id = target_student_id and sv.supervisor_id = auth.uid()
  );
$$;

-- Ativar RLS em todas as tabelas com student_id
alter table public.students enable row level security;
alter table public.student_enrollments enable row level security;
alter table public.teacher_context enable row level security;
alter table public.sessions enable row level security;
alter table public.doubts enable row level security;
alter table public.materials enable row level security;
alter table public.tutor_sessions enable row level security;
alter table public.review_items enable row level security;
alter table public.student_supervisors enable row level security;

-- Currículos sao publicos em leitura (qualquer utilizador
-- autenticado pode consultar a estrutura curricular).
alter table public.curricula enable row level security;
alter table public.curriculum_units enable row level security;
alter table public.curriculum_topics enable row level security;

-- ----------- POLITICAS PARA STUDENTS -----------
create policy "students_select_own_or_supervised"
  on public.students for select
  using (
    auth_user_id = auth.uid()
    or exists (
      select 1 from public.student_supervisors sv
      where sv.student_id = students.id and sv.supervisor_id = auth.uid()
    )
  );

create policy "students_update_own_or_supervised"
  on public.students for update
  using (
    auth_user_id = auth.uid()
    or exists (
      select 1 from public.student_supervisors sv
      where sv.student_id = students.id and sv.supervisor_id = auth.uid()
    )
  );

-- ----------- POLITICAS PARA TABELAS COM student_id -----------
-- student_enrollments
create policy "enrollments_select"
  on public.student_enrollments for select
  using (public.user_can_access_student(student_id));
create policy "enrollments_insert"
  on public.student_enrollments for insert
  with check (public.user_can_access_student(student_id));
create policy "enrollments_update"
  on public.student_enrollments for update
  using (public.user_can_access_student(student_id));
create policy "enrollments_delete"
  on public.student_enrollments for delete
  using (public.user_can_access_student(student_id));

-- teacher_context
create policy "teacher_context_select"
  on public.teacher_context for select
  using (public.user_can_access_student(student_id));
create policy "teacher_context_insert"
  on public.teacher_context for insert
  with check (public.user_can_access_student(student_id));
create policy "teacher_context_update"
  on public.teacher_context for update
  using (public.user_can_access_student(student_id));
create policy "teacher_context_delete"
  on public.teacher_context for delete
  using (public.user_can_access_student(student_id));

-- sessions
create policy "sessions_select"
  on public.sessions for select
  using (public.user_can_access_student(student_id));
create policy "sessions_insert"
  on public.sessions for insert
  with check (public.user_can_access_student(student_id));
create policy "sessions_update"
  on public.sessions for update
  using (public.user_can_access_student(student_id));
create policy "sessions_delete"
  on public.sessions for delete
  using (public.user_can_access_student(student_id));

-- doubts
create policy "doubts_select"
  on public.doubts for select
  using (public.user_can_access_student(student_id));
create policy "doubts_insert"
  on public.doubts for insert
  with check (public.user_can_access_student(student_id));
create policy "doubts_update"
  on public.doubts for update
  using (public.user_can_access_student(student_id));
create policy "doubts_delete"
  on public.doubts for delete
  using (public.user_can_access_student(student_id));

-- materials
create policy "materials_select"
  on public.materials for select
  using (public.user_can_access_student(student_id));
create policy "materials_insert"
  on public.materials for insert
  with check (public.user_can_access_student(student_id));
create policy "materials_update"
  on public.materials for update
  using (public.user_can_access_student(student_id));
create policy "materials_delete"
  on public.materials for delete
  using (public.user_can_access_student(student_id));

-- tutor_sessions
create policy "tutor_sessions_select"
  on public.tutor_sessions for select
  using (public.user_can_access_student(student_id));
create policy "tutor_sessions_insert"
  on public.tutor_sessions for insert
  with check (public.user_can_access_student(student_id));

-- review_items
create policy "review_items_select"
  on public.review_items for select
  using (public.user_can_access_student(student_id));
create policy "review_items_insert"
  on public.review_items for insert
  with check (public.user_can_access_student(student_id));
create policy "review_items_update"
  on public.review_items for update
  using (public.user_can_access_student(student_id));
create policy "review_items_delete"
  on public.review_items for delete
  using (public.user_can_access_student(student_id));

-- student_supervisors (so o proprio supervisor ve os seus links)
create policy "supervisors_select_own"
  on public.student_supervisors for select
  using (supervisor_id = auth.uid());

-- ----------- POLITICAS PARA CURRICULA (leitura publica autenticada) -----------
create policy "curricula_select_authenticated"
  on public.curricula for select
  to authenticated
  using (true);

create policy "curriculum_units_select_authenticated"
  on public.curriculum_units for select
  to authenticated
  using (true);

create policy "curriculum_topics_select_authenticated"
  on public.curriculum_topics for select
  to authenticated
  using (true);

-- ============================================================
-- COMMENTS (documentacao inline)
-- ============================================================
comment on table public.students is 'Perfil dos alunos do AEP. Camada C, raiz.';
comment on table public.curricula is 'Cabecalho de plano curricular oficial. Camada A.';
comment on table public.curriculum_units is 'Unidades curriculares, modulos ou temas. Camada A.';
comment on table public.curriculum_topics is 'Topicos finos com objetivos de aprendizagem. Camada A.';
comment on table public.teacher_context is 'Adaptacao pedagogica do professor por aluno e UC. Camada B.';
comment on table public.sessions is 'Aulas, exercicios, modulos ou provas. Camada C.';
comment on table public.doubts is 'Duvidas captadas em tempo real durante uma sessao. Camada C.';
comment on table public.materials is 'Ficheiros (slides, sebentas, fichas) com texto extraido. Camada C.';
comment on table public.tutor_sessions is 'Cada interacao com o LLM auditavel. Inclui prompt, resposta e custos. Camada C.';
comment on table public.review_items is 'Flashcards SRS gerados pelo tutor. Camada C.';
comment on table public.student_supervisors is 'Liga supervisor (auth.users) a aluno. Para acesso multi-aluno do Antero.';

-- ============================================================
-- FIM DA MIGRACAO
-- ============================================================
