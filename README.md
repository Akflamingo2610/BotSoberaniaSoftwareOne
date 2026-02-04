# Bot Soberania - Software One

Bot de assessment de soberania digital AWS + chatbot RAG para consulta de leis brasileiras (LGPD, Marco Civil, ECA Digital, BCB, MP 1318).

## Estrutura

- **soberania_app/** – App Flutter (web/mobile) com questionário e chatbot
- **rag_server/** – Servidor Node.js com RAG + Ollama para consulta de leis
- **OneDrive_1_1-26-2026/** – PDFs das leis indexados pelo RAG

## Como rodar

### 1. App Flutter

```bash
cd soberania_app
flutter pub get
flutter run -d chrome
# ou: flutter run -d windows
```

### 2. Servidor RAG

Requer [Ollama](https://ollama.com) instalado com modelo (ex: `ollama run gemma3:1b`).

```bash
cd rag_server
npm install
npm start
```

O servidor sobe em `http://localhost:4000` e indexa os PDFs da pasta `OneDrive_1_1-26-2026`.

### 3. Xano

O app usa a API Xano para login, cadastro e salvamento das respostas do assessment. Configure a URL em `soberania_app/lib/config.dart`.

## Funcionalidades

- Assessment por fases (Quick Wins, Foundational, Efficient, Optimized)
- Chatbot de leis com RAG + Ollama (resposta em streaming)
- Botão "Dúvida? Consulte as leis" em cada pergunta do assessment
