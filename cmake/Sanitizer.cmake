# Ported from Clickhouse: https://github.com/ClickHouse/ClickHouse/blob/master/cmake/sanitize.cmake

option (SANITIZE "Enable sanitizer: address, memory, undefined, leak (comma separated list)" "")
set (SAN_FLAGS "${SAN_FLAGS} -g -fno-omit-frame-pointer -DSANITIZER")
# O1 is normally set by clang, and -Og by gcc
if (COMPILER_GCC)
    if (ENABLE_FULL_DEBUG MATCHES "ON")
        set (SAN_FLAGS "${SAN_FLAGS} -O0")
    else()
        set (SAN_FLAGS "${SAN_FLAGS} -Og")
    endif()
else ()
    if (ENABLE_FULL_DEBUG MATCHES "ON")
        set (SAN_FLAGS "${SAN_FLAGS} -O0")
    else()
        set (SAN_FLAGS "${SAN_FLAGS} -O1")
    endif()
endif ()
if (SANITIZE)
    if (ENABLE_JEMALLOC MATCHES "ON")
        message (STATUS "Jemalloc support is useless in case of build with sanitizers")
        set (ENABLE_JEMALLOC "OFF")
    endif ()

    string(REPLACE "," ";" SANITIZE_LIST ${SANITIZE})
    foreach(SANITIZE ${SANITIZE_LIST})
        if (SANITIZE STREQUAL "address")
            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fsanitize-address-use-after-scope")
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=address -fsanitize-address-use-after-scope")
            set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address -fsanitize-address-use-after-scope")
            if (COMPILER_GCC)
                set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libasan")
                set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libasan")
                set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libasan")
            endif ()

        elseif (SANITIZE STREQUAL "leak")
            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=leak")
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=leak")
            set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=leak")

        elseif (SANITIZE STREQUAL "memory")
            set (MSAN_FLAGS "-fsanitize=memory -fsanitize-memory-track-origins -fno-optimize-sibling-calls")

            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${MSAN_FLAGS}")
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${MSAN_FLAGS}")
            set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=memory")

            if (COMPILER_GCC)
                set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libmsan")
                set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libmsan")
                set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libmsan")
            endif ()

        elseif (SANITIZE STREQUAL "undefined")
            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=undefined -fno-sanitize-recover=all")
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=undefined -fno-sanitize-recover=all")
            set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=undefined")

            if (COMPILER_GCC)
                set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libubsan")
                set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libubsan")
                set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libubsan")
            endif ()
        else ()
            message (FATAL_ERROR "Unknown sanitizer type: ${SANITIZE}")
        endif ()
    endforeach ()
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SAN_FLAGS}")
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SAN_FLAGS}")
    message (STATUS "Add sanitizer: ${SANITIZE}")
    # Disable sanitizing on make stage e.g. for snowball compiler
    set (ENV{ASAN_OPTIONS} "detect_leaks=0")
    message (STATUS "Sanitizer CFLAGS: ${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE_UC}}")
    message (STATUS "Sanitizer CXXFLAGS: ${CMAKE_CXX_FLAGS} ${CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE_UC}}")
endif()