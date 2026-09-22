ks_external_project_directories(zstd)

ExternalProject_Add(zstd
    GIT_REPOSITORY "${KS_ZSTD_REPOSITORY}"
    GIT_TAG "${KS_ZSTD_REVISION}"
    GIT_SHALLOW FALSE
    UPDATE_DISCONNECTED TRUE
    DOWNLOAD_DIR "${KS_DOWNLOAD_DIR}"
    SOURCE_DIR "${zstd_SOURCE_DIR}"
    STAMP_DIR "${zstd_STAMP_DIR}"
    BUILD_IN_SOURCE TRUE
    CONFIGURE_COMMAND ""
    BUILD_COMMAND
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}"
        -C <SOURCE_DIR>/lib clean
        COMMAND
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}"
        -C <SOURCE_DIR>/lib "-j${KS_BUILD_JOBS}" libzstd.a
    INSTALL_COMMAND
        "${KS_EMMAKE}" "${KS_MAKE_EXECUTABLE}"
        -C <SOURCE_DIR>/lib
        install-static install-includes install-pc
        "PREFIX=${KS_WASM_SYSROOT}"
        "PKGCONFIGDIR=${KS_WASM_SYSROOT}/lib/pkgconfig"
    BUILD_BYPRODUCTS
        "${KS_WASM_SYSROOT}/lib/libzstd.a"
    LOG_BUILD TRUE
    LOG_INSTALL TRUE)
