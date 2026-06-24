CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS rag_knowledge_bases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rag_documents (
  id uuid PRIMARY KEY,
  kb_id uuid NOT NULL REFERENCES rag_knowledge_bases(id),
  source_sha256 char(64) NOT NULL,
  filename text NOT NULL,
  extension text NOT NULL,
  mime_type text NOT NULL,
  source_size bigint NOT NULL CHECK (source_size >= 0),
  source_key text,
  status text NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'processing', 'extracting', 'chunking', 'embedding', 'indexed', 'failed')
  ),
  processing_attempt integer NOT NULL DEFAULT 1 CHECK (processing_attempt > 0),
  chunk_count integer NOT NULL DEFAULT 0 CHECK (chunk_count >= 0),
  artifact_manifest jsonb NOT NULL DEFAULT '{}'::jsonb,
  error_stage text,
  error_code text,
  error_message text,
  error_details jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  indexed_at timestamptz,
  UNIQUE (kb_id, source_sha256)
);

CREATE TABLE IF NOT EXISTS rag_document_events (
  id bigserial PRIMARY KEY,
  document_id uuid NOT NULL REFERENCES rag_documents(id) ON DELETE CASCADE,
  status text NOT NULL,
  stage text NOT NULL,
  message text,
  details jsonb,
  execution_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS rag_documents_kb_status_idx
  ON rag_documents (kb_id, status, updated_at DESC);

CREATE INDEX IF NOT EXISTS rag_documents_stale_processing_idx
  ON rag_documents (updated_at)
  WHERE status IN ('pending', 'processing', 'extracting', 'chunking', 'embedding');

CREATE INDEX IF NOT EXISTS rag_document_events_document_idx
  ON rag_document_events (document_id, created_at DESC);

INSERT INTO rag_knowledge_bases (id, slug, name)
VALUES ('00000000-0000-4000-8000-000000000001', 'local-fixtures', 'Local fixture knowledge base')
ON CONFLICT (id) DO UPDATE
SET slug = EXCLUDED.slug,
    name = EXCLUDED.name,
    updated_at = now();
