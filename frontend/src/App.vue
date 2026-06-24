<script setup>
import { computed, onMounted, ref } from 'vue'

const DEFAULT_KB_ID = '00000000-0000-4000-8000-000000000001'
const STORAGE_KEY = 'local-rag-documents-v1'

const query = ref('')
const answer = ref(null)
const documents = ref([])
const selectedDocumentId = ref('')
const isQuerying = ref(false)
const isUploading = ref(false)
const isAdminAction = ref(false)
const isDragging = ref(false)
const notice = ref(null)
const fileInput = ref(null)
const apiOnline = ref(false)

const selectedDocument = computed(() =>
  documents.value.find((document) => document.documentId === selectedDocumentId.value) || null,
)

function persistDocuments() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(documents.value.slice(0, 20)))
}

function upsertDocument(document) {
  const existing = documents.value.find((item) => item.documentId === document.documentId)
  const next = {
    ...existing,
    ...document,
    updatedAt: new Date().toISOString(),
  }
  documents.value = [next, ...documents.value.filter((item) => item.documentId !== next.documentId)]
  selectedDocumentId.value = next.documentId
  persistDocuments()
}

async function callRag(body) {
  const response = await fetch('/webhook/rag', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  const payload = await response.json().catch(() => ({}))
  if (!response.ok || payload.ok === false) {
    const message = payload.error?.message || payload.error || payload.message || `Request failed (${response.status})`
    throw new Error(message)
  }
  return payload
}

async function ask() {
  const message = query.value.trim()
  if (!message || isQuerying.value) return
  isQuerying.value = true
  answer.value = null
  notice.value = null
  try {
    answer.value = await callRag({ action: 'query', query: message, kbId: DEFAULT_KB_ID, topK: 6 })
  } catch (error) {
    notice.value = { type: 'error', text: error.message }
  } finally {
    isQuerying.value = false
  }
}

async function upload(file) {
  if (!file || isUploading.value) return
  if (file.size > 25 * 1024 * 1024) {
    notice.value = { type: 'error', text: 'Files must be 25 MiB or smaller.' }
    return
  }
  isUploading.value = true
  notice.value = { type: 'progress', text: `Indexing ${file.name}. This may take a minute.` }
  const form = new FormData()
  form.append('action', 'ingest')
  form.append('kbId', DEFAULT_KB_ID)
  form.append('file', file)
  try {
    const response = await fetch('/webhook/rag', { method: 'POST', body: form })
    const payload = await response.json().catch(() => ({}))
    if (!response.ok || payload.ok === false) {
      throw new Error(payload.error?.message || payload.error || payload.message || `Upload failed (${response.status})`)
    }
    upsertDocument({ ...payload, filename: file.name, size: file.size })
    notice.value = { type: 'success', text: `${file.name} is indexed and ready.` }
  } catch (error) {
    notice.value = { type: 'error', text: error.message }
  } finally {
    isUploading.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

function chooseFiles(event) {
  upload(event.target.files?.[0])
}

function dropFile(event) {
  isDragging.value = false
  upload(event.dataTransfer.files?.[0])
}

async function runAdminAction(action) {
  const document = selectedDocument.value
  if (!document || isAdminAction.value) return
  isAdminAction.value = true
  notice.value = null
  try {
    const payload = await callRag({ action, documentId: document.documentId, confirm: 'RESET' })
    if (action === 'reset') {
      upsertDocument({ ...document, status: 'pending', chunkCount: 0 })
      notice.value = { type: 'success', text: `${document.filename} was reset. Source artifacts were preserved.` }
    } else {
      upsertDocument({ ...document, ...payload })
      notice.value = { type: 'success', text: `${document.filename} was reprocessed.` }
    }
  } catch (error) {
    notice.value = { type: 'error', text: error.message }
  } finally {
    isAdminAction.value = false
  }
}

function formatBytes(bytes) {
  if (!bytes) return ''
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

onMounted(async () => {
  try {
    documents.value = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
    selectedDocumentId.value = documents.value[0]?.documentId || ''
  } catch {
    documents.value = []
  }
  try {
    apiOnline.value = (await fetch('/health', { cache: 'no-store' })).ok
  } catch {
    apiOnline.value = false
  }
})
</script>

<template>
  <div class="app-shell">
    <header class="topbar">
      <a class="brand" href="#main" aria-label="Local RAG home">
        <span class="brand-mark" aria-hidden="true">LR</span>
        <span>Local RAG</span>
      </a>
      <nav aria-label="Primary navigation">
        <a class="nav-link active" href="#ask">Ask</a>
        <a class="nav-link" href="#documents">Documents</a>
        <a class="nav-link" href="#system">System</a>
      </nav>
      <span class="privacy-note"><span class="status-dot" :class="{ online: apiOnline }"></span>{{ apiOnline ? 'Local services ready' : 'Services unavailable' }}</span>
    </header>

    <main id="main" class="workspace">
      <section id="ask" class="reading-pane" aria-labelledby="page-title">
        <div class="intro">
          <h1 id="page-title">Ask your knowledge base</h1>
          <p>Answers stay grounded in your indexed documents.</p>
        </div>

        <form class="question-form" @submit.prevent="ask">
          <label for="question">Your question</label>
          <div class="composer">
            <textarea
              id="question"
              v-model="query"
              rows="3"
              placeholder="Ask a question about your documents"
              @keydown.ctrl.enter="ask"
              @keydown.meta.enter="ask"
            ></textarea>
            <button class="primary-button" type="submit" :disabled="!query.trim() || isQuerying">
              <span v-if="isQuerying" class="spinner" aria-hidden="true"></span>
              {{ isQuerying ? 'Thinking' : 'Ask' }}
            </button>
          </div>
          <span class="shortcut">Ctrl/⌘ + Enter</span>
        </form>

        <div v-if="notice" class="notice" :class="notice.type" role="status">{{ notice.text }}</div>

        <article v-if="answer" class="answer-block" aria-live="polite">
          <div class="answer-label">Grounded answer</div>
          <p class="answer-text">{{ answer.answer }}</p>
          <div class="answer-meta">
            <span>{{ answer.model || 'Local model' }}</span>
            <span>{{ answer.retrieval?.resultCount || 0 }} sources retrieved</span>
          </div>
        </article>

        <div v-else-if="isQuerying" class="answer-skeleton" aria-live="polite">
          <span>Searching indexed passages</span>
          <i></i><i></i><i></i>
        </div>

        <div v-else class="empty-answer">
          <div class="empty-glyph" aria-hidden="true">?</div>
          <h2>Start with a precise question</h2>
          <p>Local RAG will retrieve relevant passages, answer from them, and show every source it used.</p>
        </div>

        <section v-if="answer?.sources?.length" class="source-list" aria-labelledby="source-title">
          <h2 id="source-title">Sources</h2>
          <ol>
            <li v-for="source in answer.sources" :key="source.id">
              <span class="source-number">{{ source.id }}</span>
              <div>
                <strong>{{ source.filename }}</strong>
                <p>{{ source.headingPath?.join(' › ') || 'Document passage' }}</p>
              </div>
              <span class="score">{{ Math.round(source.score * 100) }}%</span>
            </li>
          </ol>
        </section>
      </section>

      <aside id="documents" class="document-rail" aria-labelledby="documents-title">
        <div class="rail-header">
          <div>
            <span class="section-index">01</span>
            <h2 id="documents-title">Documents</h2>
          </div>
          <button class="text-button" type="button" @click="fileInput?.click()">Add document</button>
        </div>

        <input ref="fileInput" class="visually-hidden" type="file" @change="chooseFiles" />
        <button
          class="dropzone"
          :class="{ dragging: isDragging, busy: isUploading }"
          type="button"
          :disabled="isUploading"
          @click="fileInput?.click()"
          @dragover.prevent="isDragging = true"
          @dragleave.prevent="isDragging = false"
          @drop.prevent="dropFile"
        >
          <span class="upload-icon" aria-hidden="true">↑</span>
          <strong>{{ isUploading ? 'Indexing document…' : 'Drop a file here' }}</strong>
          <span>PDF, DOCX, PPTX, HTML, Markdown and more · 25 MiB max</span>
        </button>

        <div v-if="documents.length" class="document-list">
          <button
            v-for="document in documents"
            :key="document.documentId"
            class="document-row"
            :class="{ selected: document.documentId === selectedDocumentId }"
            type="button"
            @click="selectedDocumentId = document.documentId"
          >
            <span class="file-monogram">{{ document.filename?.split('.').pop()?.slice(0, 3).toUpperCase() || 'DOC' }}</span>
            <span class="document-copy">
              <strong>{{ document.filename || 'Indexed document' }}</strong>
              <small>{{ document.status }} · {{ document.chunkCount || 0 }} chunks <template v-if="document.size">· {{ formatBytes(document.size) }}</template></small>
            </span>
            <span class="row-check" aria-hidden="true">✓</span>
          </button>
        </div>
        <p v-else class="no-documents">No documents added from this browser yet.</p>

        <div v-if="selectedDocument" class="document-actions">
          <button type="button" :disabled="isAdminAction" @click="runAdminAction('reprocess')">Reprocess</button>
          <button class="danger-link" type="button" :disabled="isAdminAction" @click="runAdminAction('reset')">Reset vectors</button>
        </div>

        <section id="system" class="system-status" aria-labelledby="system-title">
          <div class="rail-header compact">
            <div><span class="section-index">02</span><h2 id="system-title">System</h2></div>
          </div>
          <ul>
            <li v-for="service in ['n8n', 'Qdrant', 'Ollama', 'Docling']" :key="service">
              <span>{{ service }}</span>
              <span class="service-state"><i :class="{ online: apiOnline }"></i>{{ apiOnline ? 'ready' : 'offline' }}</span>
            </li>
          </ul>
        </section>
      </aside>
    </main>

    <footer>
      <span>Private by design. Documents and inference stay on this machine.</span>
      <span>n8n orchestrated · local models</span>
    </footer>
  </div>
</template>
