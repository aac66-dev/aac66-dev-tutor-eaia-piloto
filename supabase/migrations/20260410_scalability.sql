-- Migração de escalabilidade: suporte multi-curriculum, limites de custo e domínio pedagógico
-- Estas alterações preparam o AEP para escalar além de um único contexto educativo.

-- 1. Domínio pedagógico no currículo
-- Permite adaptar o tutor ao tipo de área de estudo (saúde, engenharia, direito, etc.)
ALTER TABLE curricula
  ADD COLUMN IF NOT EXISTS pedagogical_domain TEXT DEFAULT 'geral',
  ADD COLUMN IF NOT EXISTS domain_instructions TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS max_monthly_cost_usd NUMERIC(10,2) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS default_model TEXT DEFAULT NULL;

COMMENT ON COLUMN curricula.pedagogical_domain IS 'Domínio pedagógico: saude, engenharia, direito, humanidades, ciencias, geral';
COMMENT ON COLUMN curricula.domain_instructions IS 'Instruções pedagógicas específicas do domínio, injetadas no prompt do tutor';
COMMENT ON COLUMN curricula.max_monthly_cost_usd IS 'Limite mensal de custo em USD para este currículo (NULL = sem limite)';
COMMENT ON COLUMN curricula.default_model IS 'Modelo Claude a usar neste currículo (NULL = usar default global)';

-- 2. Limites de custo por supervisor
ALTER TABLE supervisors
  ADD COLUMN IF NOT EXISTS max_monthly_cost_usd NUMERIC(10,2) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS max_students INTEGER DEFAULT NULL;

COMMENT ON COLUMN supervisors.max_monthly_cost_usd IS 'Limite mensal de custo em USD para todos os alunos deste supervisor';
COMMENT ON COLUMN supervisors.max_students IS 'Número máximo de alunos que este supervisor pode gerir';

-- 3. Preferências de idioma e género no perfil do aluno
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'pt-PT',
  ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT NULL;

COMMENT ON COLUMN students.preferred_language IS 'Idioma preferido do aluno (pt-PT, pt-BR, en, es, fr)';
COMMENT ON COLUMN students.gender IS 'Género para personalização linguística (M, F, NB, NULL)';

-- 4. Vista materializada para custo mensal por currículo (para dashboards)
CREATE OR REPLACE VIEW monthly_cost_by_curriculum AS
SELECT
  se.curriculum_id,
  c.title AS curriculum_title,
  DATE_TRUNC('month', ts.created_at) AS month,
  COUNT(*) AS session_count,
  SUM(COALESCE(ts.cost_usd, 0)) AS total_cost_usd,
  COUNT(DISTINCT ts.student_id) AS active_students
FROM tutor_sessions ts
JOIN student_enrollments se ON se.student_id = ts.student_id AND se.active = true
JOIN curricula c ON c.id = se.curriculum_id
GROUP BY se.curriculum_id, c.title, DATE_TRUNC('month', ts.created_at);

-- 5. Vista para custo mensal por supervisor
CREATE OR REPLACE VIEW monthly_cost_by_supervisor AS
SELECT
  s.id AS supervisor_id,
  s.full_name AS supervisor_name,
  DATE_TRUNC('month', ts.created_at) AS month,
  COUNT(*) AS session_count,
  SUM(COALESCE(ts.cost_usd, 0)) AS total_cost_usd,
  COUNT(DISTINCT ts.student_id) AS active_students
FROM tutor_sessions ts
JOIN supervisor_students ss ON ss.student_id = ts.student_id
JOIN supervisors s ON s.id = ss.supervisor_id
GROUP BY s.id, s.full_name, DATE_TRUNC('month', ts.created_at);

-- 6. Índices para performance em escala
CREATE INDEX IF NOT EXISTS idx_tutor_sessions_student_created
  ON tutor_sessions (student_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tutor_sessions_unit_created
  ON tutor_sessions (unit_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_student_enrollments_active
  ON student_enrollments (student_id, active) WHERE active = true;

CREATE INDEX IF NOT EXISTS idx_student_notes_doubts
  ON student_notes (student_id, note_type, resolved)
  WHERE note_type = 'doubt' AND resolved = false;
