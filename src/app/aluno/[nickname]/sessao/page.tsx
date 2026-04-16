"use client";

import { useEffect, useState, useRef } from "react";
import { useParams, useRouter } from "next/navigation";

// ── tipos locais ─────────────────────────────────────────────────────
interface StudentBasic {
  id: string;
  nickname: string;
  full_name: string;
  education_level: string;
}
interface CurriculumBasic {
  id: string;
  slug: string;
  title: string;
}
interface UnitBasic {
  id: string;
  title: string;
}
interface TopicBasic {
  id: string;
  title: string;
  code: string;
}
interface UnitWithTopics {
  unit: UnitBasic;
  topics: TopicBasic[];
}
interface Message {
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
}

const SESSION_TYPES = [
  { key: "explicacao", label: "Explicação", icon: "📖", desc: "Explicação clara do tópico, do simples ao complexo" },
  { key: "revisao", label: "Revisão", icon: "🔄", desc: "Resumo dos pontos-chave para avaliação" },
  { key: "quiz", label: "Quiz", icon: "❓", desc: "5 perguntas de escolha múltipla com respostas" },
  { key: "exame", label: "Exame", icon: "📝", desc: "Simulação de pergunta de exame com feedback" },
  { key: "resumo", label: "Resumo", icon: "📋", desc: "Resumo estruturado e conciso do tópico" },
] as const;

// ── componente ───────────────────────────────────────────────────────
export default function SessaoPage() {
  const params = useParams();
  const router = useRouter();
  const nickname = params.nickname as string;

  // estado
  const [student, setStudent] = useState<StudentBasic | null>(null);
  const [curricula, setCurricula] = useState<CurriculumBasic[]>([]);
  const [selectedCurriculum, setSelectedCurriculum] = useState<string>("");
  const [unitsTopics, setUnitsTopics] = useState<UnitWithTopics[]>([]);
  const [selectedUnit, setSelectedUnit] = useState<string>("");
  const [selectedTopic, setSelectedTopic] = useState<string>("");
  const [sessionType, setSessionType] = useState<string>("explicacao");
  const [userQuestion, setUserQuestion] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pageLoading, setPageLoading] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // carregar aluno e currículos
  useEffect(() => {
    async function load() {
      try {
        const [sRes, cRes] = await Promise.all([
          fetch(`/api/student?nickname=${nickname}`),
          fetch(`/api/curricula`),
        ]);
        if (sRes.ok) setStudent(await sRes.json());
        if (cRes.ok) setCurricula(await cRes.json());
      } catch (e) {
        setError("Erro ao carregar dados: " + (e as Error).message);
      } finally {
        setPageLoading(false);
      }
    }
    load();
  }, [nickname]);

  // carregar unidades/tópicos quando seleciona currículo
  useEffect(() => {
    if (!selectedCurriculum) {
      setUnitsTopics([]);
      setSelectedUnit("");
      setSelectedTopic("");
      return;
    }
    fetch(`/api/curricula/${selectedCurriculum}/units`)
      .then((r) => r.json())
      .then((data) => setUnitsTopics(data))
      .catch(() => setUnitsTopics([]));
  }, [selectedCurriculum]);

  // scroll automático para última mensagem
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // enviar mensagem ao tutor
  async function sendMessage() {
    if (!student) return;
    const question = userQuestion.trim();

    // Adicionar mensagem do utilizador ao chat
    const userMsg: Message = {
      role: "user",
      content:
        question ||
        `[Pedido de ${SESSION_TYPES.find((t) => t.key === sessionType)?.label ?? sessionType}]`,
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, userMsg]);
    setUserQuestion("");
    setLoading(true);
    setError(null);

    try {
      const body: Record<string, unknown> = {
        student_id: student.id,
        session_type: sessionType,
      };
      if (selectedCurriculum) body.curriculum_id = selectedCurriculum;
      if (selectedUnit) body.unit_id = selectedUnit;
      if (selectedTopic) body.topic_id = selectedTopic;
      if (question) body.student_question = question;
      if (sessionId) body.session_id = sessionId;

      const resp = await fetch("/api/tutor", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      const data = await resp.json();
      if (!resp.ok) throw new Error(data.error || "Erro do tutor");

      if (data.session_id) setSessionId(data.session_id);

      const assistantMsg: Message = {
        role: "assistant",
        content: data.response,
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, assistantMsg]);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }

  // nova sessão
  function resetSession() {
    setMessages([]);
    setSessionId(null);
    setError(null);
    setUserQuestion("");
  }

  if (pageLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-muted-foreground">A carregar...</p>
      </div>
    );
  }

  if (!student) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <p className="text-destructive">Aluno &quot;{nickname}&quot; não encontrado.</p>
      </div>
    );
  }

  const availableTopics = unitsTopics.find((ut) => ut.unit.id === selectedUnit)?.topics ?? [];

  return (
    <div className="min-h-screen flex flex-col bg-background">
      {/* Header */}
      <header className="border-b border-border bg-card">
        <div className="container flex items-center justify-between h-14">
          <div className="flex items-center gap-3">
            <a href={`/aluno/${nickname}`} className="text-primary hover:underline text-sm">
              ← Dashboard
            </a>
            <span className="text-muted-foreground">/</span>
            <span className="font-semibold">{student.full_name}</span>
            <span className="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded">
              Sessão de tutoria
            </span>
          </div>
          {sessionId && (
            <button
              onClick={resetSession}
              className="text-sm text-muted-foreground hover:text-primary border border-border rounded px-3 py-1"
            >
              Nova sessão
            </button>
          )}
        </div>
      </header>

      <div className="flex-1 container flex gap-4 py-4" style={{ maxHeight: "calc(100vh - 56px)" }}>
        {/* Sidebar, configuração da sessão */}
        <aside className="w-72 shrink-0 space-y-4 overflow-y-auto">
          {/* Tipo de sessão */}
          <div>
            <label className="block text-xs font-medium text-muted-foreground mb-2">
              Tipo de sessão
            </label>
            <div className="space-y-1">
              {SESSION_TYPES.map((t) => (
                <button
                  key={t.key}
                  onClick={() => setSessionType(t.key)}
                  className={`w-full text-left px-3 py-2 rounded text-sm transition-colors ${
                    sessionType === t.key
                      ? "bg-primary text-primary-foreground"
                      : "hover:bg-accent"
                  }`}
                  title={t.desc}
                >
                  <span className="mr-2">{t.icon}</span>
                  {t.label}
                </button>
              ))}
            </div>
          </div>

          {/* Seletor de currículo */}
          <div>
            <label className="block text-xs font-medium text-muted-foreground mb-1">
              Currículo
            </label>
            <select
              value={selectedCurriculum}
              onChange={(e) => {
                setSelectedCurriculum(e.target.value);
                setSelectedUnit("");
                setSelectedTopic("");
              }}
              className="w-full border border-border rounded px-2 py-1.5 text-sm bg-background"
            >
              <option value="">Geral (sem currículo)</option>
              {curricula.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.title}
                </option>
              ))}
            </select>
          </div>

          {/* Seletor de unidade */}
          {unitsTopics.length > 0 && (
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">
                Unidade
              </label>
              <select
                value={selectedUnit}
                onChange={(e) => {
                  setSelectedUnit(e.target.value);
                  setSelectedTopic("");
                }}
                className="w-full border border-border rounded px-2 py-1.5 text-sm bg-background"
              >
                <option value="">Todas as unidades</option>
                {unitsTopics.map((ut) => (
                  <option key={ut.unit.id} value={ut.unit.id}>
                    {ut.unit.title}
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Seletor de tópico */}
          {availableTopics.length > 0 && (
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1">
                Tópico (AE)
              </label>
              <select
                value={selectedTopic}
                onChange={(e) => setSelectedTopic(e.target.value)}
                className="w-full border border-border rounded px-2 py-1.5 text-sm bg-background"
              >
                <option value="">Todos os tópicos</option>
                {availableTopics.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.code}: {t.title.slice(0, 60)}
                    {t.title.length > 60 ? "..." : ""}
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Info */}
          <div className="text-xs text-muted-foreground border border-border rounded p-2 space-y-1">
            <p>Perfil sintético para demonstração.</p>
            <p>As respostas são geradas por IA e devem ser validadas pelo professor.</p>
          </div>
        </aside>

        {/* Área de conversa */}
        <main className="flex-1 flex flex-col min-w-0 border border-border rounded-lg bg-card overflow-hidden">
          {/* Mensagens */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {messages.length === 0 && (
              <div className="h-full flex items-center justify-center text-center">
                <div className="space-y-3 max-w-md">
                  <p className="text-2xl">📚</p>
                  <p className="text-lg font-medium">Olá, {student.nickname ?? student.full_name}!</p>
                  <p className="text-sm text-muted-foreground">
                    Seleciona um tipo de sessão na barra lateral, escolhe opcionalmente um currículo e tópico, e escreve a tua dúvida ou clica em &quot;Enviar&quot; para começar.
                  </p>
                </div>
              </div>
            )}

            {messages.map((msg, i) => (
              <div
                key={i}
                className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
              >
                <div
                  className={`max-w-[80%] rounded-lg px-4 py-3 text-sm ${
                    msg.role === "user"
                      ? "bg-primary text-primary-foreground"
                      : "bg-accent"
                  }`}
                >
                  <div className="whitespace-pre-wrap">{msg.content}</div>
                  <div
                    className={`text-xs mt-1 ${
                      msg.role === "user"
                        ? "text-primary-foreground/60"
                        : "text-muted-foreground"
                    }`}
                  >
                    {msg.timestamp.toLocaleTimeString("pt-PT", {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </div>
                </div>
              </div>
            ))}

            {loading && (
              <div className="flex justify-start">
                <div className="bg-accent rounded-lg px-4 py-3 text-sm text-muted-foreground">
                  A pensar...
                </div>
              </div>
            )}

            {error && (
              <div className="flex justify-center">
                <div className="bg-destructive/10 text-destructive rounded-lg px-4 py-2 text-sm">
                  {error}
                </div>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Input */}
          <div className="border-t border-border p-3">
            <div className="flex gap-2">
              <input
                type="text"
                value={userQuestion}
                onChange={(e) => setUserQuestion(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey && !loading) {
                    e.preventDefault();
                    sendMessage();
                  }
                }}
                placeholder={
                  sessionId
                    ? "Continuar a conversa..."
                    : `Dúvida ou pedido (${SESSION_TYPES.find((t) => t.key === sessionType)?.label ?? ""})`
                }
                className="flex-1 border border-border rounded px-3 py-2 text-sm bg-background focus:outline-none focus:ring-1 focus:ring-primary"
                disabled={loading}
              />
              <button
                onClick={sendMessage}
                disabled={loading || !student}
                className="bg-primary text-primary-foreground px-4 py-2 rounded text-sm font-medium disabled:opacity-50 hover:bg-primary/90 transition-colors"
              >
                {loading ? "..." : "Enviar"}
              </button>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
