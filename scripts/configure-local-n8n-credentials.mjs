import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

function parseEnv(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const values = {};
  for (const rawLine of fs.readFileSync(filePath, 'utf8').split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const separator = line.indexOf('=');
    if (separator < 1) continue;
    const key = line.slice(0, separator).trim();
    let value = line.slice(separator + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    values[key] = value;
  }
  return values;
}

const projectEnv = parseEnv(path.resolve('.env'));
const codexEnv = parseEnv(path.join(os.homedir(), '.codex', '.env'));
const apiUrl = process.env.N8N_API_URL || 'http://127.0.0.1:5678';
const apiKey = process.env.N8N_API_KEY || codexEnv.N8N_API_KEY;

if (!apiKey) throw new Error('N8N_API_KEY is not available in the process or ~/.codex/.env.');

for (const name of ['RAG_DB_USER', 'RAG_DB_PASSWORD', 'RAG_DB_NAME', 'MINIO_ROOT_USER', 'MINIO_ROOT_PASSWORD', 'QDRANT_API_KEY']) {
  if (!projectEnv[name] || projectEnv[name].startsWith('REPLACE_WITH_')) {
    throw new Error(`Missing configured ${name} in .env.`);
  }
}

const headers = {
  'Content-Type': 'application/json',
  'X-N8N-API-KEY': apiKey,
};

async function request(route, options = {}) {
  const response = await fetch(`${apiUrl}/api/v1${route}`, { ...options, headers: { ...headers, ...options.headers } });
  const text = await response.text();
  const body = text ? JSON.parse(text) : null;
  if (!response.ok) throw new Error(`n8n API ${response.status} for ${route}: ${body?.message || 'request failed'}`);
  return body;
}

const listed = await request('/credentials?limit=100');
const existing = new Map((listed.data || []).map((credential) => [credential.name, credential]));

const definitions = [
  {
    name: 'Local RAG PostgreSQL',
    type: 'postgres',
    data: {
      host: 'postgres',
      port: 5432,
      database: projectEnv.RAG_DB_NAME,
      user: projectEnv.RAG_DB_USER,
      password: projectEnv.RAG_DB_PASSWORD,
      maxConnections: 5,
      ssl: 'disable',
      allowUnauthorizedCerts: false,
      sshTunnel: false
    }
  },
  {
    name: 'Local RAG MinIO',
    type: 's3',
    data: {
      endpoint: 'http://minio:9000',
      region: 'us-east-1',
      accessKeyId: projectEnv.MINIO_ROOT_USER,
      secretAccessKey: projectEnv.MINIO_ROOT_PASSWORD,
      forcePathStyle: true,
      ignoreSSLIssues: false
    }
  },
  {
    name: 'Local RAG Qdrant',
    type: 'qdrantApi',
    data: {
      qdrantUrl: 'http://qdrant:6333',
      apiKey: projectEnv.QDRANT_API_KEY,
      allowedHttpRequestDomains: 'domains',
      allowedDomains: 'qdrant'
    }
  },
  {
    name: 'Local RAG Ollama',
    type: 'ollamaApi',
    data: {
      baseUrl: 'http://ollama:11434',
      allowedHttpRequestDomains: 'domains',
      allowedDomains: 'ollama'
    }
  }
];

const results = [];
for (const definition of definitions) {
  if (existing.has(definition.name)) {
    results.push({ id: existing.get(definition.name).id, name: definition.name, created: false });
    continue;
  }
  const created = await request('/credentials', { method: 'POST', body: JSON.stringify(definition) });
  results.push({ id: created.id, name: created.name, created: true });
}

console.log(JSON.stringify(results, null, 2));
