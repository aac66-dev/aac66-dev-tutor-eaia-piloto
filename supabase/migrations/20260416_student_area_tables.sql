-- Tutor EAIA Student Area Tables Migration
-- Created: 2026-04-16

-- 1. student_notes table
CREATE TABLE IF NOT EXISTS student_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id),
    unit_id UUID REFERENCES curriculum_units(id),
    topic_id UUID REFERENCES curriculum_topics(id),
    note_type TEXT NOT NULL CHECK (note_type IN ('doubt','note','bookmark')) DEFAULT 'note',
    title TEXT,
    content TEXT,
    resolved BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. student_documents table
CREATE TABLE IF NOT EXISTS student_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id),
    unit_id UUID REFERENCES curriculum_units(id),
    topic_id UUID REFERENCES curriculum_topics(id),
    file_name TEXT NOT NULL,
    doc_type TEXT DEFAULT 'documento',
    file_url TEXT,
    extracted_text TEXT,
    processing_status TEXT DEFAULT 'pending' CHECK (processing_status IN ('pending','processing','done','error')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. teacher_profiles table
CREATE TABLE IF NOT EXISTS teacher_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id),
    unit_id UUID NOT NULL REFERENCES curriculum_units(id),
    teacher_name TEXT,
    teaching_style TEXT,
    exam_style TEXT,
    grading_criteria TEXT,
    preferred_bibliography TEXT,
    common_questions TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(student_id, unit_id)
);

-- 4. teacher_profile_docs table
CREATE TABLE IF NOT EXISTS teacher_profile_docs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_profile_id UUID NOT NULL REFERENCES teacher_profiles(id) ON DELETE CASCADE,
    title TEXT,
    file_name TEXT,
    doc_type TEXT DEFAULT 'documento',
    file_url TEXT,
    extracted_text TEXT,
    processing_status TEXT DEFAULT 'pending' CHECK (processing_status IN ('pending','processing','done','error')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. curriculum_official_docs table
CREATE TABLE IF NOT EXISTS curriculum_official_docs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id UUID NOT NULL REFERENCES curriculum_units(id),
    title TEXT NOT NULL,
    doc_type TEXT DEFAULT 'documento',
    file_url TEXT,
    extracted_text TEXT,
    processing_status TEXT DEFAULT 'pending' CHECK (processing_status IN ('pending','processing','done','error')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE student_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_profile_docs ENABLE ROW LEVEL SECURITY;
ALTER TABLE curriculum_official_docs ENABLE ROW LEVEL SECURITY;
