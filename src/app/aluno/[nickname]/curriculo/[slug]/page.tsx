import { notFound } from 'next/navigation';
import { AppShell } from '@/components/AppShell';
import { MasteryBar } from '@/components/MasteryBar';
import {
  getStudentByNickname,
  masteryForCurriculum,
} from '@/lib/queries';
import { masteryBandLabel } from '@/lib/types';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

interface PageProps {
  params: { nickname: string; slug: string };
}

export default async function CurriculumDetailPage({ params }: PageProps) {
  const student = await getStudentByNickname(params.nickname);
  if (!student) notFound();

  const data = await masteryForCurriculum(student.id, params.slug).catch(() => null);
  if (!data) notFound();

  const { curriculum, units } = data;
  const totalTopics = units.reduce((s, u) => s + u.topics.length, 0);
  const totalDominated = units.reduce(
    (s, u) => s + u.topics.filter((t) => t.p_mastery >= 0.7).length,
    0,
  );
  const totalAttempts = units.reduce(
    (s, u) => s + u.topics.reduce((x, t) => x + t.attempts, 0),
    0,
  );

  const overall =
    totalTopics === 0
      ? 0
      : units.reduce(
          (s, u) => s + u.topics.reduce((x, t) => x + t.p_mastery, 0),
          0,
        ) / totalTopics;

  return (
    <AppShell
      breadcrumb={[
        { label: 'Supervisor', href: '/supervisor' },
        {
          label: student.nickname ?? student.full_name,
          href: `/aluno/${student.nickname}`,
        },
        { label: `${curriculum.discipline} ${curriculum.school_year}.º` },
      ]}
    >
      <div className="space-y-8">
        <section className="flex items-start justify-between gap-6 flex-wrap">
          <div>
            <p className="text-xs uppercase tracking-widest text-muted-foreground">
              Currículo oficial DGE
            </p>
            <h1 className="text-3xl font-serif font-semibold mt-1">
              {curriculum.discipline} {curriculum.school_year}.º ano
            </h1>
            <p className="text-sm text-muted-foreground mt-2 max-w-2xl">
              Vista detalhada da mestria de {student.nickname} em cada domínio
              pedagógico e em cada Aprendizagem Essencial oficial.
            </p>
          </div>
          <div className="min-w-[260px] flex-1 max-w-sm rounded-lg border border-border bg-card p-4">
            <div className="flex items-baseline justify-between mb-2">
              <span className="text-sm text-muted-foreground">
                Mestria neste currículo
              </span>
              <span className="text-xl font-serif font-semibold tabular-nums">
                {(overall * 100).toFixed(1)}%
              </span>
            </div>
            <MasteryBar value={overall} size="lg" />
            <div className="grid grid-cols-3 gap-2 mt-3 text-center text-xs">
              <div>
                <div className="font-serif font-semibold text-lg">
                  {totalTopics}
                </div>
                <div className="text-muted-foreground">AE</div>
              </div>
              <div>
                <div className="font-serif font-semibold text-lg text-emerald-600">
                  {totalDominated}
                </div>
                <div className="text-muted-foreground">Dominadas</div>
              </div>
              <div>
                <div className="font-serif font-semibold text-lg">
                  {totalAttempts}
                </div>
                <div className="text-muted-foreground">Tentativas</div>
              </div>
            </div>
          </div>
        </section>

        <section className="space-y-6">
          {units.map((u) => (
            <div
              key={u.unit.id}
              className="rounded-lg border border-border bg-card"
            >
              <header className="flex items-baseline justify-between p-4 border-b border-border">
                <div>
                  <h2 className="font-serif font-semibold text-lg">
                    {u.unit.code ? `${u.unit.code}. ` : ''}
                    {u.unit.title}
                  </h2>
                  <p className="text-xs text-muted-foreground">
                    {u.topics.length} AE · {masteryBandLabel(u.avg)}
                  </p>
                </div>
                <div className="text-right min-w-[140px]">
                  <div className="text-sm font-semibold tabular-nums">
                    {(u.avg * 100).toFixed(0)}%
                  </div>
                  <MasteryBar value={u.avg} size="sm" />
                </div>
              </header>

              <ul className="divide-y divide-border">
                {u.topics.map((t) => (
                  <li
                    key={t.topic.id}
                    className="p-4 flex items-start gap-4 hover:bg-secondary/30"
                  >
                    <span className="text-xs font-mono text-muted-foreground shrink-0 min-w-[5rem] pt-0.5">
                      {t.topic.code ?? `AE-${t.topic.order_index}`}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm leading-snug">
                        {t.topic.title}
                      </p>
                      <div className="mt-2 max-w-md">
                        <MasteryBar value={t.p_mastery} showValue size="sm" />
                      </div>
                    </div>
                    <div className="text-xs text-muted-foreground shrink-0 pt-1 text-right min-w-[4.5rem]">
                      {t.attempts} tent.
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </section>
      </div>
    </AppShell>
  );
}
