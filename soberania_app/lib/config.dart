/// URL base do backend HTTP (FastAPI).
///
/// **Produção (web/Firebase):** Railway `triumphant-trust` (default abaixo).
///
/// **Local:** rode com override, por exemplo:
/// `flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000`
const String backendBaseUrl = String.fromEnvironment(
  'BACKEND_BASE_URL',
  defaultValue: 'https://triumphant-trust-production-477b.up.railway.app',
);

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
