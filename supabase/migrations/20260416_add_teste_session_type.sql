-- Adicionar 'teste' como tipo de sessão válido (simula teste de aula)
-- Mantém 'revisao' para retrocompatibilidade com sessões existentes

ALTER TABLE tutor_sessions DROP CONSTRAINT IF EXISTS tutor_sessions_session_type_check;
ALTER TABLE tutor_sessions ADD CONSTRAINT tutor_sessions_session_type_check
  CHECK (session_type = ANY (ARRAY['explicacao','resumo','quiz','teste','exame','revisao']));
