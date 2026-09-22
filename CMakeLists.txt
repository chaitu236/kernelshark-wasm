cmake_minimum_required(VERSION 3.24)

project(kernelshark-wasm LANGUAGES NONE)

include(ExternalProject)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(Versions)
include(SuperbuildOptions)
include(SuperbuildHelpers)

include(projects/JsonC)
include(projects/LibTraceEvent)
include(projects/LibTraceFS)
include(projects/Zstd)
include(projects/TraceCmd)
include(projects/KernelShark)
