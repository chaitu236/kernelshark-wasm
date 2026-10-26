foreach(_ks_required_variable
    KS_PROJECT_ROOT
    KS_COMPONENT_SOURCE_ROOT
    KS_EMSDK_ROOT
    KS_QT_LICENSE_DIR
    KS_QT_VERSION
        KS_SOURCE_DIR
        KS_DIST_DIR
        KS_QT_LOADER
        KS_ICON_SOURCE
        KS_ICON_LICENSE_SOURCE
        KS_GZIP_EXECUTABLE
        KS_BROTLI_EXECUTABLE)
    if(NOT DEFINED ${_ks_required_variable})
        message(FATAL_ERROR "${_ks_required_variable} is required")
    endif()
endforeach()

set(_ks_project_license_files
    LICENSE
    LICENSES/MIT.txt
    LICENSES/LGPL-2.1-only.txt
    LICENSES/GPL-3.0-only.txt)
foreach(_ks_license_file IN LISTS _ks_project_license_files)
    if(NOT EXISTS "${KS_PROJECT_ROOT}/${_ks_license_file}")
        message(FATAL_ERROR "Missing project license: ${_ks_license_file}")
    endif()
endforeach()

include("${CMAKE_CURRENT_LIST_DIR}/CollectLicenses.cmake")
ks_prepare_licenses()

set(_ks_runtime_artifacts
    kernelshark.js
    kernelshark.wasm
    kernelshark.worker.js)

set(_ks_asset_fingerprint "")
foreach(_ks_artifact IN LISTS _ks_runtime_artifacts)
    set(_ks_source "${KS_SOURCE_DIR}/${_ks_artifact}")
    if(NOT EXISTS "${_ks_source}")
        message(FATAL_ERROR "Missing KernelShark artifact: ${_ks_source}")
    endif()
    file(SHA256 "${_ks_source}" _ks_artifact_hash)
    string(APPEND _ks_asset_fingerprint
        "${_ks_artifact}:${_ks_artifact_hash}\n")
endforeach()

foreach(_ks_named_source IN ITEMS
        "qtloader.js|${KS_QT_LOADER}"
        "favicon.svg|${KS_ICON_SOURCE}")
    string(REPLACE "|" ";" _ks_source_parts "${_ks_named_source}")
    list(GET _ks_source_parts 0 _ks_asset_name)
    list(GET _ks_source_parts 1 _ks_source)
    if(NOT EXISTS "${_ks_source}")
        message(FATAL_ERROR "Missing KernelShark asset: ${_ks_source}")
    endif()
    file(SHA256 "${_ks_source}" _ks_artifact_hash)
    string(APPEND _ks_asset_fingerprint
        "${_ks_asset_name}:${_ks_artifact_hash}\n")
endforeach()

string(SHA256 _ks_asset_hash "${_ks_asset_fingerprint}")
set(_ks_asset_version "${_ks_asset_hash}")
set(_ks_asset_relative_dir "assets/${_ks_asset_version}")
set(_ks_asset_dir "${KS_DIST_DIR}/${_ks_asset_relative_dir}")

file(REMOVE_RECURSE "${KS_DIST_DIR}")
file(MAKE_DIRECTORY "${_ks_asset_dir}")
ks_write_licenses()

foreach(_ks_license_file IN LISTS _ks_project_license_files)
    get_filename_component(_ks_license_dir
        "${KS_DIST_DIR}/${_ks_license_file}" DIRECTORY)
    file(MAKE_DIRECTORY "${_ks_license_dir}")
    file(COPY_FILE
        "${KS_PROJECT_ROOT}/${_ks_license_file}"
        "${KS_DIST_DIR}/${_ks_license_file}")
endforeach()

set(_ks_html_source "${KS_SOURCE_DIR}/kernelshark.html")
if(NOT EXISTS "${_ks_html_source}")
    message(FATAL_ERROR "Missing KernelShark artifact: ${_ks_html_source}")
endif()
file(READ "${_ks_html_source}" _ks_html)
foreach(_ks_html_marker IN ITEMS
        "href=\"favicon.svg\""
        "QtLoader({"
        "src=\"qtloader.js\"")
    string(FIND "${_ks_html}" "${_ks_html_marker}" _ks_marker_position)
    if(_ks_marker_position EQUAL -1)
        message(FATAL_ERROR
            "Missing expected HTML marker: ${_ks_html_marker}")
    endif()
endforeach()
string(REPLACE
    "href=\"favicon.svg\""
    "href=\"${_ks_asset_relative_dir}/favicon.svg\""
    _ks_html "${_ks_html}")
string(REPLACE
    "QtLoader({"
    "QtLoader({\n          path: '${_ks_asset_relative_dir}',"
    _ks_html "${_ks_html}")
string(REPLACE
    "src=\"qtloader.js\""
    "src=\"${_ks_asset_relative_dir}/qtloader.js\""
    _ks_html "${_ks_html}")
file(WRITE "${KS_DIST_DIR}/kernelshark.html" "${_ks_html}")

foreach(_ks_artifact IN LISTS _ks_runtime_artifacts)
    file(COPY_FILE
        "${KS_SOURCE_DIR}/${_ks_artifact}"
        "${_ks_asset_dir}/${_ks_artifact}"
        ONLY_IF_DIFFERENT)
endforeach()

file(COPY_FILE
    "${KS_QT_LOADER}"
    "${_ks_asset_dir}/qtloader.js"
    ONLY_IF_DIFFERENT)

file(COPY_FILE
    "${KS_ICON_SOURCE}"
    "${_ks_asset_dir}/favicon.svg"
    ONLY_IF_DIFFERENT)

file(COPY_FILE
    "${KS_ICON_LICENSE_SOURCE}"
    "${KS_DIST_DIR}/favicon-license.txt"
    ONLY_IF_DIFFERENT)

file(WRITE "${KS_DIST_DIR}/asset-version.txt" "${_ks_asset_version}\n")

foreach(_ks_artifact IN ITEMS
        kernelshark.js
        kernelshark.wasm
        kernelshark.worker.js)
    execute_process(
        COMMAND "${KS_GZIP_EXECUTABLE}" -n -9 -c
            "${_ks_asset_dir}/${_ks_artifact}"
        OUTPUT_FILE "${_ks_asset_dir}/${_ks_artifact}.gz"
        COMMAND_ERROR_IS_FATAL ANY)
endforeach()

execute_process(
    COMMAND "${KS_BROTLI_EXECUTABLE}" --quality=11 --stdout
        "${_ks_asset_dir}/kernelshark.wasm"
    OUTPUT_FILE "${_ks_asset_dir}/kernelshark.wasm.br"
    COMMAND_ERROR_IS_FATAL ANY)

file(GLOB_RECURSE _ks_forbidden_artifacts
    "${KS_DIST_DIR}/*.data"
    "${KS_DIST_DIR}/plugin-*.so")
if(_ks_forbidden_artifacts)
    message(FATAL_ERROR
        "Unexpected deployment artifacts: ${_ks_forbidden_artifacts}")
endif()
