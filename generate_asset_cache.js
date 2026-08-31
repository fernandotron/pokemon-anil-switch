const fs = require('fs');
const path = require('path');

console.log('[Asset Cache Generator] Building ultra-fast binary & Ruby asset index for Nintendo Switch...');

const graphicsLookup = {};
const audioLookup = {};

function scanDir(dir, isAudio = false) {
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  // Separate files and subdirs, process files prioritizing .wav over .ogg
  const files = [];
  const subdirs = [];

  for (const entry of entries) {
    if (entry.name.startsWith('.')) continue;
    const fullPath = path.join(dir, entry.name).replace(/\\/g, '/');
    if (entry.isDirectory()) {
      subdirs.push(fullPath);
    } else {
      files.push(fullPath);
    }
  }

  // Sort files so .wav comes AFTER .ogg (so .wav overwrites base keys and takes priority)
  if (isAudio) {
    files.sort((a, b) => {
      const isWavA = a.toLowerCase().endsWith('.wav') ? 1 : 0;
      const isWavB = b.toLowerCase().endsWith('.wav') ? 1 : 0;
      return isWavA - isWavB;
    });
  }

  for (const fullPath of files) {
    if (isAudio) {
      if (!fullPath.match(/\.(wav|ogg|mp3|mid|midi|wma)$/i)) {
        continue;
      }

      const isSEorME = fullPath.toLowerCase().startsWith('audio/se') || fullPath.toLowerCase().startsWith('audio/me');
      if (isSEorME && !fullPath.toLowerCase().endsWith('.wav')) {
        continue;
      }

      const cleanFull = fullPath.toLowerCase();
      const cleanNoExt = cleanFull.replace(/\.[^.]+$/, '');
      const relAudio = cleanFull.replace(/^audio\//i, '');
      const relAudioNoExt = relAudio.replace(/\.[^.]+$/, '');
      const baseWithExt = path.basename(fullPath).toLowerCase();
      const baseNoExt = baseWithExt.replace(/\.[^.]+$/, '');

      // Qualified folder keys (highest priority)
      audioLookup[cleanFull] = fullPath;
      audioLookup[cleanNoExt] = fullPath;
      audioLookup[relAudio] = fullPath;
      audioLookup[relAudioNoExt] = fullPath;

      // Base / naked keys (prevent SE/ME from overwriting BGM/BGS)
      const setBaseIfAllowed = (k, v) => {
        if (!audioLookup[k] || !audioLookup[k].toLowerCase().startsWith('audio/bgm')) {
          audioLookup[k] = v;
        }
      };

      setBaseIfAllowed(baseWithExt, fullPath);
      setBaseIfAllowed(baseNoExt, fullPath);
      setBaseIfAllowed(baseNoExt.replace(/ /g, ''), fullPath);
      setBaseIfAllowed(baseNoExt.replace(/_/g, ''), fullPath);
      setBaseIfAllowed(baseNoExt.replace(/-/g, ''), fullPath);
      setBaseIfAllowed(baseNoExt.replace(/[ _-]/g, ''), fullPath);

      if (baseNoExt.startsWith('prsfx- ') || baseNoExt.startsWith('prsfx-')) {
        const stripped = baseNoExt.replace(/^prsfx-\s*/, '');
        audioLookup['anim/' + stripped] = fullPath;
        audioLookup['audio/se/anim/' + stripped] = fullPath;
        audioLookup['audio/se/' + stripped] = fullPath;
        audioLookup['se/' + stripped] = fullPath;
        setBaseIfAllowed(stripped, fullPath);
        setBaseIfAllowed(stripped.replace(/ /g, ''), fullPath);
        setBaseIfAllowed(stripped.replace(/_/g, ''), fullPath);
        setBaseIfAllowed(stripped.replace(/-/g, ''), fullPath);
        setBaseIfAllowed(stripped.replace(/[ _-]/g, ''), fullPath);
      }

      if (cleanFull.includes('/cries/')) {
        audioLookup['cries/' + baseNoExt] = fullPath;
        audioLookup['audio/se/cries/' + baseNoExt] = fullPath;
        audioLookup['audio/cries/' + baseNoExt] = fullPath;
        audioLookup['se/cries/' + baseNoExt] = fullPath;
        setBaseIfAllowed(baseNoExt, fullPath);
      }
    } else {
      const cleanFull = fullPath.toLowerCase();
      const cleanNoExt = cleanFull.replace(/\.[^.]+$/, '');
      const baseWithExt = path.basename(fullPath).toLowerCase();
      const baseNoExt = baseWithExt.replace(/\.[^.]+$/, '');
      const relToGfx = fullPath.replace(/^Graphics\//i, '').toLowerCase();
      const relToGfxNoExt = relToGfx.replace(/\.[^.]+$/, '');

      graphicsLookup[cleanFull] = fullPath;
      graphicsLookup[cleanNoExt] = fullPath;
      graphicsLookup[relToGfx] = fullPath;
      graphicsLookup[relToGfxNoExt] = fullPath;
      graphicsLookup[baseWithExt] = fullPath;
      graphicsLookup[baseNoExt] = fullPath;
      graphicsLookup[baseNoExt.replace(/ /g, '')] = fullPath;
      graphicsLookup[baseNoExt.replace(/_/g, '')] = fullPath;
      graphicsLookup[baseNoExt.replace(/-/g, '')] = fullPath;
      graphicsLookup[baseNoExt.replace(/[ _-]/g, '')] = fullPath;

      // Map subfolder prefixes (characters/, animations/, pictures/, ui/, battlers/, etc.)
      const subMatch = relToGfx.match(/^([^\/]+)\/(.+)$/);
      if (subMatch) {
        const folder = subMatch[1];
        const subPath = subMatch[2];
        const subNoExt = subPath.replace(/\.[^.]+$/, '');
        
        graphicsLookup[subPath] = fullPath;
        graphicsLookup[subNoExt] = fullPath;
        graphicsLookup[folder + '/' + subPath] = fullPath;
        graphicsLookup[folder + '/' + subNoExt] = fullPath;
        graphicsLookup['graphics/' + folder + '/' + subPath] = fullPath;
        graphicsLookup['graphics/' + folder + '/' + subNoExt] = fullPath;
      }
    }
  }

  for (const sub of subdirs) {
    scanDir(sub, isAudio);
  }
}

// Scan Graphics and Data
['Graphics', 'Data'].forEach(d => scanDir(d, false));

// Scan Audio
['Audio'].forEach(d => scanDir(d, true));

// Add BGM Aliases
const aliases = {
  "battle trainer": "Audio/BGM/Entrenador.ogg",
  "battle wild": "Audio/BGM/Salvaje.ogg",
  "battle victory": "Audio/BGM/VictoriaSalvaje.ogg",
  "battle trainer victory": "Audio/BGM/VictoriaEntrenador.ogg",
  "battle leader": "Audio/BGM/CombateLider.ogg",
  "battle rival": "Audio/BGM/CombateRival.ogg",
  "battle champion": "Audio/BGM/BatallaCampeon.ogg",
  "battle elite four": "Audio/BGM/AltoMando.ogg",
  "trainer": "Audio/BGM/Entrenador.ogg",
  "wild": "Audio/BGM/Salvaje.ogg"
};

for (const [k, v] of Object.entries(aliases)) {
  const realFile = audioLookup[v.toLowerCase()] || audioLookup[path.basename(v).toLowerCase()] || v;
  audioLookup[k] = realFile;
  audioLookup['audio/bgm/' + k] = realFile;
  audioLookup['audio/' + k] = realFile;
}

// ==============================================================================
// 1. Generate Binary Marshal File (Data/switch_assets_index.dat) for Instant Boot
// ==============================================================================
function writeFixnum(n) {
  if (n === 0) return Buffer.from([0]);
  if (n > 0 && n < 123) return Buffer.from([n + 5]);
  if (n >= 123 && n <= 0xff) return Buffer.from([1, n & 0xff]);
  if (n > 0xff && n <= 0xffff) return Buffer.from([2, n & 0xff, (n >> 8) & 0xff]);
  if (n > 0xffff && n <= 0xffffff) return Buffer.from([3, n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff]);
  return Buffer.from([4, n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >> 24) & 0xff]);
}

function writeString(str) {
  const buf = Buffer.isBuffer(str) ? str : Buffer.from(str, 'utf-8');
  return Buffer.concat([Buffer.from([0x22]), writeFixnum(buf.length), buf]);
}

function writeHash(map) {
  const keys = Object.keys(map);
  const chunks = [Buffer.from([0x7b]), writeFixnum(keys.length)];
  for (const k of keys) {
    chunks.push(writeString(k));
    chunks.push(writeString(map[k]));
  }
  return Buffer.concat(chunks);
}

function writeArray(arr) {
  const chunks = [Buffer.from([0x5b]), writeFixnum(arr.length)];
  for (const item of arr) {
    chunks.push(item);
  }
  return Buffer.concat(chunks);
}

const gfxKeys = Object.keys(graphicsLookup);
const audioKeys = Object.keys(audioLookup);

console.log(`[Asset Cache Generator] Indexed ${gfxKeys.length} Graphics and ${audioKeys.length} Audios.`);

const gfxHashBuf = writeHash(graphicsLookup);
const audioHashBuf = writeHash(audioLookup);
const arrBuf = writeArray([gfxHashBuf, audioHashBuf]);
const finalMarshal = Buffer.concat([Buffer.from([0x04, 0x08]), arrBuf]);

fs.writeFileSync('Data/switch_assets_index.dat', finalMarshal);
console.log(`[Asset Cache Generator] Generated Data/switch_assets_index.dat (${(finalMarshal.length / 1024 / 1024).toFixed(2)} MB binary) - Boot time: ~0.05s!`);

// ==============================================================================
// 2. Generate Fallback Ruby File (Data/switch_assets_index.rb)
// ==============================================================================
let rubyCode = '# Pre-compiled Switch Assets Table\n';
rubyCode += '$GRAPHICS_LOOKUP_TABLE ||= {}\n';
rubyCode += '$AUDIO_LOOKUP_TABLE ||= {}\n';

rubyCode += `\n# Graphic Assets (${gfxKeys.length})\n`;
rubyCode += '$GRAPHICS_LOOKUP_TABLE.merge!({\n';
rubyCode += gfxKeys.map(k => `  ${JSON.stringify(k)} => ${JSON.stringify(graphicsLookup[k])}`).join(',\n');
rubyCode += '\n})\n';

rubyCode += `\n# Audio Assets (${audioKeys.length})\n`;
rubyCode += '$AUDIO_LOOKUP_TABLE.merge!({\n';
rubyCode += audioKeys.map(k => `  ${JSON.stringify(k)} => ${JSON.stringify(audioLookup[k])}`).join(',\n');
rubyCode += '\n})\n';

fs.writeFileSync('Data/switch_assets_index.rb', rubyCode, 'utf-8');
console.log(`[Asset Cache Generator] Generated Data/switch_assets_index.rb (${(rubyCode.length / 1024 / 1024).toFixed(2)} MB fallback)`);
