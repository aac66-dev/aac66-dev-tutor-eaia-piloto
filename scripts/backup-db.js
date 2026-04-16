#!/usr/bin/env node

/**
 * Script de backup da base de dados Supabase do AEP.
 *
 * Exporta todas as tabelas principais para um ficheiro JSON com timestamp.
 * Uso: node scripts/backup-db.js
 *
 * Requer as variáveis de ambiente:
 *   NEXT_PUBLIC_SUPABASE_URL
 *   SUPABASE_SERVICE_ROLE_KEY
 *
 * Opcionalmente aceita --output=<pasta> para definir destino (default: ./backups/).
 */

const fs = require('fs');
const path = require('path');

// Tabelas a exportar (ordem respeitando dependências)
const TABLES = [
  'curricula',
  'curriculum_units',
  'curriculum_topics',
  'students',
  'student_enrollments',
  'supervisors',
  'supervisor_students',
  'tutor_sessions',
  'student_notes',
  'student_documents',
  'teacher_profiles',
  'teacher_profile_docs',
  'curriculum_official_docs',
  'assessments',
];

async function main() {
  // Carregar .env.local se disponível
  try {
    const envPath = path.resolve(__dirname, '..', '.env.local');
    if (fs.existsSync(envPath)) {
      const envContent = fs.readFileSync(envPath, 'utf-8');
      for (const line of envContent.split('\n')) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#')) continue;
        const eqIdx = trimmed.indexOf('=');
        if (eqIdx < 0) continue;
        const key = trimmed.slice(0, eqIdx).trim();
        const value = trimmed.slice(eqIdx + 1).trim();
        if (!process.env[key]) {
          process.env[key] = value;
        }
      }
    }
  } catch {
    // Ignorar erros de leitura de .env
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !serviceKey) {
    console.error('Erro: NEXT_PUBLIC_SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios.');
    console.error('Defina-os em .env.local ou como variáveis de ambiente.');
    process.exit(1);
  }

  // Pasta de destino
  const outputArg = process.argv.find((a) => a.startsWith('--output='));
  const outputDir = outputArg
    ? path.resolve(outputArg.split('=')[1])
    : path.resolve(__dirname, '..', 'backups');

  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const backupData = {
    meta: {
      created_at: new Date().toISOString(),
      supabase_url: supabaseUrl,
      tables: TABLES,
    },
    data: {},
  };

  let totalRows = 0;
  let errors = 0;

  console.log(`\nAEP Backup — ${new Date().toLocaleString('pt-PT')}`);
  console.log(`Supabase: ${supabaseUrl}`);
  console.log(`Destino: ${outputDir}\n`);

  for (const table of TABLES) {
    try {
      // Usar REST API do Supabase directamente (sem SDK para manter o script leve)
      const url = `${supabaseUrl}/rest/v1/${table}?select=*&order=created_at.asc`;
      const res = await fetch(url, {
        headers: {
          apikey: serviceKey,
          Authorization: `Bearer ${serviceKey}`,
          'Content-Type': 'application/json',
          Prefer: 'count=exact',
        },
      });

      if (!res.ok) {
        const text = await res.text();
        console.error(`  ✗ ${table}: HTTP ${res.status} — ${text.slice(0, 120)}`);
        errors++;
        continue;
      }

      const rows = await res.json();
      const count = rows.length;
      backupData.data[table] = rows;
      totalRows += count;

      const pad = table.padEnd(28);
      console.log(`  ✓ ${pad} ${count} registos`);
    } catch (err) {
      console.error(`  ✗ ${table}: ${err.message}`);
      errors++;
    }
  }

  // Gravar ficheiro JSON
  const filename = `aep-backup-${timestamp}.json`;
  const filepath = path.join(outputDir, filename);
  fs.writeFileSync(filepath, JSON.stringify(backupData, null, 2), 'utf-8');

  const sizeKB = (fs.statSync(filepath).size / 1024).toFixed(1);

  console.log(`\n— Resumo —`);
  console.log(`  Tabelas: ${TABLES.length - errors}/${TABLES.length} exportadas`);
  console.log(`  Registos: ${totalRows}`);
  console.log(`  Ficheiro: ${filename} (${sizeKB} KB)`);
  if (errors > 0) {
    console.log(`  Erros: ${errors}`);
  }
  console.log('');
}

main().catch((err) => {
  console.error('Erro fatal:', err);
  process.exit(1);
});
