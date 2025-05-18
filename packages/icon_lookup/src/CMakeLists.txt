# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.15)

project(icon_lookup_library VERSION 0.0.1 LANGUAGES C)

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
    MANIFEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/rust/Cargo.toml
    CRATE_TYPES staticlib
)


add_library(icon_lookup SHARED
  "icon_lookup.c"
)

target_link_libraries(icon_lookup PUBLIC rust_icon_lookup)

set_target_properties(icon_lookup PROPERTIES
  PUBLIC_HEADER icon_lookup.h
  OUTPUT_NAME "icon_lookup"
)

target_compile_definitions(icon_lookup PUBLIC DART_SHARED_LIB)
