# Tutor EAIA, piloto Opção 2

Aplicação Next.js 14 do Tutor EAIA (Ensino Apoiado por Inteligência Artificial), versão reescrita a raiz para o piloto de prova de conceito do concurso nacional do Ministério da Educação.

## Contexto

O piloto adopta o âmbito canónico Opção 2:

- Espinha dorsal, Português 7.º ao 12.º ano, 6 currículos.
- Transversal 9.º ano, Matemática, Ciências Naturais e Físico-Química, 3 currículos.

Total, 9 currículos da DGE, 39 domínios pedagógicos, 406 Aprendizagens Essenciais.

## Estrutura

```
codigo/
├── src/                       Frontend novo do Tutor EAIA
│   ├── app/
│   │   ├── layout.tsx         Root layout
│   │   ├── page.tsx           Redirecciona para /supervisor
│   │   ├── supervisor/        Painel do supervisor
│   │   └── aluno/[nickname]/  Dashboard do aluno e detalhe por currículo
│   ├── components/            AppShell, MasteryBar, CurriculumTile
│   └── lib/                   supabase-server, queries, types, cn
├── src-legacy-aep/            Código AEP preservado, fora do build
├── scripts/                   Scripts Python de seed e verificação
│   ├── seed-opcao2.py         Seed dos 9 currículos
│   ├── seed-alunos-sinteticos.py   Seed dos 3 alunos + mastery + sessões
│   └── verify-eaia-seed.py    Verificação da integridade do seed
├── supabase/migrations/       Migrations SQL aplicadas
└── DEPLOY.md                  Guia de deploy para a Vercel
```

## Scripts de execução

```bash
npm install              # instalar dependências
npm run dev              # dev server em http://localhost:3000
npm run build            # build de produção
npm run lint             # lint
npm run typecheck        # verificação TypeScript sem emissão
```

## Scripts Python (seed e verificação)

```bash
python3 scripts/seed-opcao2.py              # popula 9 currículos
python3 scripts/seed-alunos-sinteticos.py   # cria 3 alunos + mastery + sessões
python3 scripts/verify-eaia-seed.py         # verifica integridade
```

Todos os scripts lêem `.env.local` e ligam via pooler `aws-0-eu-west-1.pooler.supabase.com:6543`.

## Base de dados

Projeto Supabase dedicado `tutor-eaia-pt`, ref `gkvxhbzoilewqwootkqh`, região `eu-west-1` (Irlanda), para cumprimento do RGPD. Separado do piloto AEP Rita.

Principais tabelas:
- `curricula`, `curriculum_units`, `curriculum_topics` (currículo oficial DGE)
- `dkm_concepts`, `dkm_domains`, `dkm_competencies` (Domain Knowledge Model)
- `students`, `student_enrollments`, `student_mastery` (BKT)
- `tutor_sessions`, `session_messages`, `student_feedback` (interacção)
- `pilot_scope` (registo do âmbito Opção 2)

## Deploy

Ver `DEPLOY.md`.
