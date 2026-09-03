#!/usr/bin/env bash
set -e

# ==============================================================================
# Script de compilación y empaquetado de mkxp-z para Nintendo Switch (.nro)
# ==============================================================================

echo "=== [1/6] Comprobando entorno devkitPro ==="
if [ -z "$DEVKITPRO" ]; then
    export DEVKITPRO="/opt/devkitpro"
fi

if [ ! -d "$DEVKITPRO/devkitA64" ]; then
    echo "ERROR: devkitA64 no encontrado en $DEVKITPRO/devkitA64."
    echo "Asegúrate de tener instalado devkitPro con el payload de Nintendo Switch."
    exit 1
fi

export PATH="$DEVKITPRO/devkitA64/bin:$DEVKITPRO/tools/bin:$DEVKITPRO/portlibs/switch/bin:$PATH"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/build-switch"
OUTPUT_NRO="$PROJECT_ROOT/port.nro"
NACP_FILE="$PROJECT_ROOT/port.nacp"
ICON_FILE="$PROJECT_ROOT/icon.jpg"

echo "=== [2/6] Preparando dependencias y código fuente de mkxp-z ==="

# 2.1 Compilar SDL_sound para Switch si no está instalado
if [ ! -f "$DEVKITPRO/portlibs/switch/lib/libSDL2_sound.a" ]; then
    echo "--- Compilando SDL_sound para Switch ---"
    if [ ! -d "/tmp/SDL_sound" ]; then
        git clone --depth 1 -b SDL2 https://github.com/icculus/SDL_sound.git /tmp/SDL_sound || git clone --depth 1 -b v2.0.1 https://github.com/icculus/SDL_sound.git /tmp/SDL_sound
    fi
    cmake -B /tmp/SDL_sound/build -S /tmp/SDL_sound \
        -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/DevkitProSwitch.cmake" \
        -DCMAKE_INSTALL_PREFIX="$DEVKITPRO/portlibs/switch" \
        -DSDLSOUND_BUILD_STATIC=ON \
        -DSDLSOUND_BUILD_SHARED=OFF \
        -DSDLSOUND_BUILD_TEST=OFF
    cmake --build /tmp/SDL_sound/build --target install
fi

# 2.2 Compilar Pixman para Switch si no está instalado
if [ ! -f "$DEVKITPRO/portlibs/switch/lib/libpixman-1.a" ]; then
    echo "--- Compilando Pixman para Switch ---"
    if [ ! -d "/tmp/pixman" ]; then
        git clone --depth 1 -b pixman-0.42.2 https://gitlab.freedesktop.org/pixman/pixman.git /tmp/pixman || git clone --depth 1 https://gitlab.freedesktop.org/pixman/pixman.git /tmp/pixman
    fi
    meson setup /tmp/pixman/build /tmp/pixman \
        --cross-file "$PROJECT_ROOT/switch.cross" \
        --prefix="$DEVKITPRO/portlibs/switch" \
        --default-library=static \
        -Dtests=disabled \
        -Dgtk=disabled
    ninja -C /tmp/pixman/build install
fi

# 2.3 Compilar uchardet para Switch si no está instalado
if [ ! -f "$DEVKITPRO/portlibs/switch/lib/libuchardet.a" ]; then
    echo "--- Compilando uchardet para Switch ---"
    if [ ! -d "/tmp/uchardet" ]; then
        git clone --depth 1 https://gitlab.freedesktop.org/uchardet/uchardet.git /tmp/uchardet
    fi
    cmake -B /tmp/uchardet/build -S /tmp/uchardet \
        -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/DevkitProSwitch.cmake" \
        -DCMAKE_INSTALL_PREFIX="$DEVKITPRO/portlibs/switch" \
        -DBUILD_STATIC=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_BINARY=OFF
    cmake --build /tmp/uchardet/build --target install
fi

# 2.4 Compilar libiconv y libcharset para Switch si no está instalado
if [ ! -f "$DEVKITPRO/portlibs/switch/lib/libiconv.a" ]; then
    echo "--- Compilando libiconv y libcharset para Switch ---"
    if [ ! -d "/tmp/libiconv" ]; then
        curl -sL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz | tar -xz -C /tmp
        mv /tmp/libiconv-1.17 /tmp/libiconv
    fi
    cd /tmp/libiconv
    CFLAGS="-march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIE -I$DEVKITPRO/libnx/include -std=gnu89" \
    ./configure --host=aarch64-none-elf \
        --prefix="$DEVKITPRO/portlibs/switch" \
        --enable-static \
        --disable-shared \
        CC=aarch64-none-elf-gcc \
        AR=aarch64-none-elf-gcc-ar \
        RANLIB=aarch64-none-elf-gcc-ranlib
    cd /tmp/libiconv/libcharset && make install-lib libdir="$DEVKITPRO/portlibs/switch/lib" includedir="$DEVKITPRO/portlibs/switch/include"
    cp -f /tmp/libiconv/libcharset/include/localcharset.h /tmp/libiconv/lib/
    cd /tmp/libiconv/lib && make install-lib libdir="$DEVKITPRO/portlibs/switch/lib" includedir="$DEVKITPRO/portlibs/switch/include"
    cp -f /tmp/libiconv/include/iconv.h.inst "$DEVKITPRO/portlibs/switch/include/iconv.h" || cp -f /tmp/libiconv/include/iconv.h "$DEVKITPRO/portlibs/switch/include/iconv.h" || true
    cd "$PROJECT_ROOT"
fi

# 2.5 Compilar Ruby 3.1 para Switch si no está instalado
# Instrumentacion paso a paso del arranque de Ruby. APAGADA por defecto: mete cientos de
# escrituras a microSD dentro de ruby_setup(). Para diagnosticar: RUBY_STEP_LOG=1 ./build_switch.sh
RUBY_STEP_LOG="${RUBY_STEP_LOG:-0}"
if [ "$RUBY_STEP_LOG" = "1" ]; then
    RUBY_STEP_DEF="-DMKXPZ_RUBY_STEP_LOG"
    echo "[AVISO] RUBY_STEP_LOG=1: se compila Ruby con instrumentacion paso a paso."
    echo "        Esto ANADE tiempo de arranque. No usar para medir el arranque real."
else
    RUBY_STEP_DEF=""
fi

RUBY_STAMP_FILE="$DEVKITPRO/portlibs/switch/.ruby_build_stamp"
CURRENT_RUBY_STAMP=$(md5sum "$0" "$PROJECT_ROOT"/patches/* 2>/dev/null | md5sum | cut -d' ' -f1)

if [ -f "$RUBY_STAMP_FILE" ] && [ "$(cat "$RUBY_STAMP_FILE" 2>/dev/null)" != "$CURRENT_RUBY_STAMP" ]; then
    echo "--- Configuración de build o parches modificados: invalidando libruby previa ---"
    rm -f "$DEVKITPRO/portlibs/switch/lib/libruby"* "$RUBY_STAMP_FILE"
fi

if [ ! -f "$DEVKITPRO/portlibs/switch/lib/libruby-static.a" ] && [ ! -f "$DEVKITPRO/portlibs/switch/lib/libruby.a" ]; then
    echo "--- Compilando Ruby 3.1 para Nintendo Switch ---"
    
    # Crear shim para sys/mman.h y poll.h en newlib / libnx
    mkdir -p "$DEVKITPRO/portlibs/switch/include/sys"
    cat << 'EOF' > "$DEVKITPRO/portlibs/switch/include/sys/mman.h"
#ifndef _SYS_MMAN_H
#define _SYS_MMAN_H
#include <stddef.h>
#define PROT_READ 0x1
#define PROT_WRITE 0x2
#define PROT_EXEC 0x4
#define PROT_NONE 0x0
#define MAP_SHARED 0x01
#define MAP_PRIVATE 0x02
#define MAP_ANONYMOUS 0x20
#define MAP_ANON MAP_ANONYMOUS
#define MAP_FAILED ((void*)-1)
#endif
EOF

    cat << 'EOF' > "$DEVKITPRO/portlibs/switch/include/poll.h"
#ifndef _POLL_H
#define _POLL_H
typedef unsigned long int nfds_t;
struct pollfd {
    int fd;
    short events;
    short revents;
};
#define POLLIN 0x0001
#define POLLPRI 0x0002
#define POLLOUT 0x0004
#define POLLERR 0x0008
#define POLLHUP 0x0010
#define POLLNVAL 0x0020
#endif
EOF
    cp -f "$DEVKITPRO/portlibs/switch/include/poll.h" "$DEVKITPRO/portlibs/switch/include/sys/poll.h"

    if [ ! -d "/tmp/ruby-3.1" ]; then
        curl -sL https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.4.tar.gz | tar -xz -C /tmp
        mv /tmp/ruby-3.1.4 /tmp/ruby-3.1
    fi
    cd /tmp/ruby-3.1    # Parches para sistemas embebidos sin sa_sigaction ni SA_SIGINFO ni waitpid ni poll ni dladdr
    sed -i 's/action.sa_sigaction = read_barrier_signal;/action.sa_handler = SIG_DFL;/g' gc.c || true
    sed -i 's/action.sa_flags = SA_SIGINFO | SA_ONSTACK;/action.sa_flags = 0;/g' gc.c || true
    sed -i 's/read_barrier_handler((uintptr_t)info->si_addr);/(void)info;/g' gc.c || true
    sed -i 's/#if USE_MMAP_ALIGNED_ALLOC/#if 0/g' gc.c || true
    sed -i 's/defined(SA_SIGINFO)/0/g' gc.c || true
    sed -i 's/#  error waitpid or wait4 is required./return (rb_pid_t)-1;/g' process.c || true
    sed -i '1i #include <poll.h>' thread_pthread.c || true
    # Instrumentar ruby_setup e inits con logs detallados paso a paso
cat << 'EOF' > patch_eval_setup.c
#include <stdio.h>
#include <time.h>

/* Instrumentacion paso a paso del arranque de Ruby.
 *
 * APAGADA POR DEFECTO, y el motivo es serio: los sed de mas abajo reescriben la macro
 * CALL(n) de inits.c, asi que CADA Init_ de rb_call_inits emite DOS llamadas a esta
 * funcion. Son cientos, dentro de ruby_setup(), y cada una escribia en la microSD.
 * Medido en consola: el motor entero tarda 1,49 s en llegar a ruby_setup() y el arranque
 * completo tarda 34 s, asi que ~32 s se van ahi dentro.
 *
 * Para diagnosticar: RUBY_STEP_LOG=1 ./build_switch.sh
 * Escribe en sdmc:/switch/pokemon_anil/mkxp_ruby_init.log, fichero propio para no pisar
 * mkxp.log, que tiene su propio escritor con handle persistente. */
#ifdef MKXPZ_RUBY_STEP_LOG
static FILE *_rstep = NULL;
static void log_ruby_step(const char *msg) {
    struct timespec ts;
    if (!_rstep) _rstep = fopen("sdmc:/switch/pokemon_anil/mkxp_ruby_init.log", "w");
    if (_rstep) {
        clock_gettime(CLOCK_MONOTONIC, &ts);
        fprintf(_rstep, "[%8lu ms] %s\n", (unsigned long)(ts.tv_sec * 1000UL + ts.tv_nsec / 1000000UL), msg);
        /* fflush por linea: lo caro es el fopen(append)+fclose, no esto, y sin el un
         * cierre por error se llevaria justo las lineas que dicen donde se colgo. */
        fflush(_rstep);
    }
}
#else
static inline void log_ruby_step(const char *msg) { (void)msg; }
#endif
EOF
    sed -i '1i #include "patch_eval_setup.c"' eval.c || true
    sed -i 's/Init_BareVM();/log_ruby_step("  [ruby_setup 3] Init_BareVM"); Init_BareVM(); log_ruby_step("  [ruby_setup 3.1] Init_BareVM OK");/g' eval.c || true
    sed -i 's/Init_heap();/log_ruby_step("  [ruby_setup 4] Init_heap"); Init_heap(); log_ruby_step("  [ruby_setup 4.1] Init_heap OK");/g' eval.c || true
    sed -i 's/Init_vm_objects();/log_ruby_step("  [ruby_setup 5] Init_vm_objects"); Init_vm_objects(); log_ruby_step("  [ruby_setup 5.1] Init_vm_objects OK");/g' eval.c || true
    sed -i 's/rb_call_inits();/log_ruby_step("  [ruby_setup 6] rb_call_inits"); rb_call_inits(); log_ruby_step("  [ruby_setup 6.1] rb_call_inits OK");/g' eval.c || true
    sed -i 's/ruby_prog_init();/log_ruby_step("  [ruby_setup 7] ruby_prog_init"); ruby_prog_init(); log_ruby_step("  [ruby_setup 7.1] ruby_prog_init OK");/g' eval.c || true
    sed -i '1i #include "patch_eval_setup.c"' inits.c || true
    sed -i 's/#define CALL(n) {void Init_##n(void); Init_##n();}/#define CALL(n) {void Init_##n(void); log_ruby_step("    [init] " #n); Init_##n(); log_ruby_step("    [init OK] " #n);}/g' inits.c || true
    sed -i 's/#define BUILTIN(n) CALL(builtin_##n)/#define BUILTIN(n) { log_ruby_step("    [builtin] " #n); CALL(builtin_##n); }/g' inits.c || true
    sed -i '1i #include "patch_eval_setup.c"' cont.c || true
    python3 - << 'PYEOF'
import re

with open("cont.c", "r") as f:
    code = f.read()

# Eliminar completamente el bloque mprotect / guard page en cont.c
code = re.sub(r'if\s*\(\s*mprotect\s*\([^)]*\)\s*<\s*0\s*\)\s*\{[^}]*\}', '/* guard page bypassed on switch */', code)

# Predefinir rb_cFiber y rb_eFiberError al inicio de Init_Cont
init_cont_pos = code.find("void\nInit_Cont(void)\n{")
if init_cont_pos != -1:
    insert_code = """
    log_ruby_step("      [cont] Init_Cont start");
    rb_cFiber = rb_define_class("Fiber", rb_cObject);
    rb_define_alloc_func(rb_cFiber, fiber_alloc);
    rb_eFiberError = rb_define_class("FiberError", rb_eStandardError);
"""
    code = code[:init_cont_pos + len("void\nInit_Cont(void)\n{")] + insert_code + code[init_cont_pos + len("void\nInit_Cont(void)\n{"):]

with open("cont.c", "w") as f:
    f.write(code)
print(">>> Parche cont.c aplicado exitosamente con Python")
PYEOF
    sed -i 's/rb_provide("fiber.so");/rb_provide("fiber.so"); log_ruby_step("      [cont] Init_Cont complete");/g' cont.c || true
    CFLAGS="-O3 -march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIE -I$DEVKITPRO/libnx/include -I$DEVKITPRO/portlibs/switch/include -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration -Wno-error -std=gnu99 -D__SWITCH__ -D__NX__ $RUBY_STEP_DEF" \
    LDFLAGS="-specs=$DEVKITPRO/libnx/switch.specs -march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIE -L$DEVKITPRO/libnx/lib -L$DEVKITPRO/portlibs/switch/lib -lnx" \
    ./configure \
        --host=aarch64-none-elf \
        --target=aarch64-none-elf \
        --prefix="$DEVKITPRO/portlibs/switch" \
        --enable-static \
        --disable-shared \
        --disable-install-doc \
        --disable-install-rdoc \
        --disable-install-capi \
        --with-static-linked-ext \
        --disable-rubygems \
        --disable-jit-support \
        --with-coroutine=arm64 \
        --with-out-ext=openssl,readline,pty,syslog,dbm,gdbm,sdbm \
        ac_cv_func_mmap=no \
        ac_cv_func_mprotect=no \
        ac_cv_func_munmap=no \
        ac_cv_func_sigaction=no \
        ac_cv_func_sigaltstack=no \
        ac_cv_func_sigprocmask=no \
        ac_cv_func_sigsetmask=no \
        ac_cv_func_getrlimit=no \
        ac_cv_func_setrlimit=no \
        CC=aarch64-none-elf-gcc \
        AR=aarch64-none-elf-gcc-ar \
        RANLIB=aarch64-none-elf-gcc-ranlib

    cat << 'EOF' > addr2line.c
#include <stddef.h>
void rb_dump_backtrace_with_lines(int num_traces, void **traces) {}
void rb_addr2line(const char *binary, void *address) {}
EOF

    make -k -j$(nproc) || true

    cat << 'EOF' > switch_posix_compat.c
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/resource.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <pthread.h>
#include "ruby.h"

__attribute__((weak)) void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset) {
    void *ptr = malloc(length);
    if (!ptr) { errno = ENOMEM; return (void*)-1; }
    memset(ptr, 0, length);
    return ptr;
}
__attribute__((weak)) int munmap(void *addr, size_t length) {
    if (addr && addr != (void*)-1) free(addr);
    return 0;
}
__attribute__((weak)) int mprotect(void *addr, size_t len, int prot) { return 0; }
__attribute__((weak)) long sysconf(int name) { return 4096; }

__attribute__((weak)) pid_t getppid(void) { return 1; }
__attribute__((weak)) int execv(const char *path, char *const argv[]) { errno = ENOSYS; return -1; }
__attribute__((weak)) int execle(const char *path, const char *arg, ...) { errno = ENOSYS; return -1; }
__attribute__((weak)) int execl(const char *path, const char *arg, ...) { errno = ENOSYS; return -1; }
__attribute__((weak)) mode_t umask(mode_t mask) { return 022; }
__attribute__((weak)) int sigprocmask(int how, const sigset_t *set, sigset_t *oldset) { return 0; }
__attribute__((weak)) struct passwd *getpwnam(const char *name) { return NULL; }
__attribute__((weak)) void endpwent(void) {}
__attribute__((weak)) uid_t getuid(void) { return 0; }
__attribute__((weak)) uid_t geteuid(void) { return 0; }
__attribute__((weak)) gid_t getgid(void) { return 0; }
__attribute__((weak)) gid_t getegid(void) { return 0; }
__attribute__((weak)) int getrusage(int who, struct rusage *usage) {
    if (usage) memset(usage, 0, sizeof(*usage));
    return 0;
}
__attribute__((weak)) int pipe(int pipefd[2]) { errno = ENOSYS; return -1; }
typedef void (*sig_handler_t)(int);
__attribute__((weak)) sig_handler_t posix_signal(int signum, sig_handler_t handler) { return SIG_DFL; }
__attribute__((weak)) int pthread_kill(pthread_t thread, int sig) { return 0; }
__attribute__((weak)) int chown(const char *path, uid_t owner, gid_t group) { return 0; }
__attribute__((weak)) int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact) { return 0; }
__attribute__((weak)) int setmode(int fd, int mode) { return 0; }
VALUE SHORT2NUM(short v) {
    return INT2FIX((int)v);
}
VALUE rb_f_SHORT2NUM(short v) {
    return INT2FIX((int)v);
}
__attribute__((weak)) void Init_ext(void) {
    rb_provide("zlib.so");
    rb_provide("zlib");
}
__attribute__((weak)) void Init_enc(void) {}
EOF

    aarch64-none-elf-gcc -c switch_posix_compat.c -O2 -march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIE -I. -I./include -I.ext/include/aarch64-elf -I"$DEVKITPRO/libnx/include" -o switch_posix_compat.o

    # Eliminar objetos dummy de miniruby y el main de Ruby CLI
    rm -f libruby-static.a
    find . -name "*dmy*.o" -delete
    find . -name "main.o" -delete
    find . -name "miniinit.o" -delete
    
    # Empaquetar objetos reales del core de Ruby y los shims de compatibilidad
    aarch64-none-elf-gcc-ar rcs libruby-static.a $(find . ! -path "*/ext/*" ! -path "*/.bundle/*" ! -path "*/-test-/*" -name "*.o" ! -name "switch_posix_compat.o" | sort -u) switch_posix_compat.o

    # Instalar manualmente libruby y sus headers en portlibs
    mkdir -p "$DEVKITPRO/portlibs/switch/lib/pkgconfig"
    mkdir -p "$DEVKITPRO/portlibs/switch/include/ruby-3.1.0/aarch64-elf/ruby"
    mkdir -p "$DEVKITPRO/portlibs/switch/include/ruby-3.1.0/ruby"
    cp -f libruby-static.a "$DEVKITPRO/portlibs/switch/lib/libruby-static.a"
    cp -f libruby-static.a "$DEVKITPRO/portlibs/switch/lib/libruby.a"
    cp -rf include/* "$DEVKITPRO/portlibs/switch/include/ruby-3.1.0/"
    cp -f .ext/include/aarch64-elf/ruby/config.h "$DEVKITPRO/portlibs/switch/include/ruby-3.1.0/aarch64-elf/ruby/config.h"
    cp -rf .ext/include/aarch64-elf/ruby/* "$DEVKITPRO/portlibs/switch/include/ruby-3.1.0/aarch64-elf/ruby/" || true
    
    # Generar ruby-3.1.pc para Meson con whole-archive para enlace estático
    cat << 'EOF' > "$DEVKITPRO/portlibs/switch/lib/pkgconfig/ruby-3.1.pc"
prefix=/opt/devkitpro/portlibs/switch
exec_prefix=${prefix}
includedir=${prefix}/include
libdir=${prefix}/lib

Name: Ruby
Description: Ruby interpreter
Version: 3.1.4
Cflags: -I${includedir}/ruby-3.1.0 -I${includedir}/ruby-3.1.0/aarch64-elf
Libs: -L${libdir} -Wl,--whole-archive -lruby-static -Wl,--no-whole-archive -lm
EOF
    echo "$CURRENT_RUBY_STAMP" > "$RUBY_STAMP_FILE"
    cd "$PROJECT_ROOT"
fi

if [ ! -d "$PROJECT_ROOT/mkxp-z" ]; then
    echo "Clonando repositorio mkxp-z..."
    git clone --recurse-submodules https://github.com/mkxp-z/mkxp-z.git "$PROJECT_ROOT/mkxp-z"
fi

cd "$PROJECT_ROOT/mkxp-z"

# Aplicar parches de Nintendo Switch a mkxp-z si están disponibles
if [ -f "$PROJECT_ROOT/patches/mkxp-z-switch.patch" ]; then
    echo "--- Comprobando y aplicando parches de Nintendo Switch a mkxp-z ---"
    if git apply --check "$PROJECT_ROOT/patches/mkxp-z-switch.patch" >/dev/null 2>&1; then
        git apply "$PROJECT_ROOT/patches/mkxp-z-switch.patch"
        echo "Parches aplicados exitosamente a mkxp-z."
    elif git apply --reverse --check "$PROJECT_ROOT/patches/mkxp-z-switch.patch" >/dev/null 2>&1; then
        echo "Parches de Nintendo Switch ya aplicados en mkxp-z."
    else
        echo "[ERROR] Falló git apply --check sobre patches/mkxp-z-switch.patch. El parche está roto."
        exit 1
    fi
fi

echo "=== [3/6] Configurando Meson con switch.cross ==="
if [ ! -d "$BUILD_DIR" ]; then
    meson setup "$BUILD_DIR" \
        --cross-file "$PROJECT_ROOT/switch.cross" \
        --buildtype=release \
        -Ddefault_library=static \
        -Dworkdir_current=true \
        -Duse_miniffi=false \
        -Denable-https=false \
        -Dgfx_backend=gles \
        -Dshared_fluid=false \
        -Dstatic_executable=true
else
    meson setup --reconfigure "$BUILD_DIR" --cross-file "$PROJECT_ROOT/switch.cross"
fi

echo "=== [4/6] Compilando binario ELF ==="
ninja -C "$BUILD_DIR"

ELF_BINARY=$(find "$BUILD_DIR" -maxdepth 2 -type f \( -name "mkxp-z" -o -name "mkxp-z.elf" -o -name "port.elf" \) | head -n 1)

if [ -z "$ELF_BINARY" ]; then
    echo "ERROR: No se encontró el binario compilado en $BUILD_DIR"
    exit 1
fi

echo "Binario ELF generado: $ELF_BINARY"

echo "=== [5/6] Creando NACP y Metadatos ==="
nacptool --create "Pokemon Anil" "Eric Lostie / Switch Port" "4.0.0" "$NACP_FILE"

# Generar un icono genérico de 256x256 si no existe
if [ ! -f "$ICON_FILE" ]; then
    if [ -f "$PROJECT_ROOT/Graphics/Icons/icon.png" ]; then
        echo "Convirtiendo icono desde Graphics..."
        if command -v convert &>/dev/null; then
            convert "$PROJECT_ROOT/Graphics/Icons/icon.png" -resize 256x256 "$ICON_FILE"
        fi
    fi
fi

echo "=== [6/6] Empaquetando Homebrew (.nro) con elf2nro ==="
if [ -f "$ICON_FILE" ]; then
    elf2nro "$ELF_BINARY" "$OUTPUT_NRO" --nacp="$NACP_FILE" --icon="$ICON_FILE"
else
    elf2nro "$ELF_BINARY" "$OUTPUT_NRO" --nacp="$NACP_FILE"
fi

echo "=============================================================================="
echo " ¡COMPILACIÓN EXITOSA!"
echo " Archivo generado: $OUTPUT_NRO"
echo ""
echo " Estructura requerida en la tarjeta MicroSD de Nintendo Switch:"
echo "   sdmc:/switch/pokemon_anil/port.nro"
echo "   sdmc:/switch/pokemon_anil/pokemon_anil.nro  (misma copia; algunos lanzadores usan este nombre)"
echo "   sdmc:/switch/pokemon_anil/mkxp.json  (copia de mkxp.switch.json)"
echo "   sdmc:/switch/pokemon_anil/Game.ini"
echo "   sdmc:/switch/pokemon_anil/preload.rb"
echo "   sdmc:/switch/pokemon_anil/soundfont.sf2"
echo "   sdmc:/switch/pokemon_anil/Data/"
echo "   sdmc:/switch/pokemon_anil/Audio/"
echo "   sdmc:/switch/pokemon_anil/Graphics/"
echo "   sdmc:/switch/pokemon_anil/Fonts/"
echo "   sdmc:/switch/pokemon_anil/Plugins/"
echo "=============================================================================="
