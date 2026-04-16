/**
 * Edge Function: tutor-session
 *
 * Runtime: Deno (Supabase Edge Functions)
 *
 * Responsabilidades:
 *   1. Autenticar o chamador via JWT Supabase.
 *   2. Carregar o PromptBundle do aluno pedido.
 *   3. Renderizar o prompt com o prompt-builder.
 *   4. Chamar a API do Claude (mensagens).
 *   5. Registar a interaccao em tutor_sessions para auditoria.
 *   6. Devolver ao chamador a resposta do modelo + o id do registo.
 *
 * Invocacao:
 *   POST /functions/v1/tutor-session
 *   Authorization: Bearer <user JWT>
 *   body: {
 *     student_id: string,
 *     unit_id?: string,
 *     topic_id?: string,
 *     session_type: "explicacao" | "revisao" | "exame" | "resumo" | "quiz",
 *     student_question?: string,
 *     with_flashcards?: boolean
 *   }
 *
 * Nota: este ficheiro nao importa do codigo Next.js para evitar mistura
 * de runtimes. Tem copias locais minimas do prompt-builder e dos tipos
 * que precisa. A fonte canonica vive em src/lib/aep/ e qualquer alteracao
 * deve ser reflectida aqui.
 */

// deno-lint-ignore-file no-explicit-any
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

// ================== TIPOS (espelho de src/lib/aep/types.ts) ==================
type TutorSessionType = 'explicacao' | 'revisao' | 'exame' | 'resumo' | 'quiz';

interface PromptBundle {
  student: any;
  curriculum: any | null;
  unit: any | null;
  topic: any | null;
  teacher_context: any | null;
  teacher_profile: any | null;
  teacher_profile_docs: any[];
  official_docs: any[];
  recent_sessions: any[];
  open_doubts: any[];
  materials: any[];
}

// ================== PROMPT BUILDER (espelho simplificado) ==================
const SYSTEM_PREAMBLE = `Es o AEP, Assistente Educativo Personalizado.
O teu objectivo e ajudar um aluno concreto a compreender e consolidar a
materia que tem de estudar, respeitando o curriculo oficial e o estilo do
professor.

Regras permanentes:
- Responde sempre em portugues europeu, pos-Acordo Ortografico de 1990.
- Usa vocabulario e exemplos do contexto do aluno (nivel e area de estudo).
- Nao inventes factos. Se nao tiveres informacao, assume e assinala.
- Estrutura a resposta em seccoes curtas com titulos quando ajudar.
- Termina sempre com uma verificacao de compreensao, 1 a 3 perguntas.
- Nunca pecas ao aluno dados pessoais sensiveis.
- Evita o tracado longo (em dash) na escrita, usa virgulas ou pontos.

Metodologia pedagogica:
- Metodo Socrático: quando o aluno faz uma pergunta, nao dás apenas a resposta.
  Guia-o atraves de perguntas sequenciais e passos de raciocinio para que descubra
  a resposta por si mesmo. Faz perguntas progressivas que o levem a conclusoes.
- Adaptacao de dificuldade: se o historico de notas recentes (Camada C) mostra scores
  consistentes 4-5, aumenta a complexidade e profundidade. Se mostra 1-2, simplifica
  explicacoes, usa mais analogias e passos intermediarios.
- Exemplos praticos: inclui sempre pelo menos um exemplo real ou aplicado,
  relacionado com a area de estudo do aluno (ver Camada A). Conecta a teoria ao uso pratico.
- Ligacao ao conhecimento anterior: quando relevante, referencia topicos ou conceptos
  de sessoes anteriores (disponíveis na Camada C). Reforça conexoes entre ideias.
- Recursos mnemonicos: para conceptos complexos, sugere esquemas, acronimos,
  analogias ou dispositivos mnemonicos que facilitam a retencao de memoria.
- Reforco positivo: quando o aluno demonstra compreensao ou progresso, inclui
  uma breve mensagem de encorajamento. Reconhece o esforco e o desenvolvimento.
- Atribuicao de fonte: quando usas conteudo de materiais carregados (Camada C),
  referencia o nome do documento. Isto ajuda o aluno a localizar informacao e
  constroi confianca na origem do conhecimento.

Avaliacao automatica (OBRIGATORIO em TODAS as respostas):
No final absoluto da tua resposta, depois de todo o conteudo visivel,
inclui uma linha com exactamente "---SCORING---" seguida de um unico
objecto JSON com esta estrutura (sem texto adicional depois do JSON):
{"score":3,"difficulty":"media","topics_covered":["Topico A","Topico B"],"comprehension_estimate":"parcial","notes":"breve observacao"}
Campos:
- score: inteiro 1-5, avaliacao da qualidade da interaccao e profundidade (1=superficial, 5=dominio solido)
- difficulty: "baixa" | "media" | "alta" | "muito_alta"
- topics_covered: array com nomes dos topicos abordados
- comprehension_estimate: "nenhuma" | "parcial" | "boa" | "excelente"
- notes: frase curta com observacao pedagogica relevante para o supervisor`;

function section(title: string, body: string | null | undefined): string {
  if (!body || !body.trim()) return '';
  return `\n## ${title}\n${body.trim()}\n`;
}

function formatLayerA(b: PromptBundle): string {
  const parts: string[] = [];
  if (b.curriculum) {
    parts.push(
      `Curso: ${b.curriculum.title}${b.curriculum.version ? ` (${b.curriculum.version})` : ''}`,
    );
    if (b.curriculum.pedagogical_domain && b.curriculum.pedagogical_domain !== 'geral') {
      parts.push(`Dominio pedagogico: ${b.curriculum.pedagogical_domain}`);
    }
    if (b.curriculum.domain_instructions) {
      parts.push(`Instrucoes especificas do dominio:\n${b.curriculum.domain_instructions}`);
    }
  }
  if (b.unit) {
    const ects = b.unit.ects ? `, ${b.unit.ects} ECTS` : '';
    parts.push(
      `Unidade curricular: ${b.unit.title}${b.unit.period ? ` (${b.unit.period}${ects})` : ''}`,
    );
    if (b.unit.evaluation_criteria) {
      parts.push(`Criterios de avaliacao: ${b.unit.evaluation_criteria}`);
    }
  }
  if (b.topic) {
    parts.push(`Topico: ${b.topic.title}`);
    if (b.topic.learning_objectives) {
      parts.push(`Objectivos de aprendizagem: ${b.topic.learning_objectives}`);
    }
    if (b.topic.description) parts.push(`Descricao: ${b.topic.description}`);
  }

  // Documentos oficiais do curriculo (carregados pelo supervisor)
  if (b.official_docs.length > 0) {
    const docsWithText = b.official_docs
      .filter((d: any) => d.extracted_text && d.extracted_text.trim().length > 0)
      .slice(0, 2);

    if (docsWithText.length > 0) {
      const MAX_CHARS = 5000;
      const blocks = docsWithText.map((d: any) => {
        const txt = d.extracted_text.trim();
        const truncated = txt.length > MAX_CHARS
          ? txt.slice(0, MAX_CHARS) + '\n[... truncado]'
          : txt;
        return `### ${d.title} (${d.doc_type}):\n${truncated}`;
      }).join('\n\n');
      parts.push(`\nDocumentacao oficial da unidade curricular (usa como referencia autoritativa):\n${blocks}`);
    }
  }

  return parts.join('\n');
}

function formatLayerB(b: PromptBundle): string {
  const parts: string[] = [];

  // Eixo 2: Perfil do professor (preenchido pelo aluno)
  const tp = b.teacher_profile;
  if (tp) {
    if (tp.teacher_name) parts.push(`Professor: ${tp.teacher_name}`);
    if (tp.teaching_style) parts.push(`Estilo de ensino: ${tp.teaching_style}`);
    if (tp.exam_style) parts.push(`Estilo de exame: ${tp.exam_style}`);
    if (tp.grading_criteria) parts.push(`Criterios de avaliacao do professor: ${tp.grading_criteria}`);
    if (tp.preferred_bibliography) parts.push(`Bibliografia preferida: ${tp.preferred_bibliography}`);
    if (tp.common_questions) parts.push(`Perguntas frequentes / temas recorrentes: ${tp.common_questions}`);
    if (tp.notes) parts.push(`Notas adicionais sobre o professor: ${tp.notes}`);
  }

  // Documentos do professor (enunciados, slides, apontamentos) com texto extraido
  if (b.teacher_profile_docs.length > 0) {
    const docsWithText = b.teacher_profile_docs
      .filter((d: any) => d.extracted_text && d.extracted_text.trim().length > 0)
      .slice(0, 3);

    if (docsWithText.length > 0) {
      const MAX_CHARS = 5000;
      const blocks = docsWithText.map((d: any) => {
        const txt = d.extracted_text.trim();
        const truncated = txt.length > MAX_CHARS
          ? txt.slice(0, MAX_CHARS) + '\n[... truncado]'
          : txt;
        const label = d.title ?? d.file_name ?? 'Documento';
        const docType = d.doc_type ?? 'documento';
        return `### ${label} (${docType}):\n${truncated}`;
      }).join('\n\n');
      parts.push(`\nDocumentos do professor (usa para adaptar ao estilo de ensino e avaliacao):\n${blocks}`);
    }
  }

  // Fallback: teacher_context legado (se existir e nao houver teacher_profile)
  if (!tp && b.teacher_context) {
    const tc = b.teacher_context;
    if (tc.teacher_name) parts.push(`Professor: ${tc.teacher_name}`);
    if (tc.teaching_style) parts.push(`Estilo de ensino: ${tc.teaching_style}`);
    if (tc.evaluation_notes) parts.push(`Notas de avaliacao: ${tc.evaluation_notes}`);
    if (tc.bibliography) parts.push(`Bibliografia: ${tc.bibliography}`);
    if (tc.calendar_notes) parts.push(`Calendario: ${tc.calendar_notes}`);
  }

  return parts.join('\n');
}

function formatLayerC(b: PromptBundle): string {
  const parts: string[] = [];

  // Sessoes recentes (tutor_sessions)
  if (b.recent_sessions.length > 0) {
    const rows = b.recent_sessions
      .slice(0, 10)
      .map((s) => {
        const dt = s.created_at
          ? new Date(s.created_at).toLocaleDateString('pt-PT', { day: '2-digit', month: '2-digit' })
          : '??';
        const score = s.performance_snapshot?.score
          ? ` (nota: ${s.performance_snapshot.score}/5)`
          : '';
        return `- ${dt} [${s.session_type}]${score}`;
      })
      .join('\n');
    parts.push(`Sessoes recentes:\n${rows}`);
  }

  // Duvidas abertas (student_notes com note_type='doubt' e resolved=false)
  if (b.open_doubts.length > 0) {
    const rows = b.open_doubts
      .slice(0, 8)
      .map((d) => `- ${d.title ?? 'Sem titulo'}: ${(d.content ?? '').slice(0, 120)}`)
      .join('\n');
    parts.push(`Duvidas abertas do aluno:\n${rows}`);
  }

  // Materiais com texto extraido (student_documents com processing_status='done')
  if (b.materials.length > 0) {
    // Primeiro, listar os documentos disponiveis
    const listing = b.materials
      .slice(0, 10)
      .map((m) => `- ${m.file_name} (${m.doc_type ?? 'ficheiro'})`)
      .join('\n');
    parts.push(`Materiais do aluno:\n${listing}`);

    // Depois, injetar o texto extraido dos documentos relevantes
    // Limitar a ~6000 caracteres por documento e maximo 3 documentos com texto
    const docsWithText = b.materials
      .filter((m: any) => m.extracted_text && m.extracted_text.trim().length > 0)
      .slice(0, 3);

    if (docsWithText.length > 0) {
      const MAX_CHARS_PER_DOC = 6000;
      const textBlocks = docsWithText
        .map((m: any) => {
          const txt = m.extracted_text.trim();
          const truncated = txt.length > MAX_CHARS_PER_DOC
            ? txt.slice(0, MAX_CHARS_PER_DOC) + '\n[... texto truncado por limite de contexto]'
            : txt;
          return `### Conteudo de "${m.file_name}":\n${truncated}`;
        })
        .join('\n\n');
      parts.push(`Conteudo extraido dos materiais do aluno (usa para fundamentar as tuas respostas):\n${textBlocks}`);
    }
  }

  return parts.join('\n\n');
}

function taskInstructions(
  type: TutorSessionType,
  question?: string,
  withFlashcards?: boolean,
): string {
  let body = '';
  switch (type) {
    case 'explicacao':
      body =
        'Explica o topico actual de forma clara, do simples para o complexo.' +
        ' Relaciona com topicos anteriores se fizer sentido.';
      break;
    case 'revisao':
      body =
        'Faz um resumo de revisao do topico actual, cobrindo os pontos-chave' +
        ' que costumam cair em avaliacao. Inclui mnemonicas quando ajudar.';
      break;
    case 'exame':
      body =
        'Simula uma pergunta de exame ao nivel do topico actual, espera que o' +
        ' aluno responda, e depois da feedback detalhado.';
      break;
    case 'resumo':
      body =
        'Produz um resumo estruturado e conciso do topico, em maximo uma pagina,' +
        ' com headings claros e bullets curtos.';
      break;
    case 'quiz':
      body =
        'Gera 5 perguntas de escolha multipla sobre o topico, com 4 opcoes cada,' +
        ' indicando a resposta correcta e uma justificacao curta.';
      break;
  }
  if (question && question.trim()) {
    body += `\n\nPedido especifico do aluno:\n"${question.trim()}"`;
  }
  if (withFlashcards) {
    body +=
      '\n\nNo final, depois de uma linha com exactamente "---FLASHCARDS---",' +
      ' devolve um array JSON com 3 a 6 objectos no formato' +
      ' {"q": "pergunta", "a": "resposta curta"} para alimentar o sistema' +
      ' de repeticao espacada. Nao adiciones texto depois do array.';
  }
  return body;
}

function buildPrompt(
  bundle: PromptBundle,
  session_type: TutorSessionType,
  student_question?: string,
  with_flashcards?: boolean,
): { system: string; user: string; template_name: string } {
  const curriculumName = bundle.curriculum?.title ? `, ${bundle.curriculum.title}` : '';
  const studentLine = `Aluno: ${bundle.student.nickname ?? bundle.student.full_name}, ${bundle.student.education_level ?? 'ensino superior'}${curriculumName}${bundle.student.institution ? ', ' + bundle.student.institution : ''}.`;
  const user =
    studentLine +
    section('CAMADA A, curriculo oficial', formatLayerA(bundle)) +
    section('CAMADA B, contexto do professor', formatLayerB(bundle)) +
    section('CAMADA C, historico recente do aluno', formatLayerC(bundle)) +
    section('TAREFA', taskInstructions(session_type, student_question, with_flashcards));
  return {
    system: SYSTEM_PREAMBLE,
    user: user.trim(),
    template_name: `aep.${session_type}${with_flashcards ? '.with-flashcards' : ''}.v1`,
  };
}

// ================== HANDLER ==================
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

async function loadBundle(
  supabase: any,
  student_id: string,
  unit_id: string | null,
  topic_id: string | null,
): Promise<PromptBundle> {
  const { data: student, error: e1 } = await supabase
    .from('students')
    .select('*')
    .eq('id', student_id)
    .single();
  if (e1 || !student) throw new Error('student not found');

  const { data: enrollment } = await supabase
    .from('student_enrollments')
    .select('curriculum_id')
    .eq('student_id', student_id)
    .eq('active', true)
    .order('start_date', { ascending: false })
    .limit(1)
    .maybeSingle();

  let curriculum = null;
  if (enrollment?.curriculum_id) {
    const { data } = await supabase
      .from('curricula')
      .select('*')
      .eq('id', enrollment.curriculum_id)
      .single();
    curriculum = data;
  }

  let unit = null;
  if (unit_id) {
    const { data } = await supabase
      .from('curriculum_units')
      .select('*')
      .eq('id', unit_id)
      .single();
    unit = data;
  }

  let topic = null;
  if (topic_id) {
    const { data } = await supabase
      .from('curriculum_topics')
      .select('*')
      .eq('id', topic_id)
      .single();
    topic = data;
  }

  let teacher_context = null;
  if (unit_id) {
    const { data } = await supabase
      .from('teacher_context')
      .select('*')
      .eq('student_id', student_id)
      .eq('unit_id', unit_id)
      .maybeSingle();
    teacher_context = data;
  }

  // Phase 2: tutor_sessions (substitui tabela legacy 'sessions')
  let recentQ = supabase
    .from('tutor_sessions')
    .select('id, session_type, performance_snapshot, created_at, unit_id, topic_id')
    .eq('student_id', student_id)
    .order('created_at', { ascending: false })
    .limit(10);
  if (unit_id) recentQ = recentQ.eq('unit_id', unit_id);
  const { data: recent_sessions } = await recentQ;

  // Phase 2: student_notes com note_type='doubt' e resolved=false (substitui tabela legacy 'doubts')
  let doubtsQ = supabase
    .from('student_notes')
    .select('id, title, content, topic_id, unit_id, created_at')
    .eq('student_id', student_id)
    .eq('note_type', 'doubt')
    .eq('resolved', false)
    .order('created_at', { ascending: false })
    .limit(8);
  if (topic_id) doubtsQ = doubtsQ.eq('topic_id', topic_id);
  const { data: open_doubts } = await doubtsQ;

  // Phase 2: student_documents com processing_status='done' (substitui tabela legacy 'materials')
  let matQ = supabase
    .from('student_documents')
    .select('id, file_name, doc_type, extracted_text, unit_id, topic_id, created_at')
    .eq('student_id', student_id)
    .eq('processing_status', 'done')
    .order('created_at', { ascending: false })
    .limit(10);
  if (unit_id) matQ = matQ.eq('unit_id', unit_id);
  const { data: materials } = await matQ;

  // Phase 2 – Eixo 1: Documentos oficiais do curriculo (carregados pelo supervisor)
  let official_docs: any[] = [];
  if (unit_id) {
    const { data } = await supabase
      .from('curriculum_official_docs')
      .select('id, title, doc_type, extracted_text, created_at')
      .eq('unit_id', unit_id)
      .eq('processing_status', 'done')
      .order('created_at', { ascending: false })
      .limit(3);
    official_docs = data ?? [];
  }

  // Phase 2 – Eixo 2: Perfil do professor (preenchido pelo aluno)
  let teacher_profile: any = null;
  let teacher_profile_docs: any[] = [];
  if (unit_id) {
    const { data: tp } = await supabase
      .from('teacher_profiles')
      .select('*')
      .eq('student_id', student_id)
      .eq('unit_id', unit_id)
      .maybeSingle();
    teacher_profile = tp;

    if (tp) {
      const { data: tpDocs } = await supabase
        .from('teacher_profile_docs')
        .select('id, title, file_name, doc_type, extracted_text, processing_status, created_at')
        .eq('teacher_profile_id', tp.id)
        .eq('processing_status', 'done')
        .order('created_at', { ascending: false })
        .limit(5);
      teacher_profile_docs = tpDocs ?? [];
    }
  }

  return {
    student,
    curriculum,
    unit,
    topic,
    teacher_context,
    teacher_profile,
    teacher_profile_docs,
    official_docs,
    recent_sessions: recent_sessions ?? [],
    open_doubts: open_doubts ?? [],
    materials: materials ?? [],
  };
}

async function callClaude(
  system: string,
  userPrompt: string,
  model: string,
  maxTokens: number,
  apiKey: string,
): Promise<{
  text: string;
  input_tokens: number | null;
  output_tokens: number | null;
}> {
  const resp = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      max_tokens: maxTokens,
      system,
      messages: [{ role: 'user', content: userPrompt }],
    }),
  });
  if (!resp.ok) {
    const err = await resp.text();
    throw new Error(`Claude API ${resp.status}: ${err}`);
  }
  const data = await resp.json();
  const text = (data.content ?? [])
    .map((c: any) => (c.type === 'text' ? c.text : ''))
    .join('')
    .trim();
  return {
    text,
    input_tokens: data.usage?.input_tokens ?? null,
    output_tokens: data.usage?.output_tokens ?? null,
  };
}

function estimateCostUsd(
  model: string,
  input_tokens: number | null,
  output_tokens: number | null,
): number | null {
  if (input_tokens == null || output_tokens == null) return null;
  // Precos orientativos Sonnet 4.5 (USD por milhao de tokens).
  // Actualizar quando a Anthropic publicar tabela oficial para Sonnet 4.6.
  const priceIn = model.includes('opus') ? 15 : 3;
  const priceOut = model.includes('opus') ? 75 : 15;
  return (input_tokens * priceIn + output_tokens * priceOut) / 1_000_000;
}

async function checkCostLimits(
  supabase: any,
  student_id: string,
  curriculum: any | null,
): Promise<{
  blocked: boolean;
  reason: string;
  currentCost: number;
  limit: number | null;
}> {
  const DEFAULT_GLOBAL_LIMIT = parseFloat(
    Deno.env.get('AEP_MONTHLY_BUDGET_USD') ?? '50',
  );

  // Calcular custo do mês corrente para este aluno
  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);

  const { data: monthSessions } = await supabase
    .from('tutor_sessions')
    .select('cost_usd')
    .eq('student_id', student_id)
    .gte('created_at', monthStart.toISOString());

  const currentCost = (monthSessions ?? []).reduce(
    (sum: number, s: any) => sum + (s.cost_usd ?? 0),
    0,
  );

  // 1. Verificar limite do curriculo
  if (curriculum?.max_monthly_cost_usd) {
    const currLimit = parseFloat(String(curriculum.max_monthly_cost_usd));
    if (currentCost >= currLimit) {
      return {
        blocked: true,
        reason: `Limite mensal do curriculo atingido ($${currentCost.toFixed(2)} / $${currLimit.toFixed(2)}). Contacta o teu supervisor.`,
        currentCost,
        limit: currLimit,
      };
    }
  }

  // 2. Verificar limite do supervisor
  const { data: supervisorLink } = await supabase
    .from('supervisor_students')
    .select('supervisor_id, supervisors(max_monthly_cost_usd)')
    .eq('student_id', student_id)
    .limit(1)
    .maybeSingle();

  if (supervisorLink?.supervisors?.max_monthly_cost_usd) {
    const supLimit = parseFloat(
      String(supervisorLink.supervisors.max_monthly_cost_usd),
    );
    // Para o supervisor, verificar custo total de TODOS os seus alunos
    const { data: allStudents } = await supabase
      .from('supervisor_students')
      .select('student_id')
      .eq('supervisor_id', supervisorLink.supervisor_id);

    const allStudentIds = (allStudents ?? []).map((s: any) => s.student_id);
    if (allStudentIds.length > 0) {
      const { data: allSessions } = await supabase
        .from('tutor_sessions')
        .select('cost_usd')
        .in('student_id', allStudentIds)
        .gte('created_at', monthStart.toISOString());

      const totalSupCost = (allSessions ?? []).reduce(
        (sum: number, s: any) => sum + (s.cost_usd ?? 0),
        0,
      );

      if (totalSupCost >= supLimit) {
        return {
          blocked: true,
          reason: `Limite mensal do supervisor atingido. Contacta o teu supervisor.`,
          currentCost: totalSupCost,
          limit: supLimit,
        };
      }
    }
  }

  // 3. Verificar limite global (fallback)
  if (DEFAULT_GLOBAL_LIMIT > 0 && currentCost >= DEFAULT_GLOBAL_LIMIT) {
    return {
      blocked: true,
      reason: `Limite mensal global atingido ($${currentCost.toFixed(2)} / $${DEFAULT_GLOBAL_LIMIT.toFixed(2)}). Contacta o administrador.`,
      currentCost,
      limit: DEFAULT_GLOBAL_LIMIT,
    };
  }

  return { blocked: false, reason: '', currentCost, limit: null };
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS });
  if (req.method !== 'POST') return json(405, { error: 'method not allowed' });

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.toLowerCase().startsWith('bearer ')) {
    return json(401, { error: 'missing bearer token' });
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json(400, { error: 'invalid json body' });
  }

  const {
    student_id,
    unit_id = null,
    topic_id = null,
    session_type,
    student_question,
    with_flashcards,
  } = body ?? {};
  if (!student_id || !session_type) {
    return json(400, { error: 'student_id and session_type are required' });
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
  const SUPABASE_ANON = Deno.env.get('SUPABASE_ANON_KEY');
  const ANTHROPIC_KEY = Deno.env.get('ANTHROPIC_API_KEY');
  const DEFAULT_MODEL = Deno.env.get('AEP_DEFAULT_MODEL') ?? 'claude-sonnet-4-5-20250929';
  const MAX_TOKENS = Number(Deno.env.get('AEP_MAX_TOKENS') ?? '4096');
  if (!SUPABASE_URL || !SUPABASE_ANON) {
    return json(500, { error: 'Supabase env vars missing' });
  }
  if (!ANTHROPIC_KEY) {
    return json(503, { error: 'Anthropic key not configured yet' });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON, {
    global: { headers: { Authorization: authHeader } },
  });

  // Verificacao explicita de autenticacao (necessaria com --no-verify-jwt)
  const { data: { user: authUser }, error: authErr } = await supabase.auth.getUser();
  if (authErr || !authUser) {
    return json(401, { error: 'Nao autenticado. Faz login novamente.' });
  }

  try {
    const bundle = await loadBundle(supabase, student_id, unit_id, topic_id);

    // Verificacao de limites de custo antes de chamar o Claude
    const costCheck = await checkCostLimits(supabase, student_id, bundle.curriculum);
    if (costCheck.blocked) {
      return json(429, {
        error: costCheck.reason,
        cost_limit_reached: true,
        current_month_cost: costCheck.currentCost,
        monthly_limit: costCheck.limit,
      });
    }

    // Modelo pode ser customizado por currículo
    const effectiveModel = bundle.curriculum?.default_model ?? DEFAULT_MODEL;

    const { system, user, template_name } = buildPrompt(
      bundle,
      session_type as TutorSessionType,
      student_question,
      with_flashcards,
    );
    const claude = await callClaude(system, user, effectiveModel, MAX_TOKENS, ANTHROPIC_KEY);
    const cost_usd = estimateCostUsd(effectiveModel, claude.input_tokens, claude.output_tokens);

    // Parse scoring automatico do final da resposta
    let visibleResponse = claude.text;
    let performanceSnapshot: Record<string, unknown> | null = null;

    const scoringIdx = claude.text.indexOf('---SCORING---');
    if (scoringIdx !== -1) {
      visibleResponse = claude.text.slice(0, scoringIdx).trim();
      const jsonPart = claude.text.slice(scoringIdx + '---SCORING---'.length).trim();
      try {
        const parsed = JSON.parse(jsonPart);
        performanceSnapshot = {
          score: typeof parsed.score === 'number' ? Math.min(5, Math.max(1, parsed.score)) : null,
          difficulty: parsed.difficulty ?? null,
          topics_covered: Array.isArray(parsed.topics_covered) ? parsed.topics_covered : [],
          comprehension_estimate: parsed.comprehension_estimate ?? null,
          notes: parsed.notes ?? null,
        };
      } catch {
        // Se o JSON estiver mal formado, tentar extrair pelo menos o score
        const scoreMatch = jsonPart.match(/"score"\s*:\s*(\d)/);
        if (scoreMatch) {
          performanceSnapshot = { score: parseInt(scoreMatch[1], 10) };
        }
      }
    }

    const { data: inserted, error: insertErr } = await supabase
      .from('tutor_sessions')
      .insert([
        {
          student_id,
          unit_id,
          topic_id,
          session_type,
          model: effectiveModel,
          prompt_template: template_name,
          prompt_rendered: user,
          response: visibleResponse,
          input_tokens: claude.input_tokens,
          output_tokens: claude.output_tokens,
          cost_usd,
          performance_snapshot: performanceSnapshot,
        },
      ])
      .select('id')
      .single();

    if (insertErr) {
      return json(500, { error: 'db insert failed: ' + insertErr.message });
    }

    return json(200, {
      tutor_session_id: inserted?.id,
      template: template_name,
      response: visibleResponse,
      tokens: {
        input: claude.input_tokens,
        output: claude.output_tokens,
      },
      cost_usd,
      performance_snapshot: performanceSnapshot,
    });
  } catch (e) {
    return json(500, { error: (e as Error).message });
  }
});
