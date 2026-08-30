# Dockerfile para compilar mkxp-z para Nintendo Switch con devkitPro
FROM devkitpro/devkita64:latest

# Actualizar sistema e instalar herramientas de compilación con apt
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    meson \
    ninja-build \
    python3 \
    python3-pip \
    ruby \
    imagemagick \
    pkg-config \
    ca-certificates \
    xxd \
    && rm -rf /var/lib/apt/lists/*

# Instalar librerías de devkitPro para Switch
RUN dkp-pacman -Syu --noconfirm \
    switch-dev \
    switch-portlibs \
    switch-sdl2 \
    switch-sdl2_image \
    switch-sdl2_ttf \
    switch-sdl2_mixer \
    switch-mesa \
    switch-libvorbis \
    switch-flac \
    switch-libtheora \
    switch-freetype \
    switch-mbedtls \
    switch-zlib \
    switch-bzip2 \
    switch-tools \
    && dkp-pacman -Scc --noconfirm


WORKDIR /work

COPY . /work/

RUN chmod +x /work/build_switch.sh

ENTRYPOINT ["/bin/bash", "/work/build_switch.sh"]
