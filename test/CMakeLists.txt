cmake_minimum_required(VERSION 3.20)

enable_testing()

# Integration: run analyzer on fixture IR
set(FIXTURE_IR "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/ir/simple.ll")
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
