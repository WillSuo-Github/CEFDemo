cmake_minimum_required(VERSION 3.21)

project(EmptyWindowApp LANGUAGES C CXX OBJC)
set(CMAKE_CONFIGURATION_TYPES Debug Release)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 让 CMake 生成 macOS Bundle 应用
set(MACOSX_BUNDLE TRUE)
set(MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist")

# 指定可执行文件并将其打包为 macOS 应用（.app）
add_executable(${PROJECT_NAME} MACOSX_BUNDLE
    main.mm
    AppDelegate.mm
    AppDelegate.h
    ClientApp.h
    ClientApp.cpp
)

# 链接 Cocoa 框架（创建 macOS 原生窗口所需）
target_link_libraries(${PROJECT_NAME}
    "-framework Cocoa"
)

set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/cef")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CEF_ROOT}/cmake")


find_package(CEF REQUIRED)

# Target executable names.
set(CEF_TARGET ${PROJECT_NAME})

if(OS_MAC)
    set(CEF_HELPER_TARGET "${PROJECT_NAME}_Helper")
    set(CEF_HELPER_OUTPUT_NAME "${PROJECT_NAME} Helper")
else()
    # Logical target used to link the libcef library.
    ADD_LOGICAL_TARGET("libcef_lib" "${CEF_LIB_DEBUG}" "${CEF_LIB_RELEASE}")
endif()

add_subdirectory(${CEF_LIBCEF_DLL_WRAPPER_PATH} libcef_dll_wrapper)


# cefsimple helper sources.
set(CEFSIMPLE_HELPER_SRCS_MAC
    process_helper_mac.cc
)
APPEND_PLATFORM_SOURCES(CEFSIMPLE_HELPER_SRCS)
source_group(cefsimple FILES ${CEFSIMPLE_HELPER_SRCS})

# cefsimple resources.
set(CEFSIMPLE_RESOURCES_MAC_SRCS_MAC
    mac/Info.plist.in
    mac/cefsimple.icns
)
APPEND_PLATFORM_SOURCES(CEFSIMPLE_RESOURCES_MAC_SRCS)
source_group(cefsimple\\\\mac FILES ${CEFSIMPLE_RESOURCES_MAC_SRCS})

set(CEFSIMPLE_RESOURCES_MAC_ENGLISH_LPROJ_SRCS_MAC
    mac/English.lproj/InfoPlist.strings
    mac/English.lproj/MainMenu.xib
)
APPEND_PLATFORM_SOURCES(CEFSIMPLE_RESOURCES_MAC_ENGLISH_LPROJ_SRCS)
source_group(cefsimple\\\\mac\\\\English.lproj FILES ${CEFSIMPLE_RESOURCES_MAC_ENGLISH_LPROJ_SRCS})

set(CEFSIMPLE_RESOURCES_SRCS
    ${CEFSIMPLE_RESOURCES_MAC_SRCS}
    ${CEFSIMPLE_RESOURCES_MAC_ENGLISH_LPROJ_SRCS}
)

# Determine the target output directory.
SET_CEF_TARGET_OUT_DIR()

#
# Mac OS X configuration.
#
if(OS_MAC)
    option(OPTION_USE_ARC "Build with ARC (automatic Reference Counting) on macOS." ON)

    if(OPTION_USE_ARC)
        list(APPEND CEF_COMPILER_FLAGS
            -fobjc-arc
        )
        set_target_properties(${target} PROPERTIES
            CLANG_ENABLE_OBJC_ARC "YES"
        )
    endif()

    # Output path for the main app bundle.
    set(CEF_APP "${CEF_TARGET_OUT_DIR}/${CEF_TARGET}.app")

    # Variables referenced from the main Info.plist file.
    set(EXECUTABLE_NAME "${CEF_TARGET}")
    set(PRODUCT_NAME "${CEF_TARGET}")

    if(USE_SANDBOX)
        # Logical target used to link the cef_sandbox library.
        ADD_LOGICAL_TARGET("cef_sandbox_lib" "${CEF_SANDBOX_LIB_DEBUG}" "${CEF_SANDBOX_LIB_RELEASE}")
    endif()

    # Main app bundle target.
    SET_EXECUTABLE_TARGET_PROPERTIES(${CEF_TARGET})
    add_dependencies(${CEF_TARGET} libcef_dll_wrapper)
    target_link_libraries(${CEF_TARGET} libcef_dll_wrapper ${CEF_STANDARD_LIBS})
    set_target_properties(${CEF_TARGET} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/mac/Info.plist.in
    )

    # Copy the CEF framework into the Frameworks directory.
    add_custom_command(
        TARGET ${CEF_TARGET}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CEF_BINARY_DIR}/Chromium Embedded Framework.framework"
        "${CEF_APP}/Contents/Frameworks/Chromium Embedded Framework.framework"
        VERBATIM
    )

    # Create the multiple Helper app bundle targets.
    foreach(_suffix_list ${CEF_HELPER_APP_SUFFIXES})
        # Convert to a list and extract the suffix values.
        string(REPLACE ":" ";" _suffix_list ${_suffix_list})
        list(GET _suffix_list 0 _name_suffix)
        list(GET _suffix_list 1 _target_suffix)
        list(GET _suffix_list 2 _plist_suffix)

        # Define Helper target and output names.
        set(_helper_target "${CEF_HELPER_TARGET}${_target_suffix}")
        set(_helper_output_name "${CEF_HELPER_OUTPUT_NAME}${_name_suffix}")

        # Create Helper-specific variants of the helper-Info.plist file. Do this
        # manually because the configure_file command (which is executed as part of
        # MACOSX_BUNDLE_INFO_PLIST) uses global env variables and would insert the
        # wrong values with multiple targets.
        set(_helper_info_plist "${CMAKE_CURRENT_BINARY_DIR}/helper-Info${_target_suffix}.plist")
        file(READ "${CMAKE_CURRENT_SOURCE_DIR}/mac/helper-Info.plist.in" _plist_contents)
        string(REPLACE "\${EXECUTABLE_NAME}" "${_helper_output_name}" _plist_contents ${_plist_contents})
        string(REPLACE "\${PRODUCT_NAME}" "${_helper_output_name}" _plist_contents ${_plist_contents})
        string(REPLACE "\${BUNDLE_ID_SUFFIX}" "${_plist_suffix}" _plist_contents ${_plist_contents})
        file(WRITE ${_helper_info_plist} ${_plist_contents})

        # Create Helper executable target.
        add_executable(${_helper_target} MACOSX_BUNDLE ${CEFSIMPLE_HELPER_SRCS})
        SET_EXECUTABLE_TARGET_PROPERTIES(${_helper_target})
        add_dependencies(${_helper_target} libcef_dll_wrapper)
        target_link_libraries(${_helper_target} libcef_dll_wrapper ${CEF_STANDARD_LIBS})
        set_target_properties(${_helper_target} PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST ${_helper_info_plist}
            OUTPUT_NAME ${_helper_output_name}
        )

        if(USE_SANDBOX)
            target_link_libraries(${_helper_target} cef_sandbox_lib)
        endif()

        # Add the Helper as a dependency of the main executable target.
        add_dependencies(${CEF_TARGET} "${_helper_target}")

        # Copy the Helper app bundle into the Frameworks directory.
        add_custom_command(
            TARGET ${CEF_TARGET}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_TARGET_OUT_DIR}/${_helper_output_name}.app"
            "${CEF_APP}/Contents/Frameworks/${_helper_output_name}.app"
            VERBATIM
        )
    endforeach()

    # Manually process and copy over resource files.
    # The Xcode generator can support this via the set_target_properties RESOURCE
    # directive but that doesn't properly handle nested resource directories.
    # Remove these prefixes from input file paths.
    set(PREFIXES "mac/")
    COPY_MAC_RESOURCES("${CEFSIMPLE_RESOURCES_SRCS}" "${PREFIXES}" "${CEF_TARGET}" "${CMAKE_CURRENT_SOURCE_DIR}" "${CEF_APP}")
endif()

PRINT_CEF_CONFIG()