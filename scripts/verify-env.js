#!/usr/bin/env node
/**
 * verify-env.js
 * -----------------------------------------------------------------
 * Valida o ficheiro .env.local e confirma que todas as credenciais
 * do AEP estao presentes e bem formatadas. Opcionalmente, testa
 * conectividade real com Supabase e Anthropic.
 *
 * Uso:
 *   node scripts/verify-env.js             # validacao basica
 *   node scripts/verify-env.js --ping      # + teste de ligacao
 *
 * Autor: Claude (Anthropic), 9 de abril de 2026
 * -----------------------------------------------------------------
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// ---------- Carregar .env.local manualmente ----------
const envPath = path.join(__dirname, '..', '.env.local');

if (!fs.existsSync(envPath)) {
  console.error('\x1b[31m[ERRO]\x1b[0m Ficheiro .env.local nao encontrado em:', envPath);
  console.error('Copia .env.example para .env.local e preenche os valores.');
  process.exit(1);
}

const envContent = fs.readFileSync(envPath, 'utf-8');
const env = {};
envContent.split('\n').forEach((line) => {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('#')) return;
  const [key, ...rest] = trimmed.split('=');
  if (key) env[key.trim()] = rest.join('=').trim();
});

// ---------- Regras de validacao ----------
const rules = [
  {
    key: 'NEXT_PUBLIC_SUPABASE_URL',
    required: true,
    pattern: /^https:\/\/[a-z0-9]{20}\.supabase\.co$/,
    hint: 'Formato esperado: https://xxxxxxxxxxxxxxxxxxxx.supabase.co',
  },
  {
    key: 'NEXT_PUBLIC_SUPABASE_ANON_KEY',
    required: true,
    pattern: /^(eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+|sb_publishable_[A-Za-z0-9_-]+)$/,
    hint: 'JWT classico "eyJ..." ou nova chave "sb_publishable_...".',
  },
  {
    key: 'SUPABASE_SERVICE_ROLE_KEY',
    required: true,
    pattern: /^(eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+|sb_secret_[A-Za-z0-9_-]+)$/,
    hint: 'JWT classico "eyJ..." ou nova chave "sb_secret_...". SECRETO.',
  },
  {
    key: 'SUPABASE_DB_PASSWORD',
    required: false,
    pattern: /^.{8,}$/,
    hint: 'Minimo 8 caracteres. Opcional, so necessario para psql e Supabase CLI admin.',
  },
  {
    key: 'SUPABASE_PROJECT_REF',
    required: true,
    pattern: /^[a-z0-9]{20}$/,
    hint: '20 caracteres alfanumericos minusculos.',
  },
  {
    key: 'ANTHROPIC_API_KEY',
    required: false,
    pattern: /^sk-ant-api03-[A-Za-z0-9_-]+$/,
    hint: 'Formato: sk-ant-api03-... (Etapa 3 adiada, servidor Anthropic temporariamente indisponivel).',
  },
  {
    key: 'GITHUB_REPO_URL',
    required: false,
    pattern: /^https:\/\/github\.com\/[^\/]+\/[^\/]+$/,
    hint: 'Formato: https://github.com/user/repo',
  },
  {
    key: 'AEP_ENV',
    required: true,
    pattern: /^(development|production|staging)$/,
    hint: 'development | production | staging',
  },
  {
    key: 'AEP_DEFAULT_MODEL',
    required: true,
    pattern: /^claude-(sonnet|opus|haiku)-\d/,
    hint: 'Ex.: claude-sonnet-4-5-20250929',
  },
];

// ---------- Executar validacao ----------
console.log('\n==============================================');
console.log('  AEP, verificacao de credenciais .env.local');
console.log('==============================================\n');

let errors = 0;
let warnings = 0;

rules.forEach((rule) => {
  const value = env[rule.key];
  if (!value || value === '') {
    if (rule.required) {
      console.log(`\x1b[31m[ERRO]\x1b[0m    ${rule.key} em falta`);
      console.log(`          Hint: ${rule.hint}`);
      errors++;
    } else {
      console.log(`\x1b[33m[AVISO]\x1b[0m   ${rule.key} vazio (opcional)`);
      warnings++;
    }
    return;
  }
  if (rule.pattern && !rule.pattern.test(value)) {
    console.log(`\x1b[31m[ERRO]\x1b[0m    ${rule.key} formato invalido`);
    console.log(`          Valor: ${value.substring(0, 30)}...`);
    console.log(`          Hint:  ${rule.hint}`);
    errors++;
    return;
  }
  // mascarar secrets
  const display = rule.key.includes('KEY') || rule.key.includes('PASSWORD')
    ? value.substring(0, 8) + '...' + value.substring(value.length - 4)
    : value;
  console.log(`\x1b[32m[OK]\x1b[0m      ${rule.key} = ${display}`);
});

console.log('\n----------------------------------------------');
console.log(`  Erros: ${errors} | Avisos: ${warnings}`);
console.log('----------------------------------------------\n');

if (errors > 0) {
  console.log('\x1b[31mFALHOU.\x1b[0m Corrige os erros acima antes de continuar.\n');
  process.exit(1);
}

// ---------- Teste opcional de conectividade ----------
if (process.argv.includes('--ping')) {
  console.log('A testar ligacao a Supabase e Anthropic...\n');

  const pingSupabase = () => new Promise((resolve) => {
    // Testamos dois endpoints:
    //   1) /auth/v1/health com a publishable (valida GoTrue),
    //   2) /rest/v1/ com a secret (valida PostgREST).
    // Ambos precisam de responder 200 para dar OK.
    const base = new URL(env.NEXT_PUBLIC_SUPABASE_URL);
    const pub = env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    const sec = env.SUPABASE_SERVICE_ROLE_KEY;

    const hit = (pathname, headers) => new Promise((res) => {
      const req = https.request({
        hostname: base.hostname,
        path: pathname,
        method: 'GET',
        headers,
      }, (r) => { res(r.statusCode); });
      req.on('error', () => res(null));
      req.end();
    });

    Promise.all([
      hit('/auth/v1/health', { apikey: pub }),
      hit('/rest/v1/', { apikey: sec, Authorization: 'Bearer ' + sec }),
    ]).then(([authStatus, restStatus]) => {
      const authOk = authStatus === 200;
      const restOk = restStatus === 200;
      if (authOk) {
        console.log('\x1b[32m[OK]\x1b[0m      Supabase GoTrue respondeu 200');
      } else {
        console.log(`\x1b[31m[ERRO]\x1b[0m    Supabase GoTrue respondeu ${authStatus}`);
      }
      if (restOk) {
        console.log('\x1b[32m[OK]\x1b[0m      Supabase PostgREST respondeu 200');
      } else {
        console.log(`\x1b[31m[ERRO]\x1b[0m    Supabase PostgREST respondeu ${restStatus}`);
      }
      resolve(authOk && restOk);
    });
  });

  const pingAnthropic = () => new Promise((resolve) => {
    const req = https.request({
      hostname: 'api.anthropic.com',
      path: '/v1/messages',
      method: 'POST',
      headers: {
        'x-api-key': env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
    }, (res) => {
      let body = '';
      res.on('data', (d) => body += d);
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log('\x1b[32m[OK]\x1b[0m      Anthropic respondeu 200');
          resolve(true);
        } else if (res.statusCode === 401) {
          console.log('\x1b[31m[ERRO]\x1b[0m    Anthropic 401, API key invalida');
          resolve(false);
        } else if (res.statusCode === 402) {
          console.log('\x1b[33m[AVISO]\x1b[0m   Anthropic 402, falta adicionar creditos');
          resolve(false);
        } else {
          console.log(`\x1b[33m[AVISO]\x1b[0m   Anthropic respondeu ${res.statusCode}: ${body.substring(0, 100)}`);
          resolve(false);
        }
      });
    });
    req.on('error', (e) => {
      console.log('\x1b[31m[ERRO]\x1b[0m    Anthropic nao respondeu:', e.message);
      resolve(false);
    });
    req.write(JSON.stringify({
      model: env.AEP_DEFAULT_MODEL || 'claude-sonnet-4-5-20250929',
      max_tokens: 10,
      messages: [{ role: 'user', content: 'ping' }],
    }));
    req.end();
  });

  (async () => {
    const tasks = [pingSupabase()];
    const hasAnthropic = !!env.ANTHROPIC_API_KEY;
    if (hasAnthropic) {
      tasks.push(pingAnthropic());
    } else {
      console.log('\x1b[33m[AVISO]\x1b[0m   ANTHROPIC_API_KEY em falta, ping Anthropic ignorado.');
    }
    const results = await Promise.all(tasks);
    const supaOk = results[0];
    const anthOk = hasAnthropic ? results[1] : null;
    console.log('\n==============================================');
    if (supaOk && (anthOk === true || anthOk === null)) {
      if (anthOk === null) {
        console.log('\x1b[33mSUPABASE OK, ANTHROPIC ADIADO.\x1b[0m Podes avancar com o schema.\n');
      } else {
        console.log('\x1b[32mTUDO OK.\x1b[0m Ambiente AEP pronto a executar.\n');
      }
      process.exit(0);
    } else {
      console.log('\x1b[31mALGUNS PROBLEMAS.\x1b[0m Ver acima.\n');
      process.exit(1);
    }
  })();
} else {
  console.log('\x1b[32mValidacao de formato PASSOU.\x1b[0m');
  console.log('Corre com --ping para testar a ligacao real.\n');
  process.exit(0);
}
