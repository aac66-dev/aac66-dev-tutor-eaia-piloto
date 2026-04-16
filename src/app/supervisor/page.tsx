import Link from 'next/link';
import { AppShell } from '@/components/AppShell';
import { MasteryBar } from '@/components/MasteryBar';
import {
  listStudents,
  listCurricula,
  studentOverallMastery,
} from '@/lib/queries';
import { masteryBandLabel } from '@/lib/types';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function SupervisorPage() {
  const [students, curricula] = await Promise.all([
    listStudents(),
    listCurricula(),
  ]);

  const overalls = await Promise.all(
    students.map((s) => studentOverallMastery(s.id)),
  );

  return (
    <AppShell breadcrumb={[{ label: 'Supervisor' }]}>
      <div className="space-y-8">
        <section>
          <h1 className="text-3xl font-serif font-semibold">
            Painel do Supervisor
          </h1>
          <p className="text-muted-foreground mt-2 max-w-3xl">
            Acompanhamento de 3 perfis sintéticos no âmbito canónico Opção 2:
            Português do 7.º ao 12.º ano, mais Matemática, Ciências Naturais e
            Físico-Química do 9.º ano, totalizando {curricula.length} currículos
            oficiais da DGE.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-serif font-semibold mb-4">
            Alunos em piloto
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {students.map((s, i) => {
              const o = overalls[i];
              const perfil = s.nickname === 'Maria'
                ? 'Perfil Fraco'
                : s.nickname === 'Joao'
                  ? 'Perfil Médio'
                  : 'Perfil Forte';
              return (
                <Link
                  key={s.id}
                  href={`/aluno/${s.nickname}`}
                  className="group rounded-lg border border-border bg-card p-5 hover:border-primary hover:shadow-sm transition"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-serif font-semibold text-xl">
                        {s.nickname}
                      </h3>
                      <p className="text-sm text-muted-foreground">
                        {s.full_name}
                      </p>
                    </div>
                    <span className="text-xs px-2 py-0.5 rounded bg-secondary text-secondary-foreground">
                      {perfil}
                    </span>
                  </div>

                  <div className="mt-4 space-y-3">
                    <div>
                      <div className="flex items-baseline justify-between text-sm mb-1">
                        <span className="text-muted-foreground">
                          Mestria global
                        </span>
                        <span className="font-semibold tabular-nums">
                          {(o.avg * 100).toFixed(1)}%
                        </span>
                      </div>
                      <MasteryBar value={o.avg} size="md" />
                      <p className="text-xs text-muted-foreground mt-1">
                        {masteryBandLabel(o.avg)}, {o.ae} AE, {o.attempts}{' '}
                        tentativas
                      </p>
                    </div>
                    <div className="text-xs text-muted-foreground">
                      {s.current_period ?? 'período não definido'} ·{' '}
                      {s.institution ?? 'instituição não definida'}
                    </div>
                  </div>

                  <div className="mt-4 pt-3 border-t border-border flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">
                      Abrir dashboard
                    </span>
                    <span className="text-primary group-hover:translate-x-0.5 transition">
                      →
                    </span>
                  </div>
                </Link>
              );
            })}
          </div>
        </section>

        <section>
          <h2 className="text-xl font-serif font-semibold mb-4">
            Âmbito curricular
          </h2>
          <div className="rounded-lg border border-border bg-card p-5">
            <p className="text-sm text-muted-foreground mb-4">
              Os {curricula.length} currículos oficiais abrangidos pelo piloto,
              na ordem em que aparecem na grelha do aluno:
            </p>
            <ol className="grid grid-cols-1 md:grid-cols-3 gap-2 text-sm">
              {curricula.map((c) => (
                <li
                  key={c.id}
                  className="flex items-center gap-2 p-2 rounded bg-secondary/40"
                >
                  <span className="inline-block w-8 h-6 rounded bg-primary text-primary-foreground grid place-items-center text-xs font-semibold">
                    {c.discipline_code}
                  </span>
                  <span className="font-medium">
                    {c.discipline} {c.school_year}.º
                  </span>
                  <span className="text-xs text-muted-foreground ml-auto">
                    {c.education_level === 'ensino_basico' ? 'Básico' : 'Secundário'}
                  </span>
                </li>
              ))}
            </ol>
          </div>
        </section>
      </div>
    </AppShell>
  );
}
