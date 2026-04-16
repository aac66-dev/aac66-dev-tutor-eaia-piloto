-- ============================================================
-- Tutor EAIA, Domain Knowledge Model (ADR-0001)
-- Migration: 20260414_dkm_init.sql
-- ============================================================
-- 7 tabelas DKM + 1 tabela student_mastery + 2 auxiliares.
-- Alinhado com Aprendizagens Essenciais DGE e Informação-Prova IAVE.
-- ============================================================

-- 1. DKM_DOMAINS
CREATE TABLE IF NOT EXISTS public.dkm_domains (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  curriculum_id uuid NOT NULL REFERENCES public.curricula(id) ON DELETE CASCADE,
  code text NOT NULL,
  name text NOT NULL,
  description text,
  display_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (curriculum_id, code)
);
COMMENT ON TABLE public.dkm_domains IS 'Dominio curricular (ex: Oralidade, Leitura, Educacao Literaria, Escrita, Gramatica para Portugues)';

-- 2. DKM_SUBDOMAINS (opcional)
CREATE TABLE IF NOT EXISTS public.dkm_subdomains (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  domain_id uuid NOT NULL REFERENCES public.dkm_domains(id) ON DELETE CASCADE,
  code text NOT NULL,
  name text NOT NULL,
  description text,
  display_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (domain_id, code)
);
COMMENT ON TABLE public.dkm_subdomains IS 'Subdivisao opcional do dominio (ex: Compreensao, Expressao dentro de Oralidade)';

-- 3. DKM_COMPETENCIES (Aprendizagens Essenciais)
CREATE TABLE IF NOT EXISTS public.dkm_competencies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  domain_id uuid NOT NULL REFERENCES public.dkm_domains(id) ON DELETE CASCADE,
  subdomain_id uuid REFERENCES public.dkm_subdomains(id) ON DELETE SET NULL,
  code text NOT NULL,
  descriptor text NOT NULL,
  year_level int NOT NULL,
  source text NOT NULL DEFAULT 'AE-DGE',
  action_verbs text[] DEFAULT ARRAY[]::text[],
  profile_descriptors text[] DEFAULT ARRAY[]::text[],
  display_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (domain_id, code)
);
COMMENT ON TABLE public.dkm_competencies IS 'Competencia formal (Aprendizagem Essencial DGE, com codigo oficial como O.C.9.1)';
COMMENT ON COLUMN public.dkm_competencies.profile_descriptors IS 'Descritores do Perfil do Aluno (A-J) associados a esta AE';

-- 4. DKM_CONCEPTS (unidade mínima de mestria)
CREATE TABLE IF NOT EXISTS public.dkm_concepts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  title text NOT NULL,
  summary text,
  bloom_level text CHECK (bloom_level IN ('lembrar','compreender','aplicar','analisar','avaliar','criar')),
  difficulty_baseline numeric(3,2) DEFAULT 0.5 CHECK (difficulty_baseline BETWEEN 0 AND 1),
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dkm_concepts IS 'Conceito atomico (unidade minima sujeita a Student Tracing BKT)';

-- 5. DKM_CONCEPT_COMPETENCIES (M:N)
CREATE TABLE IF NOT EXISTS public.dkm_concept_competencies (
  concept_id uuid NOT NULL REFERENCES public.dkm_concepts(id) ON DELETE CASCADE,
  competency_id uuid NOT NULL REFERENCES public.dkm_competencies(id) ON DELETE CASCADE,
  weight numeric(3,2) NOT NULL DEFAULT 1.0 CHECK (weight BETWEEN 0 AND 1),
  PRIMARY KEY (concept_id, competency_id)
);
COMMENT ON TABLE public.dkm_concept_competencies IS 'Liga um conceito a uma ou mais competencias AE, com peso';

-- 6. DKM_PREREQUISITES (grafo)
CREATE TABLE IF NOT EXISTS public.dkm_prerequisites (
  concept_id uuid NOT NULL REFERENCES public.dkm_concepts(id) ON DELETE CASCADE,
  prerequisite_id uuid NOT NULL REFERENCES public.dkm_concepts(id) ON DELETE CASCADE,
  strength numeric(3,2) NOT NULL DEFAULT 1.0 CHECK (strength BETWEEN 0 AND 1),
  PRIMARY KEY (concept_id, prerequisite_id),
  CHECK (concept_id <> prerequisite_id)
);
COMMENT ON TABLE public.dkm_prerequisites IS 'Grafo dirigido de pre-requisitos entre conceitos. strength=1 e pre-requisito rigido, <1 e fraco.';

-- 7. DKM_ITEMS (exercícios e questões)
CREATE TABLE IF NOT EXISTS public.dkm_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  item_type text NOT NULL CHECK (item_type IN (
    'escolha_multipla','resposta_restrita','resposta_extensa',
    'verdadeiro_falso','preenchimento','ordenacao',
    'associacao','socratica','producao_escrita'
  )),
  prompt text NOT NULL,
  options jsonb,
  expected_answer text,
  rubric jsonb,
  difficulty numeric(3,2) DEFAULT 0.5 CHECK (difficulty BETWEEN 0 AND 1),
  estimated_duration_seconds int DEFAULT 120,
  source_ref text,
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dkm_items IS 'Item avaliativo individual (exercicio, pergunta, producao, etc.)';

-- 8. DKM_ITEM_CONCEPTS (M:N)
CREATE TABLE IF NOT EXISTS public.dkm_item_concepts (
  item_id uuid NOT NULL REFERENCES public.dkm_items(id) ON DELETE CASCADE,
  concept_id uuid NOT NULL REFERENCES public.dkm_concepts(id) ON DELETE CASCADE,
  weight numeric(3,2) NOT NULL DEFAULT 1.0 CHECK (weight BETWEEN 0 AND 1),
  PRIMARY KEY (item_id, concept_id)
);
COMMENT ON TABLE public.dkm_item_concepts IS 'Liga um item avaliativo aos conceitos que testa, com peso';

-- 9. DKM_PROFILE_DESCRIPTORS (A-J)
CREATE TABLE IF NOT EXISTS public.dkm_profile_descriptors (
  code text PRIMARY KEY,
  name text NOT NULL,
  description text NOT NULL
);
COMMENT ON TABLE public.dkm_profile_descriptors IS 'Descritores do Perfil do Aluno a Saida da Escolaridade Obrigatoria (A-J)';

-- 10. STUDENT_MASTERY (estado BKT por aluno e conceito)
CREATE TABLE IF NOT EXISTS public.student_mastery (
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  concept_id uuid NOT NULL REFERENCES public.dkm_concepts(id) ON DELETE CASCADE,
  p_mastery numeric(5,4) NOT NULL DEFAULT 0.1 CHECK (p_mastery BETWEEN 0 AND 1),
  p_transit numeric(5,4) NOT NULL DEFAULT 0.1 CHECK (p_transit BETWEEN 0 AND 1),
  p_slip numeric(5,4) NOT NULL DEFAULT 0.1 CHECK (p_slip BETWEEN 0 AND 1),
  p_guess numeric(5,4) NOT NULL DEFAULT 0.2 CHECK (p_guess BETWEEN 0 AND 1),
  attempts int NOT NULL DEFAULT 0,
  correct_attempts int NOT NULL DEFAULT 0,
  last_attempted_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (student_id, concept_id)
);
COMMENT ON TABLE public.student_mastery IS 'Estado bayesiano de mestria (BKT) por aluno-conceito';
COMMENT ON COLUMN public.student_mastery.p_mastery IS 'P(L_n) probabilidade de ter aprendido';
COMMENT ON COLUMN public.student_mastery.p_transit IS 'P(T) probabilidade de transitar de nao-sabe para sabe apos instrucao';
COMMENT ON COLUMN public.student_mastery.p_slip IS 'P(S) probabilidade de errar mesmo sabendo';
COMMENT ON COLUMN public.student_mastery.p_guess IS 'P(G) probabilidade de acertar sem saber';

CREATE INDEX IF NOT EXISTS idx_student_mastery_student ON public.student_mastery(student_id);
CREATE INDEX IF NOT EXISTS idx_student_mastery_updated ON public.student_mastery(updated_at DESC);

-- 11. DKM_EXTERNAL_REFS (rastreabilidade a documentos oficiais)
CREATE TABLE IF NOT EXISTS public.dkm_external_refs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source text NOT NULL,
  source_version text,
  source_url text,
  entity_type text NOT NULL CHECK (entity_type IN ('domain','subdomain','competency','concept','item')),
  entity_id uuid NOT NULL,
  citation text,
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.dkm_external_refs IS 'Rastreabilidade formal de entidades DKM para fontes oficiais (DGE, IAVE, DR, etc.)';
CREATE INDEX IF NOT EXISTS idx_dkm_external_refs_entity ON public.dkm_external_refs(entity_type, entity_id);

-- 12. ENABLE RLS
ALTER TABLE public.dkm_domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dkm_subdomains ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dkm_competencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dkm_concepts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dkm_concept_competencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dkm_prerequisites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dkm_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dkm_item_concepts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dkm_profile_descriptors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_mastery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dkm_external_refs ENABLE ROW LEVEL SECURITY;

-- RLS: conteudo DKM e publico-leitura para autenticados, escrita so service_role
DO $$
DECLARE t text;
BEGIN
  FOR t IN SELECT unnest(ARRAY['dkm_domains','dkm_subdomains','dkm_competencies','dkm_concepts','dkm_concept_competencies','dkm_prerequisites','dkm_items','dkm_item_concepts','dkm_profile_descriptors','dkm_external_refs'])
  LOOP
    EXECUTE format('CREATE POLICY "%s_read_authenticated" ON public."%s" AS PERMISSIVE FOR SELECT TO authenticated USING (true)', t, t);
  END LOOP;
END $$;

-- student_mastery: aluno so ve o seu, supervisor ve dos alunos sob orientacao
CREATE POLICY "student_mastery_select_own"
  ON public.student_mastery AS PERMISSIVE FOR SELECT TO authenticated
  USING (user_can_access_student(student_id));

CREATE POLICY "student_mastery_upsert_service"
  ON public.student_mastery AS PERMISSIVE FOR ALL TO service_role
  USING (true) WITH CHECK (true);
