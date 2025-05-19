# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.15)

# Enforce relative paths in build commands
set(CMAKE_USE_RELATIVE_PATHS ON)
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_INSTALL_RPATH "$ORIGIN")  # Linux

project(rresvg_library VERSION 0.0.1 LANGUAGES C)

# Add Corrosion
include(FetchContent)
FetchContent_Declare(
    Corrosion
    GIT_REPOSITORY https://github.com/corrosion-rs/corrosion.git
    GIT_TAG v0.5.2  # Use latest release tag
)
FetchContent_MakeAvailable(Corrosion)

# Import Rust library
corrosion_import_crate(
    MANIFEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/resvg/crates/c-api/Cargo.toml
    CRATE_TYPES cdylib  # For C-ABI compatible shared library
)

add_library(rresvg SHARED
  "rresvg.c"
)

target_link_libraries(rresvg PUBLIC resvg)

set_target_properties(rresvg PROPERTIES
  PUBLIC_HEADER rresvg.h
  OUTPUT_NAME "rresvg"
)

target_compile_definitions(rresvg PUBLIC DART_SHARED_LIB)
