foreach(_ks_required_variable
        KS_SOURCE_DIR
        KS_DIST_DIR
        KS_QT_LOADER
        KS_GZIP_EXECUTABLE)
    if(NOT DEFINED ${_ks_required_variable})
        message(FATAL_ERROR "${_ks_required_variable} is required")
    endif()
endforeach()

set(_ks_core_artifacts
    kernelshark.html
    kernelshark.js
    kernelshark.wasm
    kernelshark.worker.js)

file(REMOVE_RECURSE "${KS_DIST_DIR}")
file(MAKE_DIRECTORY "${KS_DIST_DIR}")

foreach(_ks_artifact IN LISTS _ks_core_artifacts)
    set(_ks_source "${KS_SOURCE_DIR}/${_ks_artifact}")
    set(_ks_destination "${KS_DIST_DIR}/${_ks_artifact}")
    if(NOT EXISTS "${_ks_source}")
        message(FATAL_ERROR "Missing KernelShark artifact: ${_ks_source}")
    endif()
    file(COPY_FILE "${_ks_source}" "${_ks_destination}" ONLY_IF_DIFFERENT)
endforeach()

file(COPY_FILE
    "${KS_QT_LOADER}"
    "${KS_DIST_DIR}/qtloader.js"
    ONLY_IF_DIFFERENT)

foreach(_ks_artifact IN ITEMS
        kernelshark.js
        kernelshark.wasm
        kernelshark.worker.js)
    execute_process(
        COMMAND "${KS_GZIP_EXECUTABLE}" -9 -c
            "${KS_DIST_DIR}/${_ks_artifact}"
        OUTPUT_FILE "${KS_DIST_DIR}/${_ks_artifact}.gz"
        COMMAND_ERROR_IS_FATAL ANY)
endforeach()

file(GLOB _ks_forbidden_artifacts
    "${KS_DIST_DIR}/*.data"
    "${KS_DIST_DIR}/plugin-*.so")
if(_ks_forbidden_artifacts)
    message(FATAL_ERROR
        "Unexpected deployment artifacts: ${_ks_forbidden_artifacts}")
endif()
