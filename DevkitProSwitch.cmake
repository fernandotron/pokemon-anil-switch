# CMake Toolchain file for Nintendo Switch (devkitPro / libnx)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

if(NOT DEFINED ENV{DEVKITPRO})
    set(ENV{DEVKITPRO} "/opt/devkitpro")
endif()

set(DEVKITPRO $ENV{DEVKITPRO})
set(DEVKITA64 ${DEVKITPRO}/devkitA64)
set(PORTLIBS  ${DEVKITPRO}/portlibs/switch)
set(LIBNX     ${DEVKITPRO}/libnx)

set(CMAKE_C_COMPILER   ${DEVKITA64}/bin/aarch64-none-elf-gcc)
set(CMAKE_CXX_COMPILER ${DEVKITA64}/bin/aarch64-none-elf-g++)
set(CMAKE_AR           ${DEVKITA64}/bin/aarch64-none-elf-gcc-ar CACHE STRING "")
set(CMAKE_RANLIB       ${DEVKITA64}/bin/aarch64-none-elf-gcc-ranlib CACHE STRING "")
set(CMAKE_STRIP        ${DEVKITA64}/bin/aarch64-none-elf-strip CACHE STRING "")

set(ARCH_FLAGS "-march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIE")

set(CMAKE_C_FLAGS_INIT   "${ARCH_FLAGS} -O3 -ffunction-sections -fdata-sections -D__SWITCH__ -D__NX__ -I${LIBNX}/include -I${PORTLIBS}/include")
set(CMAKE_CXX_FLAGS_INIT "${ARCH_FLAGS} -O3 -ffunction-sections -fdata-sections -D__SWITCH__ -D__NX__ -I${LIBNX}/include -I${PORTLIBS}/include")

set(CMAKE_EXE_LINKER_FLAGS_INIT "-specs=${LIBNX}/switch.specs ${ARCH_FLAGS} -fPIE -L${LIBNX}/lib -L${PORTLIBS}/lib -Wl,--gc-sections -lnx")

set(CMAKE_FIND_ROOT_PATH ${PORTLIBS} ${LIBNX} ${DEVKITA64})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(PKG_CONFIG_EXECUTABLE ${PORTLIBS}/bin/aarch64-none-elf-pkg-config CACHE STRING "")
