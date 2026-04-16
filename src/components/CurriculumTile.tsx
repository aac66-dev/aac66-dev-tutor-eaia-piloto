import Link from 'next/link';
import { cn } from '@/lib/cn';
import { MasteryBar } from '@/components/MasteryBar';
import type { Curriculum } from '@/lib/types';

interface CurriculumTileProps {
  curriculum: Curriculum;
  studentNickname: string;
  mastery: { avg: number; attempts: number; ae: number } | undefined;
}

const DISCIPLINE_STYLES: Record<string, string> = {
  PT: 'bg-blue-50 border-blue-200',
  MAT: 'bg-violet-50 border-violet-200',
  CN: 'bg-emerald-50 border-emerald-200',
  FQ: 'bg-orange-50 border-orange-200',
};

const DISCIPLINE_BADGE: Record<string, string> = {
  PT: 'bg-blue-600 text-white',
  MAT: 'bg-violet-600 text-white',
  CN: 'bg-emerald-600 text-white',
  FQ: 'bg-orange-600 text-white',
};

export function CurriculumTile({
  curriculum,
  studentNickname,
  mastery,
}: CurriculumTileProps) {
  const code = curriculum.discipline_code ?? 'X';
  const bg = DISCIPLINE_STYLES[code] ?? 'bg-card border-border';
  const badge = DISCIPLINE_BADGE[code] ?? 'bg-primary text-primary-foreground';

  const avg = mastery?.avg ?? 0;
  const ae = mastery?.ae ?? 0;
  const attempts = mastery?.attempts ?? 0;

  return (
    <Link
      href={`/aluno/${studentNickname}/curriculo/${curriculum.slug}`}
      className={cn(
        'group rounded-lg border p-4 hover:shadow-md hover:border-primary transition flex flex-col gap-3',
        bg,
      )}
    >
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-2">
          <span
            className={cn(
              'inline-flex items-center justify-center w-10 h-10 rounded-md font-serif font-bold text-sm',
              badge,
            )}
          >
            {code}
          </span>
          <div>
            <div className="font-serif font-semibold leading-tight">
              {curriculum.discipline}
            </div>
            <div className="text-xs text-muted-foreground">
              {curriculum.school_year}.º ano
            </div>
          </div>
        </div>
        <span className="text-xs text-muted-foreground">{ae} AE</span>
      </div>

      <div>
        <div className="flex items-baseline justify-between mb-1">
          <span className="text-xs text-muted-foreground">Mestria média</span>
          <span className="text-sm font-semibold tabular-nums">
            {(avg * 100).toFixed(0)}%
          </span>
        </div>
        <MasteryBar value={avg} size="sm" />
      </div>

      <div className="flex items-center justify-between text-xs text-muted-foreground pt-1 border-t border-border/50">
        <span>{attempts} tentativas</span>
        <span className="text-primary group-hover:translate-x-0.5 transition">
          Detalhe →
        </span>
      </div>
    </Link>
  );
}
