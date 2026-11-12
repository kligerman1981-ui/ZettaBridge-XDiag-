cmake_minimum_required(VERSION 3.22)
project(zettabridge LANGUAGES C CXX ASM)

set(CMAKE_CXX_STANDARD 20)
if (NOT CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
    message(FATAL_ERROR
        "ZettaBridge runtime requires an AArch64 target. For Android use "
        "-DCMAKE_TOOLCHAIN_FILE=<NDK>/build/cmake/android.toolchain.cmake "
        "-DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26")
endif()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
add_compile_definitions(FMT_CONSTEVAL=)

if (ANDROID)
    set(CMAKE_CXX_VISIBILITY_PRESET hidden)
    set(CMAKE_C_VISIBILITY_PRESET hidden)
    set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
    add_compile_options(-ffunction-sections -fdata-sections)
endif()

set(DYNARMIC_FRONTENDS "A32" CACHE STRING "" FORCE)
set(DYNARMIC_TESTS OFF CACHE BOOL "" FORCE)
set(DYNARMIC_WARNINGS_AS_ERRORS OFF CACHE BOOL "" FORCE)
set(DYNARMIC_USE_BUNDLED_EXTERNALS ON CACHE BOOL "" FORCE)
set(DYNARMIC_USE_PRECOMPILED_HEADERS OFF CACHE BOOL "" FORCE)
add_subdirectory(third_party/dynarmic EXCLUDE_FROM_ALL)

add_subdirectory(core)
add_subdirectory(cli/zbfix)
add_subdirectory(cli/zbrun)

option(ZB_BUILD_TESTS "Build host tests" ON)
if (ZB_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests/host)
endif()
