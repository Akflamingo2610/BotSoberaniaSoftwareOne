# Bot Soberania - Software One

Bot de assessment de soberania digital AWS + chatbot RAG para consulta de leis brasileiras (LGPD, Marco Civil, ECA Digital, BCB, MP 1318).

## Estrutura

- **soberania_app/** – App Flutter (web/mobile) com questionário, resultados e chatbot
- **rag_server/** – Servidor Node.js com RAG (Ollama local ou Groq na nuvem)
- **OneDrive_1_1-26-2026/** – PDFs das leis (também copiados em `rag_server/docs` para deploy)

## Como rodar localmente

### 1. App Flutter

```bash
cd soberania_app
flutter pub get
flutter run -d chrome
# ou: flutter run -d windows
```

### 2. Servidor RAG

**Opção A – Groq (nuvem, recomendado):**
```bash
cd rag_server
set GROQ_API_KEY=sua_chave_groq
npm install
npm start
```

**Opção B – Ollama (local):**
Instale [Ollama](https://ollama.com) e rode `ollama run gemma3:1b`. Depois:
```bash
cd rag_server
npm install
npm start
```

O servidor sobe em `http://localhost:4000`. Indexa PDFs de `OneDrive_1_1-26-2026` ou `rag_server/docs`.

### 3. Xano

Configure a URL da API em `soberania_app/lib/config.dart` (`xanoBaseUrl`).

## Funcionalidades

- **Assessment** por fases (Quick Wins, Foundational, Efficient, Optimized)
- **AWS Service** exibido ao lado de cada questão (Compliance, etc.)
- **Resultados** – Após responder todas as questões: botão "Resultados" com 3 gráficos:
  - Score por Pilar (Compliance, Control, Continuity)
  - Score por Fase
  - Radar (Visão Geral)
- **Chatbot** de leis com RAG (resposta em streaming)
- **Header** nos resultados: "Fornecidos por [nome] e [email]"

## Deploy na web

### App Flutter (Firebase Hosting)

```bash
cd soberania_app
flutter build web
npx firebase deploy
```

### RAG (Railway ou Render)

Para o chat funcionar em qualquer PC, hospede o RAG na nuvem. Veja [rag_server/DEPLOY.md](rag_server/DEPLOY.md).

1. Copie os PDFs para `rag_server/docs`
2. Deploy no Railway com `GROQ_API_KEY`
3. Atualize `ragBaseUrl` em `soberania_app/lib/config.dart` com a URL do Railway
