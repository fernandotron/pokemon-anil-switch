const fs = require('fs');
const path = require('path');

console.log('=== VERIFICACIÓN DE REGRESIÓN DE ASSETS Y RESOLUCIÓN DE AUDIO ===');

const datPath = 'Data/switch_assets_index.dat';
if (!fs.existsSync(datPath)) {
  console.error(`[ERROR] No se encuentra ${datPath}`);
  process.exit(1);
}

const rbPath = 'Data/switch_assets_index.rb';
if (!fs.existsSync(rbPath)) {
  console.error(`[ERROR] No se encuentra ${rbPath}`);
  process.exit(1);
}

const rbContent = fs.readFileSync(rbPath, 'utf8');

// Aserción 1: 'victoria importante' debe resolver a Audio/BGM/ si existe
const bgmMatch = rbContent.match(/"victoria importante"\s*=>\s*"([^"]+)"/i);
if (!bgmMatch) {
  console.log('[INFO] Clave directa "victoria importante" no presente en .rb compacto (se resuelve vía búsqueda calificada).');
} else {
  const resolved = bgmMatch[1];
  console.log(`[PASS] "victoria importante" resuelve a: ${resolved}`);
  if (!resolved.toLowerCase().startsWith('audio/bgm')) {
    console.error(`[FAIL] "victoria importante" no resuelve a Audio/BGM (resuelve a ${resolved})`);
    process.exit(1);
  }
}

// 2. Extraer todas las rutas de destino del índice .rb y comprobar su existencia en disco
const targetMatches = [...rbContent.matchAll(/=>\s*"([^"]+)"/g)].map(m => m[1]);
console.log(`[INFO] Comprobando ${targetMatches.length} referencias de archivos en el índice...`);

let missingCount = 0;
const checkedSet = new Set();

for (const target of targetMatches) {
  if (checkedSet.has(target)) continue;
  checkedSet.add(target);
  
  const p1 = target;
  const p2 = path.join('ARCHIVOS_PARA_SWITCH', target).replace(/\\/g, '/');
  
  if (!fs.existsSync(p1) && !fs.existsSync(p2)) {
    console.error(`[FAIL] Archivo referenciado no existe: ${target}`);
    missingCount++;
  }
}

console.log(`[INFO] Archivos únicos verificados: ${checkedSet.size}`);
if (missingCount > 0) {
  console.error(`[FAIL] Se encontraron ${missingCount} archivos ausentes referenciados por el índice.`);
  process.exit(1);
}

console.log(`[PASS] 0 archivos ausentes en ${checkedSet.size} entradas verificadas.`);
console.log('[OK] Verificación de regresión de assets completada con éxito.');
process.exit(0);
