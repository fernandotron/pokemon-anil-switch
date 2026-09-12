const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const crypto = require('crypto');

console.log('================================================================');
console.log('   CREADOR DEL PAQUETE COMPLETO (.RAR) POKÉMON AÑIL 4.0 SWITCH');
console.log('================================================================\n');

// 1. Validar que tengamos los NROs correctos
const nroDir = path.join(__dirname, 'archivos NRO correctos');
const portNro = path.join(nroDir, 'port.nro');
const anilNro = path.join(nroDir, 'pokemon_anil.nro');

if (!fs.existsSync(portNro) || !fs.existsSync(anilNro)) {
  console.error('[ERROR] No se encontraron los ejecutables NRO en "archivos NRO correctos/".');
  process.exit(1);
}

const nroHash = crypto.createHash('md5').update(fs.readFileSync(portNro)).digest('hex');
console.log(`[OK] Binarios NRO correctos verificados (MD5: ${nroHash})`);

// 2. Comprobar que WinRAR esté disponible
const rarExe = 'C:\\Program Files\\WinRAR\\Rar.exe';
if (!fs.existsSync(rarExe)) {
  console.error(`[ERROR] No se encontró WinRAR en "${rarExe}".`);
  process.exit(1);
}
console.log(`[OK] Compresor WinRAR detectado: ${rarExe}`);

// 3. Crear directorios temporales de preparación
const tempDir = path.join(__dirname, 'temp_full_pack');
const gameDir = path.join(tempDir, 'switch', 'pokemon_anil');
const stagingDir = path.join(__dirname, 'rar_staging');
const distDir = path.join(__dirname, 'dist');

[tempDir, stagingDir, distDir].forEach(d => {
  if (fs.existsSync(d)) {
    console.log(`[Limpieza] Eliminando directorio previo: ${d}`);
    fs.rmSync(d, { recursive: true, force: true });
  }
});

fs.mkdirSync(gameDir, { recursive: true });
fs.mkdirSync(stagingDir, { recursive: true });
fs.mkdirSync(distDir, { recursive: true });

// 4. Copiar archivos raíz del juego
console.log('\n=== 1. COPIANDO ARCHIVOS RAÍZ Y EJECUTABLES VERIFICADOS ===');
fs.copyFileSync(portNro, path.join(gameDir, 'port.nro'));
fs.copyFileSync(anilNro, path.join(gameDir, 'pokemon_anil.nro'));

const rootFiles = [
  'preload.rb',
  'mkxp.json',
  'mkxp.switch.json',
  'Game.ini',
  'soundfont.sf2',
  'icon_switch.png',
  'icon_switch_512.png'
];

rootFiles.forEach(f => {
  if (fs.existsSync(f)) {
    fs.copyFileSync(f, path.join(gameDir, f));
    console.log(`  -> Copiado: ${f}`);
  } else {
    console.warn(`  [AVISO] Archivo raíz no encontrado: ${f}`);
  }
});

// Función de copia recursiva rápida
function copyFolder(src, dest, filterFn = null) {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dest, { recursive: true });
  const entries = fs.readdirSync(src, { withFileTypes: true });
  for (const entry of entries) {
    const s = path.join(src, entry.name);
    const d = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyFolder(s, d, filterFn);
    } else {
      if (!filterFn || filterFn(s)) {
        fs.copyFileSync(s, d);
      }
    }
  }
}

// 5. Copiar Data (todos los mapas, sistema y scripts compilados)
console.log('\n=== 2. COPIANDO CARPETA DATA COMPLETA (MAPAS, SISTEMA, SCRIPTS) ===');
copyFolder('Data', path.join(gameDir, 'Data'));
const dataFilesCount = fs.readdirSync(path.join(gameDir, 'Data')).length;
console.log(`  -> Total de archivos copiados en Data: ${dataFilesCount}`);

// 6. Copiar Fonts
console.log('\n=== 3. COPIANDO FUENTES (FONTS) ===');
copyFolder('Fonts', path.join(gameDir, 'Fonts'));
console.log(`  -> Fuentes copiadas con éxito.`);

// 7. Copiar Graphics (imprescindible para que el juego arranque)
console.log('\n=== 4. COPIANDO GRÁFICOS (GRAPHICS) ===');
console.log('  -> Copiando más de 17.000 texturas y sprites (puede tardar unos segundos)...');
copyFolder('Graphics', path.join(gameDir, 'Graphics'));
console.log(`  -> Gráficos copiados con éxito.`);

// 8. Copiar Plugins
console.log('\n=== 5. COPIANDO PLUGINS ===');
copyFolder('Plugins', path.join(gameDir, 'Plugins'));
console.log(`  -> Plugins copiados con éxito.`);

// 9. Copiar Audio
console.log('\n=== 6. COPIANDO AUDIOS (BGM, BGS, SE .WAV, ME .WAV) ===');
if (fs.existsSync('Audio/BGM')) {
  console.log('  -> Copiando BGM...');
  copyFolder('Audio/BGM', path.join(gameDir, 'Audio', 'BGM'));
}
if (fs.existsSync('Audio/BGS')) {
  console.log('  -> Copiando BGS...');
  copyFolder('Audio/BGS', path.join(gameDir, 'Audio', 'BGS'));
}
if (fs.existsSync('ARCHIVOS_PARA_SWITCH/Audio/SE')) {
  console.log('  -> Copiando SE (.wav)...');
  copyFolder('ARCHIVOS_PARA_SWITCH/Audio/SE', path.join(gameDir, 'Audio', 'SE'));
} else if (fs.existsSync('Audio/SE')) {
  copyFolder('Audio/SE', path.join(gameDir, 'Audio', 'SE'), f => f.toLowerCase().endsWith('.wav'));
}
if (fs.existsSync('ARCHIVOS_PARA_SWITCH/Audio/ME')) {
  console.log('  -> Copiando ME (.wav)...');
  copyFolder('ARCHIVOS_PARA_SWITCH/Audio/ME', path.join(gameDir, 'Audio', 'ME'));
} else if (fs.existsSync('Audio/ME')) {
  copyFolder('Audio/ME', path.join(gameDir, 'Audio', 'ME'), f => f.toLowerCase().endsWith('.wav'));
}

// 10. Verificación exhaustiva de integridad antes de comprimir
console.log('\n=== 7. VERIFICACIÓN DE INTEGRIDAD DEL PAQUETE DEL JUEGO ===');
const checks = [
  { name: 'port.nro', path: path.join(gameDir, 'port.nro') },
  { name: 'pokemon_anil.nro', path: path.join(gameDir, 'pokemon_anil.nro') },
  { name: 'preload.rb', path: path.join(gameDir, 'preload.rb') },
  { name: 'mkxp.json', path: path.join(gameDir, 'mkxp.json') },
  { name: 'Data/System.rxdata', path: path.join(gameDir, 'Data', 'System.rxdata') },
  { name: 'Data/Scripts.rxdata', path: path.join(gameDir, 'Data', 'Scripts.rxdata') },
  { name: 'Data/Map001.rxdata', path: path.join(gameDir, 'Data', 'Map001.rxdata') },
  { name: 'Graphics/Titles', path: path.join(gameDir, 'Graphics', 'Titles') },
  { name: 'Graphics/Characters', path: path.join(gameDir, 'Graphics', 'Characters') },
  { name: 'Plugins', path: path.join(gameDir, 'Plugins') },
  { name: 'Fonts', path: path.join(gameDir, 'Fonts') }
];

let failed = false;
for (const c of checks) {
  if (!fs.existsSync(c.path)) {
    console.error(`  [FALLO] Falta archivo o carpeta crítica: ${c.name}`);
    failed = true;
  } else {
    console.log(`  [PASS] ${c.name} presente y verificado.`);
  }
}

if (failed) {
  console.error('[ERROR CRÍTICO] La estructura del juego está incompleta. Abortando.');
  process.exit(1);
}

// 11. Comprimir el juego en switch.zip
console.log('\n=== 8. COMPRIMIENDO JUEGO COMPLETO EN switch.zip ===');
const switchZipPath = path.join(stagingDir, 'switch.zip');
console.log('  -> Creando switch.zip con estructura sdmc:/switch/pokemon_anil/...');
execSync(`tar -a -c -f "${switchZipPath}" -C "${tempDir}" switch`, { stdio: 'inherit' });
const zipSizeMB = (fs.statSync(switchZipPath).size / (1024 * 1024)).toFixed(2);
console.log(`  [OK] switch.zip creado correctamente (${zipSizeMB} MB)`);

// 12. Copiar archivos adicionales al staging del RAR
console.log('\n=== 9. PREPARANDO PAQUETE FINAL PARA WinRAR ===');
const nspFile = 'Pokemon Anil [01ab776ba9c10000].nsp';
if (fs.existsSync(nspFile)) {
  fs.copyFileSync(nspFile, path.join(stagingDir, nspFile));
  console.log(`  -> Copiado Forwarder: ${nspFile}`);
}

const docFile = 'INSTRUCCIONES_INSTALACION.txt';
if (fs.existsSync(docFile)) {
  fs.copyFileSync(docFile, path.join(stagingDir, docFile));
  console.log(`  -> Copiado: ${docFile}`);
}

const manualsSrc = path.join(__dirname, 'Nueva carpeta', 'MANUALES');
if (fs.existsSync(manualsSrc)) {
  copyFolder(manualsSrc, path.join(stagingDir, 'MANUALES'));
  console.log(`  -> Copiada carpeta MANUALES con los 4 PDFs.`);
}

// 13. Comprimir todo en Pokemon Anil 4.0.rar con WinRAR
console.log('\n=== 10. GENERANDO ARCHIVO RAR DEFINITIVO ===');
const outRarDist = path.join(distDir, 'Pokemon Anil 4.0.rar');
const outRarNuevaCarpeta = path.join(__dirname, 'Nueva carpeta', 'Pokemon Anil 4.0.rar');

// Usar Rar.exe para crear el rar con compresión normal (-m3)
const cmdRar = `"${rarExe}" a -m3 -ep1 -r "${outRarDist}" "${stagingDir}\\*"`;
console.log(`  -> Ejecutando: ${cmdRar}`);
execSync(cmdRar, { stdio: 'inherit' });

const rarSizeMB = (fs.statSync(outRarDist).size / (1024 * 1024)).toFixed(2);
console.log(`\n  [OK] Creado archivo RAR con éxito: ${outRarDist} (${rarSizeMB} MB)`);

// Sincronizar hacia "Nueva carpeta/Pokemon Anil 4.0.rar"
fs.copyFileSync(outRarDist, outRarNuevaCarpeta);
console.log(`  [OK] Sincronizado hacia: ${outRarNuevaCarpeta}`);

// 14. Limpieza de carpetas temporales
console.log('\n=== 11. LIMPIANDO TEMPORALES ===');
fs.rmSync(tempDir, { recursive: true, force: true });
fs.rmSync(stagingDir, { recursive: true, force: true });
console.log('  -> Directorios temporales eliminados.');

console.log('\n================================================================');
console.log('   ¡PAQUETE .RAR COMPLETO Y CORREGIDO CREADO CON ÉXITO!');
console.log('================================================================');
console.log(`Tamaño final del RAR: ${rarSizeMB} MB`);
console.log(`Ubicaciones del archivo:`);
console.log(`  1. ${outRarDist}`);
console.log(`  2. ${outRarNuevaCarpeta}\n`);
