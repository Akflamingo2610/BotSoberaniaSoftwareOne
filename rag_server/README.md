# RAG Server - Chatbot de Leis

Servidor que indexa os PDFs da pasta `OneDrive_1_1-26-2026` (LGPD, Marco Civil, ECA Digital, BCB, etc.) e responde perguntas via busca semântica.

## Uso

```bash
cd rag_server
npm install
npm start
```

O servidor sobe em `http://localhost:4000`.

## Endpoints

- `GET /health` - Status e quantidade de chunks indexados
- `POST /ask` - Body: `{ "query": "sua pergunta" }`

## PDFs indexados

- BCB 85 de 2021
- LEI 15.211 ECA DIGITAL
- LEI N 12.965 MARCO CIVIL
- LEI N 13.709 LGPD
- LEI N 4595 Sistema Financeiro Nacional
- MEDIDA PROVISÓRIA Nº 1.318

## Flutter

Configure `ragBaseUrl` em `lib/config.dart`. Para app web em dev: `http://localhost:4000`. Para emulador Android: use o IP da máquina, ex: `http://10.0.2.2:4000`.
