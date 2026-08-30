const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('=== 1. LIMPIANDO CARPETAS DE DISTRIBUCIÓN ===');
function removeDir(dirPath) {
  if (fs.existsSync(dirPath)) {
    fs.rmSync(dirPath, { recursive: true, force: true });
    console.log('Directorio eliminado:', dirPath);
  }
}

removeDir('ARCHIVOS_PARA_SWITCH');
removeDir('switch_release/switch/pokemon_anil');
removeDir('release_ready/switch/pokemon_anil');

console.log('\n=== 2. GENERANDO ÍNDICE DE ASSETS EN RAM ===');
execSync('node generate_asset_cache.js', { stdio: 'inherit' });

console.log('\n=== 3. RECONSTRUYENDO Data/Scripts.rxdata ===');
execSync('node patch_scripts.js', { stdio: 'inherit' });

console.log('\n=== 4. RECONSTRUYENDO Data/PluginScripts.rxdata ===');
execSync('node patch_plugins_complete.js', { stdio: 'inherit' });

console.log('\n=== 5. DESPLEGANDO TODOS LOS ARCHIVOS FRESCOS ===');
const now = new Date();

function copyAndTouch(src, dest) {
  const content = fs.readFileSync(src);
  fs.writeFileSync(dest, content);
  fs.utimesSync(dest, now, now);
}

function copyDir(src, dest) {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dest, { recursive: true });
  for (const item of fs.readdirSync(src)) {
    const s = path.join(src, item);
    const d = path.join(dest, item);
    if (fs.statSync(s).isDirectory()) {
      copyDir(s, d);
    } else {
      copyAndTouch(s, d);
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
  ['Scripts.rxdata', 'PluginScripts.rxdata', 'switch_assets_index.rb'].forEach(f => {
    const s = path.join('Data', f);
    if (fs.existsSync(s)) {
      copyAndTouch(s, path.join(dir, 'Data', f));
    }
  });

  // Fonts
  if (fs.existsSync('Fonts')) {
    copyDir('Fonts', path.join(dir, 'Fonts'));
  }

  // Audio BGM
  const bgmDir = path.join(dir, 'Audio', 'BGM');
  fs.mkdirSync(bgmDir, { recursive: true });
  ['Title.ogg', 'title.ogg', 'title_frlg.ogg'].forEach(f => {
    const s = path.join('Audio', 'BGM', f);
    if (fs.existsSync(s)) {
      copyAndTouch(s, path.join(bgmDir, f));
    }
  });
});

console.log('\n=== 5. VERIFICACIÓN DE ARCHIVOS EN ARCHIVOS_PARA_SWITCH ===');
function list(dir, base = '') {
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    const rel = path.join(base, f);
    const s = fs.statSync(p);
    if (s.isDirectory()) {
      list(p, rel);
    } else {
      console.log(rel.padEnd(35), (s.size + ' B').padStart(12), '  Última mod:', s.mtime.toLocaleString());
    }
  }
}
list('ARCHIVOS_PARA_SWITCH');
console.log('\n¡Todos los archivos han sido regenerados y fechados a este instante!');
