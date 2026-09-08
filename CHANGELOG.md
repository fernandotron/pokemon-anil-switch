# Historial de Cambios (Changelog) — Pokémon Añil 4.0 Switch

Todas las mejoras, correcciones y novedades notables de este port se documentan en este archivo.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

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
