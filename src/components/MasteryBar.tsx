import { cn } from '@/lib/cn';
import { masteryColor } from '@/lib/types';

interface MasteryBarProps {
  value: number;
  showValue?: boolean;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export function MasteryBar({
  value,
  showValue = false,
  size = 'md',
  className,
}: MasteryBarProps) {
  const pct = Math.max(0, Math.min(1, value)) * 100;
  const heightCls = size === 'sm' ? 'h-1.5' : size === 'lg' ? 'h-3' : 'h-2';

  return (
    <div className={cn('w-full flex items-center gap-2', className)}>
      <div className={cn('flex-1 rounded-full bg-secondary overflow-hidden', heightCls)}>
        <div
          className={cn('h-full rounded-full transition-all', masteryColor(value))}
          style={{ width: `${pct}%` }}
        />
      </div>
      {showValue && (
        <span className="text-xs tabular-nums text-muted-foreground w-10 text-right">
          {pct.toFixed(0)}%
        </span>
      )}
    </div>
  );
}
