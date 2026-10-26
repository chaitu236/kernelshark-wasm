foreach(_ks_required_variable
        KS_PROJECT_ROOT KS_PROJECT_REPOSITORY KS_SOURCE_INFO_FILE KS_BUILD_TYPE)
    if(NOT DEFINED ${_ks_required_variable})
        message(FATAL_ERROR "${_ks_required_variable} is required")
    endif()
endforeach()
if(NOT KS_PROJECT_REPOSITORY MATCHES "^https://github\\.com/[^/]+/[^/]+$")
    message(FATAL_ERROR "KS_PROJECT_REPOSITORY must be a public GitHub project URL")
endif()
find_program(_ks_git git REQUIRED)
execute_process(
    COMMAND "${_ks_git}" -C "${KS_PROJECT_ROOT}" rev-parse HEAD
    OUTPUT_VARIABLE _ks_revision OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
execute_process(
    COMMAND "${_ks_git}" -C "${KS_PROJECT_ROOT}" diff --quiet HEAD --
        CMakeLists.txt CMakePresets.json build.sh build_container.sh
        cmake containers patches
    RESULT_VARIABLE _ks_modified)
if(NOT _ks_modified EQUAL 0 AND NOT _ks_modified EQUAL 1)
    message(FATAL_ERROR "Could not determine project source state")
endif()
execute_process(
    COMMAND "${_ks_git}" -C "${KS_PROJECT_ROOT}" ls-files --others
        --exclude-standard -- CMakeLists.txt CMakePresets.json build.sh
        build_container.sh cmake containers patches
    OUTPUT_VARIABLE _ks_untracked OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
if(_ks_untracked)
    set(_ks_modified 1)
endif()

include("${KS_PROJECT_ROOT}/cmake/Versions.cmake")
set(_ks_source_info
    "KernelShark WebAssembly source information\n\n")
string(APPEND _ks_source_info
    "Project: ${KS_PROJECT_REPOSITORY}\n"
    "Project base revision: ${_ks_revision}\n"
    "Project build inputs modified: ${_ks_modified}\n"
    "Source and patches: ${KS_PROJECT_REPOSITORY}/tree/${_ks_revision}\n"
    "Version pins: ${KS_PROJECT_REPOSITORY}/blob/${_ks_revision}/cmake/Versions.cmake\n"
    "Build instructions: ${KS_PROJECT_REPOSITORY}/blob/${_ks_revision}/README.md\n"
    "Build type: ${KS_BUILD_TYPE}\n\n"
    "Retrieve the project with:\n"
    "  git clone ${KS_PROJECT_REPOSITORY}.git kernelshark-wasm\n"
    "  cd kernelshark-wasm\n"
    "  git checkout --detach ${_ks_revision}\n\n"
    "The project build retrieves and patches the upstream sources automatically.\n"
    "For manual retrieval, run the following from the project checkout:\n"
    "  mkdir -p upstream\n\n"
    "Upstream source revisions:\n")
foreach(_ks_component IN ITEMS KERNELSHARK JSON_C LIBTRACEEVENT LIBTRACEFS TRACE_CMD ZSTD)
    string(TOLOWER "${_ks_component}" _ks_checkout_dir)
    string(APPEND _ks_source_info
        "\n${_ks_component}\n"
        "  Repository: ${KS_${_ks_component}_REPOSITORY}\n"
        "  Revision: ${KS_${_ks_component}_REVISION}\n"
        "  git clone ${KS_${_ks_component}_REPOSITORY} upstream/${_ks_checkout_dir}\n"
        "  git -C upstream/${_ks_checkout_dir} checkout --detach ${KS_${_ks_component}_REVISION}\n")
endforeach()
string(APPEND _ks_source_info
    "\nThe project build scripts fetch these revisions and apply the patches\n"
    "in patches/<component>/ in filename order. Use the patches from the\n"
    "project revision above, not a newer development branch.\n\n"
    "Qt ${KS_QT_VERSION} source archive:\n"
    "  ${KS_QT_ARCHIVE_URL}\n"
    "  SHA256: ${KS_QT_ARCHIVE_SHA256}\n"
    "  Build configuration: ${KS_PROJECT_REPOSITORY}/blob/${_ks_revision}/containers/builder/Dockerfile\n\n"
    "Emscripten ${KS_EMSCRIPTEN_VERSION} sources, including bundled runtime libraries:\n"
    "  https://github.com/emscripten-core/emscripten/tree/${KS_EMSCRIPTEN_VERSION}\n"
    "  https://github.com/emscripten-core/emscripten/archive/refs/tags/${KS_EMSCRIPTEN_VERSION}.tar.gz\n"
    "  Toolchain image: ${KS_EMSCRIPTEN_IMAGE}\n\n"
    "Build using the checked-out project's README and builder Dockerfile:\n"
    "  ./build_container.sh\n"
    "  ./build.sh\n")
get_filename_component(_ks_parent "${KS_SOURCE_INFO_FILE}" DIRECTORY)
file(MAKE_DIRECTORY "${_ks_parent}")
file(WRITE "${KS_SOURCE_INFO_FILE}" "${_ks_source_info}")
