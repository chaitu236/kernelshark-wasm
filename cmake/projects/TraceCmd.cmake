ks_external_project_directories(trace_cmd)
ks_patch_command(
    _ks_trace_cmd_patch_command
    "${KS_TRACE_CMD_REVISION}"
    "${CMAKE_CURRENT_SOURCE_DIR}/patches/trace-cmd")

set(_ks_trace_cmd_make_args
    "prefix=${KS_WASM_SYSROOT}"
    "pkgconfig_dir=${KS_WASM_SYSROOT}/usr/share/pkgconfig"
    "PKG_CONFIG=env PKG_CONFIG_PATH=${KS_PKG_CONFIG_PATH} ${KS_PKG_CONFIG_EXECUTABLE}"
    "CONFIG_INCLUDES=${KS_UAPI_INCLUDES}"
    WASM=1
    NO_PTRACE=1
    NO_PYTHON=1)

ExternalProject_Add(trace-cmd
    GIT_REPOSITORY "${KS_TRACE_CMD_REPOSITORY}"
    GIT_TAG "${KS_TRACE_CMD_REVISION}"
    GIT_SHALLOW FALSE
    UPDATE_DISCONNECTED TRUE
    DOWNLOAD_DIR "${KS_DOWNLOAD_DIR}"
    SOURCE_DIR "${trace_cmd_SOURCE_DIR}"
    STAMP_DIR "${trace_cmd_STAMP_DIR}"
    BUILD_IN_SOURCE TRUE
    PATCH_COMMAND ${_ks_trace_cmd_patch_command}
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
        "-j${KS_BUILD_JOBS}" ${_ks_trace_cmd_make_args}
    INSTALL_COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-pthread"
        "PKG_CONFIG_PATH=${KS_PKG_CONFIG_PATH}"
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}"
        ${_ks_trace_cmd_make_args} install
    BUILD_BYPRODUCTS
        "${KS_WASM_SYSROOT}/lib/libtracecmd.a"
    DEPENDS libtraceevent libtracefs zstd
    LOG_BUILD TRUE
    LOG_INSTALL TRUE)
