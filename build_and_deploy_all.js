const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('=== 1. VALIDACIÓN DE SINTAXIS RUBY ===');
try {
  execSync('node check_syntax.js', { stdio: 'inherit' });
  execSync('node validate_ruby.js', { stdio: 'inherit' });
} catch (e) {
  console.error('[ERROR] Falló la validación de sintaxis Ruby.');
  process.exit(1);
}

console.log('\n=== 2. CONVIRTIENDO AUDIOS (SE y ME) A PCM WAV SIN LATENCIA ===');
if (fs.existsSync('convert_audio_to_wav.js')) {
  try {
    execSync('node convert_audio_to_wav.js', { stdio: 'inherit' });
  } catch (e) {
    console.error('[ERROR] Falló el paso: convert_audio_to_wav.js');
    process.exit(1);
  }
} else {
  console.warn('[AVISO] convert_audio_to_wav.js no existe; los .wav ya estan versionados. Paso omitido.');
}

console.log('\n=== 3. GENERANDO ÍNDICE BINARIO (.dat) Y FALLBACK (.rb) DE ASSETS EN RAM ===');
try {
  execSync('node generate_asset_cache.js', { stdio: 'inherit' });
} catch (e) {
  console.error('[ERROR] Falló el paso: generate_asset_cache.js');
  process.exit(1);
}

console.log('\n=== 4. RECONSTRUYENDO Data/Scripts.rxdata CON OPTIMIZACIONES DE AUDIO ===');
try {
  execSync('node patch_scripts.js', { stdio: 'inherit' });
} catch (e) {
  console.error('[ERROR] Falló el paso: patch_scripts.js');
  process.exit(1);
}

console.log('\n=== 5. RECONSTRUYENDO Data/PluginScripts.rxdata ===');
try {
  execSync('node patch_plugins_complete.js', { stdio: 'inherit' });
} catch (e) {
  console.error('[ERROR] Falló el paso: patch_plugins_complete.js');
  process.exit(1);
}

console.log('\n=== 6. DESPLEGANDO TODOS LOS ARCHIVOS FRESCOS ===');
const now = new Date();

function copyAndTouch(src, dest) {
  const content = fs.readFileSync(src);
  fs.writeFileSync(dest, content);
  fs.utimesSync(dest, now, now);
}

function copyDir(src, dest, filterFn = null) {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dest, { recursive: true });
  for (const item of fs.readdirSync(src)) {
    const s = path.join(src, item);
    const d = path.join(dest, item);
    if (fs.statSync(s).isDirectory()) {
      copyDir(s, d, filterFn);
    } else {
      if (!filterFn || filterFn(s)) {
        copyAndTouch(s, d);
      }
    }
  }
}

const targets = [
  'ARCHIVOS_PARA_SWITCH',
  'switch_release/switch/pokemon_anil',
  'release_ready/switch/pokemon_anil'
];

targets.forEach(dir => {
  fs.mkdirSync(path.join(dir, 'Data'), { recursive: true });
  
  // Archivos raíz
  ['preload.rb', 'mkxp.json', 'mkxp.switch.json', 'Game.ini', 'pokemon_anil.nro', 'port.nro', 'soundfont.sf2', 'icon_switch.png'].forEach(f => {
    if (fs.existsSync(f)) {
      copyAndTouch(f, path.join(dir, f));
    }
  });

  // Archivos de Data
  ['Scripts.rxdata', 'PluginScripts.rxdata', 'switch_assets_index.dat', 'switch_assets_index.rb', 'PkmnAnimations.rxdata', 'Animations.rxdata', 'move2anim.dat'].forEach(f => {
    const s = path.join('Data', f);
    if (fs.existsSync(s)) {
      copyAndTouch(s, path.join(dir, 'Data', f));
    }
  });

  // Fonts
  if (fs.existsSync('Fonts')) {
    copyDir('Fonts', path.join(dir, 'Fonts'));
  }

  // Audio BGM y BGS
  console.log(`[Despliegue] Copiando audios BGM/BGS a ${dir}...`);
  if (fs.existsSync('Audio/BGM')) {
    copyDir('Audio/BGM', path.join(dir, 'Audio', 'BGM'));
  }
  if (fs.existsSync('Audio/BGS')) {
    copyDir('Audio/BGS', path.join(dir, 'Audio', 'BGS'));
  }

  // Audio SE y ME (Copiar archivos WAV para reproducción instantánea en Switch)
  console.log(`[Despliegue] Copiando audios SE/ME (.wav) a ${dir}...`);
  if (fs.existsSync('Audio/SE')) {
    copyDir('Audio/SE', path.join(dir, 'Audio', 'SE'), (f) => f.toLowerCase().endsWith('.wav'));
  }
  if (fs.existsSync('Audio/ME')) {
    copyDir('Audio/ME', path.join(dir, 'Audio', 'ME'), (f) => f.toLowerCase().endsWith('.wav'));
  }
});

console.log('\n=== 7. VERIFICACIÓN DE ARCHIVOS EN ARCHIVOS_PARA_SWITCH ===');
function list(dir, base = '') {
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    const rel = path.join(base, f);
    const s = fs.statSync(p);
    if (s.isDirectory()) {
      list(p, rel);
    } else {
      console.log(rel.padEnd(45), (s.size + ' B').padStart(12), '  Última mod:', s.mtime.toLocaleString());
    }
  }
}
list('ARCHIVOS_PARA_SWITCH');
console.log('\n¡Todos los archivos han sido optimizados, regenerados y empaquetados con éxito!');

const src = 'Data/Scripts.rxdata';
const dst = 'ARCHIVOS_PARA_SWITCH/Data/Scripts.rxdata';
if (!fs.existsSync(dst)) {
  console.error('[ERROR] ' + dst + ' no existe tras el despliegue.');
  process.exit(1);
}
if (fs.statSync(dst).mtimeMs < fs.statSync(src).mtimeMs) {
  console.error('[ERROR] ' + dst + ' es mas viejo que ' + src + '. El despliegue no ocurrio.');
  process.exit(1);
}
console.log('[OK] Despliegue verificado.');

console.log('\n=== 8. VERIFICACIÓN DEL ARTEFACTO FINAL (verify_artifact.js) ===');
try {
  execSync('node verify_artifact.js', { stdio: 'inherit' });
} catch (e) {
  console.error('[ERROR] Falló la verificación del artefacto Scripts.rxdata.');
  process.exit(1);
}
