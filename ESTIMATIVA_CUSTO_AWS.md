# Estimativa de custo mensal – Solução na AWS (3 partes)

Cenário: **~1.000 acessos/mês**, Flutter web + backend (substituindo Xano) + RAG + IA (Bedrock).  
Preços em **USD**, região exemplo **us-east-1** (N. Virginia). Valores aproximados; consulte a [Calculadora de Preços AWS](https://calculator.aws/) para números exatos.

---

## Visão geral

| Parte | O que inclui | Faixa mensal (USD) |
|-------|----------------|---------------------|
| **1. Frontend (Flutter)** | S3 + CloudFront, arquivos estáticos | **$0 – 2** |
| **2. Backend** | Migração do Xano → API Gateway + Lambda + DynamoDB + Cognito | **$0 – 5** |
| **3. RAG + IA** | App Runner (ou ECS Fargate) + Bedrock (Llama) | **$15 – 25** |
| **Total** | | **~$15 – 32 / mês** |

---

## 1. Frontend Flutter (arquivos estáticos)

**Serviços:** S3 (armazenamento) + CloudFront (CDN + HTTPS).

| Item | Uso estimado | Custo mensal (USD) |
|------|----------------|---------------------|
| **S3** | ~50–200 MB (build web do Flutter) | ~\$0,01 – 0,50 |
| **CloudFront** | 1.000 requisições, ~3–5 GB de saída (1.000 × ~3 MB) | **Free Tier:** 1 TB saída + 10 M req → **\$0** |
| **Certificado SSL** | ACM (público) | **\$0** |

**Subtotal Parte 1:** **$0 – 2** (dentro do free tier do CloudFront costaria **$0**; fora do free tier, alguns dólares).

---

## 2. Backend (migrar Xano para AWS)

**Serviços:** API Gateway (REST ou HTTP API), Lambda, DynamoDB (ou RDS), Cognito (auth).

| Item | Uso estimado (1.000 acessos/mês) | Custo mensal (USD) |
|------|-----------------------------------|---------------------|
| **API Gateway** | ~1.000–5.000 chamadas (app + health checks) | **Free Tier (12 meses):** 1 M chamadas → **\$0** |
| **Lambda** | ~1.000–10.000 invocações (lógica de API) | **Free Tier (permanente):** 1 M req + 400k GB-s → **\$0** |
| **DynamoDB** | Poucos GB, leituras/escritas baixas | **Free Tier (permanente):** 25 GB, 25 RCU/WCU → **\$0** |
| **Cognito** | &lt; 1.000 usuários ativos/mês | **Free Tier:** 50.000 MAU → **\$0** |

**Subtotal Parte 2:** **$0 – 5** (com esse volume, tende a ficar em **$0** no free tier; acima ou sem free tier, poucos dólares).

---

## 3. RAG + IA

**Serviços:** App Runner (ou ECS Fargate) para o `rag_server` + Amazon Bedrock (Llama).

### 3.1 Servidor RAG (App Runner ou ECS Fargate)

Configuração mínima típica: **0,25 vCPU**, **0,5 GB** de RAM, 24/7.

| Serviço | Cálculo | Custo mensal (USD) |
|---------|---------|---------------------|
| **App Runner** | 0,25 vCPU × \$0,064/h × 730 h ≈ \$11,70<br>0,5 GB × \$0,007/h × 730 h ≈ \$2,56<br>+ deploy automático ≈ \$1 | **~\$15 – 16** |
| **ECS Fargate** (alternativa) | 0,25 vCPU + 0,5 GB, 730 h/mês | **~\$14 – 18** |

### 3.2 IA (Bedrock – Llama)

Cenário: **1.000 requisições/mês**, **~1.000 tokens entrada** e **~1.000 tokens saída** por requisição → **~1 M tokens entrada + 1 M tokens saída**.

| Modelo | Entrada (1 M tokens) | Saída (1 M tokens) | Custo mensal (USD) |
|--------|-----------------------|----------------------|---------------------|
| **Llama 3.1 70B** | ~\$2,65 | ~\$3,50 | **~\$6 – 7** |
| **Llama 3.1 8B** | ~\$0,30 | ~\$0,60 | **~\$1** |

**Subtotal Parte 3:**  
- **RAG (App Runner) + Bedrock 70B:** **~\$21 – 23 / mês**  
- **RAG (App Runner) + Bedrock 8B:** **~\$16 – 17 / mês**

---

## Resumo das 3 partes

| Parte | Descrição | Faixa (USD/mês) |
|-------|-----------|------------------|
| **1. Frontend** | Flutter (S3 + CloudFront) | **0 – 2** |
| **2. Backend** | API + Lambda + DynamoDB + Cognito (no lugar do Xano) | **0 – 5** |
| **3. RAG + IA** | App Runner + Bedrock (Llama 70B ou 8B) | **15 – 25** |
| **Total** | | **~15 – 32** |

- **Cenário “barato”:** frontend e backend no free tier, RAG no App Runner + Llama 8B → **~\$16 – 18 / mês**.  
- **Cenário “qualidade”:** frontend e backend no free tier, RAG no App Runner + Llama 70B → **~\$21 – 24 / mês**.

---

## Observações

- **Região:** Preços acima são para **us-east-1**. Outras regiões (ex.: **sa-east-1** – São Paulo) podem ser 10–20% mais caras.  
- **Free tier:** Conta nova tem 12 meses de free tier em vários serviços (API Gateway, etc.); Lambda e DynamoDB têm free tier permanente.  
- **Impostos:** Valores sem impostos; pode haver tributos locais.  
- **Crescimento:** Se passar de 1.000 acessos/mês, o que mais sobe é Bedrock (tokens) e, em seguida, App Runner se precisar de mais instâncias.

Use esta estimativa como base e refine na [Calculadora AWS](https://calculator.aws/) com seu uso real (requisições, tokens, armazenamento).
