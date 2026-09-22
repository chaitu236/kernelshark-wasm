ks_external_project_directories(libtraceevent)
ks_patch_command(
    _ks_libtraceevent_patch_command
    "${KS_LIBTRACEEVENT_REVISION}"
    "${CMAKE_CURRENT_SOURCE_DIR}/patches/libtraceevent")

set(_ks_libtraceevent_make_args
    "prefix=${KS_WASM_SYSROOT}"
    "pkgconfig_dir=${KS_WASM_SYSROOT}/usr/share/pkgconfig"
    "CONFIG_INCLUDES=${KS_UAPI_INCLUDES}"
    WASM=1)

ExternalProject_Add(libtraceevent
    GIT_REPOSITORY "${KS_LIBTRACEEVENT_REPOSITORY}"
    GIT_TAG "${KS_LIBTRACEEVENT_REVISION}"
    GIT_SHALLOW FALSE
    UPDATE_DISCONNECTED TRUE
    DOWNLOAD_DIR "${KS_DOWNLOAD_DIR}"
    SOURCE_DIR "${libtraceevent_SOURCE_DIR}"
    STAMP_DIR "${libtraceevent_STAMP_DIR}"
    BUILD_IN_SOURCE TRUE
    PATCH_COMMAND ${_ks_libtraceevent_patch_command}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-pthread"
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}" clean
        COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-pthread"
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}"
        "-j${KS_BUILD_JOBS}" ${_ks_libtraceevent_make_args}
    INSTALL_COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-pthread"
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}"
        ${_ks_libtraceevent_make_args} install
    BUILD_BYPRODUCTS
        "${KS_WASM_SYSROOT}/lib/libtraceevent.a"
    LOG_BUILD TRUE
    LOG_INSTALL TRUE)
