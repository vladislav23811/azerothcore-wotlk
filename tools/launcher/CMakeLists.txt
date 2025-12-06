cmake_minimum_required(VERSION 3.15)
project(WoWLauncher)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt6 or Qt5
find_package(Qt6 COMPONENTS Core Widgets Network REQUIRED)
if(NOT Qt6_FOUND)
    find_package(Qt5 5.15 REQUIRED COMPONENTS Core Widgets Network)
    set(QT_VERSION_MAJOR 5)
else()
    set(QT_VERSION_MAJOR 6)
endif()

# Source files
set(SOURCES
    src/main.cpp
    src/MainWindow.cpp
    src/LauncherCore.cpp
    src/DownloadManager.cpp
)

set(HEADERS
    src/MainWindow.h
    src/LauncherCore.h
    src/DownloadManager.h
)

# UI files (if using Qt Designer)
# set(UI_FILES
#     ui/MainWindow.ui
# )

# Resources (icons, images)
# set(RESOURCES
#     resources/resources.qrc
# )

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

# Link Qt libraries
if(QT_VERSION_MAJOR EQUAL 6)
    target_link_libraries(${PROJECT_NAME} 
        Qt6::Core 
        Qt6::Widgets 
        Qt6::Network
    )
else()
    target_link_libraries(${PROJECT_NAME} 
        Qt5::Core 
        Qt5::Widgets 
        Qt5::Network
    )
endif()

# Windows-specific settings
if(WIN32)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
    
    # Copy Qt DLLs to output directory (for distribution)
    if(QT_VERSION_MAJOR EQUAL 6)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:Qt6::Core>
            $<TARGET_FILE:Qt6::Widgets>
            $<TARGET_FILE:Qt6::Network>
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        )
    endif()
endif()

# Install
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
)

