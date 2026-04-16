-- Tabela de mensagens de conversação (multi-turn)
-- Permite que o aluno faça perguntas de seguimento dentro da mesma sessão.

CREATE TABLE IF NOT EXISTS session_messages (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id      UUID NOT NULL REFERENCES tutor_sessions(id) ON DELETE CASCADE,
  role            TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content         TEXT NOT NULL,
  input_tokens    INTEGER,
  output_tokens   INTEGER,
  cost_usd        NUMERIC(10,6),
  created_at      TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- RLS: aluno só vê mensagens das suas sessões
ALTER TABLE session_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "student_own_messages"
  ON session_messages
  FOR ALL
  USING (
    session_id IN (
      SELECT ts.id FROM tutor_sessions ts
      JOIN students s ON s.id = ts.student_id
      WHERE s.auth_user_id = auth.uid()
    )
  );

-- Supervisor pode ler mensagens dos seus alunos
CREATE POLICY "supervisor_read_messages"
  ON session_messages
  FOR SELECT
  USING (
    session_id IN (
      SELECT ts.id FROM tutor_sessions ts
      JOIN supervisor_students ss ON ss.student_id = ts.student_id
      JOIN supervisors sup ON sup.id = ss.supervisor_id
      WHERE sup.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "service_role_all_messages"
  ON session_messages
  FOR ALL
  USING (auth.role() = 'service_role');

-- Índice para buscar mensagens por sessão
CREATE INDEX IF NOT EXISTS idx_session_messages_session
  ON session_messages (session_id, created_at ASC);
