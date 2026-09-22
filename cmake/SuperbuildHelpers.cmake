function(ks_patch_command output revision patch_directory)
    file(GLOB _ks_patches CONFIGURE_DEPENDS
        "${patch_directory}/*.patch")
    list(SORT _ks_patches)

    set(_ks_command
        "${KS_GIT_EXECUTABLE}" -C <SOURCE_DIR> reset --hard "${revision}"
        COMMAND "${KS_GIT_EXECUTABLE}" -C <SOURCE_DIR> clean -fdx)

    foreach(_ks_patch IN LISTS _ks_patches)
        list(APPEND _ks_command
            COMMAND "${KS_GIT_EXECUTABLE}" -C <SOURCE_DIR> apply
                --whitespace=error-all "${_ks_patch}")
    endforeach()

    set(${output} "${_ks_command}" PARENT_SCOPE)
endfunction()

function(ks_external_project_directories project_name)
    set(${project_name}_SOURCE_DIR
        "${KS_SOURCE_ROOT}/${project_name}" PARENT_SCOPE)
    set(${project_name}_BINARY_DIR
        "${KS_BUILD_ROOT}/${project_name}" PARENT_SCOPE)
    set(${project_name}_STAMP_DIR
        "${KS_STAMP_ROOT}/${project_name}" PARENT_SCOPE)
endfunction()
