const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const targetFile = process.argv.find(a => !a.startsWith('-') && a !== process.argv[0] && a !== process.argv[1]) || 'Data/Scripts.rxdata';
const isBaseline = process.argv.includes('--baseline');

if (!fs.existsSync(targetFile)) {
  console.error(`[ERROR] Archivo no encontrado: ${targetFile}`);
  process.exit(1);
}

const buf = fs.readFileSync(targetFile);

let streams = 0;
let totalRuby = '';

for (let i = 0; i < buf.length - 2; i++) {
  if (buf[i] === 0x78 && (buf[i + 1] === 0x9c || buf[i + 1] === 0xda || buf[i + 1] === 0x01)) {
    try {
      const inflated = zlib.inflateSync(buf.subarray(i));
      streams++;
      totalRuby += inflated.toString('utf-8');
    } catch (e) {
      // Ignorar cabeceras falsas que fallan al inflar
    }
  }
}

const totalBytes = Buffer.byteLength(totalRuby, 'utf-8');

function countOccurrences(str, pat) {
  let count = 0;
  let pos = 0;
  while ((pos = str.indexOf(pat, pos)) !== -1) {
    count++;
    pos += pat.length;
  }
  return count;
}

const metrics = [
  {
    name: 'Flujos zlib encontrados',
    actual: streams,
    expected: 437,
    type: 'exact',
    description: 'Cantidad total de scripts comprimidos en rxdata'
  },
  {
    name: 'Bytes de Ruby inflado',
    expected: 6068863,
    actual: totalBytes,
    type: 'exact',
    description: 'Tamaño total del código fuente Ruby inflado'
  },
  {
    name: 'Inyecciones de barra de arranque',
    actual: countOccurrences(totalRuby, 'Cargando motor de juego'),
    expected: 29,
    type: 'exact',
    description: 'Puntos de progreso inyectados por patch_scripts.js. Si sale MAYOR que 29, patch_scripts.js ha vuelto a ser no idempotente y está apilando una línea por ejecución sobre las secciones separadoras que no tienen un .rb en disco'
  },
  {
    name: 'Precarga de animaciones en el arranque',
    actual: countOccurrences(totalRuby, '$PokemonBattleAnimations = pbLoadBattleAnimations'),
    expected: 1,
    type: 'exact',
    description: 'Data/PkmnAnimations.rxdata DEBE precargarse en el arranque. Si sale 0, alguien ha vuelto a diferirlo: ya se intento y el commit cb20f818 tuvo que revertirlo, porque prewarm_battle hace su "||= load_data" justo despues de que pbBattleAnimationCore deje un viewport negro opaco a z=99999, y el resultado es varios segundos de pantalla negra congelada con la musica de combate sonando en la primera batalla de cada sesion'
  },
  {
    name: 'eval(script, binding)',
    actual: countOccurrences(totalRuby, 'eval(script, binding)'),
    expected: 1,
    type: 'exact',
    description: 'Ocurrencias de eval en el bucle de ejecución de scripts'
  },
  {
    name: 'PluginManager.runPlugins',
    actual: countOccurrences(totalRuby, 'PluginManager.runPlugins'),
    expected: 1,
    type: 'exact',
    description: 'Punto de entrada de inicialización de plugins'
  },
  {
    name: 'misc_scripts',
    actual: countOccurrences(totalRuby, 'misc_scripts'),
    expected: 0,
    type: 'exact',
    description: 'Scripts obsoletos de misc_scripts que no deben aparecer en Scripts.rxdata'
  },
  {
    name: 'prewarm_all',
    actual: countOccurrences(totalRuby, 'prewarm_all'),
    expected: 1,
    type: 'exact',
    description: 'Llamada conectada a SwitchAssetOptimizer.prewarm_all en arranque'
  },
  {
    name: '!$PokemonBattleAnimations.empty?',
    actual: countOccurrences(totalRuby, '!$PokemonBattleAnimations.empty?'),
    expected: 0,
    type: 'exact',
    description: 'Guarda rota de caché de animaciones que no debe aparecer en Scripts.rxdata'
  },
  {
    name: 'Data/battle_animations.dat',
    actual: countOccurrences(totalRuby, 'Data/battle_animations.dat'),
    expected: 0,
    type: 'exact',
    description: 'Fallback a archivo inexistente de animaciones de combate'
  }
];

if (isBaseline) {
  console.log(`=== Línea base de ${targetFile} ===`);
  console.log(`| Métrica | Valor actual |`);
  console.log(`|---|---|`);
  metrics.forEach(m => {
    console.log(`| ${m.name} | ${m.actual.toLocaleString()} |`);
  });
  process.exit(0);
}

console.log(`=== Verificando artefacto: ${targetFile} ===`);
let failed = 0;

for (const m of metrics) {
  let pass = false;
  if (m.type === 'exact') {
    pass = (m.actual === m.expected);
  }
  
  if (pass) {
    console.log(`[PASS] ${m.name}: ${m.actual} (esperado: ${m.expected})`);
  } else {
    console.error(`[FAIL] ${m.name}: ${m.actual} (esperado: ${m.expected}) - ${m.description}`);
    failed++;
  }
}

if (failed > 0) {
  console.error(`\n[ERROR] Verificación de artefacto fallida: ${failed} aserción(es) fallaron.`);
  process.exit(1);
} else {
  console.log(`\n[OK] Todas las aserciones (${metrics.length}) pasaron con éxito.`);
  process.exit(0);
}
