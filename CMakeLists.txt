cmake_minimum_required(VERSION 3.10)

project(EmptyWindowApp LANGUAGES C CXX OBJC)

# 让 CMake 生成 macOS Bundle 应用
set(MACOSX_BUNDLE TRUE)
set(MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist")

# 指定可执行文件并将其打包为 macOS 应用（.app）
add_executable(${PROJECT_NAME} MACOSX_BUNDLE
    main.m
)

# 链接 Cocoa 框架（创建 macOS 原生窗口所需）
target_link_libraries(${PROJECT_NAME}
    "-framework Cocoa"
)