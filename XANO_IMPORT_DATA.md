# Importar Data.csv no Xano

## 1. Tabela de questões no Xano

A tabela `questions` deve ter estas colunas (ou equivalentes):

| Coluna Xano       | Coluna no Data.csv | Observação |
|-------------------|---------------------|------------|
| `id`              | (auto/sequencial)   | ID único   |
| `phase`           | Phase               | **Mapear** (ver abaixo) |
| `pilar`           | Pilares             | Compliance, Control, Continuity |
| `dominio`         | Dominio             | **Novo** – Soberania de Dados, etc. |
| `recommendation`  | Recommendation      | Texto da pergunta |
| `order_index`     | (Unnamed: 0 ou row) | 1, 2, 3... para ordenação |
| `aws_service`     | Associated AWS Service | Opcional |

## 2. Mapeamento da coluna Phase

O app espera os valores: `Quick_Wins`, `Foundational`, `Efficient`, `Optimized`.

No Data.csv os valores vêm como:
- `Phase 1: Quick Wins` → use **`Quick_Wins`**
- `Phase 2: Foundational` → use **`Foundational`**
- `Phase 3: Efficient` → use **`Efficient`**
- `Phase 4: Optimized` → use **`Optimized`**

Ao importar no Xano, faça essa transformação (planilha, script ou função no Xano).

## 3. Domínios no Data.csv

Exemplos de domínios que aparecem no arquivo:
- Soberania de Dados
- Soberania de Infraestrutura
- Soberania Operacional
- Continuidade e Portabilidade
- Governança e Conformidade
- Soberania Organizacional

## 4. Score / Alignment

O Data.csv usa valores numéricos (0.25, 0.5, 0.75, 1.0) na coluna Score. No app, as respostas do usuário usam textos como "25% Alinhado", "50% Alinhado", etc. O Xano deve armazenar a resposta do usuário; o CSV serve só como referência das perguntas.

## 5. Passos sugeridos

1. No Xano, apague apenas os registros da tabela `questions`.
2. Garanta que a tabela tenha a coluna `dominio` (ou equivalente).
3. Converta o Data.csv:
   - Crie a coluna `phase` com os valores mapeados (Quick_Wins etc.).
   - Confirme as colunas `pilar`, `dominio`, `recommendation`, `order_index`.
4. Importe o CSV no Xano (import/copy ou API).
5. Confira se o endpoint `/questions` retorna as questões com `dominio`.

Após isso, o app mostrará o gráfico **"Score por Domínio"** na tela de resultados.
