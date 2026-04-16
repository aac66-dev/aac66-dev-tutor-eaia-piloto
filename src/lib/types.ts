/**
 * Tipos do domínio Tutor EAIA, âmbito canónico Opção 2.
 * Espelham o schema Supabase após a migration 20260416_scope_multidisciplina.
 */

export type EducationLevel =
  | 'ensino_basico'
  | 'secundario'
  | 'ensino_superior_politecnico'
  | 'cteSP';

export type DisciplineCode = 'PT' | 'MAT' | 'CN' | 'FQ';

export interface Student {
  id: string;
  full_name: string;
  nickname: string | null;
  education_level: EducationLevel;
  institution: string | null;
  current_period: string | null;
  gender: string | null;
  preferred_language: string | null;
  notes: string | null;
}

export interface Curriculum {
  id: string;
  slug: string;
  title: string;
  education_level: EducationLevel;
  discipline: string | null;
  discipline_code: DisciplineCode | null;
  school_year: string | null;
  display_order: number | null;
  pedagogical_domain: string | null;
  source_url: string | null;
  version: string | null;
}

export interface CurriculumUnit {
  id: string;
  curriculum_id: string;
  code: string | null;
  title: string;
  period: string | null;
  order_index: number;
}

export interface CurriculumTopic {
  id: string;
  unit_id: string;
  code: string | null;
  title: string;
  description: string | null;
  order_index: number;
}

export interface StudentMastery {
  student_id: string;
  concept_id: string;
  p_mastery: number;
  attempts: number;
  correct_attempts: number;
  last_attempted_at: string | null;
}

export interface CurriculumMasterySummary {
  curriculum: Curriculum;
  avg_mastery: number;
  attempts_total: number;
  ae_count: number;
}

export type MasteryBand = 'inicial' | 'emprogresso' | 'dominado';

export function masteryBand(p: number): MasteryBand {
  if (p < 0.4) return 'inicial';
  if (p < 0.7) return 'emprogresso';
  return 'dominado';
}

export function masteryColor(p: number): string {
  if (p < 0.4) return 'bg-rose-500';
  if (p < 0.7) return 'bg-amber-500';
  return 'bg-emerald-500';
}

export function masteryBandLabel(p: number): string {
  if (p < 0.4) return 'Inicial';
  if (p < 0.7) return 'Em progresso';
  return 'Dominado';
}
