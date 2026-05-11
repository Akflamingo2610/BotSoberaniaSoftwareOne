# Deploy do RAG na nuvem (para funcionar em qualquer PC)

Para o chat funcionar quando alguém acessa o app web de qualquer lugar, o servidor RAG precisa estar hospedado na internet.

## Passo 1: Criar conta Groq (gratuita)

1. Acesse https://console.groq.com
2. Cadastre-se (email ou GitHub)
3. Vá em **API Keys** e crie uma chave
4. Guarde a chave (ex: `gsk_xxxxxxxxxxxx`)

## Passo 2: Copiar os PDFs para o RAG

Os PDFs precisam estar dentro da pasta `rag_server/docs` para o deploy.

**PowerShell** (na pasta Bot_Soberania):
```powershell
Copy-Item "OneDrive_1_1-26-2026\*.pdf" -Destination "rag_server\docs\"
```

**CMD:**
```cmd
copy OneDrive_1_1-26-2026\*.pdf rag_server\docs\
```

## Passo 3: Deploy no Railway

1. Acesse https://railway.app e faça login (GitHub)
2. **New Project** → **Deploy from GitHub repo**
3. Conecte o repositório (ou faça upload do `rag_server` como pasta raiz)
4. **Root Directory**: se o repo tem só `rag_server`, deixe vazio. Se é o repo inteiro, coloque `rag_server`
5. Em **Variables**, adicione:
   - `GROQ_API_KEY` = sua chave da Groq
   - `GROQ_MODEL` = `llama-3.3-70b-versatile` (respostas mais naturais; use `llama-3.1-8b-instant` para mais rápido)
6. Railway detecta Node.js e faz o deploy
7. Após o deploy, clique em **Settings** → **Generate Domain** para obter a URL (ex: `https://seu-rag.up.railway.app`)

## Passo 4: Atualizar o app Flutter

Em `soberania_app/lib/config.dart`, altere:

```dart
const String ragBaseUrl = 'https://SEU-PROJETO.up.railway.app';
```

(Substitua pela URL que o Railway gerou)

Depois faça rebuild e redeploy do app:

```bash
cd soberania_app
flutter build web
npx firebase deploy
```

## Alternativa: Render

1. Acesse https://render.com e faça login
2. **New** → **Web Service**
3. Conecte o repositório
4. **Root Directory**: `rag_server`
5. **Build Command**: `npm install`
6. **Start Command**: `npm start`
7. Em **Environment**, adicione `GROQ_API_KEY`
8. Deploy → use a URL gerada (ex: `https://seu-rag.onrender.com`) no `config.dart`

---

**Resumo:** Com `GROQ_API_KEY` definida, o RAG usa a Groq (nuvem) em vez do Ollama. Sem a chave, continua usando Ollama local.
