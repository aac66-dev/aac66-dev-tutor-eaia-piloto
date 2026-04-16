import { supabaseServer } from './supabase-server';
import type {
  Student,
  Curriculum,
  CurriculumUnit,
  CurriculumTopic,
  CurriculumMasterySummary,
} from './types';

/**
 * Lista os alunos activos no piloto, ordenados por perfil (Fraco, Médio, Forte).
 */
export async function listStudents(): Promise<Student[]> {
  const db = supabaseServer();
  const { data, error } = await db
    .from('students')
    .select(
      'id, full_name, nickname, education_level, institution, current_period, gender, preferred_language, notes',
    )
    .order('created_at');
  if (error) throw error;
  const order = { Maria: 1, Joao: 2, Sofia: 3 } as Record<string, number>;
  return (data ?? []).sort(
    (a, b) => (order[a.nickname ?? ''] ?? 99) - (order[b.nickname ?? ''] ?? 99),
  );
}

/**
 * Lista os 9 currículos do âmbito canónico ordenados por display_order.
 */
export async function listCurricula(): Promise<Curriculum[]> {
  const db = supabaseServer();
  const { data, error } = await db
    .from('curricula')
    .select(
      'id, slug, title, education_level, discipline, discipline_code, school_year, display_order, pedagogical_domain, source_url, version',
    )
    .order('display_order');
  if (error) throw error;
  return data ?? [];
}

/**
 * Busca um aluno pelo nickname (Maria, Joao, Sofia).
 */
export async function getStudentByNickname(
  nickname: string,
): Promise<Student | null> {
  const db = supabaseServer();
  const { data, error } = await db
    .from('students')
    .select('*')
    .eq('nickname', nickname)
    .maybeSingle();
  if (error) throw error;
  return data;
}

/**
 * Mestria média por currículo para um aluno dado.
 * Usa o prefixo do código dkm_concepts (discipline_code-school_year-...) para ligar aos currículos.
 */
export async function masteryByCurriculum(
  studentId: string,
): Promise<Map<string, { avg: number; attempts: number; ae: number }>> {
  const db = supabaseServer();
  // Agrupar do lado do cliente: obtemos conceitos + mestria e juntamos pelo prefixo do código.
  const [curRes, conceptRes, masteryRes] = await Promise.all([
    db
      .from('curricula')
      .select('slug, discipline_code, school_year, id'),
    db.from('dkm_concepts').select('id, code'),
    db
      .from('student_mastery')
      .select('concept_id, p_mastery, attempts')
      .eq('student_id', studentId),
  ]);
  if (curRes.error) throw curRes.error;
  if (conceptRes.error) throw conceptRes.error;
  if (masteryRes.error) throw masteryRes.error;

  // Mapear concept_id -> slug
  const slugByConcept = new Map<string, string>();
  const slugFromCode = (code: string): string | null => {
    const parts = code.split('-');
    if (parts.length < 2) return null;
    const [disc, year] = parts;
    const match = (curRes.data ?? []).find(
      (c) =>
        (c.discipline_code ?? '') === disc && (c.school_year ?? '') === year,
    );
    return match?.slug ?? null;
  };
  for (const c of conceptRes.data ?? []) {
    const slug = slugFromCode(c.code);
    if (slug) slugByConcept.set(c.id, slug);
  }

  const agg = new Map<
    string,
    { sum: number; attempts: number; ae: number }
  >();
  for (const m of masteryRes.data ?? []) {
    const slug = slugByConcept.get(m.concept_id);
    if (!slug) continue;
    const prev = agg.get(slug) ?? { sum: 0, attempts: 0, ae: 0 };
    prev.sum += Number(m.p_mastery);
    prev.attempts += m.attempts;
    prev.ae += 1;
    agg.set(slug, prev);
  }

  const out = new Map<string, { avg: number; attempts: number; ae: number }>();
  for (const [slug, v] of agg.entries()) {
    out.set(slug, {
      avg: v.ae > 0 ? v.sum / v.ae : 0,
      attempts: v.attempts,
      ae: v.ae,
    });
  }
  return out;
}

/**
 * Mestria detalhada por (unit, topic) para um aluno num currículo específico.
 */
export async function masteryForCurriculum(
  studentId: string,
  curriculumSlug: string,
): Promise<{
  curriculum: Curriculum;
  units: Array<{
    unit: CurriculumUnit;
    avg: number;
    topics: Array<{ topic: CurriculumTopic; p_mastery: number; attempts: number }>;
  }>;
}> {
  const db = supabaseServer();

  const { data: cur, error: curErr } = await db
    .from('curricula')
    .select('*')
    .eq('slug', curriculumSlug)
    .single();
  if (curErr) throw curErr;

  const { data: units, error: unitsErr } = await db
    .from('curriculum_units')
    .select('*')
    .eq('curriculum_id', cur.id)
    .order('order_index');
  if (unitsErr) throw unitsErr;

  const unitIds = (units ?? []).map((u) => u.id);
  const { data: topics, error: topicsErr } = await db
    .from('curriculum_topics')
    .select('*')
    .in('unit_id', unitIds.length ? unitIds : ['00000000-0000-0000-0000-000000000000'])
    .order('order_index');
  if (topicsErr) throw topicsErr;

  // Map AE code → concept id (via dkm_concepts código prefixado)
  const { data: concepts, error: conceptsErr } = await db
    .from('dkm_concepts')
    .select('id, code')
    .ilike('code', `${cur.discipline_code}-${cur.school_year}-%`);
  if (conceptsErr) throw conceptsErr;

  const conceptIdByTopicCode = new Map<string, string>();
  for (const c of concepts ?? []) {
    const parts = c.code.split('-');
    const aeCode = parts.slice(2).join('-');
    conceptIdByTopicCode.set(aeCode, c.id);
  }

  const conceptIds = Array.from(conceptIdByTopicCode.values());
  const { data: mastery, error: mastErr } = await db
    .from('student_mastery')
    .select('concept_id, p_mastery, attempts')
    .eq('student_id', studentId)
    .in('concept_id', conceptIds.length ? conceptIds : ['00000000-0000-0000-0000-000000000000']);
  if (mastErr) throw mastErr;

  const masteryByConcept = new Map<
    string,
    { p_mastery: number; attempts: number }
  >();
  for (const m of mastery ?? []) {
    masteryByConcept.set(m.concept_id, {
      p_mastery: Number(m.p_mastery),
      attempts: m.attempts,
    });
  }

  const unitsOut = (units ?? []).map((u) => {
    const unitTopics = (topics ?? []).filter((t) => t.unit_id === u.id);
    const topicsOut = unitTopics.map((t) => {
      const cid = conceptIdByTopicCode.get(t.code ?? '');
      const m = cid ? masteryByConcept.get(cid) : undefined;
      return {
        topic: t,
        p_mastery: m?.p_mastery ?? 0,
        attempts: m?.attempts ?? 0,
      };
    });
    const avg =
      topicsOut.length > 0
        ? topicsOut.reduce((s, x) => s + x.p_mastery, 0) / topicsOut.length
        : 0;
    return { unit: u, avg, topics: topicsOut };
  });

  return { curriculum: cur, units: unitsOut };
}

/**
 * Lista unidades e tópicos de um currículo, para seletor na área do aluno.
 */
export async function unitsAndTopics(
  curriculumId: string,
): Promise<
  Array<{
    unit: CurriculumUnit;
    topics: CurriculumTopic[];
  }>
> {
  const db = supabaseServer();
  const { data: units, error: uErr } = await db
    .from('curriculum_units')
    .select('*')
    .eq('curriculum_id', curriculumId)
    .order('order_index');
  if (uErr) throw uErr;

  const unitIds = (units ?? []).map((u) => u.id);
  if (unitIds.length === 0) return [];

  const { data: topics, error: tErr } = await db
    .from('curriculum_topics')
    .select('*')
    .in('unit_id', unitIds)
    .order('order_index');
  if (tErr) throw tErr;

  return (units ?? []).map((u) => ({
    unit: u,
    topics: (topics ?? []).filter((t) => t.unit_id === u.id),
  }));
}

/**
 * Mestria global agregada por aluno (média de todas as AE).
 */
export async function studentOverallMastery(
  studentId: string,
): Promise<{ avg: number; attempts: number; ae: number }> {
  const db = supabaseServer();
  const { data, error } = await db
    .from('student_mastery')
    .select('p_mastery, attempts')
    .eq('student_id', studentId);
  if (error) throw error;
  const ae = (data ?? []).length;
  if (ae === 0) return { avg: 0, attempts: 0, ae: 0 };
  const sum = (data ?? []).reduce((s, r) => s + Number(r.p_mastery), 0);
  const att = (data ?? []).reduce((s, r) => s + r.attempts, 0);
  return { avg: sum / ae, attempts: att, ae };
}
