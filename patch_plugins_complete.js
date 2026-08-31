const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const sourceFile = fs.existsSync('Data/PluginScripts.rxdata.bak') ? 'Data/PluginScripts.rxdata.bak' : 'Data/PluginScripts.rxdata';
const buf = fs.readFileSync(sourceFile);
console.log('Reading plugins from:', sourceFile);
let pos = 2;
function readByte() { return buf[pos++]; }
function readFixnum() {
  const b = buf[pos++];
  if (b === 0) return 0;
  if (b > 0 && b <= 4) { let val = 0; for (let i = 0; i < b; i++) val |= buf[pos++] << (i * 8); return val; }
  if (b >= 5 && b <= 127) return b - 5;
  if (b >= 252) { const count = 256 - b; let val = 0; for (let i = 0; i < count; i++) val |= buf[pos++] << (i * 8); return -(~val + 1); }
  if (b >= 128) return b - 251;
  return b;
}

const symbols = [];
function readObject() {
  const t = readByte();
  if (t === 0x69) return { type: 'fixnum', val: readFixnum() };
  if (t === 0x54) return { type: 'true' };
  if (t === 0x46) return { type: 'false' };
  if (t === 0x30) return { type: 'nil' };
  if (t === 0x3a) {
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len).toString('utf-8');
    pos += len;
    symbols.push(s);
    return { type: 'sym_def', name: s };
  }
  if (t === 0x3b) {
    const idx = readFixnum();
    return { type: 'sym_ref', name: symbols[idx], idx };
  }
  if (t === 0x22) {
    const len = readFixnum();
    const s = buf.subarray(pos, pos + len);
    pos += len;
    return { type: 'raw_str', data: s };
  }
  if (t === 0x49) {
    const strObj = readObject();
    const count = readFixnum();
    const ivars = [];
    for (let i = 0; i < count; i++) {
      ivars.push([readObject(), readObject()]);
    }
    return { type: 'ivar_str', str: strObj, ivars };
  }
  if (t === 0x5b) {
    const len = readFixnum();
    const arr = [];
    for (let i = 0; i < len; i++) arr.push(readObject());
    return { type: 'array', elements: arr };
  }
  if (t === 0x7b) {
    const len = readFixnum();
    const pairs = [];
    for (let i = 0; i < len; i++) pairs.push([readObject(), readObject()]);
    return { type: 'hash', pairs };
  }
  if (t === 0x40) {
    const idx = readFixnum();
    return { type: 'obj_link', idx };
  }
  throw new Error('type ' + t + ' (' + String.fromCharCode(t) + ') at pos ' + (pos - 1));
}

const root = readObject();

function getStringValue(obj) {
  if (!obj) return '';
  if (obj.type === 'raw_str') return obj.data.toString('utf-8');
  if (obj.type === 'ivar_str') return getStringValue(obj.str);
  if (obj.type === 'sym_def' || obj.type === 'sym_ref') return obj.name;
  return '';
}

// Modify plugins in AST
root.elements.forEach(pluginNode => {
  const pluginName = getStringValue(pluginNode.elements[0]);
  const filesArray = pluginNode.elements[2];
  console.log('Detected Plugin in RXDATA:', pluginName);
  
  {
    const explicitPluginDirMap = {
      'Multi Save': 'Multi Save',
      'Visible Overworld Wild Encounters': '[VOE] - MAIN',
      '[MUI] Enhanced Pokemon UI': '[LBDSKY] [MUI_001] Enhanced Pokemon UI',
      'Type Icons in Battle': '[LBDSKY] [Plugin] Mostrar tipos en combate',
      'Marin\'s Footprints': '[LBDSKY] [Plugin] Huellas en la arena',
      '[DBK] Animated Pokémon System': '[LBDSKY] [Plugin] Pokémon Animados para DBK',
      '[MUI] Pokedex Data Page': '[LBDSKY] [MUI_002] Pokedex Data Page',
      '[DBK] Enhanced Battle UI': '[DBK_001] Enhanced Battle UI',
      'Random Pokemon & Moves + Randomizer EX (Abilities)': 'Modo Random',
      'Challenge Modes': 'Nuzlocke EX',
      'Lens of truth': 'LenteRevelacion',
      'Discord Rich Presence API': 'Discord RPC API',
      'PauseMenuDP': 'DP Pause Menu',
      'Continuos Weather Animations': 'Continuous Weather Animations',
      'BW Key Items': 'Animacion Objetos Clave',
      'Misc Scripts Añil': 'misc_scripts',
      'v21.1 Hotfixes': '[LBDSKY] v21.1 Hotfixes',
      'Modular UI Scenes': '[LBDSKY] [MUI_000] Modular UI Scenes',
      'Following Pokemon EX': '[LBDS] [Plugin] Following Pokemon EX',
      'Deluxe Battle Kit': '[DBK_000] Deluxe Battle Kit',
      'Intro Versus': '[LBDSKY] [Plugin] Intro Versus',
      'Fancy Badges': '[LBDSKY] [Plugin] Fancy Badges',
      'Tileset Rearranger': '[LBDSKY] Tileset Rearranger',
      'Marin\'s Scripting Utilities': '[LBDSKY] Marin\'s Scripting Utilities',
      'Luka\'s Scripting Utilities': '[LBDSKY] Luka\'s Scripting Utilities',
      'Lin\'s IV EV Summary Screen': '[LBDSKY] Lin\'s IV EV Summary Screen',
      'Pantalla de Título Animada': '[LBDSKY] [Plugin] Pantalla de Título Animada',
      'Advanced AI System': '[AAI] Advanced AI System',
      'Level Caps EX': 'Level Caps EX',
      'Trade Expert': 'Trade Expert',
      'Torre Batalla': 'Torre Batalla',
      'Switch and Variable Usage Report': 'Switch and Variable Usage Report',
      'DP Scripting Utilities': 'DP Scripting Utilities',
      'Marin Side Stairs': 'Side Stairs',
      'Pokerider': 'Pokerider',
      'Pokemon Essentials Game Updater': 'PokemonEssentialsGameUpdater',
      'Stream Overlay Updater': 'StreamOverlayUpdater',
      'Mover panorama': 'Mover panoramas',
      'Cable Club': 'Cable Club',
      'Monotype Challenge': 'Monotype',
      'Map Zoom': 'Map Zoom',
      'Letreros en Mapas': 'Letreros',
      'Hall de la Fama BW': 'Hall de la Fama BW',
      'Fotos del equipo': 'Fotos del equipo',
      'Export to Showdown': 'ExportToShowdown',
      '[SV] Summary Screen': '[SV] Summary Screen',
      'Chapas': 'ChapasEVs',
      'Caruban\'s Dynamic Darkness': 'Caruban\'s Dynamic Darkness',
      'Mr. Gela\'s HGSS Trainer Card Scene': 'Trainer Card Scene',
      'Box Auto-Sort': 'Box Auto-Sort',
      'Barra Dominantes/Bosses': 'Barra Dominantes',
      'Advanced Items - Field Moves': 'Advanced Items Field Moves',
      'Following Pokemon EX': '[LBDS] [Plugin] Following Pokemon EX'
    };

    function findFileInDir(dir, targetBaseName) {
      if (!fs.existsSync(dir)) return null;
      const list = fs.readdirSync(dir);
      for (const item of list) {
        const full = path.join(dir, item);
        const stat = fs.statSync(full);
        if (stat && stat.isDirectory()) {
          const res = findFileInDir(full, targetBaseName);
          if (res) return res;
        } else if (item.toLowerCase() === targetBaseName.toLowerCase()) {
          return full;
        }
      }
      return null;
    }

    const mappedDir = explicitPluginDirMap[pluginName] || pluginName;
    const pluginBaseDir = path.join('Plugins', mappedDir);

    if (pluginName.includes('Discord') || pluginName.includes('Game Updater') || pluginName.includes('Stream Overlay')) {
      console.log('Neutering incompatible plugin for Switch:', pluginName);
      filesArray.elements.forEach(fileNode => {
        const fileName = getStringValue(fileNode.elements[0]);
        console.log('  -> Neutering file:', fileName);
        const safeCode = `# Plugin ${pluginName} disabled for Switch\nmodule ${pluginName.replace(/[^a-zA-Z0-9_]/g, '')}; end\n`;
        const codeBuf = Buffer.from(safeCode, 'utf-8');
        fileNode.elements[1] = {
          type: 'ivar_str',
          str: { type: 'raw_str', data: codeBuf },
          ivars: [[{ type: 'sym_def', name: 'E' }, { type: 'true' }]]
        };
      });
      return;
    }

    // Sanitize and check all files for UTF-8 correctness and superclass mismatches
    filesArray.elements.forEach(fileNode => {
      const fileName = getStringValue(fileNode.elements[0]);
      const rawData = fileNode.elements[1] && (fileNode.elements[1].data || (fileNode.elements[1].str && fileNode.elements[1].str.data));
      if (rawData) {
        let code = '';
        try {
          code = zlib.inflateSync(rawData).toString('utf-8');
        } catch (e) {
          try {
            code = zlib.inflateSync(rawData).toString('latin1');
          } catch (e2) {
            code = rawData.toString('utf-8');
          }
        }
        
        const normFileName = fileName.replace(/\\/g, '/');
        const baseName = path.basename(normFileName);
        const diskPath = findFileInDir(pluginBaseDir, baseName);

        let readFromDisk = false;
        if (diskPath) {
          console.log(`  -> Reading fresh file from disk: ${diskPath}`);
          code = fs.readFileSync(diskPath, 'utf-8');
          readFromDisk = true;
        }

        let orig = code;
        code = code.replace(/\r\n/g, '\n');
        code = code.replace(/class\s+(GameStats|Game_Temp|PokemonSystem|PokemonBoxArrow|Rect|Color|Tone|Sprite|Bitmap|Viewport|Window|ScrollingSprite|RainbowSprite|TrailingSprite)\s*<\s*[\w:]+/g, 'class $1');
        code = code.replace(/Kernel\.exit!\s*true/g, 'puts "[Plugin exit intercepted]"');
        
        if (fileName.includes('Scene Intro') || code.includes('class Scene_Intro')) {
          console.log('  -> Using updated Scene_Intro from disk in plugin:', pluginName, fileName);
          code = code.replace(/Graphics\.transition\(0\)/g, 'Graphics.transition(10) rescue nil');
        }
        const codeBuf = Buffer.from(code, 'utf-8');
        fileNode.elements[1] = {
          type: 'ivar_str',
          str: { type: 'raw_str', data: codeBuf },
          ivars: [[{ type: 'sym_def', name: 'E' }, { type: 'true' }]]
        };
      }
    });
  }
});

// Serializer
function writeFixnum(n) {
  if (n === 0) return Buffer.from([0]);
  if (n > 0 && n < 123) return Buffer.from([n + 5]);
  if (n >= 123 && n <= 255) return Buffer.from([1, n]);
  if (n > 255 && n <= 65535) return Buffer.from([2, n & 0xff, (n >> 8) & 0xff]);
  if (n > 65535 && n <= 16777215) return Buffer.from([3, n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff]);
  return Buffer.from([4, n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >> 24) & 0xff]);
}

const outSymbols = [];
const outChunks = [Buffer.from([0x04, 0x08])];

function writeObject(obj) {
  if (obj.type === 'fixnum') {
    outChunks.push(Buffer.from([0x69]), writeFixnum(obj.val));
  } else if (obj.type === 'true') {
    outChunks.push(Buffer.from([0x54]));
  } else if (obj.type === 'false') {
    outChunks.push(Buffer.from([0x46]));
  } else if (obj.type === 'nil') {
    outChunks.push(Buffer.from([0x30]));
  } else if (obj.type === 'sym_def' || obj.type === 'sym_ref') {
    const symName = obj.name;
    const existingIdx = outSymbols.indexOf(symName);
    if (existingIdx !== -1) {
      outChunks.push(Buffer.from([0x3b]), writeFixnum(existingIdx));
    } else {
      outSymbols.push(symName);
      const strBuf = Buffer.from(symName, 'utf-8');
      outChunks.push(Buffer.from([0x3a]), writeFixnum(strBuf.length), strBuf);
    }
  } else if (obj.type === 'raw_str') {
    outChunks.push(Buffer.from([0x22]), writeFixnum(obj.data.length), obj.data);
  } else if (obj.type === 'ivar_str') {
    outChunks.push(Buffer.from([0x49]));
    writeObject(obj.str);
    outChunks.push(writeFixnum(obj.ivars.length));
    for (const [k, v] of obj.ivars) {
      writeObject(k);
      writeObject(v);
    }
  } else if (obj.type === 'obj_link') {
    outChunks.push(Buffer.from([0x40]), writeFixnum(obj.idx));
  } else if (obj.type === 'array') {
    outChunks.push(Buffer.from([0x5b]), writeFixnum(obj.elements.length));
    for (const el of obj.elements) writeObject(el);
  } else if (obj.type === 'hash') {
    outChunks.push(Buffer.from([0x7b]), writeFixnum(obj.pairs.length));
    for (const [k, v] of obj.pairs) {
      writeObject(k);
      writeObject(v);
    }
  }
}

writeObject(root);
const finalBuf = Buffer.concat(outChunks);
fs.writeFileSync('Data/PluginScripts.rxdata', finalBuf);
if (fs.existsSync('switch_release/switch/pokemon_anil/Data')) {
  fs.writeFileSync('switch_release/switch/pokemon_anil/Data/PluginScripts.rxdata', finalBuf);
}
if (fs.existsSync('release_ready/switch/pokemon_anil/Data')) {
  fs.writeFileSync('release_ready/switch/pokemon_anil/Data/PluginScripts.rxdata', finalBuf);
}
fs.mkdirSync('ARCHIVOS_PARA_SWITCH/Data', { recursive: true });
fs.writeFileSync('ARCHIVOS_PARA_SWITCH/Data/PluginScripts.rxdata', finalBuf);
console.log('Saved patched Data/PluginScripts.rxdata! Size:', finalBuf.length);
