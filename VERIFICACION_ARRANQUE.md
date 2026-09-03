# Verificación del arranque — optimización de 3-sep-2026

Guía para quien revisa y aprueba este cambio. Cada punto lleva **cómo comprobarlo**: con un comando
aquí, o como paso `[consola]` según manda `AGENTS.md` §5.

> **Estado:** auditoría adversarial pasada (8 frentes, 17 agentes, 26 defectos confirmados).
> Veredicto: *merge con reservas*. Los 6 defectos marcados para arreglar antes del merge **ya están
> corregidos** — ver §3. Ninguna cifra de tiempo de esta página está medida en hardware.

---

## ⚠️ Antes de medir nada: el `.nro`

Esto se descubrió **después** de una primera prueba en consola en la que el arranque salió igual.
Era la causa.

**Había dos binarios y ninguno se regeneraba.** `port.nro` y `pokemon_anil.nro` eran copias byte a
byte del mismo `.nro` del commit de import, y `build_and_deploy_all.js` desplegaba los dos tal cual:

- `build_switch.sh` genera **sólo** `port.nro` (su `OUTPUT_NRO`)
- CI publica **sólo** `port.nro`
- `pokemon_anil.nro` no lo generaba **nada**, pero se copiaba a la tarjeta igual

Quien lanzara `pokemon_anil.nro` ejecutaba el binario del commit de import, y **ningún cambio de C++
le llegaba jamás**, sin ningún aviso. Cualquier medición de arranque sobre ese fichero da un falso
negativo.

**Corregido en este PR:** el despliegue escribe ahora el mismo `port.nro` bajo los dos nombres, así
que da igual cuál abra el lanzador. Y si el binario que se despliega es el base del repositorio, el
script lo dice a gritos por consola en vez de callárselo.

**El orden sigue importando:** `build_and_deploy_all.js` copia el `.nro` **base**, así que
sobrescribe cualquier binario fresco puesto antes.

1. `node build_and_deploy_all.js`
2. Copiar `ARCHIVOS_PARA_SWITCH/` a la tarjeta
3. **Al final**, copiar encima el `port.nro` de CI — **con los dos nombres**

**Comprobación de 10 segundos:** el binario base pesa **exactamente 19.091.512 bytes**. Si el de la
tarjeta mide eso, es el viejo, se llame como se llame.

---

## 1. Diagnóstico

El arranque tardaba **~34 s en negro** y después encadenaba una segunda espera sin feedback.
No era un problema, eran dos:

**a) Los 34 s de negro son C++, no Ruby.** `createPathCache()` en
`mkxp-z/src/filesystem/filesystem.cpp` llama a `PHYSFS_stat` por **cada** entrada del árbol, y su
único uso es distinguir directorio de fichero. En Horizon OS ese `stat` sobre un fichero se
convierte en `fsFsGetEntryType` + `fsFsOpenFile` + `fsFileGetSize` + `fsFileClose`: 3-4 IPC al
sysmodule FS. Con 17.824 gráficos y 5.524 audios, indexar equivale a **abrir y cerrar los ~24.000
ficheros uno a uno**, en el hilo de dibujo, con la pantalla negra. Se dispara desde
`sharedstate.cpp:147`, antes de que Ruby ejecute una línea. Medido en el árbol real:
**24.663 `PHYSFS_stat` → 292**.

**b) La "segunda pantalla de carga" es un negro, no una carga.** El bloque `Main` destruía la
pantalla de arranque y *después* `Scene_Intro` pasaba varios segundos en `ModularTitleScreen.new`
construyendo bitmaps, con el televisor en negro y sin ningún indicador.

### Presupuesto de arranque (estimado, **nunca medido en hardware**)

| Fase | Antes | Después | Qué ve el jugador |
|---|---:|---:|---|
| Pantalla negra | ~34 s | ~12 s | de los 34, ~22 s eran el path cache |
| Barra de progreso | ~20 s | ~18 s | monótona de principio a fin |
| Construcción del título | ~6 s | ~6 s | **antes en negro, ahora con pantalla de carga al 92 %** |
| **Total hasta el título** | **~60 s** | **~36 s** | |

> La construcción del título **no se ha acelerado**: sigue durando lo mismo. Lo que cambia es que
> deja de ser un negro sin explicación. `ModularTitleScreen#initialize` no llama a `Graphics.update`,
> así que la barra se queda congelada al 92 % ese tramo — es lo máximo que se puede hacer sin
> reescribir esa clase.

---

## 2. Cambios aplicados

### Vía A — sin recompilar el NRO

`node build_and_deploy_all.js` y copiar `ARCHIVOS_PARA_SWITCH/`.

#### A1. La barra sobrevive a la construcción del título · **elimina ~6 s de negro**

`patch_scripts.js` (`mainFunctionDebug` y fin de `Main`), `Scene Intro.rb`, `preload.rb`.

Esta es **la "segunda pantalla de carga"** reportada. La overlay sigue viva hasta que el título está
compuesto, y la retira `pbDisposeBootOverlay`, que centraliza un descarte que antes estaba duplicado
en dos bloques (el segundo era código muerto).

Descubierto de paso: el `Graphics.transition(10)` del final de `Main` **no hacía nada**. Sin un
`Graphics.freeze` previo es un no-op (`graphics.cpp:1246`: `if (!p->frozen) return;`), así que todos
los cortes del arranque eran a negro seco.

**Verificar `[consola]`:** desde el logo hasta el título **no debe haber ni un fotograma negro**.

#### A2. La barra deja de retroceder · **4 emisores sincronizados + clamp**

`preload.rb`, `patch_scripts.js`, `006_PluginManager.rb:644`, `002_GameData.rb:289`.

La barra la alimentan **cuatro** emisores con bandas independientes. Antes: `preload.rb` subía al
22 % y el bucle de scripts reiniciaba en 5 %; la inyección se cortaba en la sección 420 de 437, así
que las últimas 17 no reportaban nada; y `PluginManager` y `GameData` calculaban su porcentaje con
constantes a mano (28 y 52) desincronizadas del resto.

Ahora los puntos inyectados se reparten **por bytes de código, no por índice** —las secciones van de
3 KB a más de 300 KB— y las cuatro bandas encajan:

```
2 → 5   preload.rb
6 → 34  scripts (29 puntos, por bytes)
35      Main: iniciando
37 → 62 PluginManager (banda anclada en 37)
64 → 72 GameData (banda anclada en 64)
74 → 86 animaciones de combate
88      configurando sistema
92      preparando título   ← se congela aquí durante ModularTitleScreen.new
100     título montado
```

Además `update_boot_progress` tiene ahora un **clamp monótono**: ignora cualquier valor menor que el
último pintado. Es la red de seguridad por si aparece un quinto emisor con banda vieja.

**Verificar `[consola]`:** la barra avanza siempre hacia delante, sin saltos atrás.

#### A3. La partida guardada ya no se deserializa dos veces · **−0,8 s**

`Plugins/Multi Save/Multi Save.rb`.

El mismo fichero de 1-4 MB se leía y deserializaba en el arranque y otra vez al abrir la pantalla de
carga. Ahora `set_up_system` deja lo leído en una global y `pbStartLoadScreen` siembra con ella su
caché. Tres guardas: hash no vacío (deja pasar las corruptas a su rama de detección), **el fichero
debe seguir existiendo en disco** (si no, una partida borrada reaparecería), y el slot debe coincidir.

**Verificar `[consola]`:** entrar y salir de «Continuar» varias veces; borrar una partida y
comprobar que **no reaparece**; con partida avanzada, que los datos mostrados sean los correctos.

#### A4. Guardas en los 17 `gsub` del `Kernel#eval` redefinido · **−0,5 s**

`preload.rb`.

Ese `eval` intercepta la evaluación de los 437 scripts y los 320 ficheros de plugin —unos 10,5 MB— y
les pasaba 17 expresiones regulares **sin ninguna guarda**, cada una recorriendo el texto entero con
Onigmo y devolviendo una copia del String aunque no hubiera coincidencia.

Cada `gsub` va ahora detrás de un `String#include?` con una subcadena que la regex **exige
obligatoriamente**. Son guardas superset: si la guarda falla, la regex tampoco podía casar.

**Revisar en el diff:** que cada guarda sea una subcadena literal presente en su propia regex.

#### A5. Se elimina el `GC.start` del arranque · **−0,6 s**

`patch_scripts.js`, final del bloque `Main`.

Un marcado completo sobre el millón y pico de objetos vivos que deja la carga, ejecutado justo antes
del título, y que **no puede liberar casi nada** porque prácticamente todo sigue referenciado. Se
mantiene el `GC.enable`.

**Verificar `[consola]`:** jugar 10-15 min y vigilar tirones nuevos o un fatal por memoria.

#### A6. PUERTA: `patch_scripts.js` vuelve a ser idempotente · **bloqueante**

**Esto no estaba en el encargo y bloqueaba todo lo demás.** Probado: una segunda ejecución
**inflaba el artefacto en 754 bytes** y rompía `verify_artifact.js`, así que el despliegue habría
fallado en cuanto alguien tocara cualquier `.rb`.

Causa: las 8 secciones separadoras (`[[ Files ]]`, `[[ Data ]]`, `[[ Scene ]]`…) no tienen un `.rb`
en disco que `syncFromDisk` reescriba, y acumulaban una línea de barra por ejecución.

**Verificar aquí:**

```bash
node patch_scripts.js && node verify_artifact.js --baseline
node patch_scripts.js && node verify_artifact.js --baseline
```

Los dos «Bytes de Ruby inflado» deben ser **idénticos**. Comprobado con y sin
`Data/Scripts.rxdata.bak`, que es el caso de CI (`*.bak` está en `.gitignore`).

#### A7. Dos guardas de regresión nuevas en el verificador

`verify_artifact.js`, de 8 a 10 aserciones.

- *Inyecciones de barra de arranque* = **29**: si sube, la idempotencia se rompió otra vez.
- *Precarga de animaciones* = **1**: impide que alguien vuelva a diferirla (ver §3).

### Vía B — requiere recompilar el NRO

Toca `patches/mkxp-z-switch.patch`. El push a `main` publica `PokemonAnil-Switch-NRO`.

#### B8. Fuera el `PHYSFS_stat` por fichero del path cache · **−18 a −22 s**

`mkxp-z/src/filesystem/filesystem.cpp`, `cacheEnumCB`. **Este es el origen de los 34 s.**

Una lista blanca de extensiones resuelve el test por nombre bajo `#ifdef __SWITCH__`, y **todo lo
que no reconoce cae al `stat` de siempre**: un directorio con un punto en el nombre se seguiría
clasificando bien. Verificado sobre el árbol real: 0 directorios con punto, 0 ficheros sin extensión,
16 extensiones distintas. La rama no-Switch queda idéntica a la original.

**Por qué no basta con `pathCache: false`:** sin caché, `FileSystem::openRead` enumera el directorio
entero en *cada* `Bitmap.new` — 1.646 entradas sólo en `Pokemon/Front`. La congelación se
trasladaría del arranque al juego.

**Limitación conocida:** la heurística es correcta para lo que se embarca, pero no se ha podido
probar con carpetas que añada el jugador a mano (`Data.bak`, `Graphics.old`…).

#### B9. Instrumentación: convertir la estimación en una medida

El paso más caro del arranque corría a ciegas. Ahora emite duración y conteos. Se añadió también un
`size()` a `BoostHash`, que no lo tenía.

**Verificar `[consola]`:** en el log, `Path cache completed in NNNN ms, N files in N directories.`
Esperado: ~24.000 ficheros y **~291 directorios**. Si el conteo de directorios sale muy por debajo,
la heurística está clasificando alguna carpeta como fichero y esa carpeta ha desaparecido del caché.

---

## 3. Correcciones tras la auditoría adversarial

La auditoría encontró 26 defectos confirmados, 6 de ellos a corregir antes del merge. Todos
corregidos. Los dos primeros eran errores míos de razonamiento, no descuidos:

### 3.1 GRAVE — se estaba revirtiendo el arreglo del commit anterior

Se había **quitado del arranque** la precarga de `PkmnAnimations.rxdata` (14,9 MB), con el argumento
de que `prewarm_battle` ya la fuerza al montar el combate. **Ese argumento estaba invertido.**

`git show cb20f818^:preload.rb` demuestra que, *antes* de ese commit, `prewarm_battle` **ya hacía**
el `||= load_data(...)` perezoso. Y el propio mensaje de `cb20f818` dice que añadió la precarga
anticipada *"eliminando por completo la congelación con pantalla negra y música en la primera
batalla contra entrenador"*. Es decir: la configuración que se citaba como prueba de que diferir era
seguro **es exactamente la que se demostró defectuosa**.

El motivo es el encuadre, no el cargador: `pbBattleAnimationCore` termina dejando un viewport negro
**opaco** a `z=99999` como último fotograma presentado, y la primera sentencia tras el `yield` es
`prewarm_battle`. La carga diferida cae justo ahí: negro total, congelado, con la música de combate
sonando.

**Corregido:** la precarga vuelve al arranque, ahora bajo la overlay viva (74 % → 86 %), con un
comentario que documenta por qué no se debe volver a quitar, y una aserción en `verify_artifact.js`
que lo impide. Se pierden ~5,5 s de la ganancia de arranque, y era el precio correcto: **los 34 s
venían del path cache en C++, no de aquí**.

### 3.2 La barra retrocedía dos veces, contradiciendo su propio comentario

`PluginManager` y `GameData` emiten su porcentaje con constantes a mano (28 y 52) que no se
actualizaron al renumerar `Main` a 37 y 64. Con `p_idx = 0` los primeros valores pintados eran
exactamente 28 y 52: **37 → 28** y **64 → 52**, en el 100 % de los arranques.

**Corregido:** las dos bandas anclan ahora en 37 y 64, y `update_boot_progress` tiene un clamp
monótono como red de seguridad.

### 3.3 Al volver al título se quedaba el mapa pegado en pantalla

Se había eliminado el `Graphics.transition(10)` del principio de `Scene_Intro#main` por ser un no-op
**en el arranque en frío**. Pero al *volver* al título desde la partida sí hay un `Graphics.freeze`
pendiente, y sin él el último fotograma del mapa se queda congelado.

**Corregido:** restaurado, con el comentario explicando por qué hace falta pese a parecer inútil.

### 3.4 El fundido revelaba el título para que la intro lo borrase de golpe

`pbDisposeBootOverlay(12)` fundía 12 fotogramas hasta el título ya terminado, y acto seguido
`@screen.intro` lo borraba con un destello blanco.
**Corregido:** `pbDisposeBootOverlay(0)`; la propia intro hace de transición.

### 3.5 Un comentario afirmaba algo falso

Decía que la barra «acompaña toda la construcción» del título. No es cierto:
`ModularTitleScreen#initialize` no llama a `Graphics.update` y la barra se congela al 92 %.
**Corregido:** el comentario ahora dice lo que de verdad pasa.

### 3.6 La partida borrada revivía

`pbStartDeleteScreen` vuelve al título sin pasar por `pbStartLoadScreen`, así que las globales del
arranque sobrevivían y la partida borrada se sembraba en la caché.
**Corregido:** se valida contra disco que el fichero siga existiendo antes de sembrar — cubre
también las rutas de borrado que no conocemos.

### Defectos confirmados que **no** bloquean

Son **preexistentes**, no los introduce este cambio: el envenenamiento del memo de animaciones, el
bucle de reintentos de 14,9 MB, el `.nro` obsoleto, y que CI no ejecute el pipeline Node (alguien
puede editar un `.rb`, no regenerar, y CI seguirá en verde).

---

## 4. Protocolo de verificación en consola `[consola]`

1. **Desplegar y *después* copiar el NRO de CI** — en ese orden (ver el aviso del principio).
2. **Cronometrar hasta el primer píxel** — antes ~34 s, objetivo ~12 s.
3. **Leer la medida real del path cache** — `Path cache completed in …` en el log. Es la única
   medición dura que produce este cambio. Comprobar que el conteo de directorios ronda 291.
4. **Vigilar la barra** — siempre hacia delante; se congela al 92 % unos segundos (es lo esperado) y
   salta a 100 %. **Sin ningún tramo en negro** hasta el título.
5. **Primer combate de la sesión** — el punto que revierte `cb20f818`. Cronometrar la pantalla negra
   con música tras la animación de entrada. Debería ser inapreciable; si no lo es, la precarga no
   está llegando.
6. **Volver al título desde la partida** — menú de pausa → Salir. Vigilar que **no** se quede el
   fotograma del mapa pegado.
7. **Cargar, guardar y borrar partida** — que los datos sean los correctos y que una partida borrada
   no reaparezca.
8. **Sesión larga (10-15 min)** y, si es posible, **en modo applet** — es donde menos heap hay y
   donde aparecería un `NoMemoryError`.

---

## 5. Hallazgos refutados — no perseguir

- **«`compile_strip` y `refresh` construyen los fotogramas dos veces» — falso.** `compile_strip`
  llama a `refresh(strip)`; con argumento no-nil, `refresh` entra en la rama `else` y sólo hace
  `@bitmaps = bitmaps`.
- **«La segunda pantalla de carga es un segundo path cache» — falso.** No hay ninguna llamada a
  `System.mount` en los 437 scripts.
- **«El soundfont de 4,1 MB bloquea el arranque» — falso.** No se lee nunca:
  `-Dshared_fluid=false` y `SDL_LoadObject` devuelve `NULL` en un NRO estático.
- **«`Game.initialize` es el paso más caro» — falso.** ~711.000 nodos y ~2,9 MB: ~1,6 s.

### Trampa que invalida experimentos anteriores

**`mkxp.switch.json` nunca lo lee el motor**: `config.cpp` abre `mkxp.json`. El despliegue copia los
dos ficheros, lo que refuerza la impresión contraria. Cualquier ajuste probado en ese fichero **no
ha tenido efecto jamás**. No se ha tocado aquí porque cambia el comportamiento del motor y merece su
propia revisión.

---

## 6. Lo que queda pendiente

| Acción | Ahorro | Riesgo | Por qué no se hizo |
|---|---:|---|---|
| Caché de ISeq en la consola | −16 s | alto | Única palanca contra los 20 s de parseo de MRI. Proyecto aparte. |
| Serializar el path cache a disco | −3 s más | medio | Llevaría el indexado a ~0,15 s. B8 captura la mayor parte con mucho menos riesgo. |
| Quitar el splash y la intro larga | −3,6 s | bajo | Arte deliberado y **visible**, no espera muerta. Decisión de producto: `SPLASH_IMAGES = []` y quitar `"intro:2"` de `Config.rb:66`. |
| `Graphics.update` dentro de `ModularTitleScreen` | barra viva | medio | Haría avanzar la barra durante los ~6 s del título en vez de congelarla al 92 %. Toca la construcción del título; sin consola es arriesgado. |
| Sombras del título construidas dos veces | −0,3 s | medio | Real: `Main Class.rb` las crea en 83/111/136/164 y las recrea en el bucle de 362. |
| Splash en C++ antes del path cache | 1.er píxel <1 s | alto | Mini-pipeline GLES2 autónomo antes de que existan `ShaderSet` y `SharedState`. |

---

## 7. Estado de la verificación local

| Comprobación | Resultado |
|---|---|
| `node build_and_deploy_all.js` | exit 0 |
| Aserciones de `verify_artifact.js` | 10 / 10 |
| Regresión de assets | 0 ausentes de 22.331 |
| Idempotencia de `patch_scripts.js` | estable con y sin `.bak` |
| Monotonía de la barra (extraída del artefacto) | 2→5→6..34→35→37..62→64..72→74→86→88→92→100 |
| md5 `Data/*.rxdata` vs `ARCHIVOS_PARA_SWITCH/` | coinciden |
| `git diff --no-index` de `preload.rb` | sin diferencias |
| `git apply --check` del parche C++ | limpio sobre submódulo pristino |
| **Compilación del NRO** | **no realizable aquí** |
| **Ejecución en consola** | **no realizable aquí** |
| **Intérprete de Ruby** | **no disponible en la máquina** |

`check_syntax.js` y `validate_ruby.js` son contadores de bloques heurísticos, no parsers: producen
falsos positivos sobre los `.rb` del motor (incluido `006_PluginManager.rb`, verificado contra la
versión intacta de `HEAD`). Que salgan verdes no prueba que el código corra.

El parche C++ se aplicó de verdad sobre el submódulo para confirmar que genera el código esperado, y
después se revirtió: `mkxp-z/` queda pristino y el cambio vive únicamente en
`patches/mkxp-z-switch.patch`, como manda `AGENTS.md`.
