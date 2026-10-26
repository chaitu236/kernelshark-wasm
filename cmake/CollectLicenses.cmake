function(ks_register_notice source destination)
    if(NOT EXISTS "${source}" OR IS_DIRECTORY "${source}")
        message(FATAL_ERROR "Missing license input: ${source}")
    endif()
    list(APPEND _ks_notice_sources "${source}")
    list(APPEND _ks_notice_destinations "${destination}")
    set(_ks_notice_sources "${_ks_notice_sources}" PARENT_SCOPE)
    set(_ks_notice_destinations "${_ks_notice_destinations}" PARENT_SCOPE)
endfunction()

function(ks_prepare_licenses)
    set(_ks_notice_sources "")
    set(_ks_notice_destinations "")
    set(_ks_notices "KernelShark WebAssembly third-party notices\n\n")
    include("${KS_PROJECT_ROOT}/cmake/Versions.cmake")
    string(APPEND _ks_notices
        "KernelShark: ${KS_KERNELSHARK_REVISION}\n"
        "libtraceevent: ${KS_LIBTRACEEVENT_REVISION}\n"
        "libtracefs: ${KS_LIBTRACEFS_REVISION}\n"
        "libtracecmd: ${KS_TRACE_CMD_REVISION}\n"
        "json-c: ${KS_JSON_C_REVISION}\n"
        "Zstandard: ${KS_ZSTD_REVISION}\n"
        "Qt: ${KS_QT_VERSION}\nEmscripten: ${KS_EMSCRIPTEN_VERSION}\n\n"
        "Upstream license texts and source notices follow. Some source license\n"
        "alternatives and build-time components are retained conservatively;\n"
        "their inclusion here does not change the combined program's license.\n"
        "Zstandard licensing alternative selected: BSD-3-Clause.\n\n")

    foreach(_ks_component IN ITEMS kernelshark libtraceevent libtracefs trace_cmd)
        foreach(_ks_license IN ITEMS GPL-2.0 LGPL-2.1)
            ks_register_notice(
                "${KS_COMPONENT_SOURCE_ROOT}/${_ks_component}/LICENSES/${_ks_license}"
                "LICENSES/${_ks_component}/${_ks_license}")
        endforeach()
    endforeach()
    ks_register_notice("${KS_COMPONENT_SOURCE_ROOT}/json_c/COPYING"
        "LICENSES/json_c/COPYING")
    ks_register_notice("${KS_COMPONENT_SOURCE_ROOT}/zstd/LICENSE"
        "LICENSES/zstd/LICENSE")
    foreach(_ks_component IN ITEMS kernelshark libtraceevent libtracefs trace_cmd json_c zstd)
        if(_ks_component STREQUAL "trace_cmd")
            set(_ks_library_root "${KS_COMPONENT_SOURCE_ROOT}/${_ks_component}/lib/trace-cmd")
        elseif(_ks_component STREQUAL "json_c")
            set(_ks_library_root "${KS_COMPONENT_SOURCE_ROOT}/${_ks_component}")
        elseif(_ks_component STREQUAL "zstd")
            set(_ks_library_root "${KS_COMPONENT_SOURCE_ROOT}/${_ks_component}/lib")
        else()
            set(_ks_library_root "${KS_COMPONENT_SOURCE_ROOT}/${_ks_component}/src")
        endif()
        file(GLOB_RECURSE _ks_sources LIST_DIRECTORIES FALSE
            "${_ks_library_root}/*.c" "${_ks_library_root}/*.h"
            "${_ks_library_root}/*.cpp" "${_ks_library_root}/*.hpp")
        set(_ks_copyright_lines "")
        foreach(_ks_source IN LISTS _ks_sources)
            file(STRINGS "${_ks_source}" _ks_source_copyright
                LIMIT_INPUT 8192 REGEX "[Cc]opyright")
            list(APPEND _ks_copyright_lines ${_ks_source_copyright})
        endforeach()
        list(REMOVE_DUPLICATES _ks_copyright_lines)
        list(SORT _ks_copyright_lines)
        string(APPEND _ks_notices "${_ks_component} source copyright notices:\n")
        foreach(_ks_copyright IN LISTS _ks_copyright_lines)
            string(APPEND _ks_notices "${_ks_copyright}\n")
        endforeach()
        string(APPEND _ks_notices "\n")
    endforeach()

    set(_ks_parser "${KS_COMPONENT_SOURCE_ROOT}/libtracefs/src/sqlhist.tab.c")
    if(NOT EXISTS "${_ks_parser}")
        message(FATAL_ERROR "Missing generated parser notices: ${_ks_parser}")
    endif()
    file(READ "${_ks_parser}" _ks_parser_header LIMIT 8192)
    string(FIND "${_ks_parser_header}" "/* C LALR(1)" _ks_parser_header_end)
    if(_ks_parser_header_end LESS 1)
        message(FATAL_ERROR "Unrecognized Bison license header: ${_ks_parser}")
    endif()
    string(SUBSTRING "${_ks_parser_header}" 0 ${_ks_parser_header_end} _ks_parser_header)
    string(APPEND _ks_notices "libtracefs generated parser:\n${_ks_parser_header}\n")

    set(_ks_emscripten "${KS_EMSDK_ROOT}/upstream/emscripten")
    foreach(_ks_file IN ITEMS LICENSE AUTHORS)
        ks_register_notice("${_ks_emscripten}/${_ks_file}"
            "LICENSES/emscripten/${_ks_file}")
    endforeach()
    foreach(_ks_library IN ITEMS libcxx libcxxabi libunwind compiler-rt)
        ks_register_notice("${_ks_emscripten}/system/lib/${_ks_library}/LICENSE.TXT"
            "LICENSES/emscripten/${_ks_library}/LICENSE.TXT")
    endforeach()
    ks_register_notice("${_ks_emscripten}/system/lib/libc/musl/COPYRIGHT"
        "LICENSES/emscripten/musl/COPYRIGHT")

    if(NOT EXISTS "${KS_QT_LICENSE_DIR}/FILES.sha256")
        message(FATAL_ERROR
            "Qt license manifest missing. Rebuild the builder image or supply KS_QT_LICENSE_DIR.")
    endif()
    file(STRINGS "${KS_QT_LICENSE_DIR}/FILES.sha256" _ks_qt_manifest)
    if(NOT _ks_qt_manifest)
        message(FATAL_ERROR "Qt license manifest is empty")
    endif()
    foreach(_ks_record IN LISTS _ks_qt_manifest)
        if(NOT _ks_record MATCHES "^([0-9a-f]+)  (.+)$")
            message(FATAL_ERROR "Invalid Qt notice manifest entry: ${_ks_record}")
        endif()
        set(_ks_expected_hash "${CMAKE_MATCH_1}")
        set(_ks_file "${CMAKE_MATCH_2}")
        string(LENGTH "${_ks_expected_hash}" _ks_hash_length)
        if(NOT _ks_hash_length EQUAL 64 OR IS_ABSOLUTE "${_ks_file}"
                OR _ks_file MATCHES "(^|/)\\.\\.(/|$)")
            message(FATAL_ERROR "Invalid Qt notice path or hash: ${_ks_record}")
        endif()
        ks_register_notice("${KS_QT_LICENSE_DIR}/${_ks_file}"
            "LICENSES/qt/${_ks_file}")
        file(SHA256 "${KS_QT_LICENSE_DIR}/${_ks_file}" _ks_actual_hash)
        if(NOT _ks_actual_hash STREQUAL _ks_expected_hash)
            message(FATAL_ERROR "Qt notice checksum mismatch: ${_ks_file}")
        endif()
    endforeach()
    ks_register_notice("${KS_QT_LICENSE_DIR}/FILES.sha256" "LICENSES/qt/FILES.sha256")
    file(READ "${KS_QT_LICENSE_DIR}/qt-version.txt" _ks_qt_notice_version)
    string(STRIP "${_ks_qt_notice_version}" _ks_qt_notice_version)
    if(NOT _ks_qt_notice_version STREQUAL KS_QT_VERSION)
        message(FATAL_ERROR "Qt notice bundle does not match Qt ${KS_QT_VERSION}")
    endif()
    file(READ "${KS_QT_LICENSE_DIR}/THIRD-PARTY-NOTICES.txt" _ks_qt_notices)
    string(APPEND _ks_notices "${_ks_qt_notices}\n")

    ks_register_notice("${KS_ICON_LICENSE_SOURCE}" "LICENSES/kernelshark/CC_BY-4.0")
    string(APPEND _ks_notices
        "KernelShark favicon (KS_icon_shark.svg)\n"
        "Creator: Stela Stamenkova; contributed to the KernelShark project.\n"
        "License: Creative Commons Attribution 4.0 International.\n"
        "https://creativecommons.org/licenses/by/4.0/\n"
        "Source: https://git.kernel.org/pub/scm/utils/trace-cmd/kernel-shark.git/tree/icons/KS_icon_shark.svg?id=${KS_KERNELSHARK_REVISION}\n"
        "Attribution: https://lore.kernel.org/linux-trace-devel/20190607095056.14666-2-ykaradzhov@vmware.com/\n"
        "Copied unchanged from upstream; filename changed to favicon.svg.\n\n"
        "Full license and notice files:\n")
    foreach(_ks_destination IN LISTS _ks_notice_destinations)
        string(APPEND _ks_notices "${_ks_destination}\n")
    endforeach()
    set(_ks_notice_sources "${_ks_notice_sources}" PARENT_SCOPE)
    set(_ks_notice_destinations "${_ks_notice_destinations}" PARENT_SCOPE)
    set(_ks_dependency_notices "${_ks_notices}" PARENT_SCOPE)
endfunction()

function(ks_write_licenses)
    list(LENGTH _ks_notice_sources _ks_count)
    math(EXPR _ks_last "${_ks_count} - 1")
    foreach(_ks_index RANGE 0 ${_ks_last})
        list(GET _ks_notice_sources ${_ks_index} _ks_source)
        list(GET _ks_notice_destinations ${_ks_index} _ks_destination)
        get_filename_component(_ks_parent "${KS_DIST_DIR}/${_ks_destination}" DIRECTORY)
        file(MAKE_DIRECTORY "${_ks_parent}")
        file(COPY_FILE "${_ks_source}" "${KS_DIST_DIR}/${_ks_destination}")
    endforeach()
    file(WRITE "${KS_DIST_DIR}/THIRD-PARTY-NOTICES.txt" "${_ks_dependency_notices}")
endfunction()
