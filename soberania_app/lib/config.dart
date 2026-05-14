/// URL base do backend HTTP (FastAPI).
///
/// Exemplo:
/// const backendBaseUrl = 'http://localhost:8000';
///
/// Valor principal usado pela aplicacao.
const String backendBaseUrl = 'http://localhost:8000';

/// Compatibilidade com codigo legado.
/// Manter enquanto `XanoApi` existir no app.
const String xanoBaseUrl = backendBaseUrl;

/// URL do servidor RAG (chatbot AWS + leis).
/// Para testar local: use 'http://localhost:4000' (com RAG rodando em npm start).
/// Produção: Railway

const String ragBaseUrl = //'http://localhost:4000';
    'https://botsoberaniasoftwareone-production.up.railway.app';

/// Valores de `questions.phase` no banco (API `GET /questions?phase=...`).
/// Deve coincidir com o Postgres / migrations; senao listas de perguntas ficam vazias.
const List<String> kAssessmentPhaseValues = [
  'Quick_Wins',
  'Foundational',
  'Efficient',
  'Optimized',
];
