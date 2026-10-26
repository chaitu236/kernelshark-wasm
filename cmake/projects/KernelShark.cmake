ks_external_project_directories(kernelshark)
ks_patch_command(
    _ks_kernelshark_patch_command
    "${KS_KERNELSHARK_REVISION}"
    "${CMAKE_CURRENT_SOURCE_DIR}/patches/kernel-shark")

ExternalProject_Add(kernelshark
    GIT_REPOSITORY "${KS_KERNELSHARK_REPOSITORY}"
    GIT_TAG "${KS_KERNELSHARK_REVISION}"
    GIT_SHALLOW FALSE
    UPDATE_DISCONNECTED TRUE
    DOWNLOAD_DIR "${KS_DOWNLOAD_DIR}"
    SOURCE_DIR "${kernelshark_SOURCE_DIR}"
    BINARY_DIR "${kernelshark_BINARY_DIR}"
    STAMP_DIR "${kernelshark_STAMP_DIR}"
    PATCH_COMMAND ${_ks_kernelshark_patch_command}
    CONFIGURE_COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-pthread"
        "PKG_CONFIG_PATH=${KS_PKG_CONFIG_PATH}"
        "${KS_QT_CMAKE}"
        -S <SOURCE_DIR>
        -B <BINARY_DIR>
        "-DCMAKE_BUILD_TYPE=${KS_BUILD_TYPE}"
    BUILD_COMMAND
        "${CMAKE_COMMAND}"
        "-DKS_PROJECT_ROOT=${CMAKE_CURRENT_SOURCE_DIR}"
        "-DKS_PROJECT_REPOSITORY=${KS_PROJECT_REPOSITORY}"
        "-DKS_SOURCE_INFO_FILE=${kernelshark_BINARY_DIR}/SOURCE-INFO.pending.txt"
        "-DKS_BUILD_TYPE=${KS_BUILD_TYPE}"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/WriteSourceInfo.cmake"
        COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-pthread"
        "PKG_CONFIG_PATH=${KS_PKG_CONFIG_PATH}"
        "${CMAKE_COMMAND}" --build <BINARY_DIR>
        --target kernelshark
        --parallel "${KS_BUILD_JOBS}"
        COMMAND "${CMAKE_COMMAND}" -E rename
        "${kernelshark_BINARY_DIR}/SOURCE-INFO.pending.txt"
        "${kernelshark_BINARY_DIR}/SOURCE-INFO.txt"
    INSTALL_COMMAND ""
    BUILD_BYPRODUCTS
        <SOURCE_DIR>/bin/kernelshark.js
        <SOURCE_DIR>/bin/kernelshark.wasm
        <SOURCE_DIR>/bin/kernelshark.worker.js
        <SOURCE_DIR>/bin/kernelshark.html
    DEPENDS json-c libtraceevent libtracefs zstd trace-cmd
    LOG_CONFIGURE TRUE
    LOG_BUILD TRUE)

ExternalProject_Add_Step(kernelshark collect
    COMMAND
        "${CMAKE_COMMAND}"
        "-DKS_PROJECT_ROOT=${CMAKE_CURRENT_SOURCE_DIR}"
        "-DKS_COMPONENT_SOURCE_ROOT=${KS_SOURCE_ROOT}"
        "-DKS_EMSDK_ROOT=${KS_EMSDK_ROOT}"
        "-DKS_QT_LICENSE_DIR=${KS_QT_LICENSE_DIR}"
        "-DKS_QT_VERSION=${KS_QT_VERSION}"
        "-DKS_SOURCE_INFO_FILE=${kernelshark_BINARY_DIR}/SOURCE-INFO.txt"
        "-DKS_SOURCE_DIR=<SOURCE_DIR>/bin"
        "-DKS_DIST_DIR=${KS_DIST_DIR}"
        "-DKS_QT_LOADER=${KS_QT_LOADER}"
        "-DKS_ICON_SOURCE=<SOURCE_DIR>/icons/KS_icon_shark.svg"
        "-DKS_ICON_LICENSE_SOURCE=<SOURCE_DIR>/icons/CC_BY-4.0"
        "-DKS_GZIP_EXECUTABLE=${KS_GZIP_EXECUTABLE}"
        "-DKS_BROTLI_EXECUTABLE=${KS_BROTLI_EXECUTABLE}"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CollectArtifacts.cmake"
    DEPENDEES build
    DEPENDERS install
    ALWAYS TRUE)

ExternalProject_Add_StepTargets(kernelshark collect)
add_custom_target(kernelshark-dist DEPENDS kernelshark-collect)
