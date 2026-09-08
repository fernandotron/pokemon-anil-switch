<div align="center">

<img src="icon_switch_512.png" alt="Pokémon Añil Switch" width="180" style="border-radius: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.3);"/>

# ⚡ Pokémon Añil 4.0 — Nintendo Switch Port

**El aclamado fangame de Eric Lostie llevado a Nintendo Switch con rendimiento nativo, 60 FPS, arranque ultra rápido y mejoras exclusivas de calidad de vida.**

[![Nintendo Switch](https://img.shields.io/badge/Platform-Nintendo%20Switch-E60012?style=for-the-badge&logo=nintendoswitch&logoColor=white)](https://github.com/fernandotron/pokemon-anil-switch)
[![Motor mkxp-z](https://img.shields.io/badge/Engine-mkxp--z%20ARM64-blue?style=for-the-badge)](https://github.com/mkxp-z/mkxp-z)
[![Versión](https://img.shields.io/badge/Versión-v4.0.0%20Estable-brightgreen?style=for-the-badge)](https://github.com/fernandotron/pokemon-anil-switch/releases/latest)
[![Descargas](https://img.shields.io/badge/Descargas-GitHub%20Releases-orange?style=for-the-badge)](https://github.com/fernandotron/pokemon-anil-switch/releases/latest)

---

</div>

## 📥 Enlaces de Descarga

Todas las descargas oficiales se alojan directamente en la sección de **[GitHub Releases](https://github.com/fernandotron/pokemon-anil-switch/releases/latest)** sin límites de velocidad ni acortadores:

| Paquete | Archivo | Tamaño | Descripción | Enlace |
| :--- | :--- | :--- | :--- | :---: |
| 👑 **Pack Completo (Recomendado)** | `Pokemon Anil 4.0.rar` | **~792 MB** | **Todo incluido:** Juego completo estructurado para microSD, Forwarder NSP, guía de instalación y los 4 manuales en PDF. | [**Descargar Pack**](https://github.com/fernandotron/pokemon-anil-switch/releases/latest) |
| ⚡ **Actualización Rápida** | `Pokemon_Anil_Switch_Update_v4.0.0.zip` | **~18 MB** | **Para jugadores existentes:** Solo archivos modificados (scripts, shims, NROs corregidos). Se copia en segundos sin volver a transferir audios ni gráficos. | [**Descargar Update**](https://github.com/fernandotron/pokemon-anil-switch/releases/latest) |
| 🎮 **Forwarder NSP** | `Pokemon Anil [01ab776ba9c10000].nsp` | **~395 KB** | Acceso directo para el Menú Home de Switch. Desbloquea los **3.5 GB de memoria RAM**. | [**Descargar NSP**](https://github.com/fernandotron/pokemon-anil-switch/releases/latest) |
| 📚 **Manuales y Guías** | Carpeta `MANUALES/` | **~12 MB** | Guías oficiales: Modo Clásico, Modo Completo, Modo Radical y Preguntas Frecuentes. | [**Ver Guías**](https://github.com/fernandotron/pokemon-anil-switch/releases/latest) |

> 💡 *Para ver todas las versiones anteriores o actualizaciones intermedias, visita el [Historial de Releases](https://github.com/fernandotron/pokemon-anil-switch/releases).*

---

## ✨ Novedades y Mejoras Exclusivas en Nintendo Switch

Este port ha sido reconstruido y optimizado a bajo nivel para ofrecer una experiencia fluida e idéntica a una consola oficial:

* ⚡ **Arranque Instantáneo:** Reducción de más de 24.000 comprobaciones lentas a disco en C++ a menos de 300 lecturas en memoria. El juego arranca en segundos sin pantallas negras congeladas.
* 🛡️ **Blindaje Total en Combates:** Precarga de animaciones en memoria y captura inteligente de excepciones. Se eliminaron por completo los cuelgues o congelaciones al iniciar batallas contra entrenadores o Pokémon salvajes.
* 💡 **Recordar Movimientos desde el Menú (QoL):** Implementado el sistema moderno estilo Gen 8/9. Puedes recordar cualquier ataque olvidado directamente desde la pantalla de datos del Pokémon sin necesidad de buscar al NPC Recuerda-Movimientos.
* 💾 **Guardado Atómico Anti-Corrupción:** Guardado protegido en dos pasos con archivos `.tmp` y respaldos `.bak`. Tu partida nunca se corromperá aunque la consola se apague en mitad de un guardado.
* 🧠 **Gestión Avanzada de RAM y Texturas:** Tablas de búsqueda aceleradas en RAM para más de 115.000 gráficos y 35.000 audios. Caché inteligente de texturas con límite estricto para evitar errores *Out of Memory*.
* 🎮 **Soporte Nativo de Mandos:** Control ergonómico para Joy-Con y Switch Pro Controller, con modo Turbo, Quick Save y salida rápida de menús.

---

## 🎮 Controles en Nintendo Switch

| Botón Switch | Función en el Juego |
| :---: | :--- |
| **(A)** | **Aceptar / Hablar / Interactuar / Seleccionar** |
| **(B)** | **Cancelar / Retroceder / Correr** *(Doble toque rápido para salir de menús)* |
| **(X)** | **Abrir Menú Principal** |
| **(Y)** | **Usar Objeto Registrado / Abrir Mochila** |
| **(L) / (R)** | **Cambiar de pestaña en menús, Cajas del PC y Pokédex** |
| **(ZL)** | **Guardado Rápido (Quick Save)** |
| **(ZR)** | **Alternar Modo Turbo** *(Acelera la velocidad del juego y batallas)* |
| **D-Pad / Sticks** | **Movimiento en 4 y 8 direcciones** |
| **(+) Plus** | **Pausa / Salir** |

---

## 📖 Guía de Instalación

### Método 1: Instalación Nueva (Jugadores Primerizos)

1. **Descarga el archivo** `Pokemon Anil 4.0.rar` desde [GitHub Releases](https://github.com/fernandotron/pokemon-anil-switch/releases/latest).
2. **Descomprime el archivo** en tu PC. Encontrarás:
   * `switch.zip` (el juego para Switch).
   * `Pokemon Anil [01ab776ba9c10000].nsp` (el acceso directo para el Menú Home).
   * `INSTRUCCIONES_INSTALACION.txt` y carpeta `MANUALES/`.
3. **Copia los archivos a la MicroSD:**
   * Conecta tu MicroSD al PC (o conecta la Switch con DBI en modo *MTP Responder*).
   * Descomprime `switch.zip` en la **raíz de la MicroSD**. La ruta debe quedar exactamente:
     ```text
     sdmc:/switch/pokemon_anil/
     ├── port.nro
     ├── pokemon_anil.nro
     ├── preload.rb
     ├── mkxp.json
     ├── Audio/
     ├── Data/
     ├── Fonts/
     └── Graphics/
     ```
4. **Instala el Forwarder NSP:**
   * Instala `Pokemon Anil [01ab776ba9c10000].nsp` mediante **DBI**, **TinWoo** o **Tinfoil**.
   * *(Recomendado: El NSP permite jugar con los 3.5 GB de RAM del sistema en lugar de la memoria reducida del álbum).*
5. **¡A jugar!** Inicia el juego desde el icono oficial en tu Menú Home.

---

### Método 2: Aplicar una Actualización (Si ya tienes el juego instalado)

1. Descarga el archivo ligero de actualización `Pokemon_Anil_Switch_Update_v4.0.x.zip`.
2. Extrae su contenido y copia los archivos dentro de la carpeta existente en tu MicroSD:
   `sdmc:/switch/pokemon_anil/`
3. Acepta **reemplazar todos los archivos existentes**.
4. ¡Listo! Tu partida guardada se mantendrá intacta y disfrutarás de todas las mejoras.

---

## 📋 Historial de Versiones

### [v4.0.0] - Versión Oficial Estable
* **Arranque:** Eliminada la doble carga y reducción del tiempo de inicio a segundos con barra de progreso.
* **Combates:** Blindaje de animaciones y prevención de pantallas negras en batallas salvajes y de entrenadores.
* **QoL:** Recordar movimientos desde el menú del Pokémon.
* **Estabilidad:** Guardado atómico en `.tmp` con respaldo `.bak`.
* **Rendimiento:** Caché acelerada de assets y optimización de memoria RAM.
* **Controles:** Mapeo ergonómico completo para Joy-Con y Pro Controller.

Para ver el historial detallado de cambios técnicos, consulta el archivo [CHANGELOG.md](CHANGELOG.md).

---

## 👥 Créditos y Agradecimientos

* **Eric Lostie:** Creador de Pokémon Añil.
* **Equipo de Pokémon Essentials:** Motor base sobre RPG Maker XP.
* **mkxp-z Team:** Intérprete open source de RGSS para múltiples plataformas.
* **devkitPro & libnx:** Toolchain y librerías de desarrollo homebrew para Nintendo Switch.
* **Port Nintendo Switch:** Optimización, shims, compilación ARM64 y adaptación de controles por Fernando y colaboradores.

---

<div align="center">

*Pokémon Añil es un fangame sin ánimo de lucro. Pokémon y Nintendo Switch son marcas registradas de Nintendo, Game Freak y The Pokémon Company.*

</div>
