# Requisitos do RAG para subir na AWS

Documento com tudo que o `rag_server` precisa para rodar em **App Runner** ou **ECS Fargate** (substituindo o Railway).

---

## 1. Runtime e versão

| Requisito | Valor |
|-----------|--------|
| **Runtime** | Node.js |
| **Versão recomendada** | 18 ou 20 (Railway usa 20 via nixpacks) |
| **Porta** | A que a plataforma injetar em `PORT` (App Runner/Fargate usam 8080 ou 4000; o app usa `process.env.PORT \|\| 4000`) |

---

## 2. Dependências (package.json)

```json
{
  "dependencies": {
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "minisearch": "^7.1.0",
    "pdf-parse": "^1.1.1"
  }
}
```

**Comandos:**
- Instalação: `npm install`
- Start: `npm start` (roda `node index.js`)

---

## 3. Variáveis de ambiente

| Variável | Obrigatória | Descrição | Exemplo (produção AWS) |
|----------|-------------|-----------|------------------------|
| **PORT** | Não | Porta HTTP (App Runner/Fargate definem automaticamente) | `8080` ou `4000` |
| **GROQ_API_KEY** | Sim (se usar Groq) | Chave da API Groq | `gsk_xxxx...` |
| **GROQ_MODEL** | Não | Modelo Groq (padrão: `llama-3.3-70b-versatile`) | `llama-3.3-70b-versatile` |
| **DOCS_DIR** | Não | Pasta absoluta com os PDFs (padrão: `./docs` dentro do app) | `/app/docs` ou `./docs` |
| **OLLAMA_URL** | Não | Só para desenvolvimento local com Ollama | `http://localhost:11434` |
| **OLLAMA_MODEL** | Não | Modelo Ollama local | `gemma3:1b` |

Para **produção na AWS** você precisa no mínimo:
- **GROQ_API_KEY** (até migrar para Bedrock) **ou** no futuro: variáveis do Bedrock (região, id do modelo, etc.).
- **DOCS_DIR** só se montar os PDFs em outro caminho no container (senão use o padrão `./docs`).

---

## 4. Documentos (PDFs) – pasta `docs/`

- O RAG indexa **todos os `.pdf`** dentro da pasta configurada em `DOCS_DIR` (ou `rag_server/docs` por padrão).
- Essa pasta precisa **existir no container** no momento do start (ou o servidor loga erro e não indexa).
- Para AWS:
  - **Opção A:** Incluir os PDFs na imagem Docker (pasta `docs/` no build) — mais simples.
  - **Opção B:** Montar um volume (ECS) ou baixar os PDFs de um bucket S3 no startup — mais flexível para atualizar documentos sem novo deploy.

**Resumo:** No deploy, a pasta `docs/` (ou o caminho de `DOCS_DIR`) deve estar preenchida com os PDFs que você usa hoje no Railway.

---

## 5. Estrutura de pastas mínima no repositório/imagem

```
rag_server/
├── index.js          # Entrada do servidor
├── package.json
├── package-lock.json
├── docs/             # PDFs aqui (ou via DOCS_DIR em outro lugar)
│   └── *.pdf
├── .env.example      # (opcional) referência; não subir .env com chaves
└── (opcional) Dockerfile
```

Não é necessário `nixpacks.toml` nem `railway.json` na AWS.

---

## 6. Endpoints que o Flutter usa

- **GET** `/health` — status e quantidade de chunks indexados.
- **POST** `/ask` — body: `{ "query": "sua pergunta" }`.
- **POST** `/ask/stream` — mesmo, com resposta em streaming.

O App Runner / ECS precisam expor **uma única porta** (HTTP) onde esse servidor escuta. O Flutter usa `ragBaseUrl` em `soberania_app/lib/config.dart` (ex.: `https://xxx.us-east-1.awsapprunner.com`).

---

## 7. Docker (necessário para App Runner e ECS Fargate)

Hoje o projeto **não tem Dockerfile**. Para subir na AWS você precisa de uma imagem Docker. Exemplo mínimo:

```dockerfile
# Dockerfile (criar na raiz de rag_server)
FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY index.js ./
COPY docs/ ./docs/

EXPOSE 4000
ENV PORT=4000

CMD ["node", "index.js"]
```

- **Build:** `docker build -t soberania-rag .`
- **Run local:** `docker run -p 4000:4000 -e GROQ_API_KEY=sua_chave soberania-rag`

No App Runner você aponta para esse Dockerfile (ou para uma imagem no ECR). No ECS Fargate você usa a mesma imagem no task definition.

---

## 8. Resumo rápido para deploy na AWS

| Item | O que fazer |
|------|-------------|
| **Runtime** | Node 20 (ou 18) no Dockerfile |
| **Comando de start** | `node index.js` (ou `npm start`) |
| **Porta** | Usar `process.env.PORT` (já usado no código; definir 4000 ou 8080 no Dockerfile) |
| **Variáveis** | Definir no App Runner / ECS: `GROQ_API_KEY`, opcionalmente `GROQ_MODEL` e `DOCS_DIR` |
| **PDFs** | Garantir que `docs/` (ou `DOCS_DIR`) exista na imagem ou no volume com os PDFs |
| **Saída** | URL HTTPS do serviço → atualizar `ragBaseUrl` no Flutter `config.dart` |

Com isso você tem todos os requisitos do RAG para subir na AWS (App Runner ou ECS Fargate). Se quiser, o próximo passo é trocar Groq por Bedrock e, se desejar, ler os PDFs do S3 em vez da pasta local.
