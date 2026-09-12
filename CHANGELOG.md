# Historial de Cambios (Changelog) — Pokémon Añil 4.0 Switch

Todas las mejoras, correcciones y novedades notables de este port se documentan en este archivo.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

---

## [v4.0.1] - 2026-09-12

### 🎮 Controles Personalizados y Reasignación Dinámica
- **Reasignación Completa de Botones en Switch:** Nuevo menú interactivo dentro de Controles/Opciones que permite mapear cualquier acción (Aceptar, Cancelar, Menú, Acceso Rápido, Turbo, Guardado Rápido) a cualquier botón físico del Joy-Con o Pro Controller.
- **Detección Física en Tiempo Real:** Detección automática al pulsar el botón deseado con intercambio inteligente si ya estaba asignado a otra acción.
- **Persistencia Atómica Independiente:** Almacenamiento directo en `controls.dat` que garantiza que la personalización de controles se conserve al cambiar de ranura en Multi-Save o al comenzar una Nueva Partida.
- **Restaurar Ajustes de Fábrica:** Botón de restablecimiento con un solo toque para regresar a la disposición oficial recomendada para Switch.

### 🛡️ Corrección de Bugs Críticos
- **Crasheo al Capturar Pokémon con Objeto Equipado:** Solucionado el error fatal en combate que intentaba invocar `pbConfirmMessage` (inexistente en el contexto de batalla) al enviar un Pokémon capturado a la caja del PC si llevaba un objeto equipado; reemplazado por `pbDisplayConfirm` con verificación de espacio en la mochila (`can_add?`).
- **Eliminación de Lag en Mochila con Equipo Interactivo:** Eliminado el cuello de botella que recalculaba las anotaciones del equipo en cada fotograma del bucle principal, logrando 60 FPS fluidos al examinar la mochila.
- **Bloqueo de Cursor con MTs/MOs:** Corregido el desfase de selección del cursor tras aprender o cancelar movimientos con MT o MO en la mochila.
- **Blindaje del Sumario / Olvido de Movimientos:** Envolvimiento de `pbStartForgetScreen` con bloque `ensure` para garantizar el cierre seguro de la escena gráfica, y compatibilidad dual para objetos de movimiento.
- **Colisión de pbShowCommands en Plugins:** Unificación de `pbShowCommands` y `pbShowCommandsWithHelp` en `Kernel` para eliminar interferencias entre `Map Zoom`, `Messages` y la pantalla de equipo.
- **Seguidores Fantasma de Pokémon Acompañante:** Corregido el spawn de Following Pokémon EX cuando el equipo está completamente debilitado, previniendo referencias nulas y duplicación de sprites al cambiar de mapa.

### 💡 Novedades y Calidad de Vida (QoL)
- **Menú Rápido de Medicina en Combate:** Acceso rápido durante batallas para usar Pociones, Revivir y Antídotos sin abrir la mochila completa, con selector de Pokémon objetivo (Arriba/Abajo) mostrando PS y estado alterado.
- **Sobremundo Dinámico con Encuentros Visibles (VOE):** Aumentado el tiempo de permanencia de los Pokémon salvajes visibles de 10 a 25 pasos para permitir alcanzarlos cómodamente, con algoritmo de búsqueda optimizado para parches de hierba.
- **Calibración de Audio para Switch:** Refuerzo del volumen base de BGM/ME en +35% y balance acústico adaptado a altavoces y auriculares (BGS al 80%, SE al 70%).

---

## [v4.0.0] - 2026-09-08

### ⚡ Rendimiento y Arranque
- **Arranque Instantáneo:** Eliminación del cuello de botella en C++ que causaba hasta 34 segundos de pantalla negra en el arranque. Reducción de más de 24.000 operaciones lentas de stat en tarjeta SD a menos de 300 lecturas en memoria.
- **Pantalla de Carga Visual:** Barra de progreso y logo visual desde el primer segundo de ejecución.
- **Caché Binaria de Assets (.dat):** Indexación ultrarrápida en RAM de más de 115.000 gráficos y 35.000 efectos de sonido para accesos instantáneos durante el juego.
- **60 FPS Estables:** VSync optimizado y renderizado por hardware OpenGL/Mesa para Nintendo Switch.

### 🛡️ Combates y Estabilidad
- **Blindaje Total contra Congelaciones:** Precarga inteligente de animaciones de combate (`PkmnAnimations.rxdata`) en RAM para eliminar la pantalla negra con música en la primera batalla contra entrenadores o salvajes.
- **Tolerancia a Excepciones en Escenas:** Captura segura de `SDLError` y fallos de textura de bajo nivel para prevenir cierres inesperados al lanzar movimientos o animaciones complejas.
- **Fallback Automático de Bitmaps:** Sustitución en tiempo de ejecución por texturas vacías seguras cuando un sprite secundario falta en disco, evitando crasheos fatales del motor.

### 💡 Calidad de Vida (QoL)
- **Recordar Movimientos desde el Menú:** Se añadió la opción de recordar ataques olvidados directamente desde el sumario del Pokémon (pestaña Movimientos -> Recordar Movimiento), replicando la mecánica moderna de las Generaciones 8 y 9 sin necesidad de buscar al NPC Recuerda-Movimientos.
- **Modo Turbo Nativo:** Asignado a (ZR) para acelerar velocidad de movimiento y agilizar combates y crianza.
- **Guardado Rápido (Quick Save):** Asignado a (ZL) para guardar la partida al instante en cualquier punto del mapa.

### 💾 Guardado Seguro
- **Guardado Atómico (Atomic Save):** Escritura primero en un archivo temporal (`.tmp`) con confirmación de integridad y generación de copia de seguridad (`.bak`). Protege al 100% la partida guardada frente a apagados o cierres involuntarios.

### 🎮 Controles
- Mapeo ergonómico completo para mandos Joy-Con y Nintendo Switch Pro Controller.
- Doble toque rápido del botón (B) para salir inmediatamente de menús jerárquicos o mochilas.

---
