cmake_minimum_required(VERSION 3.24)

foreach(_ks_required_variable
        KS_QT_SOURCE_ROOT
        KS_QT_LICENSE_DIR
        KS_QT_VERSION)
    if(NOT DEFINED ${_ks_required_variable})
        message(FATAL_ERROR "${_ks_required_variable} is required")
    endif()
endforeach()

function(ks_copy_qt_notice relative_path)
    set(_ks_source "${KS_QT_SOURCE_ROOT}/${relative_path}")
    if(NOT EXISTS "${_ks_source}" OR IS_DIRECTORY "${_ks_source}")
        message(FATAL_ERROR "Missing Qt notice: ${relative_path}")
    endif()
    get_filename_component(_ks_parent
        "${KS_QT_LICENSE_DIR}/${relative_path}" DIRECTORY)
    file(MAKE_DIRECTORY "${_ks_parent}")
    file(COPY_FILE "${_ks_source}" "${KS_QT_LICENSE_DIR}/${relative_path}")
    file(SHA256 "${_ks_source}" _ks_hash)
    string(APPEND _ks_qt_notice_manifest "${_ks_hash}  ${relative_path}\n")
    set(_ks_qt_notice_manifest "${_ks_qt_notice_manifest}" PARENT_SCOPE)
endfunction()

foreach(_ks_license IN ITEMS
        LICENSE.GPL2 LICENSE.GPL3 LICENSE.GPL3-EXCEPT LICENSE.LGPL3)
    ks_copy_qt_notice("${_ks_license}")
endforeach()

set(_ks_metadata_directories
    qtbase/src/3rdparty/harfbuzz-ng
    qtbase/src/3rdparty/freetype
    qtbase/src/3rdparty/libpng
    qtbase/src/3rdparty/libjpeg
    qtbase/src/3rdparty/pcre2
    qtbase/src/3rdparty/zlib
    qtbase/src/3rdparty/wasm
    qtimageformats/src/3rdparty/libtiff
    qtimageformats/src/3rdparty/libwebp)

set(_ks_notices "Qt ${KS_QT_VERSION} for WebAssembly\n")
string(APPEND _ks_notices
    "Copyright (C) The Qt Company Ltd. and other contributors.\n"
    "Open-source WASM platform and loader: GPL version 3.\n"
    "Source license alternatives and dependency notices are retained below.\n\n")

foreach(_ks_directory IN LISTS _ks_metadata_directories)
    set(_ks_metadata_path "${_ks_directory}/qt_attribution.json")
    ks_copy_qt_notice("${_ks_metadata_path}")
    file(READ "${KS_QT_SOURCE_ROOT}/${_ks_metadata_path}" _ks_metadata)
    string(JSON _ks_type TYPE "${_ks_metadata}")
    if(_ks_type STREQUAL "OBJECT")
        set(_ks_metadata "[${_ks_metadata}]")
    elseif(NOT _ks_type STREQUAL "ARRAY")
        message(FATAL_ERROR "Invalid Qt notice metadata: ${_ks_metadata_path}")
    endif()
    string(JSON _ks_count LENGTH "${_ks_metadata}")
    if(_ks_count LESS 1)
        message(FATAL_ERROR "Empty Qt notice metadata: ${_ks_metadata_path}")
    endif()
    math(EXPR _ks_last "${_ks_count} - 1")
    foreach(_ks_index RANGE 0 ${_ks_last})
        string(JSON _ks_entry GET "${_ks_metadata}" ${_ks_index})
        string(JSON _ks_name GET "${_ks_entry}" Name)
        string(JSON _ks_license_id GET "${_ks_entry}" LicenseId)
        string(APPEND _ks_notices
            "${_ks_name}\nDeclared license: ${_ks_license_id}\n")

        set(_ks_license_files "")
        string(JSON _ks_license_file ERROR_VARIABLE _ks_error
            GET "${_ks_entry}" LicenseFile)
        if(NOT _ks_error)
            list(APPEND _ks_license_files "${_ks_license_file}")
        endif()
        string(JSON _ks_file_count ERROR_VARIABLE _ks_error
            LENGTH "${_ks_entry}" LicenseFiles)
        if(NOT _ks_error AND _ks_file_count GREATER 0)
            math(EXPR _ks_file_last "${_ks_file_count} - 1")
            foreach(_ks_file_index RANGE 0 ${_ks_file_last})
                string(JSON _ks_license_file GET "${_ks_entry}"
                    LicenseFiles ${_ks_file_index})
                list(APPEND _ks_license_files "${_ks_license_file}")
            endforeach()
        endif()
        if(NOT _ks_license_files)
            message(FATAL_ERROR "No license files declared for ${_ks_name}")
        endif()
        foreach(_ks_license_file IN LISTS _ks_license_files)
            ks_copy_qt_notice("${_ks_directory}/${_ks_license_file}")
            string(APPEND _ks_notices
                "License text: ${_ks_directory}/${_ks_license_file}\n")
        endforeach()

        set(_ks_has_copyright FALSE)
        string(JSON _ks_copyright ERROR_VARIABLE _ks_error
            GET "${_ks_entry}" Copyright)
        if(NOT _ks_error)
            string(APPEND _ks_notices "${_ks_copyright}\n")
            set(_ks_has_copyright TRUE)
        endif()
        string(JSON _ks_copyright_file ERROR_VARIABLE _ks_error
            GET "${_ks_entry}" CopyrightFile)
        if(NOT _ks_error)
            ks_copy_qt_notice("${_ks_directory}/${_ks_copyright_file}")
            file(READ
                "${KS_QT_SOURCE_ROOT}/${_ks_directory}/${_ks_copyright_file}"
                _ks_copyright)
            string(APPEND _ks_notices "${_ks_copyright}\n")
            set(_ks_has_copyright TRUE)
        endif()
        if(NOT _ks_has_copyright)
            message(FATAL_ERROR "No copyright notice declared for ${_ks_name}")
        endif()
        string(APPEND _ks_notices "\n")
    endforeach()
endforeach()

ks_copy_qt_notice("qtimageformats/src/3rdparty/libwebp/PATENTS")
string(APPEND _ks_notices
    "FreeType licensing alternative selected: FreeType Project License (FTL).\n"
    "This software is based in part on the work of the FreeType Team.\n"
    "This software is based in part on the work of the Independent JPEG Group.\n")
file(WRITE "${KS_QT_LICENSE_DIR}/THIRD-PARTY-NOTICES.txt" "${_ks_notices}")
file(WRITE "${KS_QT_LICENSE_DIR}/qt-version.txt" "${KS_QT_VERSION}\n")
foreach(_ks_notice IN ITEMS THIRD-PARTY-NOTICES.txt qt-version.txt)
    file(SHA256 "${KS_QT_LICENSE_DIR}/${_ks_notice}" _ks_hash)
    string(APPEND _ks_qt_notice_manifest "${_ks_hash}  ${_ks_notice}\n")
endforeach()
file(WRITE "${KS_QT_LICENSE_DIR}/FILES.sha256" "${_ks_qt_notice_manifest}")
