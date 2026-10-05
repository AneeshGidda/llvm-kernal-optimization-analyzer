cmake_minimum_required(VERSION 3.20)
project(ai-kernel-optimization-analyzer
  VERSION 0.1.0
  LANGUAGES C CXX
  DESCRIPTION "Explains which loops LLVM failed to optimize, why, and how to fix it"
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Warnings: strict in CI, configurable
option(ANALYZER_STRICT_WARNINGS "Treat warnings as errors in CI" OFF)
if(ANALYZER_STRICT_WARNINGS)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
endif()

# Find LLVM (config mode; supports system or custom install). The analyzer
# uses LLVM 15 APIs and reports LLVM 15's vectorizer decisions, so other
# versions are rejected here rather than failing later in the build.
find_package(LLVM 15 REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "LLVM CMake dir: ${LLVM_CMAKE_DIR}")

include_directories(${LLVM_INCLUDE_DIRS})
separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
add_definitions(${LLVM_DEFINITIONS_LIST})

# Prefer the shared libLLVM (Homebrew and apt ship it): we need every target
# backend so cost queries match the triple in the input IR, and linking them
# statically is slow and large.
if(TARGET LLVM)
  set(LLVM_LIBS LLVM)
else()
  llvm_map_components_to_libnames(LLVM_LIBS
    Core
    Support
    IRReader
    Analysis
    Passes
    TransformUtils
    Vectorize
    Target
    AllTargetsCodeGens
    AllTargetsDescs
    AllTargetsInfos
  )
endif()

add_executable(analyzer
  src/main.cpp
  src/cli/CommandLine.cpp
  src/core/IRLoader.cpp
  src/core/IRNames.cpp
  src/core/LLVMAnalyses.cpp
  src/core/LoopCatalog.cpp
  src/core/VectorizerOracle.cpp
  src/analyzers/GpuAnalyzer.cpp
  src/analyzers/MemoryAccessAnalyzer.cpp
  src/analyzers/VectorizationAnalyzer.cpp
  src/diagnostics/DiagnosticEmitter.cpp
  src/diagnostics/ReportFormatter.cpp
)

target_include_directories(analyzer PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${LLVM_INCLUDE_DIRS}
)

target_link_libraries(analyzer PRIVATE ${LLVM_LIBS})

# Optional: install
install(TARGETS analyzer RUNTIME DESTINATION bin)

enable_testing()
add_subdirectory(test)
