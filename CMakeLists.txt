cmake_minimum_required(VERSION 3.20)
project(ai-kernel-optimization-analyzer
  VERSION 0.1.0
  LANGUAGES C CXX
  DESCRIPTION "LLVM-based analysis tool for AI and HPC kernel optimization diagnostics"
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Warnings: strict in CI, configurable
option(ANALYZER_STRICT_WARNINGS "Treat warnings as errors in CI" OFF)
if(ANALYZER_STRICT_WARNINGS)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
endif()

# Find LLVM (config mode; supports system or custom install)
find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "LLVM CMake dir: ${LLVM_CMAKE_DIR}")

include_directories(${LLVM_INCLUDE_DIRS})
separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
add_definitions(${LLVM_DEFINITIONS_LIST})

# Components needed for IR/bitcode loading and analysis.
# IRReader can parse both .ll and .bc via parseIRFile.
llvm_map_components_to_libnames(LLVM_LIBS
  Core
  Support
  IRReader
  Analysis
  Passes
)

add_executable(analyzer
  src/main.cpp
  src/cli/CommandLine.cpp
  src/core/IRLoader.cpp
  src/core/FunctionInfo.cpp
  src/core/AnalysisContext.cpp
  src/core/KernelClassifier.cpp
  src/analyzers/LoopAnalyzer.cpp
  src/analyzers/MemoryAccessAnalyzer.cpp
  src/analyzers/InstructionMixAnalyzer.cpp
  src/analyzers/VectorizationAnalyzer.cpp
  src/analyzers/RedundantLoadAnalyzer.cpp
  src/diagnostics/Diagnostic.cpp
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
