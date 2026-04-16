-- Códigos de convite para auto-registo de alunos
-- O supervisor gera um código que o aluno usa para se registar.

CREATE TABLE IF NOT EXISTS invite_codes (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code            TEXT NOT NULL UNIQUE,
  supervisor_id   UUID NOT NULL REFERENCES supervisors(id) ON DELETE CASCADE,
  curriculum_id   UUID REFERENCES curricula(id) ON DELETE SET NULL,
  max_uses        INTEGER DEFAULT 1,
  used_count      INTEGER DEFAULT 0,
  expires_at      TIMESTAMPTZ,
  active          BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- RLS
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

-- Supervisor gere os seus códigos
CREATE POLICY "supervisor_own_codes"
  ON invite_codes
  FOR ALL
  USING (
    supervisor_id IN (
      SELECT id FROM supervisors WHERE auth_user_id = auth.uid()
    )
  );

-- Qualquer utilizador autenticado pode ler códigos activos (para validar no registo)
CREATE POLICY "anyone_read_active_codes"
  ON invite_codes
  FOR SELECT
  USING (active = true);

CREATE POLICY "service_role_all_codes"
  ON invite_codes
  FOR ALL
  USING (auth.role() = 'service_role');

CREATE INDEX IF NOT EXISTS idx_invite_codes_code ON invite_codes (code) WHERE active = true;
