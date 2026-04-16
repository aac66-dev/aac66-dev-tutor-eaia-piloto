-- Tabela de feedback do aluno
-- Activar após 15 de Abril (formulário oculto até essa data)

CREATE TABLE IF NOT EXISTS student_feedback (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id  UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,

  -- Ratings 1-5
  general_satisfaction  SMALLINT NOT NULL CHECK (general_satisfaction BETWEEN 1 AND 5),
  study_utility         SMALLINT CHECK (study_utility BETWEEN 1 AND 5),
  ease_of_use           SMALLINT CHECK (ease_of_use BETWEEN 1 AND 5),
  tutor_quality         SMALLINT CHECK (tutor_quality BETWEEN 1 AND 5),

  -- Campos de texto
  useful_features       TEXT[] DEFAULT '{}',
  improvements          TEXT DEFAULT '',
  recommendation        TEXT DEFAULT '',
  comments              TEXT DEFAULT '',

  created_at  TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- RLS: aluno só vê os seus próprios feedbacks
ALTER TABLE student_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "students_own_feedback"
  ON student_feedback
  FOR ALL
  USING (
    student_id IN (
      SELECT id FROM students WHERE auth_user_id = auth.uid()
    )
  );

-- Supervisor pode ler feedback dos seus alunos
CREATE POLICY "supervisor_read_feedback"
  ON student_feedback
  FOR SELECT
  USING (
    student_id IN (
      SELECT ss.student_id
      FROM supervisor_students ss
      JOIN supervisors s ON s.id = ss.supervisor_id
      WHERE s.auth_user_id = auth.uid()
    )
  );

-- Service role pode fazer tudo (para API routes com service key)
CREATE POLICY "service_role_all_feedback"
  ON student_feedback
  FOR ALL
  USING (auth.role() = 'service_role');
