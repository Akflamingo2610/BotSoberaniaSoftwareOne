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
const GROQ_MODEL = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile'; // 70b gera respostas mais naturais; use llama-3.1-8b-instant para mais rápido
const DOCS_DIR = process.env.DOCS_DIR
  ? path.resolve(process.env.DOCS_DIR)
  : path.join(__dirname, 'docs');

// Arquivos AWS (soberania, security, well-architected) vs leis brasileiras
const AWS_FILE_PATTERNS = ['aws-', 'aws_', 'sovereign', 'digital-sovereignty', 'wellarchitected-security'];

function getDocType(fileName) {
  const lower = fileName.toLowerCase();
  return AWS_FILE_PATTERNS.some(p => lower.includes(p.toLowerCase())) ? 'aws' : 'lei';
}

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
      const docType = getDocType(file);
      if (chunks.length === 0) {
        docs.push({ id: title, title, file, text: title, chunkIndex: 0, docType });
        console.log('Indexado (metadado):', file, '- PDF pode ser escaneado');
      } else {
        chunks.forEach((chunk, i) => {
          docs.push({
            id: `${title}__${i}`,
            title,
            file,
            text: chunk,
            chunkIndex: i,
            docType,
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
    storeFields: ['title', 'file', 'text', 'docType'],
    searchOptions: { boost: { title: 2 }, prefix: true, fuzzy: 0.2 },
  });
  searchIndex.addAll(docs);
  console.log('Índice pronto. Total de chunks:', docs.length);
}

/** Detecta se a pergunta é sobre AWS, soberania digital em nuvem ou compliance AWS */
function isAwsQuery(query) {
  const q = (query || '').toLowerCase();
  const tokens = [
    'aws', 'amazon', 'amazon web', 'soberania', 'soberania digital', 'soberania na nuvem',
    'well-architected', 'well architected', 'security pillar', 'digital sovereignty',
    'sovereign cloud', 'região são paulo', 'são paulo region', 'sa-east-1', 'compliance aws',
    'shared responsibility', 'pilares aws', 'princípios segurança aws', 'dados no brasil',
    'nuvem', 'cloud',
  ];
  return tokens.some(t => q.includes(t));
}

/** Expande termos PT→EN para encontrar conteúdo nos PDFs AWS (que estão em inglês) */
function expandQueryForAws(query) {
  const map = {
    soberania: 'sovereignty',
    'soberania digital': 'digital sovereignty data sovereignty',
    'dados no brasil': 'data residency brazil region',
    'pilares': 'pillars principles',
    'segurança': 'security',
    'compliance': 'compliance',
    'continuidade': 'continuity resilience',
    'controle': 'control governance',
    'privacidade': 'privacy',
    'criptografia': 'encryption',
    'responsabilidade compartilhada': 'shared responsibility',
    'região': 'region',
  };
  let expanded = query;
  for (const [pt, en] of Object.entries(map)) {
    if (query.toLowerCase().includes(pt)) expanded += ' ' + en;
  }
  return expanded;
}

/** Termos em inglês que garantem hits nos PDFs AWS (digital-sovereignty-lens, wellarchitected, etc.) */
const AWS_SEED_QUERY = 'digital sovereignty data residency AWS region well-architected security';

/** Perguntas do assessment tratam de soberania digital, Control, Compliance, Continuity – preferir docs AWS */
function isAssessmentContext(query, questionContext) {
  const hasContext = questionContext && questionContext.trim().length > 20;
  const q = (query || '').toLowerCase();
  const ctx = ((query || '') + ' ' + (questionContext || '')).toLowerCase();
  const assessmentTerms = ['empresa', 'controla', 'processo', 'seleção', 'onboarding', 'fornecedores', 'audita', 'ações administrativas', 'ambientes', 'compliance', 'continuity', 'control', 'governança'];
  return hasContext && assessmentTerms.some(t => ctx.includes(t));
}

/** Busca em 2 etapas: para perguntas AWS, NUNCA retorna docs de leis (ECA, LGPD, etc.) */
function searchDocs(query, limit = 8, preferAws = false) {
  const q = query.trim();
  const awsQuery = isAwsQuery(q) || preferAws;

  if (awsQuery) {
    const awsSearchQuery = expandQueryForAws(q);
    let awsHits = searchIndex.search(awsSearchQuery, { combineWith: 'OR', filter: (r) => r.docType === 'aws' }).slice(0, limit);
    const seen = new Set(awsHits.map(h => h.id));

    // Fallback: se não achou nada, busca com termos em inglês
    if (awsHits.length === 0) {
      awsHits = searchIndex.search(AWS_SEED_QUERY, { combineWith: 'OR', filter: (r) => r.docType === 'aws' }).slice(0, limit);
      awsHits.forEach(h => seen.add(h.id));
    }

    // Complementa APENAS com outros docs AWS (NUNCA leis)
    if (awsHits.length < limit) {
      const allHits = searchIndex.search(awsSearchQuery + ' ' + AWS_SEED_QUERY, { combineWith: 'OR' });
      const awsFromAll = allHits.filter(h => h.docType === 'aws');
      for (const h of awsFromAll) {
        if (seen.has(h.id)) continue;
        awsHits.push(h);
        seen.add(h.id);
        if (awsHits.length >= limit) break;
      }
    }

    // Último recurso: pega chunks AWS direto do índice (garante que nunca vai ECA)
    if (awsHits.length === 0) {
      const awsDocs = docs.filter(d => d.docType === 'aws');
      const take = Math.min(limit, awsDocs.length);
      for (let i = 0; i < take; i++) {
        awsHits.push({ ...awsDocs[i], score: 1, id: awsDocs[i].id });
      }
    }

    return awsHits.slice(0, limit);
  }

  return searchIndex.search(q, { combineWith: 'OR' }).slice(0, limit);
}

/** Prompt base do especialista – respostas precisas e acessíveis, SEM alucinações */
const SYSTEM_PROMPT = `Você é um ESPECIALISTA em segurança, soberania digital e compliance/continuidade. Responda SEMPRE como consultor de forma clara e acessível.

IDIOMA OBRIGATÓRIO: Responda SEMPRE em português. NUNCA responda em inglês. Os documentos podem estar em inglês – TRADUZA todo o conteúdo relevante para português. O usuário espera resposta em português.

IMPORTANTE: Quando analisar resultados de assessments, NUNCA mencione nomes de empresas específicas (como "Amazon", "AWS", etc.). Refira-se sempre como "a organização", "a empresa avaliada" ou "a empresa".

REGRA CRÍTICA – RELEVÂNCIA DOS TRECHOS:
- Use APENAS trechos que respondam DIRETAMENTE à pergunta. Se um trecho contém a mesma palavra mas em contexto COMPLETAMENTE DIFERENTE (ex: "fornecedores" em lei sobre crianças/adolescentes vs "onboarding de fornecedores" em processo corporativo), IGNORE esse trecho.
- NUNCA cite ou use leis/fontes irrelevantes só porque contêm uma palavra em comum. Palavras como "fornecedores", " controle", "dados" aparecem em vários contextos – use só o que REALMENTE responde à dúvida.
- Se NENHUM trecho for relevante, responda com conhecimento geral e comece: "Com base em conhecimento geral:". NÃO invente citações nem force uso de documentos irrelevantes.

ESCOPO POR TEMA:
- AWS, soberania digital, pilares AWS, dados na nuvem → use EXCLUSIVAMENTE docs AWS (digital-sovereignty-lens, aws-overview, wellarchitected-security). NÃO misture com ECA ou LGPD.
- LGPD, Marco Civil, ECA Digital, leis brasileiras → use os docs de leis APENAS se falam diretamente do assunto perguntado.
- Conceitos de negócio (onboarding, processos, governança corporativa) → explique em linguagem simples; use leis só se falarem especificamente disso. Se a lei fala de "fornecedores" em outro contexto (ex: proteção infantil), ignore.

USER-FRIENDLY: Explique termos técnicos ao usá-los. Use linguagem natural.

PRECISÃO: Sintetize com suas palavras em português. NÃO copie trechos literais em inglês. NÃO repita o mesmo texto genérico para perguntas diferentes – adapte a resposta a cada pergunta específica.`;

function buildPrompt(query, context, questionContext, isAutoExplain = false) {
  const hasContext = context && context.trim().length > 30;
  const hasQuestion = questionContext && questionContext.trim().length > 10;
  let userPart = `Pergunta do usuário: ${query}`;
  if (hasQuestion) {
    if (isAutoExplain) {
      userPart = `Explique esta pergunta do assessment em português, de forma específica para ELA (não repita texto genérico):\n\n"${questionContext.trim()}"\n\nFaça em 2-4 parágrafos curtos: (1) o que esta pergunta avalia no contexto de soberania digital; (2) defina os termos técnicos em linguagem simples; (3) por que isso importa. Use os trechos APENAS se forem relevantes PARA ESTA PERGUNTA; caso contrário, explique com conhecimento geral. Responda SEMPRE em português.`;
    } else {
      userPart = `O usuário está respondendo a esta pergunta do assessment:\n\n"${questionContext.trim()}"\n\nDúvida dele: ${query}\n\nResponda em português, de forma acessível e específica para a dúvida. Se os trechos não forem relevantes, use conhecimento geral. Não cite fontes irrelevantes.`;
    }
  }
  const docInstruction = hasContext
    ? `Trechos dos documentos (podem estar em inglês – use só os relevantes e TRADUZA para português na sua resposta):\n\n${context}\n\n${userPart}`
    : `${userPart}\n\nNão há trechos relevantes. Responda em português com conhecimento geral, de forma clara e acessível.`;
  return `${SYSTEM_PROMPT}\n\n${docInstruction}`;
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
        model: GROQ_MODEL,
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 1200,
        temperature: 0.3,
      }),
    });
    if (!res.ok) throw new Error(`Groq ${res.status}`);
    const data = await res.json();
    let answer = (data.choices?.[0]?.message?.content || '').trim();
    if (!answer) throw new Error('Resposta vazia da Groq');
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
  const q = query.trim();
  if (q.length < 3) {
    return res.status(400).json({ error: 'Sua pergunta está muito curta. Digite pelo menos 3 caracteres (ex: "O que é soberania digital na AWS?").' });
  }

  if (!searchIndex || docs.length === 0) {
    return res.status(503).json({
      error: 'Índice não carregado. Verifique se a pasta docs existe e contém PDFs.',
    });
  }

  const qCtx = (typeof questionContext === 'string') ? questionContext.trim() : '';
  const preferAws = isAssessmentContext(q, qCtx);
  const hits = searchDocs(q, 8, preferAws);
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

  let answer = await askLLM(q, context, sources, qCtx || undefined);
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

/** Explicação automática da pergunta do assessment – sem precisar digitar nada */
app.post('/ask/explain-question/stream', async (req, res) => {
  const { questionContext } = req.body || {};
  const qCtx = (typeof questionContext === 'string') ? questionContext.trim() : '';
  if (!qCtx || qCtx.length < 10) {
    return res.status(400).json({ error: 'Envie { "questionContext": "texto da pergunta" }' });
  }
  if (!searchIndex || docs.length === 0) {
    return res.status(503).json({
      error: 'Índice não carregado. Verifique se a pasta docs existe e contém PDFs.',
    });
  }

  // Busca normal (sem preferAws) para obter contexto variado por pergunta
  const hits = searchDocs(qCtx, 8, false);
  const sources = hits.map(h => {
    const doc = docs.find(d => d.id === h.id) || h;
    return { title: doc.title || h.title, file: doc.file || h.file };
  });
  const context = hits
    .map(h => {
      const doc = docs.find(d => d.id === h.id) || h;
      const text = (doc.text || h.text || '').trim().slice(0, 700);
      const title = doc.title || h.title || 'Documento';
      return text ? `[Fonte: ${title}]\n\n${text}` : null;
    })
    .filter(Boolean)
    .join('\n\n---\n\n');

  const prompt = buildPrompt('', context, qCtx, true);

  res.setHeader('Content-Type', 'application/x-ndjson');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  const writeChunk = (t) => res.write(JSON.stringify({ t }) + '\n');
  const writeDone = () => {
    res.write(JSON.stringify({ t: '', done: true, sources }) + '\n');
    res.end();
  };

  const tryGroqNonStream = async () => {
    if (!GROQ_API_KEY) return null;
    const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 900,
        temperature: 0.3,
        stream: false,
      }),
    });
    if (!groqRes.ok) return null;
    const data = await groqRes.json();
    return (data.choices?.[0]?.message?.content || '').trim();
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
          model: GROQ_MODEL,
          messages: [{ role: 'user', content: prompt }],
          max_tokens: 900,
          temperature: 0.3,
          stream: true,
        }),
      });
      if (groqRes.ok && groqRes.body) {
        const reader = groqRes.body.getReader();
        const decoder = new TextDecoder();
        let buffer = '';
        let wroteAny = false;
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
                if (content) { writeChunk(content); wroteAny = true; }
              } catch (_) { }
            }
          }
        }
        if (wroteAny) {
          writeDone();
          return;
        }
      }
      // Fallback: streaming falhou ou veio vazio — tentar não-streaming
      const fallback = await tryGroqNonStream();
      if (fallback) {
        writeChunk(fallback);
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
        options: { num_predict: 600, num_ctx: 4096, temperature: 0.4 },
      }),
    });
    if (ollamaRes.ok && ollamaRes.body) {
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
      return;
    }
  } catch (err) {
    try {
      const fallback = GROQ_API_KEY ? await tryGroqNonStream() : null;
      if (fallback) {
        writeChunk(fallback);
        writeDone();
        return;
      }
    } catch (_) {}
    res.write(JSON.stringify({ t: '', done: true, err: err.message }) + '\n');
  }
  res.end();
});

// Resposta em streaming: o usuário vê o texto aparecer em tempo real (latência percebida muito menor)
app.post('/ask/stream', async (req, res) => {
  const { query, questionContext } = req.body || {};
  if (!query || typeof query !== 'string') {
    return res.status(400).json({ error: 'Envie { "query": "sua pergunta" }' });
  }
  const qStream = query.trim();
  if (qStream.length < 3) {
    return res.status(400).json({ error: 'Sua pergunta está muito curta. Digite pelo menos 3 caracteres.' });
  }
  if (!searchIndex || docs.length === 0) {
    return res.status(503).json({
      error: 'Índice não carregado. Verifique se a pasta docs existe e contém PDFs.',
    });
  }

  const qCtxStream = (typeof questionContext === 'string') ? questionContext.trim() : '';
  const preferAwsStream = isAssessmentContext(qStream, qCtxStream);
  const hits = searchDocs(qStream, 6, preferAwsStream);
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

  const prompt = buildPrompt(qStream, context, qCtxStream || undefined, false);

  res.setHeader('Content-Type', 'application/x-ndjson');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  const writeChunk = (t) => res.write(JSON.stringify({ t }) + '\n');
  const writeDone = () => {
    res.write(JSON.stringify({ t: '', done: true, sources }) + '\n');
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
          model: GROQ_MODEL,
          messages: [{ role: 'user', content: prompt }],
          max_tokens: 600,
          temperature: 0.3,
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
