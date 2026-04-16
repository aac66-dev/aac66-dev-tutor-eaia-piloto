import { notFound } from 'next/navigation';
import { AppShell } from '@/components/AppShell';
import { CurriculumTile } from '@/components/CurriculumTile';
import { MasteryBar } from '@/components/MasteryBar';
import {
  getStudentByNickname,
  listCurricula,
  masteryByCurriculum,
  studentOverallMastery,
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

  const [curricula, masteryMap, overall] = await Promise.all([
    listCurricula(),
    masteryByCurriculum(student.id),
    studentOverallMastery(student.id),
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
