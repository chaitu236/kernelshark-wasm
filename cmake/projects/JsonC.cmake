ks_external_project_directories(json_c)

ExternalProject_Add(json-c
    GIT_REPOSITORY "${KS_JSON_C_REPOSITORY}"
    GIT_TAG "${KS_JSON_C_REVISION}"
    GIT_SHALLOW FALSE
    UPDATE_DISCONNECTED TRUE
    DOWNLOAD_DIR "${KS_DOWNLOAD_DIR}"
    SOURCE_DIR "${json_c_SOURCE_DIR}"
    BINARY_DIR "${json_c_BINARY_DIR}"
    STAMP_DIR "${json_c_STAMP_DIR}"
    CONFIGURE_COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-s USE_PTHREADS=1"
        "${KS_EMCMAKE}" <SOURCE_DIR>/cmake-configure --
        "-DCMAKE_INSTALL_PREFIX=${KS_WASM_SYSROOT}"
        "-DCMAKE_BUILD_TYPE=${KS_BUILD_TYPE}"
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_STATIC_LIBS=ON
        -DBUILD_APPS=OFF
        -DBUILD_TESTING=OFF
    BUILD_COMMAND
        "${CMAKE_COMMAND}" -E env
        "EMCC_CFLAGS=-s USE_PTHREADS=1"
        "${CMAKE_COMMAND}" --build <BINARY_DIR>
        --parallel "${KS_BUILD_JOBS}"
    INSTALL_COMMAND
        "${CMAKE_COMMAND}" --install <BINARY_DIR>
    BUILD_BYPRODUCTS
        "${KS_WASM_SYSROOT}/lib/libjson-c.a"
    LOG_CONFIGURE TRUE
    LOG_BUILD TRUE
    LOG_INSTALL TRUE)
