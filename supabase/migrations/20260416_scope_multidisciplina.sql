-- ============================================================
-- Tutor EAIA, 2026-04-16
-- Migration consolidada:
--   A. Adicionar colunas discipline e school_year a curricula
--      (Ambito canonico Opcao 2: Portugues 7-12 + 9o ano transversal)
--   B. Corrigir migrations anteriores (feedback, conversation)
--      que referenciavam tabelas inexistentes supervisor_students e supervisors
--   C. Adicionar colunas de escalabilidade uteis ao piloto
--      (pedagogical_domain, preferred_language, gender)
--   D. Nao aplicar invite_codes e scalability supervisors
--      (nao essenciais para piloto com 3 perfis sinteticos pre-criados)
-- ============================================================

BEGIN;

-- ============================================================
-- A. Ambito multi-disciplina em curricula
-- ============================================================
ALTER TABLE public.curricula
  ADD COLUMN IF NOT EXISTS discipline TEXT,
  ADD COLUMN IF NOT EXISTS school_year TEXT,
  ADD COLUMN IF NOT EXISTS discipline_code TEXT,
  ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

COMMENT ON COLUMN public.curricula.discipline IS 'Disciplina oficial DGE: Portugues, Matematica, Ciencias Naturais, Fisico-Quimica, Matematica A, Biologia e Geologia, Fisica e Quimica A';
COMMENT ON COLUMN public.curricula.school_year IS 'Ano escolar: 7, 8, 9, 10, 11, 12';
COMMENT ON COLUMN public.curricula.discipline_code IS 'Codigo curto: PT, MAT, CN, FQ, MATA, BG, FQA';
COMMENT ON COLUMN public.curricula.display_order IS 'Ordem de apresentacao na grelha do dashboard';

CREATE INDEX IF NOT EXISTS idx_curricula_discipline ON public.curricula (discipline_code);
CREATE INDEX IF NOT EXISTS idx_curricula_year ON public.curricula (school_year);

-- ============================================================
-- B1. Fix para scalability: colunas em curricula
-- ============================================================
ALTER TABLE public.curricula
  ADD COLUMN IF NOT EXISTS pedagogical_domain TEXT DEFAULT 'ensino_basico_secundario',
  ADD COLUMN IF NOT EXISTS domain_instructions TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS default_model TEXT DEFAULT NULL;

COMMENT ON COLUMN public.curricula.pedagogical_domain IS 'Dominio pedagogico: ensino_basico_secundario, ensino_superior, formacao_profissional';

-- ============================================================
-- B2. Fix para students: colunas de idioma e genero
-- ============================================================
ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'pt-PT',
  ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT NULL;

COMMENT ON COLUMN public.students.preferred_language IS 'Idioma preferido do aluno (pt-PT default, pt-BR, en, es, fr)';
COMMENT ON COLUMN public.students.gender IS 'Genero para personalizacao linguistica (M, F, NB, NULL)';

-- ============================================================
-- C1. student_feedback (corrigido, usa student_supervisors)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.student_feedback (
  id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id           UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  general_satisfaction SMALLINT NOT NULL CHECK (general_satisfaction BETWEEN 1 AND 5),
  study_utility        SMALLINT CHECK (study_utility BETWEEN 1 AND 5),
  ease_of_use          SMALLINT CHECK (ease_of_use BETWEEN 1 AND 5),
  tutor_quality        SMALLINT CHECK (tutor_quality BETWEEN 1 AND 5),
  useful_features      TEXT[] DEFAULT '{}',
  improvements         TEXT DEFAULT '',
  recommendation       TEXT DEFAULT '',
  comments             TEXT DEFAULT '',
  created_at           TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.student_feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "students_own_feedback" ON public.student_feedback;
CREATE POLICY "students_own_feedback"
  ON public.student_feedback FOR ALL
  USING (student_id IN (SELECT id FROM public.students WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "supervisor_read_feedback" ON public.student_feedback;
CREATE POLICY "supervisor_read_feedback"
  ON public.student_feedback FOR SELECT
  USING (
    student_id IN (
      SELECT student_id FROM public.student_supervisors
      WHERE supervisor_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "service_role_all_feedback" ON public.student_feedback;
CREATE POLICY "service_role_all_feedback"
  ON public.student_feedback FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- C2. session_messages (corrigido, multi-turn do tutor)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.session_messages (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id    UUID NOT NULL REFERENCES public.tutor_sessions(id) ON DELETE CASCADE,
  role          TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content       TEXT NOT NULL,
  input_tokens  INTEGER,
  output_tokens INTEGER,
  cost_usd      NUMERIC(10,6),
  created_at    TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_session_messages_session
  ON public.session_messages (session_id, created_at ASC);

ALTER TABLE public.session_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "student_own_messages" ON public.session_messages;
CREATE POLICY "student_own_messages"
  ON public.session_messages FOR ALL
  USING (
    session_id IN (
      SELECT ts.id FROM public.tutor_sessions ts
      JOIN public.students s ON s.id = ts.student_id
      WHERE s.auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "supervisor_read_messages" ON public.session_messages;
CREATE POLICY "supervisor_read_messages"
  ON public.session_messages FOR SELECT
  USING (
    session_id IN (
      SELECT ts.id FROM public.tutor_sessions ts
      JOIN public.student_supervisors ss ON ss.student_id = ts.student_id
      WHERE ss.supervisor_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "service_role_all_messages" ON public.session_messages;
CREATE POLICY "service_role_all_messages"
  ON public.session_messages FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- D. Meta-tabela para auditoria de ambito piloto (pilot_scope)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.pilot_scope (
  id          SERIAL PRIMARY KEY,
  scope_key   TEXT UNIQUE NOT NULL,
  description TEXT,
  active      BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now()
);

INSERT INTO public.pilot_scope (scope_key, description)
VALUES (
  'opcao2-portugues-transversal-9ano',
  'Ambito canonico do Tutor EAIA, versao piloto robusto. Portugues 7-12 + 9o ano transversal em Matematica, Ciencias Naturais, Fisico-Quimica. 9 curriculos sem lacunas. Fixado 2026-04-16.'
)
ON CONFLICT (scope_key) DO UPDATE SET description = EXCLUDED.description;

COMMIT;
