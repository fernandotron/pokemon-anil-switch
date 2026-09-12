const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 1. Obtener la versión (por defecto v4.0.0 o pasada como argumento: node package_release.js v4.0.1)
const version = process.argv[2] || 'v4.0.0';
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
  'mkxp.switch.json'
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

// Comprimir en zip usando tar (nativo en Windows)
const updateZipName = `Pokemon_Anil_Switch_Update_${version}.zip`;
const updateZipPath = path.join(distDir, updateZipName);
if (fs.existsSync(updateZipPath)) {
  fs.unlinkSync(updateZipPath);
}

try {
  execSync(`tar -a -c -f "${updateZipPath}" -C "${updateTempDir}" .`, { stdio: 'inherit' });
  console.log(`[OK] Creado paquete de actualización: dist/${updateZipName} (${(fs.statSync(updateZipPath).size / (1024 * 1024)).toFixed(2)} MB)`);
} catch (err) {
  console.error('[ERROR] No se pudo empaquetar con tar:', err.message);
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
const releaseNotes = `## 🎮 Pokémon Añil 4.0 — Port Nintendo Switch (${version})

¡Versión oficial y optimizada de **Pokémon Añil 4.0** para **Nintendo Switch**!

### 📥 Archivos Disponibles para Descarga:
1. **👑 \`Pokemon Anil 4.0.rar\` (~767 MB):** Pack completo recomendado para nuevos jugadores. Incluye el juego entero estructurado para MicroSD, Forwarder NSP, guía de instalación y manuales en PDF.
2. **⚡ \`Pokemon_Anil_Switch_Update_${version}.zip\` (~20 MB):** Para quienes ya tienen el juego instalado. Actualiza scripts, shims y binarios NRO en segundos sin tener que descargar de nuevo gráficos y audios.
3. **🎮 \`Pokemon Anil [01ab776ba9c10000].nsp\` (~395 KB):** Acceso directo para el Menú Home que desbloquea los 3.5 GB de RAM.
4. **📚 \`MANUALES/\` (~12 MB):** Las 4 guías completas en PDF (Modo Clásico, Modo Completo, Modo Radical y Preguntas Frecuentes).

---

### ✨ Novedades y Mejoras Incluidas en ${version}:
- 🎮 **Reasignación Completa de Controles:** Menú interactivo en Controles/Opciones para mapear cualquier acción a cualquier botón físico del Joy-Con o Pro Controller, con detección en vivo y persistencia atómica en \`controls.dat\`.
- ⚡ **Arranque Instantáneo:** Reducción de más de 24.000 comprobaciones lentas a disco a menos de 300 en memoria; pantalla de carga visual con progreso.
- 🛡️ **Blindaje de Combates y Captura:** Precarga de animaciones en RAM; corregido el crasheo fatal al capturar Pokémon con objetos equipados (\`pbDisplayConfirm\`).
- 💊 **Menú Rápido de Medicina en Batalla:** Usa pociones, revivir y curaciones directamente en combate sin abrir la mochila entera, con selector de objetivo y visualización de PS/estados.
- 🎒 **Mochila a 60 FPS Fluidos:** Eliminado el lag en la mochila con equipo interactivo y corregido el cursor con MTs/MOs.
- 🌿 **Sobremundo Dinámico (VOE):** Los Pokémon salvajes visibles permanecen 25 pasos en el mapa para alcanzarlos fácilmente y aparecen con cadencia natural en parches de hierba.
- 💡 **Recordar Movimientos desde el Sumario:** Recupera ataques olvidados al estilo moderno (Gen 8/9) directamente desde los datos del Pokémon.
- 💾 **Guardado Atómico:** Protección contra apagados involuntarios (escritura en \`.tmp\` con respaldo \`.bak\`).
- 🔊 **Audio Calibrado para Switch:** +35% de volumen en BGM/ME para compensar los altavoces de la consola con balance óptimo de efectos.

---

### 📖 Instrucciones de Instalación:
- **Nuevos Jugadores:** Descomprime el juego en la raíz de tu tarjeta MicroSD para que quede en \`sdmc:/switch/pokemon_anil/\` e instala el NSP en el Menú Home con DBI, TinWoo o Tinfoil.
- **Actualizar:** Extrae \`Pokemon_Anil_Switch_Update_${version}.zip\` y copia los archivos en \`sdmc:/switch/pokemon_anil/\` reemplazando los existentes (tu partida se mantendrá al 100%).
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
