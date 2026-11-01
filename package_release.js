const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 1. Obtener la versión (por defecto v4.14 o pasada como argumento: node package_release.js v4.14)
const version = process.argv[2] || 'v4.14';
console.log(`=======================================================`);
console.log(`   EMPAQUETADOR DE RELEASE OFICIAL POKÉMON AÑIL SWITCH`);
console.log(`   Versión objetivo: ${version}`);
console.log(`=======================================================\n`);

// 2. Verificar que existan los NROs en "archivos NRO correctos"
const nroDir = path.join(__dirname, 'archivos NRO correctos');
const portNro = path.join(nroDir, 'port.nro');
const anilNro = path.join(nroDir, 'pokemon_anil.nro');

if (!fs.existsSync(portNro) || !fs.existsSync(anilNro)) {
  console.error(`[ERROR] No se encontraron los ejecutables en "${nroDir}".`);
  console.error(`Asegúrate de que 'port.nro' y 'pokemon_anil.nro' estén en esa carpeta.`);
  process.exit(1);
}
console.log(`[OK] Verificados ejecutables NRO correctos en: ${nroDir}`);

// 3. Sincronizar los NRO probados hacia la raíz
fs.copyFileSync(portNro, path.join(__dirname, 'port.nro'));
fs.copyFileSync(anilNro, path.join(__dirname, 'pokemon_anil.nro'));
console.log(`[OK] Binarios sincronizados a la raíz del proyecto.`);

// 4. Ejecutar el pipeline de validación y despliegue estándar
console.log(`\n=== EJECUTANDO VALIDACIÓN Y COMPILACIÓN (build_and_deploy_all.js) ===`);
try {
  execSync('node build_and_deploy_all.js', { stdio: 'inherit' });
} catch (e) {
  console.error(`[ERROR] Falló la compilación o validación.`);
  process.exit(1);
}

// 5. Preparar la carpeta de salida "dist"
const distDir = path.join(__dirname, 'dist');
fs.mkdirSync(distDir, { recursive: true });

// 6. Generar el paquete de Actualización Rápida (Update ZIP)
console.log(`\n=== GENERANDO PAQUETE DE ACTUALIZACIÓN RÁPIDA ===`);
const updateTempDir = path.join(distDir, 'update_temp');
if (fs.existsSync(updateTempDir)) {
  fs.rmSync(updateTempDir, { recursive: true, force: true });
}
fs.mkdirSync(path.join(updateTempDir, 'Data'), { recursive: true });

// Copiar archivos de actualización
const rootFilesToCopy = [
  'preload.rb',
  'mkxp.json',
  'mkxp.switch.json',
  'Game.ini'
];

rootFilesToCopy.forEach(f => {
  if (fs.existsSync(f)) {
    fs.copyFileSync(f, path.join(updateTempDir, f));
  }
});

// Copiar NROs probados
fs.copyFileSync(portNro, path.join(updateTempDir, 'port.nro'));
fs.copyFileSync(anilNro, path.join(updateTempDir, 'pokemon_anil.nro'));

// Copiar archivos de Data
const dataFilesToCopy = [
  'Scripts.rxdata',
  'PluginScripts.rxdata',
  'switch_assets_index.dat',
  'switch_assets_index.rb',
  'PkmnAnimations.rxdata',
  'Animations.rxdata',
  'move2anim.dat'
];

dataFilesToCopy.forEach(f => {
  const p = path.join('Data', f);
  if (fs.existsSync(p)) {
    fs.copyFileSync(p, path.join(updateTempDir, 'Data', f));
  }
});

if (fs.existsSync('Data/data_for_showdown')) {
  fs.mkdirSync(path.join(updateTempDir, 'Data', 'data_for_showdown'), { recursive: true });
  fs.readdirSync('Data/data_for_showdown').forEach(f => {
    fs.copyFileSync(path.join('Data', 'data_for_showdown', f), path.join(updateTempDir, 'Data', 'data_for_showdown', f));
  });
}

// Crear archivo de instrucciones para la actualización
const leemeUpdate = `====================================================================
ACTUALIZACIÓN RÁPIDA PARA NINTENDO SWITCH - POKÉMON AÑIL ${version}
====================================================================

¿CÓMO APLICAR ESTA ACTUALIZACIÓN?
1. Conecta tu MicroSD a tu ordenador (o usa DBI en modo MTP Responder).
2. Copia todos los archivos y carpetas de este paquete dentro de la carpeta
   de Pokémon Añil en tu tarjeta MicroSD:
   
   sdmc:/switch/pokemon_anil/

3. Acepta REEMPLAZAR TODOS los archivos existentes cuando el sistema te pregunte.
4. ¡Listo! Tu partida guardada se mantendrá al 100% y disfrutarás de todas
   las mejoras y correcciones más recientes sin volver a pasar audios ni gráficos.
====================================================================`;
fs.writeFileSync(path.join(updateTempDir, 'LEEME_INSTRUCCIONES.txt'), leemeUpdate, 'utf8');

// Comprimir en zip usando PowerShell Compress-Archive
const updateZipName = `Pokemon_Anil_Switch_Update_${version}.zip`;
const updateZipPath = path.join(distDir, updateZipName);
if (fs.existsSync(updateZipPath)) {
  fs.unlinkSync(updateZipPath);
}

try {
  const psCmd = `powershell -NoProfile -Command "Compress-Archive -Path '${updateTempDir}\\*' -DestinationPath '${updateZipPath}' -Force"`;
  execSync(psCmd, { stdio: 'inherit' });
  console.log(`[OK] Creado paquete de actualización: dist/${updateZipName} (${(fs.statSync(updateZipPath).size / (1024 * 1024)).toFixed(2)} MB)`);
} catch (err) {
  console.error('[ERROR] No se pudo empaquetar con Compress-Archive:', err.message);
}

// Limpiar temporal
fs.rmSync(updateTempDir, { recursive: true, force: true });

// 7. Verificar o enlazar el paquete completo (.rar)
const rarFuente = path.join(__dirname, 'Nueva carpeta', 'Pokemon Anil 4.0.rar');
if (fs.existsSync(rarFuente)) {
  const rarSizeMB = (fs.statSync(rarFuente).size / (1024 * 1024)).toFixed(2);
  console.log(`\n[OK] Encontrado el Pack Completo en: "${rarFuente}" (${rarSizeMB} MB)`);
}

// 8. Generar las notas de la release listas para publicar en GitHub
const releaseNotes = `## 🎮 Pokémon Añil 4.14 — Port Nintendo Switch (${version})

¡Versión oficial y optimizada de **Pokémon Añil 4.14** para **Nintendo Switch**!

### 📥 Archivos Disponibles para Descarga:
1. **👑 \`Pokemon Anil 4.0.rar\` (~800 MB):** Pack completo recomendado para nuevas instalaciones. Incluye el juego entero estructurado para MicroSD, Forwarder NSP, guía de instalación y manuales en PDF.
2. **⚡ \`Pokemon_Anil_Switch_Update_${version}.zip\` (~20 MB):** Para quienes ya tienen el juego instalado. Actualiza scripts, plugins, shims, assets index y binarios NRO en segundos sin tener que descargar de nuevo gráficos y audios.
3. **🎮 \`Pokemon Anil [01ab776ba9c10000].nsp\` (~395 KB):** Acceso directo para el Menú Home que desbloquea los 3.5 GB de RAM.
4. **📚 \`MANUALES/\` (~12 MB):** Las 4 guías completas en PDF (Modo Clásico, Modo Completo, Modo Radical y Preguntas Frecuentes).

---

### ✨ Novedades y Correcciones Incluidas en ${version}:
- 🔄 **Sincronización Oficial con Pokémon Añil v4.14:** Integrada la última versión oficial de EricLostie (v4.14 / v4.13): balance en Modo Random (STAB aumentado), compatibilidad con DLC y desactivación limpia de sistemas de IA inestables.
- 🐉 **Solución Definitiva a Combates de Jefes y Legendarios:** Corregido el bucle donde los legendarios quedaban atrapados entre 1% y 0% de vida, eliminado el crash \`NoMethodError\` al capturarlos con movimientos directos o multi-golpe, y corregido el cambio de forma de Terapagos Astral al 25% de PS.
- 🗼 **Estabilización de Torre Batalla:** Corregida la congelación de pantalla al iniciar combates (*"empieza el combate, adelante"*), guardado de récord de victorias y persistencia del pool de 39 jefes especiales entre sesiones.
- 🔍 **Solución de Búsqueda en Pokédex y Mochila:** Resuelto el cuelgue al escribir y buscar por nombre en la Pokédex y en la mochila.
- ⚡ **Optimización de Rendimiento y Cero Fugas de Memoria en Switch:**
  - Apertura instantánea del Álbum de Fotos eliminando recargas síncronas de la tarjeta microSD.
  - Modo Turbo (\`L\`) con caché en memoria evitando cientos de accesos a disco por segundo.
  - Liberación completa de texturas, ventanas y Viewports (\`Bitmap\` y \`Viewport\`) en combate, menús y sobremundo.
  - Reducción del uso de CPU en mapas grandes mediante memoización de eventos climáticos.
- 🚢 **Corrección de Eventos e Historia:** Registrado equipo para la entrenadora Celia en el S.S. Anne, selección de iniciales de Hisui y Paldea sin desfase de interruptores, y protección de transiciones tras desmayo.
- 🎮 **Controles y Experiencia de Usuario:** Menú de reasignación completa de controles en opciones de Switch, atajos y visualización adaptada a botones de Switch (A/B/X/Y).

---

### 📖 Instrucciones de Instalación:
- **Nuevos Jugadores (Nueva Instalación):**
  1. Descomprime el pack completo en la raíz de tu tarjeta MicroSD de modo que los archivos queden en \`sdmc:/switch/pokemon_anil/\`.
  2. Instala el NSP de acceso directo en el Menú Home usando DBI, TinWoo o Tinfoil (o lanza el juego desde el Homebrew Menu manteniendo pulsado \`R\` sobre cualquier juego para modo Title Override).
- **Actualizar una Instalación Existente:**
  1. Extrae \`Pokemon_Anil_Switch_Update_${version}.zip\`.
  2. Copia todo su contenido directamente en \`sdmc:/switch/pokemon_anil/\` de tu tarjeta MicroSD, aceptando sobrescribir todos los archivos cuando el sistema lo solicite.
  3. ¡Tu partida guardada se mantendrá intacta al 100%!
`;

fs.writeFileSync(path.join(distDir, 'RELEASE_NOTES.md'), releaseNotes, 'utf8');
console.log(`\n[OK] Generado borrador de notas de versión en: dist/RELEASE_NOTES.md`);

console.log(`\n=======================================================`);
console.log(`   ¡PROCESO COMPLETADO CON ÉXITO!`);
console.log(`=======================================================`);
console.log(`Archivos listos para subir a GitHub Releases:`);
console.log(`  1. dist/${updateZipName} (Actualización rápida)`);
if (fs.existsSync(rarFuente)) {
  console.log(`  2. Nueva carpeta/Pokemon Anil 4.0.rar (Juego completo)`);
}
const nspFile = path.join(__dirname, 'Nueva carpeta', 'Pokemon Anil [01ab776ba9c10000].nsp');
if (fs.existsSync(nspFile)) {
  console.log(`  3. Nueva carpeta/Pokemon Anil [01ab776ba9c10000].nsp (Acceso directo NSP)`);
}
console.log(`  4. dist/RELEASE_NOTES.md (Texto con formato para la Release)\n`);
