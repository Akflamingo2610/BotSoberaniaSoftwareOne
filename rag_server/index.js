const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const pdf = require('pdf-parse');
const MiniSearch = require('minisearch');

const PORT = process.env.PORT || 4000;
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'gemma3:1b';
const GROQ_API_KEY = process.env.GROQ_API_KEY;
const DOCS_DIR = process.env.DOCS_DIR
  ? path.resolve(process.env.DOCS_DIR)
  : (fs.existsSync(path.join(__dirname, '..', 'OneDrive_1_1-26-2026'))
    ? path.join(__dirname, '..', 'OneDrive_1_1-26-2026')
    : path.join(__dirname, 'docs'));

let searchIndex = null;
let docs = [];

function chunkText(text, chunkSize = 800, overlap = 150) {
  if (!text || typeof text !== 'string') return [];
  const t = text.replace(/\s+/g, ' ').trim();
  if (t.length < 20) return t.length > 0 ? [t] : [];
  const chunks = [];
  let start = 0;
  while (start < t.length) {
    let end = start + chunkSize;
    if (end < t.length) {
      const lastSpace = t.lastIndexOf(' ', end);
      if (lastSpace > start) end = lastSpace;
    }
    const chunk = t.slice(start, end).trim();
    if (chunk.length > 15) chunks.push(chunk);
    start = end - overlap;
    if (start >= t.length) break;
  }
  return chunks;
}

async function loadDocs() {
  if (!fs.existsSync(DOCS_DIR)) {
    console.error('Pasta de documentos não encontrada:', DOCS_DIR);
    return;
  }
  const files = fs.readdirSync(DOCS_DIR).filter(f => f.toLowerCase().endsWith('.pdf'));
  docs = [];
  for (const file of files) {
    try {
      const filePath = path.join(DOCS_DIR, file);
      const buffer = fs.readFileSync(filePath);
      const data = await pdf(buffer);
      const raw = (data && data.text) ? String(data.text) : '';
      const title = file.replace(/\.pdf$/i, '');
      let chunks = chunkText(raw);
      if (chunks.length === 0 && raw.length > 0) chunks = [raw.slice(0, 2000)];
      if (chunks.length === 0) {
        docs.push({ id: title, title, file, text: title, chunkIndex: 0 });
        console.log('Indexado (metadado):', file, '- PDF pode ser escaneado');
      } else {
        chunks.forEach((chunk, i) => {
          docs.push({
            id: `${title}__${i}`,
            title,
            file,
            text: chunk,
            chunkIndex: i,
          });
        });
        console.log('Indexado:', file, '-', chunks.length, 'chunks');
      }
    } catch (err) {
      console.error('Erro ao processar', file, err.message);
    }
  }

  searchIndex = new MiniSearch({
    fields: ['title', 'text'],
    storeFields: ['title', 'file', 'text'],
    searchOptions: { boost: { title: 2 }, prefix: true, fuzzy: 0.2 },
  });
  searchIndex.addAll(docs);
  console.log('Índice pronto. Total de chunks:', docs.length);
}

function buildPrompt(query, context, questionContext) {
  const hasContext = context && context.trim().length > 30;
  const hasQuestion = questionContext && questionContext.trim().length > 10;
  const system = 'Você é um assistente especializado em leis brasileiras (LGPD, Marco Civil, ECA Digital, normas BCB, MP 1318, etc.). Responda em português, de forma clara e objetiva. Se não tiver informação suficiente nos trechos fornecidos, explique o que sabe sobre o tema de forma geral. Não invente leis ou artigos específicos.';
  let userPart = `Pergunta do usuário: ${query}`;
  if (hasQuestion) {
    userPart = `O usuário está respondendo a esta pergunta do assessment:\n\n"${questionContext.trim()}"\n\nDúvida dele: ${query}\n\nResponda explicando como as leis se aplicam a essa pergunta:`;
  }
  return hasContext
    ? `${system}\n\nTrechos dos documentos (use como base para sua resposta):\n\n${context}\n\n${userPart}`
    : `${system}\n\n${userPart}\n\nNão há trechos específicos dos documentos disponíveis. Ainda assim, responda de forma útil sobre o tema, explicando conceitos gerais quando possível:`;
}

async function askGroq(prompt, sources) {
  if (!GROQ_API_KEY) return null;
  try {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'llama-3.1-8b-instant',
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 500,
        temperature: 0.4,
      }),
    });
    if (!res.ok) throw new Error(`Groq ${res.status}`);
    const data = await res.json();
    let answer = (data.choices?.[0]?.message?.content || '').trim();
    if (!answer) throw new Error('Resposta vazia da Groq');
    if (sources && sources.length > 0) {
      answer += `\n\n*Fontes consultadas: ${sources.map(s => s.title).join(', ')}*`;
    }
    answer += '\n\n*Nota: Esta é uma busca por relevância. Para interpretação jurídica, consulte um profissional.*';
    return answer;
  } catch (err) {
    console.error('Erro Groq:', err.message);
    return null;
  }
}

async function askOllama(prompt, sources) {
  try {
    const res = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt,
        stream: false,
        options: { num_predict: 450, num_ctx: 4096, temperature: 0.4 },
      }),
    });
    if (!res.ok) throw new Error(`Ollama ${res.status}`);
    const data = await res.json();
    let answer = (data.response || '').trim();
    if (!answer) throw new Error('Resposta vazia do Ollama');
    if (sources && sources.length > 0) {
      answer += `\n\n*Fontes consultadas: ${sources.map(s => s.title).join(', ')}*`;
    }
    answer += '\n\n*Nota: Esta é uma busca por relevância. Para interpretação jurídica, consulte um profissional.*';
    return answer;
  } catch (err) {
    console.error('Erro Ollama:', err.message);
    return null;
  }
}

async function askLLM(query, context, sources, questionContext) {
  const prompt = buildPrompt(query, context, questionContext);
  if (GROQ_API_KEY) {
    const answer = await askGroq(prompt, sources);
    if (answer) return answer;
  }
  return askOllama(prompt, sources);
}

const app = express();
app.use(cors({ origin: true, credentials: false }));
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', indexed: docs.length });
});

app.post('/ask', async (req, res) => {
  const { query, questionContext } = req.body || {};
  if (!query || typeof query !== 'string') {
    return res.status(400).json({ error: 'Envie { "query": "sua pergunta" }' });
  }

  if (!searchIndex || docs.length === 0) {
    return res.status(503).json({
      error: 'Índice não carregado. Verifique se a pasta OneDrive_1_1-26-2026 existe e contém PDFs.',
    });
  }

  const hits = searchIndex.search(query.trim(), { combineWith: 'OR' }).slice(0, 4);
  const sources = hits.map(h => {
    const doc = docs.find(d => d.id === h.id) || h;
    return { title: doc.title || h.title, file: doc.file || h.file };
  });
  const context = hits
    .map(h => {
      const doc = docs.find(d => d.id === h.id) || h;
      const text = (doc.text || h.text || '').trim();
      const title = doc.title || h.title || 'Documento';
      return text ? `[Fonte: ${title}]\n\n${text}` : null;
    })
    .filter(Boolean)
    .join('\n\n---\n\n');

  const qCtx = (typeof questionContext === 'string') ? questionContext.trim() : '';
  let answer = await askLLM(query, context, sources, qCtx || undefined);
  if (!answer) {
    const llmHint = GROQ_API_KEY ? 'Verifique GROQ_API_KEY.' : `Ollama não está rodando (ollama run ${OLLAMA_MODEL}).`;
    if (context && context.trim().length > 50) {
      answer = `Com base nos documentos:\n\n${context}\n\n*Nota: ${llmHint}*`;
    } else if (sources.length > 0) {
      answer = `Encontrei referência a: ${sources.map(s => s.title).join(', ')}.\n\n*Nota: ${llmHint}*`;
    } else {
      answer = 'Não encontrei trechos relevantes. Tente reformular a pergunta ou usar termos das leis (ex: LGPD, Marco Civil, dados pessoais).';
    }
  }

  res.json({ answer, sources });
});

// Resposta em streaming: o usuário vê o texto aparecer em tempo real (latência percebida muito menor)
app.post('/ask/stream', async (req, res) => {
  const { query, questionContext } = req.body || {};
  if (!query || typeof query !== 'string') {
    return res.status(400).json({ error: 'Envie { "query": "sua pergunta" }' });
  }
  if (!searchIndex || docs.length === 0) {
    return res.status(503).json({
      error: 'Índice não carregado. Verifique se a pasta OneDrive_1_1-26-2026 existe e contém PDFs.',
    });
  }

  const hits = searchIndex.search(query.trim(), { combineWith: 'OR' }).slice(0, 3);
  const sources = hits.map(h => {
    const doc = docs.find(d => d.id === h.id) || h;
    return { title: doc.title || h.title, file: doc.file || h.file };
  });
  const context = hits
    .map(h => {
      const doc = docs.find(d => d.id === h.id) || h;
      const text = (doc.text || h.text || '').trim().slice(0, 600);
      const title = doc.title || h.title || 'Documento';
      return text ? `[Fonte: ${title}]\n\n${text}` : null;
    })
    .filter(Boolean)
    .join('\n\n---\n\n');

  const qCtx = (typeof questionContext === 'string') ? questionContext.trim() : '';
  const hasContext = context && context.trim().length > 30;
  const hasQuestion = qCtx.length > 10;
  const system = 'Você é um assistente de leis brasileiras. Responda em português, de forma clara e objetiva.';
  let userPart = `Pergunta: ${query}`;
  if (hasQuestion) userPart = `Pergunta do assessment:\n"${qCtx}"\n\nDúvida: ${query}\n\nExplique como as leis se aplicam:`;
  const prompt = hasContext
    ? `${system}\n\nTrechos:\n\n${context}\n\n${userPart}`
    : `${system}\n\n${userPart}`;

  res.setHeader('Content-Type', 'application/x-ndjson');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  const writeChunk = (t) => res.write(JSON.stringify({ t }) + '\n');
  const writeDone = () => {
    if (sources.length > 0) writeChunk(`\n\n*Fontes: ${sources.map(s => s.title).join(', ')}*`);
    res.write(JSON.stringify({ t: '\n\n*Nota: Para interpretação jurídica, consulte um profissional.*', done: true, sources }) + '\n');
    res.end();
  };

  try {
    if (GROQ_API_KEY) {
      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${GROQ_API_KEY}`,
        },
        body: JSON.stringify({
          model: 'llama-3.1-8b-instant',
          messages: [{ role: 'user', content: prompt }],
          max_tokens: 500,
          temperature: 0.4,
          stream: true,
        }),
      });
      if (groqRes.ok && groqRes.body) {
        const reader = groqRes.body.getReader();
        const decoder = new TextDecoder();
        let buffer = '';
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split('\n');
          buffer = lines.pop() || '';
          for (const line of lines) {
            if (line.startsWith('data: ')) {
              const json = line.slice(6).trim();
              if (json === '[DONE]') continue;
              try {
                const obj = JSON.parse(json);
                const content = obj.choices?.[0]?.delta?.content;
                if (content) writeChunk(content);
              } catch (_) { }
            }
          }
        }
        writeDone();
        return;
      }
    }

    const ollamaRes = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt,
        stream: true,
        options: { num_predict: 450, num_ctx: 4096, temperature: 0.4 },
      }),
    });
    if (!ollamaRes.ok || !ollamaRes.body) {
      res.write(JSON.stringify({ t: '', done: true, err: GROQ_API_KEY ? 'Groq falhou' : 'Ollama indisponível' }) + '\n');
      return res.end();
    }
    const reader = ollamaRes.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';
      for (const line of lines) {
        if (!line.trim()) continue;
        try {
          const obj = JSON.parse(line);
          if (obj.response) writeChunk(obj.response);
        } catch (_) { }
      }
    }
    if (buffer.trim()) {
      try {
        const obj = JSON.parse(buffer);
        if (obj.response) writeChunk(obj.response);
      } catch (_) { }
    }
    writeDone();
  } catch (err) {
    res.write(JSON.stringify({ t: '', done: true, err: err.message }) + '\n');
    res.end();
  }
});

async function start() {
  await loadDocs();
  app.listen(PORT, () => {
    console.log(`RAG Server rodando em http://localhost:${PORT}`);
    if (GROQ_API_KEY) {
      console.log('LLM: Groq (nuvem)');
    } else {
      console.log(`LLM: Ollama ${OLLAMA_URL} (modelo: ${OLLAMA_MODEL})`);
    }
    console.log(`Docs: ${DOCS_DIR}`);
    console.log('POST /ask com { "query": "sua pergunta" }');
  });
}

start().catch(err => {
  console.error('Erro ao iniciar:', err);
  process.exit(1);
});
