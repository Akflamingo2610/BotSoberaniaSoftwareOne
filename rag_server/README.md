# RAG Server - Chatbot de Leis

Servidor que indexa PDFs de leis (LGPD, Marco Civil, ECA Digital, BCB, etc.) e responde perguntas via busca + IA.

## Uso local

```bash
cd rag_server
npm install
npm start
```

O servidor sobe em `http://localhost:4000`.

**PDFs:** Procura em `docs/` (dentro do rag_server) ou em `../OneDrive_1_1-26-2026/`.

**IA:** Sem `GROQ_API_KEY` usa Ollama local. Com `GROQ_API_KEY` usa Groq (nuvem).

## Deploy na nuvem (funcionar em qualquer PC)

Veja [DEPLOY.md](DEPLOY.md) para hospedar no Railway ou Render com Groq.

## Endpoints

- `GET /health` - Status e quantidade de chunks indexados
- `POST /ask` - Body: `{ "query": "sua pergunta" }`
- `POST /ask/stream` - Mesmo, com resposta em streaming

## Flutter

Configure `ragBaseUrl` em `soberania_app/lib/config.dart`. Local: `http://localhost:4000`. Produção: URL do Railway/Render.
