cmake_minimum_required(VERSION 3.21)
project(EmptyWindowApp LANGUAGES C CXX OBJC)

# 指定 C++17 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(MACOSX_BUNDLE YES)
set(MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist")

# CEF 相关
set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/cef")
list(APPEND CMAKE_MODULE_PATH "${CEF_ROOT}/cmake")
find_package(CEF REQUIRED)
add_subdirectory(${CEF_LIBCEF_DLL_WRAPPER_PATH} libcef_dll_wrapper)

#
# 主进程可执行 (EmptyWindowApp)
#
add_executable(${PROJECT_NAME} MACOSX_BUNDLE main.mm)
target_compile_options(${PROJECT_NAME} PRIVATE -fobjc-arc)
target_link_libraries(${PROJECT_NAME}
    libcef_dll_wrapper
    ${CEF_STANDARD_LIBS}
    "-framework Cocoa"
    "-F${CEF_BINARY_DIR}"
    "-framework Chromium Embedded Framework"
)
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CEF_INCLUDE_PATH}
)

# 拷贝 CEF Framework 到主 .app
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${CEF_BINARY_DIR}/Chromium Embedded Framework.framework"
    "$<TARGET_BUNDLE_CONTENT_DIR:${PROJECT_NAME}>/Frameworks/Chromium Embedded Framework.framework"
)

#
# Helper 进程 (EmptyWindowApp Helper)
#
set(HELPER_TARGET "${PROJECT_NAME}_Helper")
set(HELPER_NAME "${PROJECT_NAME} Helper")

# 准备 helper Info.plist
set(_helper_info_plist_in "${CMAKE_CURRENT_SOURCE_DIR}/helper-Info.plist.in")
set(_helper_info_plist_out "${CMAKE_CURRENT_BINARY_DIR}/helper-Info.plist")

file(READ "${_helper_info_plist_in}" _plist_contents)
string(REPLACE "\${EXECUTABLE_NAME}" "${HELPER_NAME}" _plist_contents ${_plist_contents})
string(REPLACE "\${PRODUCT_NAME}" "${HELPER_NAME}" _plist_contents ${_plist_contents})
string(REPLACE "\${BUNDLE_ID_SUFFIX}" ".helper" _plist_contents ${_plist_contents})
file(WRITE ${_helper_info_plist_out} ${_plist_contents})

set(HELPER_SOURCES
    process_helper_mac.cc # 你自己准备的 Helper 进程入口
)

add_executable(${HELPER_TARGET} MACOSX_BUNDLE ${HELPER_SOURCES})
set_target_properties(${HELPER_TARGET} PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST ${_helper_info_plist_out}
    OUTPUT_NAME "${HELPER_NAME}"
)
target_link_libraries(${HELPER_TARGET}
    libcef_dll_wrapper
    ${CEF_STANDARD_LIBS}
)
target_compile_options(${HELPER_TARGET} PRIVATE -fobjc-arc)
target_include_directories(${HELPER_TARGET} PRIVATE
    ${CEF_INCLUDE_PATH}
)

set_target_properties(${PROJECT_NAME} PROPERTIES
    BUILD_RPATH "@executable_path/../Frameworks"
    INSTALL_RPATH "@executable_path/../Frameworks"
)

set_target_properties(${HELPER_TARGET} PROPERTIES
    BUILD_RPATH "@executable_path/../Frameworks"
    INSTALL_RPATH "@executable_path/../Frameworks"
)

#
# 关键点：让主目标依赖 Helper，以便在主目标的 Post Build 阶段可以复制到 .app
#
add_dependencies(${PROJECT_NAME} ${HELPER_TARGET})

#
# 拷贝 Helper.app 到主 .app 的 Frameworks 目录
# 注意改用 $<TARGET_BUNDLE_DIR:target>，而不是 $<TARGET_FILE_DIR:target>
#
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    "$<TARGET_BUNDLE_DIR:${HELPER_TARGET}>"
    "$<TARGET_BUNDLE_CONTENT_DIR:${PROJECT_NAME}>/Frameworks/${HELPER_NAME}.app"
    COMMENT "Copying ${HELPER_NAME}.app into main app's Frameworks dir..."
)

message(STATUS "===== Done building EmptyWindowApp & Helper. =====")