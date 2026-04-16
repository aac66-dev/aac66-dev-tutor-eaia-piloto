/**
 * API Route: /api/tutor
 *
 * Versão piloto sem autenticação. Usa SERVICE_ROLE_KEY para contornar RLS.
 * Adapta a lógica da Edge Function tutor-session para Next.js App Router.
 *
 * POST body: {
 *   student_id: string,
 *   curriculum_id?: string,
 *   unit_id?: string,
 *   topic_id?: string,
 *   session_type: "explicacao" | "revisao" | "exame" | "resumo" | "quiz",
 *   student_question?: string,
 *   session_id?: string  // para multi-turn, envia o id da sessão anterior
 * }
 */

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

// ── tipos ────────────────────────────────────────────────────────────
type SessionType = "explicacao" | "resumo" | "quiz" | "teste" | "exame" | "revisao";

interface PromptBundle {
  student: Record<string, unknown>;
  curriculum: Record<string, unknown> | null;
  unit: Record<string, unknown> | null;
  topic: Record<string, unknown> | null;
  recent_sessions: Record<string, unknown>[];
  open_doubts: Record<string, unknown>[];
}

// ── system preamble ──────────────────────────────────────────────────
const SYSTEM = `És o Tutor EAIA, Ensino Apoiado por Inteligência Artificial.
O teu objetivo é ajudar um aluno concreto a compreender e consolidar a
matéria que tem de estudar, respeitando o currículo oficial da DGE.

Regras permanentes:
- Responde sempre em português europeu, pós-Acordo Ortográfico de 1990.
- Usa vocabulário e exemplos do contexto do aluno (nível e área de estudo).
- Não inventes factos. Se não tiveres informação, assume e assinala.
- Estrutura a resposta em secções curtas com títulos quando ajudar.
- Termina sempre com uma verificação de compreensão, 1 a 3 perguntas.
- Nunca peças ao aluno dados pessoais sensíveis.
- Evita o travessão longo na escrita, usa vírgulas ou pontos.
- Método Socrático: guia o aluno com perguntas sequenciais.
- Adaptação de dificuldade conforme o histórico.
- Inclui sempre pelo menos um exemplo prático.
- Reforço positivo quando o aluno demonstra progresso.

Avaliação automática (OBRIGATÓRIO em TODAS as respostas):
No final absoluto da tua resposta, depois de todo o conteúdo visível,
inclui uma linha com exatamente "---SCORING---" seguida de um único
objeto JSON: {"score":3,"difficulty":"media","topics_covered":["Tópico"],"comprehension_estimate":"parcial","notes":"breve observação"}`;

// ── BKT (Bayesian Knowledge Tracing) ────────────────────────────────
/**
 * Atualiza P(L_n) usando a fórmula standard de Bayesian Knowledge Tracing.
 *
 * Se o aluno acertou (correct = true):
 *   P(L_n | correct) = P(L_n-1) * (1 - P(S)) / [ P(L_n-1) * (1 - P(S)) + (1 - P(L_n-1)) * P(G) ]
 *
 * Se o aluno errou (correct = false):
 *   P(L_n | wrong) = P(L_n-1) * P(S) / [ P(L_n-1) * P(S) + (1 - P(L_n-1)) * (1 - P(G)) ]
 *
 * Depois aplica transição:
 *   P(L_n) = P(L_n | obs) + (1 - P(L_n | obs)) * P(T)
 */
function bktUpdate(
  pMastery: number,
  pTransit: number,
  pSlip: number,
  pGuess: number,
  correct: boolean,
): number {
  let posterior: number;
  if (correct) {
    const num = pMastery * (1 - pSlip);
    const den = num + (1 - pMastery) * pGuess;
    posterior = den > 0 ? num / den : pMastery;
  } else {
    const num = pMastery * pSlip;
    const den = num + (1 - pMastery) * (1 - pGuess);
    posterior = den > 0 ? num / den : pMastery;
  }
  // Transição: probabilidade de aprender após a interação
  const updated = posterior + (1 - posterior) * pTransit;
  // Clamp entre 0 e 1
  return Math.max(0, Math.min(1, updated));
}

/**
 * Mapeia score do Claude (1-5) para correct/incorrect no BKT.
 * Score >= 3 é considerado "demonstrou compreensão" (correct).
 * Adicionalmente mapeia comprehension_estimate.
 */
function scoreToCorrect(
  snapshot: Record<string, unknown> | null,
): boolean | null {
  if (!snapshot) return null;
  const score = Number(snapshot.score);
  if (isNaN(score)) {
    // Fallback para comprehension_estimate
    const est = String(snapshot.comprehension_estimate ?? "").toLowerCase();
    if (est === "boa" || est === "completa" || est === "good" || est === "complete") return true;
    if (est === "fraca" || est === "nenhuma" || est === "poor" || est === "none") return false;
    return null;
  }
  return score >= 3;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = ReturnType<typeof createClient>;

/**
 * Resolve topic_id → concept_id via dkm_concepts.
 * O código do conceito segue o padrão: {discipline_code}-{school_year}-{topic_code}
 */
async function resolveConceptId(
  supabase: SupabaseAny,
  topicId: string,
): Promise<string | null> {
  // Buscar o código do tópico
  const { data: topic } = await supabase
    .from("curriculum_topics")
    .select("code, unit_id")
    .eq("id", topicId)
    .single() as { data: { code: string; unit_id: string } | null };
  if (!topic?.code) return null;

  // Buscar a unidade para chegar ao currículo
  const { data: unit } = await supabase
    .from("curriculum_units")
    .select("curriculum_id")
    .eq("id", topic.unit_id)
    .single() as { data: { curriculum_id: string } | null };
  if (!unit?.curriculum_id) return null;

  // Buscar o currículo para obter discipline_code e school_year
  const { data: cur } = await supabase
    .from("curricula")
    .select("discipline_code, school_year")
    .eq("id", unit.curriculum_id)
    .single() as { data: { discipline_code: string; school_year: string } | null };
  if (!cur?.discipline_code || !cur?.school_year) return null;

  // Construir o código do conceito e procurar
  const conceptCode = `${cur.discipline_code}-${cur.school_year}-${topic.code}`;
  const { data: concept } = await supabase
    .from("dkm_concepts")
    .select("id")
    .eq("code", conceptCode)
    .single() as { data: { id: string } | null };

  return concept?.id ?? null;
}

/**
 * Atualiza a mestria BKT do aluno após uma interação avaliada.
 */
async function updateMastery(
  supabase: SupabaseAny,
  studentId: string,
  topicId: string | undefined,
  snapshot: Record<string, unknown> | null,
): Promise<void> {
  if (!topicId || !snapshot) return;

  const correct = scoreToCorrect(snapshot);
  if (correct === null) return;

  const conceptId = await resolveConceptId(supabase, topicId);
  if (!conceptId) return;

  // Ler mestria atual (ou usar defaults)
  const { data: current } = await supabase
    .from("student_mastery")
    .select("p_mastery, p_transit, p_slip, p_guess, attempts, correct_attempts")
    .eq("student_id", studentId)
    .eq("concept_id", conceptId)
    .maybeSingle() as {
      data: {
        p_mastery: number; p_transit: number; p_slip: number; p_guess: number;
        attempts: number; correct_attempts: number;
      } | null;
    };

  const prev = {
    p_mastery: Number(current?.p_mastery ?? 0.1),
    p_transit: Number(current?.p_transit ?? 0.1),
    p_slip: Number(current?.p_slip ?? 0.1),
    p_guess: Number(current?.p_guess ?? 0.2),
    attempts: current?.attempts ?? 0,
    correct_attempts: current?.correct_attempts ?? 0,
  };

  const newMastery = bktUpdate(
    prev.p_mastery,
    prev.p_transit,
    prev.p_slip,
    prev.p_guess,
    correct,
  );

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  await (supabase as any).from("student_mastery").upsert(
    {
      student_id: studentId,
      concept_id: conceptId,
      p_mastery: Math.round(newMastery * 10000) / 10000,
      p_transit: prev.p_transit,
      p_slip: prev.p_slip,
      p_guess: prev.p_guess,
      attempts: prev.attempts + 1,
      correct_attempts: prev.correct_attempts + (correct ? 1 : 0),
      last_attempted_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    { onConflict: "student_id,concept_id" },
  );
}

// ── helpers ──────────────────────────────────────────────────────────
function section(title: string, body: string): string {
  if (!body.trim()) return "";
  return `\n## ${title}\n${body.trim()}\n`;
}

function taskInstructions(type: SessionType, question?: string): string {
  const map: Record<string, string> = {
    explicacao:
      "Explica o tópico atual de forma clara, do simples para o complexo. Usa exemplos concretos. Relaciona com tópicos anteriores se fizer sentido. Método socrático: guia o aluno com perguntas.",
    resumo:
      "Produz um resumo estruturado e conciso do tópico, em máximo uma página, com headings claros e pontos-chave. Ideal para o aluno estudar antes de uma avaliação.",
    quiz:
      "Gera 5 perguntas de escolha múltipla sobre o tópico, com 4 opções cada (A, B, C, D). Indica a resposta correta e uma justificação curta para cada. Varia a dificuldade.",
    teste:
      "Simula um teste de aula, como o que o professor aplica em sala. Inclui uma mistura de: " +
      "1) uma pergunta de interpretação ou análise, " +
      "2) uma pergunta de desenvolvimento (resposta aberta, 8-12 linhas), " +
      "3) uma pergunta de aplicação prática ou exercício. " +
      "Apresenta as perguntas, espera que o aluno responda, e depois dá feedback detalhado com cotação simulada.",
    exame:
      "Simula uma pergunta de exame nacional oficial. Usa o formato, a linguagem e o nível de exigência das provas finais da DGE. " +
      "Apresenta a pergunta com os grupos e itens característicos do exame da disciplina. " +
      "Espera que o aluno responda e depois dá feedback com critérios de correção semelhantes aos do IAVE.",
    // Retrocompatibilidade: se alguma sessão antiga usar "revisao", redireciona para resumo
    revisao:
      "Produz um resumo estruturado e conciso do tópico, em máximo uma página, com headings claros e pontos-chave. Ideal para o aluno estudar antes de uma avaliação.",
  };
  let body = map[type] || map.explicacao;
  if (question?.trim()) {
    body += `\n\nPedido específico do aluno:\n"${question.trim()}"`;
  }
  return body;
}

function buildUserPrompt(
  bundle: PromptBundle,
  sessionType: SessionType,
  question?: string
): string {
  const s = bundle.student as Record<string, string>;
  const c = bundle.curriculum as Record<string, string> | null;
  const u = bundle.unit as Record<string, string> | null;
  const t = bundle.topic as Record<string, string> | null;

  const studentLine = `Aluno: ${s.nickname ?? s.full_name}, ${s.education_level ?? "ensino básico"}${c ? ", " + c.title : ""}${s.institution ? ", " + s.institution : ""}.`;

  // Camada A, currículo
  const layerA: string[] = [];
  if (c) layerA.push(`Curso: ${c.title}`);
  if (u) layerA.push(`Unidade curricular: ${u.title}`);
  if (t) {
    layerA.push(`Tópico: ${t.title}`);
    if (t.description) layerA.push(`Descrição: ${t.description}`);
    if (t.learning_objectives) layerA.push(`Objetivos: ${t.learning_objectives}`);
  }

  // Camada C, histórico
  const layerC: string[] = [];
  if (bundle.recent_sessions.length > 0) {
    const rows = bundle.recent_sessions.slice(0, 5).map((rs) => {
      const dt = rs.created_at
        ? new Date(rs.created_at as string).toLocaleDateString("pt-PT")
        : "??";
      const perf = rs.performance_snapshot as Record<string, unknown> | null;
      const score = perf?.score ? ` (nota: ${perf.score}/5)` : "";
      return `- ${dt} [${rs.session_type}]${score}`;
    });
    layerC.push(`Sessões recentes:\n${rows.join("\n")}`);
  }

  return (
    studentLine +
    section("CAMADA A, currículo oficial", layerA.join("\n")) +
    section("CAMADA C, histórico recente do aluno", layerC.join("\n\n")) +
    section("TAREFA", taskInstructions(sessionType, question))
  );
}

// ── rate limiting & cost protection ─────────────────────────────────
const RATE_LIMITS = {
  MAX_SESSIONS_PER_STUDENT_PER_HOUR: 20,
  MAX_MESSAGES_PER_SESSION: 30,
  MAX_DAILY_COST_USD: 5.0,
} as const;

async function checkRateLimits(
  supabase: SupabaseAny,
  studentId: string,
  sessionId?: string,
): Promise<string | null> {
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const todayStart = new Date();
  todayStart.setUTCHours(0, 0, 0, 0);
  const todayIso = todayStart.toISOString();

  // 1. Sessões por aluno na última hora
  const { count: sessionCount } = await supabase
    .from("tutor_sessions")
    .select("id", { count: "exact", head: true })
    .eq("student_id", studentId)
    .gte("created_at", oneHourAgo) as { count: number | null };

  if ((sessionCount ?? 0) >= RATE_LIMITS.MAX_SESSIONS_PER_STUDENT_PER_HOUR) {
    return `Limite atingido: máximo de ${RATE_LIMITS.MAX_SESSIONS_PER_STUDENT_PER_HOUR} sessões por hora. Aguarda um pouco antes de continuar.`;
  }

  // 2. Mensagens por sessão (multi-turn)
  if (sessionId) {
    const { count: msgCount } = await supabase
      .from("session_messages")
      .select("id", { count: "exact", head: true })
      .eq("session_id", sessionId) as { count: number | null };

    if ((msgCount ?? 0) >= RATE_LIMITS.MAX_MESSAGES_PER_SESSION) {
      return `Esta sessão atingiu o limite de ${RATE_LIMITS.MAX_MESSAGES_PER_SESSION} mensagens. Inicia uma nova sessão para continuar.`;
    }
  }

  // 3. Custo diário global
  const { data: costData } = await supabase
    .from("tutor_sessions")
    .select("cost_usd")
    .gte("created_at", todayIso) as { data: { cost_usd: number }[] | null };

  const dailyCost = (costData ?? []).reduce(
    (sum: number, r: { cost_usd: number }) => sum + (Number(r.cost_usd) || 0),
    0,
  );

  if (dailyCost >= RATE_LIMITS.MAX_DAILY_COST_USD) {
    return `Limite de custo diário atingido ($${RATE_LIMITS.MAX_DAILY_COST_USD.toFixed(2)}). Contacta o administrador para aumentar o limite.`;
  }

  return null; // sem limite atingido
}

// ── handler ──────────────────────────────────────────────────────────
export async function POST(req: NextRequest) {
  const ANTHROPIC_KEY = process.env.ANTHROPIC_API_KEY;
  if (!ANTHROPIC_KEY) {
    return NextResponse.json(
      { error: "ANTHROPIC_API_KEY não configurada" },
      { status: 503 }
    );
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false, autoRefreshToken: false } }
  );

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "JSON inválido" }, { status: 400 });
  }

  const {
    student_id,
    curriculum_id,
    unit_id,
    topic_id,
    session_type,
    student_question,
    session_id,
  } = body as {
    student_id?: string;
    curriculum_id?: string;
    unit_id?: string;
    topic_id?: string;
    session_type?: string;
    student_question?: string;
    session_id?: string;
  };

  if (!student_id || !session_type) {
    return NextResponse.json(
      { error: "student_id e session_type são obrigatórios" },
      { status: 400 }
    );
  }

  // Rate limiting e proteção de custos
  const rateLimitError = await checkRateLimits(supabase as SupabaseAny, student_id, session_id);
  if (rateLimitError) {
    return NextResponse.json(
      { error: rateLimitError },
      { status: 429 }
    );
  }

  try {
    // Carregar aluno
    const { data: student, error: e1 } = await supabase
      .from("students")
      .select("*")
      .eq("id", student_id)
      .single();
    if (e1 || !student) throw new Error("Aluno não encontrado");

    // Carregar currículo (se fornecido ou via enrollment)
    let curriculum = null;
    if (curriculum_id) {
      const { data } = await supabase
        .from("curricula")
        .select("*")
        .eq("id", curriculum_id)
        .single();
      curriculum = data;
    } else {
      const { data: enr } = await supabase
        .from("student_enrollments")
        .select("curriculum_id")
        .eq("student_id", student_id)
        .eq("active", true)
        .order("start_date", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (enr?.curriculum_id) {
        const { data } = await supabase
          .from("curricula")
          .select("*")
          .eq("id", enr.curriculum_id)
          .single();
        curriculum = data;
      }
    }

    // Unidade e tópico
    let unit = null;
    if (unit_id) {
      const { data } = await supabase
        .from("curriculum_units")
        .select("*")
        .eq("id", unit_id)
        .single();
      unit = data;
    }
    let topic = null;
    if (topic_id) {
      const { data } = await supabase
        .from("curriculum_topics")
        .select("*")
        .eq("id", topic_id)
        .single();
      topic = data;
    }

    // Sessões recentes
    let recentQ = supabase
      .from("tutor_sessions")
      .select("id, session_type, performance_snapshot, created_at")
      .eq("student_id", student_id)
      .order("created_at", { ascending: false })
      .limit(5);
    if (unit_id) recentQ = recentQ.eq("unit_id", unit_id);
    const { data: recent_sessions } = await recentQ;

    // Histórico multi-turn
    let previousMessages: { role: string; content: string }[] = [];
    if (session_id) {
      const { data: msgs } = await supabase
        .from("session_messages")
        .select("role, content")
        .eq("session_id", session_id)
        .order("created_at", { ascending: true });
      if (msgs) previousMessages = msgs;
    }

    const bundle: PromptBundle = {
      student,
      curriculum,
      unit,
      topic,
      recent_sessions: recent_sessions ?? [],
      open_doubts: [],
    };

    const userPrompt = buildUserPrompt(
      bundle,
      session_type as SessionType,
      student_question
    );

    // Construir mensagens para Claude
    const messages: { role: string; content: string }[] = [
      ...previousMessages,
      { role: "user", content: userPrompt },
    ];

    // Chamar Claude
    const MODEL = "claude-sonnet-4-5-20250929";
    const MAX_TOKENS = 4096;

    const claudeResp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: MAX_TOKENS,
        system: SYSTEM,
        messages,
      }),
    });

    if (!claudeResp.ok) {
      const errText = await claudeResp.text();
      throw new Error(`Claude API ${claudeResp.status}: ${errText}`);
    }

    const claudeData = await claudeResp.json();
    const fullText = (claudeData.content ?? [])
      .map((c: { type: string; text?: string }) =>
        c.type === "text" ? c.text : ""
      )
      .join("")
      .trim();

    const inputTokens = claudeData.usage?.input_tokens ?? null;
    const outputTokens = claudeData.usage?.output_tokens ?? null;

    // Extrair scoring
    let visibleResponse = fullText;
    let performanceSnapshot: Record<string, unknown> | null = null;

    const scoringIdx = fullText.indexOf("---SCORING---");
    if (scoringIdx !== -1) {
      visibleResponse = fullText.slice(0, scoringIdx).trim();
      const jsonPart = fullText.slice(scoringIdx + "---SCORING---".length).trim();
      try {
        performanceSnapshot = JSON.parse(jsonPart);
      } catch {
        const m = jsonPart.match(/"score"\s*:\s*(\d)/);
        if (m) performanceSnapshot = { score: parseInt(m[1], 10) };
      }
    }

    // Estimar custo
    const costUsd =
      inputTokens != null && outputTokens != null
        ? (inputTokens * 3 + outputTokens * 15) / 1_000_000
        : null;

    // Gravar sessão ou mensagem multi-turn
    let tutorSessionId = session_id;

    if (!session_id) {
      // Nova sessão
      const { data: inserted, error: insErr } = await supabase
        .from("tutor_sessions")
        .insert([
          {
            student_id,
            unit_id: unit_id || null,
            topic_id: topic_id || null,
            session_type,
            model: MODEL,
            prompt_template: `eaia.${session_type}.v1`,
            prompt_rendered: userPrompt,
            response: visibleResponse,
            input_tokens: inputTokens,
            output_tokens: outputTokens,
            cost_usd: costUsd,
            performance_snapshot: performanceSnapshot,
          },
        ])
        .select("id")
        .single();

      if (insErr) throw new Error("Erro ao gravar sessão: " + insErr.message);
      tutorSessionId = inserted?.id;

      // Gravar mensagens iniciais
      await supabase.from("session_messages").insert([
        {
          session_id: tutorSessionId,
          role: "user",
          content: userPrompt,
          input_tokens: inputTokens,
          output_tokens: 0,
          cost_usd: 0,
        },
        {
          session_id: tutorSessionId,
          role: "assistant",
          content: visibleResponse,
          input_tokens: 0,
          output_tokens: outputTokens,
          cost_usd: costUsd,
        },
      ]);
    } else {
      // Multi-turn, adicionar mensagens
      await supabase.from("session_messages").insert([
        {
          session_id,
          role: "user",
          content: student_question || userPrompt,
          input_tokens: inputTokens,
          output_tokens: 0,
          cost_usd: 0,
        },
        {
          session_id,
          role: "assistant",
          content: visibleResponse,
          input_tokens: 0,
          output_tokens: outputTokens,
          cost_usd: costUsd,
        },
      ]);
    }

    // Atualizar mestria BKT (fire-and-forget, não bloqueia a resposta)
    updateMastery(supabase as SupabaseAny, student_id, topic_id, performanceSnapshot).catch(
      (err) => console.error("[BKT] Erro ao atualizar mestria:", err),
    );

    return NextResponse.json({
      session_id: tutorSessionId,
      response: visibleResponse,
      tokens: { input: inputTokens, output: outputTokens },
      cost_usd: costUsd,
      performance_snapshot: performanceSnapshot,
    });
  } catch (e) {
    return NextResponse.json(
      { error: (e as Error).message },
      { status: 500 }
    );
  }
}
