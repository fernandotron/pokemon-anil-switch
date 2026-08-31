# AGENTS.md — Pokémon Añil para Nintendo Switch

Instrucciones permanentes para cualquier agente de código que trabaje en este repositorio.
Léelas enteras antes de tocar nada. Son cortas y todas ahorran horas.

> Este fichero lo cargan automáticamente Antigravity (v1.20.3+), Codex, Cursor, Claude Code y
> otros. Complementa a `.agents/rules/switch-workflow.md` y `.agents/skills/switch-port-verifier/`,
> que siguen siendo válidos. Si un `GEMINI.md` contradice esto, gana `GEMINI.md`.

---

## 1. Qué es este proyecto

Port de **Pokémon Añil 4.0** (fangame de RPG Maker XP + Pokémon Essentials v21.1) a
**Nintendo Switch**, usando **mkxp-z** compilado como homebrew NRO con devkitPro.

- ~152.000 líneas de Ruby en `Data/Scripts/` (357 ficheros)
- 328 ficheros de Ruby en `Plugins/` (54 plugins)
- `preload.rb` (~3.200 líneas): capa de shims de compatibilidad que mkxp-z ejecuta **antes**
  que los scripts del juego. Es donde vive casi toda la lógica del port.

---

## 2. LA REGLA QUE MÁS SE INCUMPLE

**Editar un fichero `.rb` NO cambia lo que corre en la consola.**

Los scripts viajan serializados dentro de `Data/Scripts.rxdata` y `Data/PluginScripts.rxdata`.
Todo cambio en Ruby exige regenerar y desplegar:

```bash
node check_syntax.js          # sintaxis Ruby
node validate_ruby.js         # validación
node patch_scripts.js         # -> Data/Scripts.rxdata
node patch_plugins_complete.js # -> Data/PluginScripts.rxdata
node build_and_deploy_all.js  # -> ARCHIVOS_PARA_SWITCH/
```

Si tu tarea no incluye ese paso, **está incompleta**.

### 2.1 El compilador reescribe el código

`patch_scripts.js` aplica **~110 sustituciones por expresión regular** al serializar. Algunas
**reinyectan bugs que el fuente ya tiene corregidos**.

Caso real verificado: `Data/Scripts/026_PBS data/002_MiscPBSData.rb` es correcto, pero
`patch_scripts.js` mete en su lugar una versión rota de la caché de animaciones.

**Si arreglas un `.rb` y el bug persiste, busca el patrón en `patch_scripts.js`.**

### 2.2 Verifica contra el artefacto, no contra el fuente

El `.rxdata` es la verdad. Para saber qué se ejecuta hay que inflar sus flujos zlib.

Línea base medida el 31-ago-2026 sobre `Data/Scripts.rxdata`:

| Métrica | Valor |
|---|---|
| Flujos zlib | 365 |
| Bytes de Ruby inflado | 6.021.159 |
| Secciones totales | 437 |

Cuando exista `verify_artifact.js` (issue de la fase 0.3), úsalo siempre.

---

## 3. Orden de carga: gana la última definición

```
preload.rb  →  Data/Scripts.rxdata  →  Data/PluginScripts.rxdata
```

**Un plugin puede pisar un parche puesto en `preload.rb`, y de hecho ocurre.** Dos casos
verificados:

- `Plugins/Multi Save/Multi Save.rb` pisa `Game.set_up_system` de `preload.rb`, dejando
  `SwitchAssetOptimizer.prewarm_all` como código que **nunca se ejecuta**.
- `Data/Scripts/018_Objects and windows/009_AnimatedBitmap.rb` pisa el `pbGetAnimation` de
  `preload.rb`. Parchear solo `preload.rb` no cambia nada en combate.

**Antes de parchear un método, comprueba cuántas definiciones tiene:**

```bash
grep -rn "def <nombre>" preload.rb Data/Scripts Plugins patch_scripts.js
```

Si hay más de una, parchea **la última que se evalúa**, o todas.

---

## 4. Límites: qué puedes tocar y qué no

### Puedes modificar

| Ruta | Nota |
|---|---|
| `preload.rb` | Sincroniza después con `ARCHIVOS_PARA_SWITCH/preload.rb` |
| `Data/Scripts/**/*.rb` | Requiere `node patch_scripts.js` |
| `Plugins/**/*.rb` | Requiere `node patch_plugins_complete.js` |
| `*.js` de tooling en la raíz | No viajan a la consola |
| `PBS/**` | Datos del juego |

### NO toques nunca

| Ruta | Por qué |
|---|---|
| `Data/*.rxdata`, `Data/*.dat` | **Generados.** Edítalos solo vía los scripts Node. |
| `Data/switch_assets_index.{rb,dat}` | Generado por `generate_asset_cache.js`. |
| `ARCHIVOS_PARA_SWITCH/**` | **Generado.** Si está corrupto: `git restore ARCHIVOS_PARA_SWITCH`. |
| `Data/Scripts/999_Main/999_Main.rb` | **No se embarca.** `patch_scripts.js` lo reescribe entero. Editarlo es trabajo perdido. |
| `*.nro`, `*.dll`, `*.nacp` | Binarios. Solo los regenera `build_switch.sh`. |
| `mkxp-z/` | Submódulo del motor C++. |
| `Audio/**`, `Graphics/**` | Assets. No los conviertas ni los renombres. |

### Nunca hagas esto

- **No borres `Plugins/misc_scripts/`** de `patch_plugins_complete.js`: es la única copia que
  llega a la tarjeta.
- **No quites `< Array`** de `PBAnimation` ni `PBAnimations`: el `.rxdata` usa el marcador
  Marshal `TYPE_UCLASS` y sin esa herencia la carga aborta con `dump format error`.
- **No conviertas audio ni imágenes.** Los `.wav` ya están versionados.
- **No reformatees ni "limpies" código adyacente.** El diff debe contener solo lo que pide la
  tarea.

---

## 5. Cómo se verifica aquí

**No puedes probar en la consola.** No hay emulador fiable de Horizon OS en este flujo.

Los criterios de aceptación marcados `[consola]` los ejecuta **una persona con la Switch
delante**. Si tu tarea tiene criterios `[consola]`:

1. Completa el código y la regeneración de artefactos.
2. Escribe en el Walkthrough los pasos exactos que debe seguir esa persona.
3. **Deja el issue abierto.** No lo cierres tú.

Lo que sí puedes verificar solo:

```bash
node check_syntax.js && node validate_ruby.js   # deben salir con código 0
node build_and_deploy_all.js                    # debe salir con código 0
md5sum Data/Scripts.rxdata ARCHIVOS_PARA_SWITCH/Data/Scripts.rxdata   # deben coincidir
git diff --no-index preload.rb ARCHIVOS_PARA_SWITCH/preload.rb        # salida vacía
```

---

## 6. Convenciones de Ruby en este repo

- Ruby **3.1.4** compilado para ARM64. El operador `&.` y los argumentos con nombre funcionan.
- **`rescue Exception`, no el modificador `rescue nil`**, cuando quieras ver errores de memoria:
  el modificador solo captura `StandardError` y deja escapar `NoMemoryError`.
- **Registra con `log_compat(msg)`**, no con `puts`. En Switch la salida estándar puede ir a un
  socket y bloquear.
- **Guarda todo shim con `unless method_defined?`**, y comprueba sobre el objeto correcto. Dentro
  de `class << self`, `respond_to?` mira la clase singleton: es una fuente conocida de bugs en
  este repo.
- **Alias idempotentes siempre:** `alias nuevo viejo unless method_defined?(:nuevo)`. Un alias
  sin guarda que se evalúa dos veces produce **recursión infinita**.
- **`Sprite#dispose` NO libera su `Bitmap`.** Libéralo aparte.

---

## 7. Restricciones de la plataforma

- **RAM:** un homebrew lanzado desde el álbum corre en modo applet con una fracción del heap.
  Cualquier caché sin tope es un riesgo de fatal. Presupuesta **por bytes, no por número de
  entradas**: una sola hoja de animación puede costar 16 MB.
- **microSD:** todo el I/O es **síncrono en el hilo que dibuja**. Una lectura de varios MB en
  mitad de un combate es una congelación visible.
- **Sin red, sin DLLs, sin ratón, sin hilos.** `Thread.new` está anulado en `preload.rb` y
  devuelve un objeto que descarta el bloque.
- **`Zlib` está anulado** a la identidad en `preload.rb`. No asumas que comprime.

---

## 8. Flujo de trabajo esperado

1. **Lee el issue entero**, incluido su bloque `CONTRATO PARA EL AGENTE` y su sección
   `PARA y comenta en el issue si`.
2. **Genera un Implementation Plan** antes de editar. En los issues marcados
   `agente:requiere-criterio`, **espera aprobación humana** antes de ejecutar.
3. **Usa las anclas de búsqueda (`grep`) del issue, no los números de línea.** Los números
   pueden haber cambiado; las cadenas no.
4. **Un issue, un commit temático.**
5. **Regenera y despliega** (sección 2).
6. **Walkthrough** con los pasos `[consola]` para la persona que verifica.
7. Si se cumple alguna condición de `PARA y comenta`: **para y comenta**. No improvises.

---

## 9. Contexto de la auditoría

El estado actual del port se auditó el **31-ago-2026** sobre el commit `c2e5dfd7`: 89 agentes,
11 subsistemas, consenso adversarial de 3 lentes por hallazgo. 20 hallazgos confirmados y 4
refutados.

Los issues abiertos derivan de esa auditoría y llevan su fase en el título (`Fase 0.1`,
`Fase 2.9`...). **El orden de fases es una dependencia dura, no una sugerencia:** la fase 0
arregla el hecho de que hoy los cambios no llegan a la consola.

Hipótesis ya refutadas — **no las persigas**:

- `Kernel#eval` reimplementado pierde el `self` del llamante. *(3/3 refutan)*
- La opción VSync reescribe `mkxp.json` con JSON inválido. *(3/3 refutan)*
- `RPG::Cache` no define `self.clear`. *(3/3 refutan)*
- El stub de `Thread` rompe un worker de audio. El stub es real, pero **no existe tal worker**.
  *(2/3 refutan)*
