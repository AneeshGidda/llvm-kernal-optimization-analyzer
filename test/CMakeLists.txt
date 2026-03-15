cmake_minimum_required(VERSION 3.20)

enable_testing()

# Integration: run analyzer on fixture IR
set(FIXTURE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/ir")
set(FIXTURE_IR "${FIXTURE_DIR}/simple.ll")
if(EXISTS "${FIXTURE_IR}")
  add_test(
    NAME integration_loader_valid_ir
    COMMAND $<TARGET_FILE:analyzer> "${FIXTURE_IR}"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )
  add_test(
    NAME integration_loader_help
    COMMAND $<TARGET_FILE:analyzer> --help
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )
  add_test(
    NAME integration_loader_invalid_file
    COMMAND $<TARGET_FILE:analyzer> /nonexistent/path.ll
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )
  set_tests_properties(integration_loader_invalid_file PROPERTIES WILL_FAIL true)

  add_test(
    NAME integration_json_output
    COMMAND $<TARGET_FILE:analyzer> --json "${FIXTURE_IR}"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )
  set_tests_properties(integration_json_output PROPERTIES
    PASS_REGULAR_EXPRESSION "diagnostics"
  )
endif()

# Fixture corpus: run analyzer and check for expected phrases
# redundant_load.ll needs --all so small functions (redundant_in_block, invariant_in_loop) are analyzed
set(FIXTURE_NAMES simple matmul reduction branch_heavy stencil_like redundant_load)
foreach(FIX_NAME ${FIXTURE_NAMES})
  set(FPATH "${FIXTURE_DIR}/${FIX_NAME}.ll")
  if(EXISTS "${FPATH}")
    if(FIX_NAME STREQUAL "redundant_load")
      add_test(
        NAME integration_fixture_${FIX_NAME}
        COMMAND $<TARGET_FILE:analyzer> --all "${FPATH}"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
      )
    else()
      add_test(
        NAME integration_fixture_${FIX_NAME}
        COMMAND $<TARGET_FILE:analyzer> "${FPATH}"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
      )
    endif()
    set_tests_properties(integration_fixture_${FIX_NAME} PROPERTIES
      PASS_REGULAR_EXPRESSION "Summary|loop header|depth="
    )
  endif()
endforeach()

# Expected findings per fixture (key phrases)
if(EXISTS "${FIXTURE_DIR}/branch_heavy.ll")
  add_test(
    NAME integration_fixture_branch_heavy_findings
    COMMAND $<TARGET_FILE:analyzer> "${FIXTURE_DIR}/branch_heavy.ll"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )
  set_tests_properties(integration_fixture_branch_heavy_findings PROPERTIES
    PASS_REGULAR_EXPRESSION "likely blocked|Vectorization"
  )
endif()
if(EXISTS "${FIXTURE_DIR}/redundant_load.ll")
  add_test(
    NAME integration_fixture_redundant_load_findings
    COMMAND $<TARGET_FILE:analyzer> --all "${FIXTURE_DIR}/redundant_load.ll"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )
  set_tests_properties(integration_fixture_redundant_load_findings PROPERTIES
    PASS_REGULAR_EXPRESSION "redundant|RedundantLoad|hoist"
  )
endif()
if(EXISTS "${FIXTURE_DIR}/reduction.ll")
  add_test(
    NAME integration_fixture_reduction_findings
    COMMAND $<TARGET_FILE:analyzer> "${FIXTURE_DIR}/reduction.ll"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  )
  set_tests_properties(integration_fixture_reduction_findings PROPERTIES
    PASS_REGULAR_EXPRESSION "loop header|depth=|reduction|vectoriz"
  )
endif()
