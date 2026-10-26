include(ProcessorCount)

set(KS_BUILD_TYPE "MinSizeRel" CACHE STRING
    "Build type used for CMake-based target projects")

set(KS_EMSDK_ROOT "$ENV{EMSDK}" CACHE PATH
    "Root of the active Emscripten SDK")
if(NOT KS_EMSDK_ROOT)
    set(KS_EMSDK_ROOT "/emsdk" CACHE PATH
        "Root of the active Emscripten SDK" FORCE)
endif()

set(KS_QT_WASM_ROOT "$ENV{QT_WASM}" CACHE PATH
    "Thread-enabled Qt for WebAssembly installation")
if(NOT KS_QT_WASM_ROOT)
    set(KS_QT_WASM_ROOT "/opt/qt/6.4.2/wasm-threaded" CACHE PATH
        "Thread-enabled Qt for WebAssembly installation" FORCE)
endif()

set(KS_DOWNLOAD_DIR "${CMAKE_BINARY_DIR}/downloads" CACHE PATH
    "Shared ExternalProject download cache")
set(KS_SOURCE_ROOT "${CMAKE_BINARY_DIR}/sources" CACHE PATH
    "ExternalProject source checkout root")
set(KS_BUILD_ROOT "${CMAKE_BINARY_DIR}/builds" CACHE PATH
    "ExternalProject build root")
set(KS_STAMP_ROOT "${CMAKE_BINARY_DIR}/stamps" CACHE PATH
    "ExternalProject stamp root")
set(KS_WASM_SYSROOT "${CMAKE_BINARY_DIR}/sysroot" CACHE PATH
    "Private WebAssembly dependency installation prefix")
set(KS_DIST_DIR "${CMAKE_BINARY_DIR}/dist" CACHE PATH
    "Final KernelShark browser artifact directory")

ProcessorCount(_ks_processor_count)
if(NOT _ks_processor_count)
    set(_ks_processor_count 1)
endif()
set(KS_BUILD_JOBS "${_ks_processor_count}" CACHE STRING
    "Parallel jobs passed to component builds")

find_program(KS_GIT_EXECUTABLE git REQUIRED)
find_program(KS_MAKE_EXECUTABLE make REQUIRED)
find_program(KS_PKG_CONFIG_EXECUTABLE pkg-config REQUIRED)
find_program(KS_GZIP_EXECUTABLE gzip REQUIRED)
find_program(KS_BROTLI_EXECUTABLE brotli REQUIRED)
find_program(KS_HOST_CC gcc REQUIRED)

set(KS_EMCMAKE "${KS_EMSDK_ROOT}/upstream/emscripten/emcmake")
set(KS_EMMAKE "${KS_EMSDK_ROOT}/upstream/emscripten/emmake")
set(KS_QT_CMAKE "${KS_QT_WASM_ROOT}/bin/qt-cmake")
set(KS_QT_LOADER
    "${KS_QT_WASM_ROOT}/plugins/platforms/qtloader.js")
set(KS_QT_LICENSE_DIR "${KS_QT_WASM_ROOT}/licenses" CACHE PATH
    "License and attribution bundle for the installed Qt version")

if(NOT EXISTS "${KS_QT_LICENSE_DIR}/qt-version.txt")
    message(FATAL_ERROR
        "Qt license bundle missing at ${KS_QT_LICENSE_DIR}. "
        "Rebuild the builder image, or set KS_QT_LICENSE_DIR to a matching bundle.")
endif()
file(READ "${KS_QT_LICENSE_DIR}/qt-version.txt" _ks_notice_qt_version)
string(STRIP "${_ks_notice_qt_version}" _ks_notice_qt_version)
if(NOT _ks_notice_qt_version STREQUAL KS_QT_VERSION)
    message(FATAL_ERROR
        "Qt notice version ${_ks_notice_qt_version} does not match ${KS_QT_VERSION}")
endif()

foreach(_ks_required_path
        KS_EMCMAKE
        KS_EMMAKE
        KS_QT_CMAKE
        KS_QT_LOADER)
    if(NOT EXISTS "${${_ks_required_path}}")
        message(FATAL_ERROR
            "${_ks_required_path} does not exist: ${${_ks_required_path}}")
    endif()
endforeach()

execute_process(
    COMMAND "${KS_HOST_CC}" -print-multiarch
    OUTPUT_VARIABLE KS_HOST_MULTIARCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)

set(KS_HOST_INCLUDE "/usr/include")
set(KS_HOST_ARCH_INCLUDE "/usr/include/${KS_HOST_MULTIARCH}")
set(KS_UAPI_INCLUDES
    "-idirafter ${KS_HOST_INCLUDE} -idirafter ${KS_HOST_ARCH_INCLUDE}")
set(KS_PKG_CONFIG_PATH
    "${KS_WASM_SYSROOT}/lib/pkgconfig:${KS_WASM_SYSROOT}/usr/share/pkgconfig")

file(MAKE_DIRECTORY
    "${KS_DOWNLOAD_DIR}"
    "${KS_SOURCE_ROOT}"
    "${KS_BUILD_ROOT}"
    "${KS_STAMP_ROOT}"
    "${KS_WASM_SYSROOT}"
    "${KS_DIST_DIR}")
