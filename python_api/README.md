# Python API Scaffold (Xano Parity)

Esta pasta contem os Passos 2, 3, 4 e 5.3 da migracao:

- Passo 2: API FastAPI com paridade de endpoints do Xano.
- Passo 3: persistencia em banco SQL (PostgreSQL recomendado) + importador de CSV exportado do Xano.
- Passo 4: hardening basico para producao (expiracao de token, rate limit, politica de senha e configuracao por ambiente).
- Passo 5 (inicio): containerizacao local e padronizacao de ambientes para facilitar migracao para AWS.
- Passo 5.3: migrations com Alembic para versionar schema.

## Endpoints implementados

- `POST /forgot_password`
- `POST /reset_password`
- `POST /login`
- `POST /signup_company`
- `POST /assessment/resume`
- `GET /questions?phase=...`
- `GET /progress/assessment?assessment_id=...`
- `POST /assessment/save`
- `GET /health` (auxiliar)

## Observacoes importantes

- O formato de request/response foi mantido para compatibilidade com `soberania_app/lib/api/backend_api.dart`.
- Autenticacao usa bearer token persistido na tabela `auth_tokens`.
- Tokens possuem expiracao configuravel e sao invalidados quando expirados.
- Login legado por comparacao direta de senha foi desativado por seguranca. Para usuarios importados, use o fluxo `forgot_password` + `reset_password`.

## Hardening (Passo 4)

- **Expiracao de token**: o token emitido em `login`/`signup_company` inclui timestamp de expiracao.
- **Rate limit**: endpoints sensiveis (`/login`, `/forgot_password`, `/reset_password`, `/signup_company`) possuem limite de tentativas por IP/janela de tempo.
- **Politica de senha**: minimo configuravel e exigencia de pelo menos 1 letra + 1 numero.
- **CORS por ambiente**: regex de origem permitida configuravel por variavel de ambiente.
- **Health check expandido**: `/health` retorna parametros de seguranca ativos (sem segredos).

## Como rodar local

```bash
cd python_api
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Rodar com Docker (pre-migracao AWS)

Subir API + PostgreSQL com compose:

```bash
cd python_api
docker compose --env-file .env.dev up --build -d
```

Verificar status:

```bash
docker compose ps
```

Healthcheck:

```bash
curl http://localhost:8000/health
```

Parar stack:

```bash
docker compose down
```

Swagger:

- http://localhost:8000/docs

## Configurar PostgreSQL

Defina a variavel `DATABASE_URL` antes de subir a API:

```bash
set DATABASE_URL=postgresql+psycopg2://usuario:senha@localhost:5432/bot_soberania
```

Sem `DATABASE_URL`, a API usa SQLite local (`bot_soberania.db`).

## Migrations com Alembic (Passo 5.3)

Instalar dependencias e aplicar migration inicial:

```bash
cd python_api
pip install -r requirements.txt
alembic upgrade head
```

Se o banco ja possui tabelas criadas anteriormente (ex.: via `create_all`), use baseline:

```bash
alembic stamp head
```

Criar nova migration (quando alterar `app/models.py`):

```bash
alembic revision --autogenerate -m "describe_change"
alembic upgrade head
```

Ver historico atual:

```bash
alembic history
alembic current
```

## Variaveis de ambiente (seguranca)

Defina conforme seu ambiente (local, staging, producao):

```bash
set TOKEN_TTL_MINUTES=1440
set PASSWORD_MIN_LENGTH=8
set RATE_LIMIT_WINDOW_SECONDS=60
set RATE_LIMIT_MAX_ATTEMPTS=15
set ALLOWED_ORIGIN_REGEX=^https?://(localhost|127\.0\.0\.1)(:\d+)?$
set AUTO_CREATE_SCHEMA=0
```

Arquivos sugeridos:

- `.env.dev` (desenvolvimento local)
- `.env.staging` (homologacao)
- `.env.prod` (producao)
- `.env.example` (modelo sem segredo)

Observacao:

- Em `staging/producao`, use `AUTO_CREATE_SCHEMA=0` e gerencie schema via Alembic (`alembic upgrade head`).

## Importar CSVs do Xano

```bash
python scripts/import_xano_csv.py ^
  --user-csv "C:\Users\NATH\Downloads\dbo-user-696892-live.1775499714.csv" ^
  --company-csv "C:\Users\NATH\Downloads\dbo-company-708378-live.1775500435.csv" ^
  --assessment-csv "C:\Users\NATH\Downloads\dbo-assessment-709030-live.1775500678.csv" ^
  --question-csv "C:\Users\NATH\Downloads\dbo-question-709029-live.1775500313.csv" ^
  --answer-csv "C:\Users\NATH\Downloads\dbo-answer-709031-live.1775500678.csv"
```

## Estrutura adicionada no Passo 5

- `Dockerfile`
- `.dockerignore`
- `docker-compose.yml`
- `.env.dev`
- `.env.staging`
- `.env.prod`
- `.env.example`
- `alembic.ini`
- `alembic/env.py`
- `alembic/versions/0001_initial_schema.py`

## CI/CD (GitHub Actions)

Workflows adicionados:

- `.github/workflows/ci-python-api.yml`
  - roda em push/PR para `main` (escopo `python_api/**`)
  - instala dependencias
  - valida sintaxe (`compileall`)
  - smoke test de import da API
  - smoke test do handler Lambda (`scripts/lambda_smoke_test.py`)
  - smoke test de migration (`alembic upgrade head`)
  - valida build Docker e `docker compose config`

- `.github/workflows/cd-python-api.yml`
  - execucao manual (`workflow_dispatch`)
  - gera imagem Docker da API
  - gera pacote Lambda via `sam build` e valida template (`sam validate`)
  - opcionalmente publica no GHCR (`ghcr.io/<org>/<repo>/python-api`)
  - gera artifacts com metadados de deploy e build SAM

## Lambda-ready (FastAPI + Mangum)

Arquivos adicionados para execucao em AWS Lambda:

- `app/lambda_handler.py` (handler: `app.lambda_handler.handler`)
- `template.lambda.yaml` (modelo base SAM para API Gateway HTTP + Lambda)

Dependencia:

- `mangum==0.21.0`

Observacoes:

- Endpoints permanecem os mesmos; o Flutter/React nao precisa mudar contrato.
- Para ambientes Lambda, use `AUTO_CREATE_SCHEMA=0` e aplique migrations com Alembic.

Teste local de import do handler Lambda:

```bash
cd python_api
python -c "from app.lambda_handler import handler; print(type(handler).__name__)"
```

Smoke test local da invocacao Lambda em `/health`:

```bash
cd python_api
set PYTHONPATH=.
set DATABASE_URL=sqlite:///./lambda_smoke.db
set AUTO_CREATE_SCHEMA=1
python scripts/lambda_smoke_test.py
```
