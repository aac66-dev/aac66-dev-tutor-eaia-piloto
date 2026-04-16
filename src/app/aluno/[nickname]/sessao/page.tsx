"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

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
  const [sidebarOpen, setSidebarOpen] = useState(false);
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

  // fechar sidebar ao clicar fora (mobile)
  const closeSidebar = useCallback(() => setSidebarOpen(false), []);

  // enviar mensagem ao tutor
  async function sendMessage() {
    if (!student) return;
    const question = userQuestion.trim();

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
    // Fechar sidebar em mobile ao enviar
    setSidebarOpen(false);

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
  const currentTypeLabel = SESSION_TYPES.find((t) => t.key === sessionType)?.label ?? sessionType;
  const currentTypeIcon = SESSION_TYPES.find((t) => t.key === sessionType)?.icon ?? "📖";

  // ── Sidebar content (reutilizado em desktop e drawer mobile) ───────
  const sidebarContent = (
    <div className="space-y-4">
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
    </div>
  );

  return (
    <div className="min-h-screen flex flex-col bg-background">
      {/* Header */}
      <header className="border-b border-border bg-card">
        <div className="container flex items-center justify-between h-14 px-3 sm:px-4">
          <div className="flex items-center gap-2 sm:gap-3 min-w-0">
            {/* Hamburger (mobile only) */}
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="lg:hidden shrink-0 p-1.5 rounded hover:bg-accent transition-colors"
              aria-label="Abrir configurações da sessão"
            >
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <line x1="3" y1="5" x2="17" y2="5" />
                <line x1="3" y1="10" x2="17" y2="10" />
                <line x1="3" y1="15" x2="17" y2="15" />
              </svg>
            </button>
            <a href={`/aluno/${nickname}`} className="text-primary hover:underline text-sm shrink-0">
              ← <span className="hidden sm:inline">Dashboard</span>
            </a>
            <span className="text-muted-foreground hidden sm:inline">/</span>
            <span className="font-semibold truncate">{student.full_name}</span>
            <span className="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded shrink-0 hidden sm:inline">
              Sessão de tutoria
            </span>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            {/* Badge do tipo de sessão (mobile, mostra o que está selecionado) */}
            <span className="lg:hidden text-xs bg-accent px-2 py-1 rounded">
              {currentTypeIcon} {currentTypeLabel}
            </span>
            {sessionId && (
              <button
                onClick={resetSession}
                className="text-sm text-muted-foreground hover:text-primary border border-border rounded px-3 py-1"
              >
                <span className="hidden sm:inline">Nova sessão</span>
                <span className="sm:hidden">Nova</span>
              </button>
            )}
          </div>
        </div>
      </header>

      <div className="flex-1 flex overflow-hidden" style={{ maxHeight: "calc(100vh - 56px)" }}>
        {/* Overlay backdrop (mobile) */}
        {sidebarOpen && (
          <div
            className="fixed inset-0 bg-black/40 z-30 lg:hidden"
            onClick={closeSidebar}
            aria-hidden
          />
        )}

        {/* Sidebar: drawer em mobile, fixo em desktop */}
        <aside
          className={`
            fixed top-14 left-0 bottom-0 z-40 w-72 bg-card border-r border-border
            overflow-y-auto p-4 transition-transform duration-200 ease-in-out
            lg:static lg:translate-x-0 lg:z-auto lg:shrink-0
            ${sidebarOpen ? "translate-x-0" : "-translate-x-full"}
          `}
        >
          {/* Botão fechar no drawer (mobile) */}
          <div className="flex items-center justify-between mb-3 lg:hidden">
            <span className="text-sm font-medium text-muted-foreground">Configurações</span>
            <button
              onClick={closeSidebar}
              className="p-1 rounded hover:bg-accent"
              aria-label="Fechar"
            >
              <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <line x1="4" y1="4" x2="14" y2="14" />
                <line x1="14" y1="4" x2="4" y2="14" />
              </svg>
            </button>
          </div>
          {sidebarContent}
        </aside>

        {/* Área de conversa */}
        <main className="flex-1 flex flex-col min-w-0 border-x border-border lg:border-l-0 bg-card overflow-hidden">
          {/* Mensagens */}
          <div className="flex-1 overflow-y-auto p-3 sm:p-4 space-y-3 sm:space-y-4">
            {messages.length === 0 && (
              <div className="h-full flex items-center justify-center text-center px-4">
                <div className="space-y-3 max-w-md">
                  <p className="text-2xl">📚</p>
                  <p className="text-lg font-medium">Olá, {student.nickname ?? student.full_name}!</p>
                  <p className="text-sm text-muted-foreground">
                    {/* Mobile: instrução simplificada */}
                    <span className="lg:hidden">
                      Toca no <strong>menu</strong> para configurar a sessão, depois escreve a tua dúvida.
                    </span>
                    {/* Desktop: instrução completa */}
                    <span className="hidden lg:inline">
                      Seleciona um tipo de sessão na barra lateral, escolhe opcionalmente um currículo e tópico, e escreve a tua dúvida ou clica em &quot;Enviar&quot; para começar.
                    </span>
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
                  className={`rounded-lg px-3 py-2 sm:px-4 sm:py-3 text-sm ${
                    msg.role === "user"
                      ? "bg-primary text-primary-foreground max-w-[85%] sm:max-w-[75%]"
                      : "bg-accent max-w-[90%] sm:max-w-[80%]"
                  }`}
                >
                  {msg.role === "user" ? (
                    <div className="whitespace-pre-wrap">{msg.content}</div>
                  ) : (
                    <div className="prose prose-sm max-w-none dark:prose-invert prose-headings:text-base prose-headings:font-semibold prose-headings:mt-3 prose-headings:mb-1 prose-p:my-1.5 prose-ul:my-1.5 prose-ol:my-1.5 prose-li:my-0.5 prose-code:bg-background/50 prose-code:px-1 prose-code:rounded prose-pre:bg-background/50 prose-pre:rounded-md">
                      <ReactMarkdown remarkPlugins={[remarkGfm]}>
                        {msg.content}
                      </ReactMarkdown>
                    </div>
                  )}
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
                <div className="bg-accent rounded-lg px-4 py-3 text-sm text-muted-foreground animate-pulse">
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
          <div className="border-t border-border p-2 sm:p-3">
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
                    : `Dúvida ou pedido (${currentTypeLabel})`
                }
                className="flex-1 border border-border rounded px-3 py-2 text-sm bg-background focus:outline-none focus:ring-1 focus:ring-primary"
                disabled={loading}
              />
              <button
                onClick={sendMessage}
                disabled={loading || !student}
                className="bg-primary text-primary-foreground px-3 sm:px-4 py-2 rounded text-sm font-medium disabled:opacity-50 hover:bg-primary/90 transition-colors shrink-0"
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
