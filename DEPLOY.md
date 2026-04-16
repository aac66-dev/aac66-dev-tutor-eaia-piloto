# Deploy Tutor EAIA, piloto Opção 2

Este documento descreve como colocar a nova aplicação do Tutor EAIA em produção na Vercel, apontando à base de dados Supabase dedicada (`tutor-eaia-pt`, Irlanda).

## 1. Pré-requisitos

A nova frontend, totalmente reescrita a raiz, vive em `src/`. O código herdado do AEP está preservado em `src-legacy-aep/` e excluído do build (ver `tsconfig.json`).

A base de dados já está populada:
- 9 currículos, 39 unidades, 406 Aprendizagens Essenciais.
- 3 alunos sintéticos com mestria BKT e tutor_sessions simuladas.
- Projeto Supabase `gkvxhbzoilewqwootkqh`, região `eu-west-1` (Irlanda).

## 2. Variáveis de ambiente

Na Vercel, no projeto novo do Tutor EAIA, configurar as variáveis de `.env.local`:

```
NEXT_PUBLIC_SUPABASE_URL=https://gkvxhbzoilewqwootkqh.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<ver .env.local local, publishable key>
SUPABASE_SERVICE_ROLE_KEY=<ver .env.local local, secret key, só em servidor>
SUPABASE_PROJECT_REF=gkvxhbzoilewqwootkqh
```

**Nota de segurança:** as chaves reais não são incluídas no repositório. Consultar o ficheiro `.env.local` local ou a consola Supabase do projeto para obter os valores actuais.

**Atenção:** o `SUPABASE_SERVICE_ROLE_KEY` só deve estar em variáveis de servidor, nunca expostas ao browser. No piloto actual as páginas usam este cliente para contornar RLS (sem login individual), decisão consciente e temporária.

## 3. Passos de deploy

1. Empurrar a pasta `codigo/` para o repositório GitHub dedicado ao Tutor EAIA (ainda por criar, distinto do repositório AEP).
2. Na Vercel, criar novo projecto apontando à root `codigo/`.
3. Definir as variáveis de ambiente listadas acima no separador Settings, Environment Variables.
4. Fazer deploy. A rota `/` redirecciona para `/supervisor`, que lista os 3 alunos sintéticos.

## 4. Rotas da aplicação

| Rota | Descrição |
|---|---|
| `/` | Redirecciona para `/supervisor`. |
| `/supervisor` | Painel do supervisor, lista dos 3 alunos com mestria global e âmbito curricular. |
| `/aluno/[nickname]` | Dashboard do aluno, grelha Português 7-12 + linha transversal 9.º ano. |
| `/aluno/[nickname]/curriculo/[slug]` | Mestria detalhada por domínio pedagógico e AE. |

Valores aceites para `nickname`: `Maria`, `Joao`, `Sofia`.
Valores aceites para `slug`: `portugues-7`, `portugues-8`, ..., `portugues-12`, `matematica-9`, `ciencias-naturais-9`, `fisico-quimica-9`.

## 5. Validação pós-deploy

Entrar em `/supervisor` e verificar:
- 3 cartões de alunos com mestria global diferente por perfil (Maria 0.25, João 0.56, Sofia 0.80).
- 9 currículos listados na secção Âmbito curricular.

Entrar em `/aluno/Sofia` e verificar:
- Mestria global acima de 0.75.
- Grelha com 6 cartões de Português e 3 cartões transversais, todos pintados de verde.

Entrar em `/aluno/Maria/curriculo/portugues-9` e verificar:
- Lista de 5 domínios (Oralidade, Leitura, Educação Literária, Escrita, Gramática).
- Cada domínio abre com a lista de AE oficiais, com código DGE no lado esquerdo.

## 6. Diferenças face ao piloto Rita (AEP)

| Aspecto | AEP Rita | Tutor EAIA Opção 2 |
|---|---|---|
| Público | 1 aluna universitária, Direito | 3 perfis sintéticos K-12 |
| Currículos | 2 UCs de Direito | 9 currículos DGE |
| Supabase | Outro projecto, região anterior | `gkvxhbzoilewqwootkqh`, Irlanda |
| Frontend | Dashboard centrado em UC única | Grelha multi-disciplina PT 6 + Trans. 9.º ano 3 |
| Login | Aluno autentica-se | Sem login, só supervisor vê o painel |
| Código | Em produção com a Rita, `frozen` | Reescrito a raiz, `src/` novo |

## 7. Próximos passos depois do deploy

- M6, Manual de Piloto v2 e Template de Relatório v2 alinhados com a grelha reduzida.
- M7, verificação end-to-end com o supervisor institucional.
- Eventual reintrodução de login individual quando as cartas institucionais forem aceites.
