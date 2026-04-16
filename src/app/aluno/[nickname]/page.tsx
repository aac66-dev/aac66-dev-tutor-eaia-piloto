import { notFound } from 'next/navigation';
import { AppShell } from '@/components/AppShell';
import { CurriculumTile } from '@/components/CurriculumTile';
import { MasteryBar } from '@/components/MasteryBar';
import {
  getStudentByNickname,
  listCurricula,
  masteryByCurriculum,
  studentOverallMastery,
  recentSessions,
} from '@/lib/queries';
import { masteryBandLabel } from '@/lib/types';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

interface PageProps {
  params: { nickname: string };
}

export default async function StudentDashboardPage({ params }: PageProps) {
  const student = await getStudentByNickname(params.nickname);
  if (!student) notFound();

  const [curricula, masteryMap, overall, sessions] = await Promise.all([
    listCurricula(),
    masteryByCurriculum(student.id),
    studentOverallMastery(student.id),
    recentSessions(student.id, 10),
  ]);

  const portugues = curricula.filter((c) => c.discipline_code === 'PT');
  const transversal9 = curricula.filter(
    (c) => c.discipline_code !== 'PT' && c.school_year === '9',
  );

  const perfil =
    student.nickname === 'Maria'
      ? 'Perfil Fraco'
      : student.nickname === 'Joao'
        ? 'Perfil Médio'
        : 'Perfil Forte';

  return (
    <AppShell
      breadcrumb={[
        { label: 'Supervisor', href: '/supervisor' },
        { label: student.nickname ?? student.full_name },
      ]}
    >
      <div className="space-y-8">
        <section className="flex items-start justify-between gap-6 flex-wrap">
          <div>
            <h1 className="text-3xl font-serif font-semibold">
              {student.nickname}
            </h1>
            <p className="text-muted-foreground mt-1">
              {student.full_name} · {perfil}
            </p>
            <p className="text-sm text-muted-foreground mt-2">
              {student.current_period ?? 'período não definido'} ·{' '}
              {student.institution ?? 'instituição não definida'}
            </p>
          </div>
          <div className="min-w-[260px] flex-1 max-w-sm rounded-lg border border-border bg-card p-4">
            <div className="flex items-baseline justify-between mb-2">
              <span className="text-sm text-muted-foreground">
                Mestria global
              </span>
              <span className="text-xl font-serif font-semibold tabular-nums">
                {(overall.avg * 100).toFixed(1)}%
              </span>
            </div>
            <MasteryBar value={overall.avg} size="lg" />
            <p className="text-xs text-muted-foreground mt-2">
              {masteryBandLabel(overall.avg)}, média em {overall.ae} AE, com{' '}
              {overall.attempts} tentativas históricas.
            </p>
          </div>
        </section>

        <section>
          <div className="flex items-baseline justify-between mb-3">
            <h2 className="text-xl font-serif font-semibold">
              Português, espinha dorsal
            </h2>
            <span className="text-xs text-muted-foreground">
              7.º ao 12.º ano, {portugues.length} currículos
            </span>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            {portugues.map((c) => (
              <CurriculumTile
                key={c.id}
                curriculum={c}
                studentNickname={student.nickname ?? ''}
                mastery={masteryMap.get(c.slug)}
              />
            ))}
          </div>
        </section>

        <section>
          <div className="flex items-baseline justify-between mb-3">
            <h2 className="text-xl font-serif font-semibold">
              Transversal, 9.º ano
            </h2>
            <span className="text-xs text-muted-foreground">
              Matemática, Ciências Naturais, Físico-Química
            </span>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            {transversal9.map((c) => (
              <CurriculumTile
                key={c.id}
                curriculum={c}
                studentNickname={student.nickname ?? ''}
                mastery={masteryMap.get(c.slug)}
              />
            ))}
          </div>
        </section>

        <section className="flex justify-center">
          <a
            href={`/aluno/${student.nickname}/sessao`}
            className="inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-3 text-primary-foreground font-medium hover:bg-primary/90 transition-colors"
          >
            📚 Iniciar sessão de tutoria
          </a>
        </section>

        {/* Histórico de sessões recentes */}
        {sessions.length > 0 && (
          <section>
            <h2 className="text-xl font-serif font-semibold mb-3">
              Sessões recentes
            </h2>
            <div className="rounded-lg border border-border bg-card overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border bg-accent/50 text-muted-foreground text-left">
                      <th className="px-3 py-2 font-medium">Data</th>
                      <th className="px-3 py-2 font-medium">Tipo</th>
                      <th className="px-3 py-2 font-medium">Score</th>
                      <th className="px-3 py-2 font-medium">Compreensão</th>
                      <th className="px-3 py-2 font-medium text-right">Custo</th>
                    </tr>
                  </thead>
                  <tbody>
                    {sessions.map((s) => {
                      const dt = new Date(s.created_at);
                      const dateStr = dt.toLocaleDateString('pt-PT', {
                        day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit',
                      });
                      const typeLabels: Record<string, string> = {
                        explicacao: '📖 Explicação',
                        resumo: '📋 Resumo',
                        quiz: '❓ Quiz',
                        teste: '📝 Teste',
                        exame: '🎓 Exame',
                        revisao: '🔄 Revisão',
                      };
                      const ps = s.performance_snapshot;
                      const score = ps?.score != null ? Number(ps.score) : null;
                      const comp = ps?.comprehension_estimate as string | undefined;
                      return (
                        <tr key={s.id} className="border-b border-border last:border-0 hover:bg-accent/30">
                          <td className="px-3 py-2 text-muted-foreground whitespace-nowrap">{dateStr}</td>
                          <td className="px-3 py-2 whitespace-nowrap">{typeLabels[s.session_type] ?? s.session_type}</td>
                          <td className="px-3 py-2">
                            {score != null ? (
                              <span className={`inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium ${
                                score >= 4
                                  ? 'bg-green-100 text-green-800'
                                  : score >= 3
                                    ? 'bg-blue-100 text-blue-800'
                                    : 'bg-amber-100 text-amber-800'
                              }`}>
                                {score}/5
                              </span>
                            ) : (
                              <span className="text-muted-foreground">—</span>
                            )}
                          </td>
                          <td className="px-3 py-2 text-muted-foreground">{comp ?? '—'}</td>
                          <td className="px-3 py-2 text-right text-muted-foreground tabular-nums">
                            {s.cost_usd != null ? `$${Number(s.cost_usd).toFixed(4)}` : '—'}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </section>
        )}

        <section className="rounded-lg border border-border bg-card p-5 text-sm text-muted-foreground">
          <p>
            Nota, este é um perfil sintético gerado para efeitos de piloto. A
            distribuição da mestria reflecte o {perfil.toLowerCase()} com
            variação controlada em torno da média de referência. Os valores aqui
            apresentados não correspondem a um aluno real.
          </p>
        </section>
      </div>
    </AppShell>
  );
}
