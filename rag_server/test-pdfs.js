/**
 * Testa se os PDFs têm texto extraível.
 * Execute: node test-pdfs.js
 */
const fs = require('fs');
const path = require('path');
const pdf = require('pdf-parse');

const DOCS_DIR = path.join(__dirname, '..', 'OneDrive_1_1-26-2026');

async function test() {
  if (!fs.existsSync(DOCS_DIR)) {
    console.error('Pasta não encontrada:', DOCS_DIR);
    process.exit(1);
  }
  const files = fs.readdirSync(DOCS_DIR).filter(f => f.toLowerCase().endsWith('.pdf'));
  console.log('--- Teste de extração de texto dos PDFs ---\n');
  let totalChars = 0;
  for (const file of files) {
    try {
      const filePath = path.join(DOCS_DIR, file);
      const buffer = fs.readFileSync(filePath);
      const data = await pdf(buffer);
      const raw = (data && data.text) ? String(data.text) : '';
      const len = raw.trim().length;
      totalChars += len;
      const preview = raw.trim().slice(0, 150).replace(/\s+/g, ' ');
      const status = len > 100 ? '✓ OK (texto extraído)' : len > 0 ? '⚠ Pouco texto' : '✗ Sem texto (provavelmente escaneado)';
      console.log(`${file}`);
      console.log(`  ${status} - ${len} caracteres`);
      if (len > 0) console.log(`  Prévia: "${preview}..."`);
      console.log('');
    } catch (err) {
      console.log(`${file}: ERRO - ${err.message}\n`);
    }
  }
  console.log(`Total: ${totalChars} caracteres em ${files.length} arquivos`);
  if (totalChars > 1000) {
    console.log('\n✓ Os PDFs têm texto extraível. Reinicie o rag_server (npm start) para reindexar.');
  } else {
    console.log('\n⚠ Pouco ou nenhum texto. Os PDFs podem ainda ser imagens escaneadas.');
  }
}

test().catch(console.error);
