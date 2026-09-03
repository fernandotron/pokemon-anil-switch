# Guía de Porting y Compilación para Nintendo Switch (.nro)
**Proyecto:** Pokémon Añil 4.0 (Pokémon Essentials v21.1 / RPG Maker XP)  
**Motor:** `mkxp-z` sobre Nintendo Switch Horizon OS (`libnx`, `devkitA64`, `SDL2`)

---

## 1. Resumen Técnico del Proyecto

- **Versión de Ruby:** Ruby 3.1.x / 3.3.0 (Pokémon Essentials v21.1 utiliza `x64-msvcrt-ruby310.dll` y `Ruby Library 3.3.0`).
- **Pila Gráfica / Audio:** `switch-sdl2`, `switch-mesa`, `switch-libvorbis`, `switch-flac`, `switch-libtheora`, `switch-freetype`, `switch-libphysfs`.
- **Llamadas Nativas a Windows:** El juego incluía plugins con llamadas a `DiscordAPI_XP.dll` mediante `MiniFFI`. Se ha implementado un bypass/stub seguro en [`preload.rb`](file:///c:/Users/Fernando/Desktop/port/preload.rb) para neutralizar llamadas DLL y evitar excepciones en Nintendo Switch.
- **Formato de Salida:** Binario ejecutable `.nro` con metadatos NACP e Icono de 256x256.

---

## 2. Archivos Creados para el Entorno Switch

1. [`switch.cross`](file:///c:/Users/Fernando/Desktop/port/switch.cross): Archivo de compilación cruzada para Meson dirigido a la arquitectura `aarch64-none-elf` (Cortex-A57 de Nintendo Switch) con librerías de `devkitPro/portlibs/switch` y `libnx`.
2. [`DevkitProSwitch.cmake`](file:///c:/Users/Fernando/Desktop/port/DevkitProSwitch.cmake): Toolchain alternativa para proyectos basados en CMake.
3. [`mkxp.switch.json`](file:///c:/Users/Fernando/Desktop/port/mkxp.switch.json): Configuración de `mkxp-z` adaptada a la consola (pantalla completa 720p/1080p, VSync activado, mapeo de Joy-Con / Switch Pro Controller, `pathCache: true` para compatibilidad case-insensitive con sistemas FAT32/exFAT).
4. [`preload.rb`](file:///c:/Users/Fernando/Desktop/port/preload.rb): Actualizado con stubs para `MiniFFI` y `Win32API`.
5. [`build_switch.sh`](file:///c:/Users/Fernando/Desktop/port/build_switch.sh): Script integral que clona `mkxp-z`, compila con Meson/Ninja, genera el `.nacp` y empaqueta el binario final `.nro` mediante `elf2nro`.
6. [`Dockerfile`](file:///c:/Users/Fernando/Desktop/port/Dockerfile): Entorno reproducible con Docker para compilar en cualquier sistema operativo sin instalar devkitPro manualmente.

---

## 3. Instrucciones de Compilación

### Opción A: Compilación Rápida con Docker (Recomendada)
Si tienes Docker instalado en tu equipo, puedes compilar todo en un único comando:

```bash
# 1. Construir la imagen y ejecutar la compilación
docker build -t pokemon-anil-switch .

# 2. Extraer el binario generado
docker run --rm -v "%cd%":/work/output pokemon-anil-switch cp /work/port.nro /work/output/
```

### Opción B: Compilación Nativa con devkitPro (Linux / WSL / MSYS2)
Asegúrate de tener instaladas las herramientas de devkitPro para Switch:

```bash
# 1. Instalar librerías de Switch
sudo dkp-pacman -S switch-sdl2 switch-mesa switch-libvorbis switch-flac switch-freetype switch-libphysfs switch-tools devkitA64

# 2. Dar permisos y ejecutar el script
chmod +x build_switch.sh
./build_switch.sh
```

---

## 4. Despliegue en la Consola (MicroSD)

> **Nota sobre el binario `.nro`:** Los ficheros `.nro` versionados en el repositorio son binarios base. El ejecutable compilado al día con todos los parches más recientes se genera automáticamente en GitHub Actions y se puede descargar desde los artefactos de CI (**PokemonAnil-Switch-NRO**).

> ⚠️ **El orden importa.** `build_and_deploy_all.js` copia el `.nro` **base** del repositorio, así que
> sobrescribe cualquier binario fresco que hubieras puesto antes. Para probar un cambio de C++
> (`mkxp-z/` o `patches/mkxp-z-switch.patch`):
>
> 1. Ejecuta `node build_and_deploy_all.js`
> 2. Copia `ARCHIVOS_PARA_SWITCH/` a la tarjeta
> 3. **Al final**, copia encima el `port.nro` del artefacto de CI
>
> Si lo haces al revés, medirás con el binario viejo y parecerá que el cambio no hizo nada. El
> despliegue escribe el mismo binario con los dos nombres (`port.nro` y `pokemon_anil.nro`) para
> que dé igual cuál abra tu lanzador; si sustituyes el de CI a mano, **sustituye los dos**.

Copia los archivos a tu tarjeta MicroSD en la siguiente ruta:

```text
sdmc:/
└── switch/
    └── pokemon_anil/
        ├── port.nro              <-- Binario generado (o descargado de CI)
        ├── pokemon_anil.nro      <-- Misma copia; algunos lanzadores abren este nombre
        ├── mkxp.json             <-- Renombrar mkxp.switch.json a mkxp.json
        ├── Game.ini              <-- Configuración del juego
        ├── preload.rb            <-- Script de compatibilidad
        ├── soundfont.sf2         <-- Banco de sonido MIDI
        ├── Data/                 <-- Mapas, Scripts.rxdata, Plugins
        ├── Audio/                <-- BGM, SE, BGS, ME
        ├── Graphics/             <-- Sprites, Tilesets, UI
        ├── Fonts/                <-- Fuentes del juego
        └── Plugins/              <-- Plugins de Essentials
```

---

## 5. Mapeo de Controles en Nintendo Switch

| Botón Switch | Función en Pokémon Essentials | Acción en Juego |
| :--- | :--- | :--- |
| **A** | Botón `C` / Enter | Confirmar / Hablar / Interactuar |
| **B** | Botón `B` / Esc / Shift | Cancelar / Retroceder / Correr |
| **X** | Botón `A` | Abrir Menú Principal |
| **Y** | Botón `X` | Usar Objeto Registrado / Mochila |
| **L / R** | Botón `Y` / `Z` | Cambiar página en menús / Pokedex |
| **ZL / ZR** | Botón `L` / `R` | Guardado Rápido / Alternar Turbo |
| **D-Pad / Stick** | Flechas de dirección | Movimiento del personaje |
| **+ (Plus)** | Start | Menú / Pausa |

---

## 6. Crear el Instalable en Menú de Inicio (.nsp Forwarder)

Para tener el icono de **Pokémon Añil** directamente en el Menú Principal (Home Menu) de la consola como un juego instalado:

### Método Web (Rápido y Recomendado)
1. Entra desde tu PC o móvil a: **[https://nsp-forwarder.n8.io](https://nsp-forwarder.n8.io)**
2. Configura los campos:
   * **NRO Path**: `/switch/pokemon_anil/port.nro`
   * **Title Name**: `Pokemon Anil`
   * **Publisher**: `Eric Lostie`
   * **Icon Image**: Selecciona el archivo `icon_switch.png` disponible en esta carpeta.
3. Haz clic en **Generate NSP** y descarga el archivo `.nsp`.
4. Instala el `.nsp` en tu consola usando **DBI**, **TinWoo**, **Tinfoil** o **Goldleaf**.

*¡Al abrirlo desde el menú de inicio, la Switch ejecutará automáticamente el juego con acceso al 100% de la memoria RAM (3.5 GB)!*
