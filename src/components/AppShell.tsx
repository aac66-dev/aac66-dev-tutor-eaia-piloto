import Link from 'next/link';
import { ReactNode } from 'react';

interface AppShellProps {
  children: ReactNode;
  breadcrumb?: Array<{ label: string; href?: string }>;
}

export function AppShell({ children, breadcrumb = [] }: AppShellProps) {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-border bg-card">
        <div className="container flex items-center justify-between h-16">
          <Link href="/supervisor" className="flex items-center gap-2">
            <span className="inline-block w-8 h-8 rounded-lg bg-primary text-primary-foreground grid place-items-center font-serif font-semibold">
              E
            </span>
            <div className="flex flex-col">
              <span className="font-serif font-semibold text-lg leading-none">
                Tutor EAIA
              </span>
              <span className="text-xs text-muted-foreground">
                Ensino Apoiado por Inteligência Artificial
              </span>
            </div>
          </Link>
          <nav className="flex items-center gap-6 text-sm">
            <Link
              href="/supervisor"
              className="text-muted-foreground hover:text-foreground"
            >
              Supervisor
            </Link>
            <span className="text-xs px-2 py-0.5 rounded bg-accent text-accent-foreground">
              Piloto Opção 2
            </span>
          </nav>
        </div>
      </header>

      {breadcrumb.length > 0 && (
        <div className="border-b border-border bg-background">
          <div className="container py-2 text-sm text-muted-foreground flex items-center gap-2">
            {breadcrumb.map((b, i) => (
              <span key={i} className="flex items-center gap-2">
                {i > 0 && <span className="opacity-50">/</span>}
                {b.href ? (
                  <Link href={b.href} className="hover:text-foreground">
                    {b.label}
                  </Link>
                ) : (
                  <span className="text-foreground">{b.label}</span>
                )}
              </span>
            ))}
          </div>
        </div>
      )}

      <main className="flex-1">
        <div className="container py-8">{children}</div>
      </main>

      <footer className="border-t border-border bg-card text-xs text-muted-foreground">
        <div className="container py-4 flex items-center justify-between">
          <span>
            Dados da União Europeia, Irlanda (eu-west-1). Perfis sintéticos para
            efeitos de piloto.
          </span>
          <span>Tutor EAIA, v0.1 piloto</span>
        </div>
      </footer>
    </div>
  );
}
