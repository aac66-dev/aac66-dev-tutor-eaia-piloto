import { createClient } from '@supabase/supabase-js';

/**
 * Cliente Supabase para componentes de servidor (Next.js App Router).
 * Usa service role key por defeito para bypass de RLS durante o piloto sem login.
 * Quando houver autenticação individual dos 3 alunos, trocar para anon key + sessão.
 */
export function supabaseServer() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  if (!url || !key) {
    throw new Error(
      'Variáveis NEXT_PUBLIC_SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY ausentes',
    );
  }
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
