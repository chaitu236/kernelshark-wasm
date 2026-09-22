ks_external_project_directories(libtracefs)
ks_patch_command(
    _ks_libtracefs_patch_command
    "${KS_LIBTRACEFS_REVISION}"
    "${CMAKE_CURRENT_SOURCE_DIR}/patches/libtracefs")

set(_ks_libtracefs_make_args
    "prefix=${KS_WASM_SYSROOT}"
    "pkgconfig_dir=${KS_WASM_SYSROOT}/usr/share/pkgconfig"
    "PKG_CONFIG=env PKG_CONFIG_PATH=${KS_PKG_CONFIG_PATH} ${KS_PKG_CONFIG_EXECUTABLE}"
    "CONFIG_INCLUDES=${KS_UAPI_INCLUDES}"
    WASM=1
    NO_PERF=1)

ExternalProject_Add(libtracefs
    GIT_REPOSITORY "${KS_LIBTRACEFS_REPOSITORY}"
    GIT_TAG "${KS_LIBTRACEFS_REVISION}"
    GIT_SHALLOW FALSE
    UPDATE_DISCONNECTED TRUE
    DOWNLOAD_DIR "${KS_DOWNLOAD_DIR}"
    SOURCE_DIR "${libtracefs_SOURCE_DIR}"
    STAMP_DIR "${libtracefs_STAMP_DIR}"
    BUILD_IN_SOURCE TRUE
    PATCH_COMMAND ${_ks_libtracefs_patch_command}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-pthread"
        "PKG_CONFIG_PATH=${KS_PKG_CONFIG_PATH}"
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}" clean
        COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-pthread"
        "PKG_CONFIG_PATH=${KS_PKG_CONFIG_PATH}"
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}"
        "-j${KS_BUILD_JOBS}" ${_ks_libtracefs_make_args}
    INSTALL_COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-pthread"
        "PKG_CONFIG_PATH=${KS_PKG_CONFIG_PATH}"
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}"
        ${_ks_libtracefs_make_args} install
    BUILD_BYPRODUCTS
        "${KS_WASM_SYSROOT}/lib/libtracefs.a"
    DEPENDS libtraceevent
    LOG_BUILD TRUE
    LOG_INSTALL TRUE)
