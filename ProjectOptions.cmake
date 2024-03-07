include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(stl_data_structures_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(stl_data_structures_setup_options)
  option(stl_data_structures_ENABLE_HARDENING "Enable hardening" ON)
  option(stl_data_structures_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    stl_data_structures_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    stl_data_structures_ENABLE_HARDENING
    OFF)

  stl_data_structures_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR stl_data_structures_PACKAGING_MAINTAINER_MODE)
    option(stl_data_structures_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(stl_data_structures_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(stl_data_structures_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(stl_data_structures_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(stl_data_structures_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(stl_data_structures_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(stl_data_structures_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(stl_data_structures_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(stl_data_structures_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(stl_data_structures_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(stl_data_structures_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(stl_data_structures_ENABLE_PCH "Enable precompiled headers" OFF)
    option(stl_data_structures_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(stl_data_structures_ENABLE_IPO "Enable IPO/LTO" ON)
    option(stl_data_structures_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(stl_data_structures_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(stl_data_structures_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(stl_data_structures_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(stl_data_structures_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(stl_data_structures_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(stl_data_structures_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(stl_data_structures_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(stl_data_structures_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(stl_data_structures_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(stl_data_structures_ENABLE_PCH "Enable precompiled headers" OFF)
    option(stl_data_structures_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      stl_data_structures_ENABLE_IPO
      stl_data_structures_WARNINGS_AS_ERRORS
      stl_data_structures_ENABLE_USER_LINKER
      stl_data_structures_ENABLE_SANITIZER_ADDRESS
      stl_data_structures_ENABLE_SANITIZER_LEAK
      stl_data_structures_ENABLE_SANITIZER_UNDEFINED
      stl_data_structures_ENABLE_SANITIZER_THREAD
      stl_data_structures_ENABLE_SANITIZER_MEMORY
      stl_data_structures_ENABLE_UNITY_BUILD
      stl_data_structures_ENABLE_CLANG_TIDY
      stl_data_structures_ENABLE_CPPCHECK
      stl_data_structures_ENABLE_COVERAGE
      stl_data_structures_ENABLE_PCH
      stl_data_structures_ENABLE_CACHE)
  endif()

  stl_data_structures_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (stl_data_structures_ENABLE_SANITIZER_ADDRESS OR stl_data_structures_ENABLE_SANITIZER_THREAD OR stl_data_structures_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(stl_data_structures_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(stl_data_structures_global_options)
  if(stl_data_structures_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    stl_data_structures_enable_ipo()
  endif()

  stl_data_structures_supports_sanitizers()

  if(stl_data_structures_ENABLE_HARDENING AND stl_data_structures_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR stl_data_structures_ENABLE_SANITIZER_UNDEFINED
       OR stl_data_structures_ENABLE_SANITIZER_ADDRESS
       OR stl_data_structures_ENABLE_SANITIZER_THREAD
       OR stl_data_structures_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${stl_data_structures_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${stl_data_structures_ENABLE_SANITIZER_UNDEFINED}")
    stl_data_structures_enable_hardening(stl_data_structures_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(stl_data_structures_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(stl_data_structures_warnings INTERFACE)
  add_library(stl_data_structures_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  stl_data_structures_set_project_warnings(
    stl_data_structures_warnings
    ${stl_data_structures_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(stl_data_structures_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(stl_data_structures_options)
  endif()

  include(cmake/Sanitizers.cmake)
  stl_data_structures_enable_sanitizers(
    stl_data_structures_options
    ${stl_data_structures_ENABLE_SANITIZER_ADDRESS}
    ${stl_data_structures_ENABLE_SANITIZER_LEAK}
    ${stl_data_structures_ENABLE_SANITIZER_UNDEFINED}
    ${stl_data_structures_ENABLE_SANITIZER_THREAD}
    ${stl_data_structures_ENABLE_SANITIZER_MEMORY})

  set_target_properties(stl_data_structures_options PROPERTIES UNITY_BUILD ${stl_data_structures_ENABLE_UNITY_BUILD})

  if(stl_data_structures_ENABLE_PCH)
    target_precompile_headers(
      stl_data_structures_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(stl_data_structures_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    stl_data_structures_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(stl_data_structures_ENABLE_CLANG_TIDY)
    stl_data_structures_enable_clang_tidy(stl_data_structures_options ${stl_data_structures_WARNINGS_AS_ERRORS})
  endif()

  if(stl_data_structures_ENABLE_CPPCHECK)
    stl_data_structures_enable_cppcheck(${stl_data_structures_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(stl_data_structures_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    stl_data_structures_enable_coverage(stl_data_structures_options)
  endif()

  if(stl_data_structures_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(stl_data_structures_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(stl_data_structures_ENABLE_HARDENING AND NOT stl_data_structures_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR stl_data_structures_ENABLE_SANITIZER_UNDEFINED
       OR stl_data_structures_ENABLE_SANITIZER_ADDRESS
       OR stl_data_structures_ENABLE_SANITIZER_THREAD
       OR stl_data_structures_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    stl_data_structures_enable_hardening(stl_data_structures_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
