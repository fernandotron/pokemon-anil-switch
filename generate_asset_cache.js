const fs = require('fs');
const path = require('path');

console.log('[Asset Cache Generator] Building static asset index for Nintendo Switch (Pure Ruby)...');

const graphicsLookup = {};
const audioLookup = {};

function scanDir(dir, isAudio = false) {
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.name.startsWith('.')) continue;
    const fullPath = path.join(dir, entry.name).replace(/\\/g, '/');
    if (entry.isDirectory()) {
      scanDir(fullPath, isAudio);
    } else {
      const cleanFull = fullPath.toLowerCase();
      const cleanNoExt = cleanFull.replace(/\.[^.]+$/, '');
      const baseWithExt = path.basename(fullPath).toLowerCase();
      const baseNoExt = baseWithExt.replace(/\.[^.]+$/, '');
      
      if (isAudio) {
        audioLookup[cleanFull] = fullPath;
        audioLookup[cleanNoExt] = fullPath;
        audioLookup[baseWithExt] = fullPath;
        audioLookup[baseNoExt] = fullPath;
        audioLookup[baseNoExt.replace(/ /g, '')] = fullPath;
        audioLookup[baseNoExt.replace(/_/g, '')] = fullPath;
        audioLookup[baseNoExt.replace(/-/g, '')] = fullPath;
        audioLookup[baseNoExt.replace(/[ _-]/g, '')] = fullPath;
        
        if (baseNoExt.startsWith('prsfx- ') || baseNoExt.startsWith('prsfx-')) {
          const stripped = baseNoExt.replace(/^prsfx-\s*/, '');
          audioLookup[stripped] = fullPath;
          audioLookup['anim/' + stripped] = fullPath;
          audioLookup['audio/se/anim/' + stripped] = fullPath;
          audioLookup['audio/se/' + stripped] = fullPath;
          audioLookup[stripped.replace(/ /g, '')] = fullPath;
          audioLookup[stripped.replace(/_/g, '')] = fullPath;
          audioLookup[stripped.replace(/-/g, '')] = fullPath;
          audioLookup[stripped.replace(/[ _-]/g, '')] = fullPath;
        }
        
        if (cleanFull.includes('/cries/')) {
          audioLookup['cries/' + baseNoExt] = fullPath;
          audioLookup['audio/se/cries/' + baseNoExt] = fullPath;
          audioLookup['audio/cries/' + baseNoExt] = fullPath;
          audioLookup[baseNoExt] = fullPath;
        }
      } else {
        const relToGfx = fullPath.replace(/^Graphics\//i, '').toLowerCase();
        const relToGfxNoExt = relToGfx.replace(/\.[^.]+$/, '');
        
        graphicsLookup[cleanFull] = fullPath;
        graphicsLookup[cleanNoExt] = fullPath;
        graphicsLookup[relToGfx] = fullPath;
        graphicsLookup[relToGfxNoExt] = fullPath;
        graphicsLookup[baseWithExt] = fullPath;
        graphicsLookup[baseNoExt] = fullPath;
        
        // Also map Characters, Pictures, UI prefixes
        if (relToGfx.startsWith('characters/')) {
          const charBase = relToGfx.replace(/^characters\//, '');
          graphicsLookup[charBase] = fullPath;
          graphicsLookup[charBase.replace(/\.[^.]+$/, '')] = fullPath;
        }
      }
    }
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

// Write pure Ruby file
let rubyCode = '# Pre-compiled Switch Assets Table\n';
rubyCode += '$GRAPHICS_LOOKUP_TABLE ||= {}\n';
rubyCode += '$AUDIO_LOOKUP_TABLE ||= {}\n';

// Chunk insertions for fast VM parsing
const gfxKeys = Object.keys(graphicsLookup);
const audioKeys = Object.keys(audioLookup);

rubyCode += `\n# Graphic Assets (${gfxKeys.length})\n`;
rubyCode += '$GRAPHICS_LOOKUP_TABLE.merge!({\n';
rubyCode += gfxKeys.map(k => `  ${JSON.stringify(k)} => ${JSON.stringify(graphicsLookup[k])}`).join(',\n');
rubyCode += '\n})\n';

rubyCode += `\n# Audio Assets (${audioKeys.length})\n`;
rubyCode += '$AUDIO_LOOKUP_TABLE.merge!({\n';
rubyCode += audioKeys.map(k => `  ${JSON.stringify(k)} => ${JSON.stringify(audioLookup[k])}`).join(',\n');
rubyCode += '\n})\n';

fs.writeFileSync('Data/switch_assets_index.rb', rubyCode, 'utf-8');
console.log(`[Asset Cache Generator] Generated Data/switch_assets_index.rb (${(rubyCode.length / 1024 / 1024).toFixed(2)} MB)`);
