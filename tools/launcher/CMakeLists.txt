cmake_minimum_required(VERSION 3.15)

# Check if this is being built as a subdirectory (from main CMakeLists.txt)
# or standalone (from tools/launcher directory)
get_directory_property(IS_SUBDIRECTORY PARENT_DIRECTORY)

if(IS_SUBDIRECTORY)
    # Being built as part of main project
    project(WoWLauncher)
else()
    # Being built standalone
    project(WoWLauncher)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt6 or Qt5
# If Qt6 is not found, try Qt5
find_package(Qt6 QUIET COMPONENTS Core Widgets Network)
if(Qt6_FOUND)
    set(QT_VERSION_MAJOR 6)
    message(STATUS "Launcher: Using Qt6")
else()
    find_package(Qt5 5.15 QUIET COMPONENTS Core Widgets Network)
    if(Qt5_FOUND)
        set(QT_VERSION_MAJOR 5)
        message(STATUS "Launcher: Using Qt5")
    else()
        if(IS_SUBDIRECTORY)
            # If built as subdirectory and Qt not found, just skip (don't fail main build)
            message(WARNING "Launcher: Qt not found. Skipping launcher build.")
            message(WARNING "Launcher: Install Qt5 or Qt6 to build the launcher.")
            return()
        else()
            # If built standalone, Qt is required
            message(FATAL_ERROR "Launcher: Qt5 or Qt6 is required but not found. Install Qt to build the launcher.")
        endif()
    endif()
endif()

# Source files
set(SOURCES
    src/main.cpp
    src/MainWindow.cpp
    src/LauncherCore.cpp
    src/DownloadManager.cpp
    src/SettingsDialog.cpp
)

set(HEADERS
    src/MainWindow.h
    src/LauncherCore.h
    src/DownloadManager.h
    src/SettingsDialog.h
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
    elseif(QT_VERSION_MAJOR EQUAL 5)
        # For Qt5, we can use windeployqt if available, or manually copy DLLs
        find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS ${Qt5_DIR}/../../../bin)
        if(WINDEPLOYQT_EXECUTABLE)
            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${WINDEPLOYQT_EXECUTABLE} $<TARGET_FILE:${PROJECT_NAME}>
                COMMENT "Deploying Qt5 libraries..."
            )
        endif()
    endif()
endif()

# Set output directory to match server build structure when built as subdirectory
if(IS_SUBDIRECTORY)
    # When built with server, put launcher in bin/RelWithDebInfo (or Release/Debug based on config)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/$<CONFIG>"
    )
    message(STATUS "Launcher: Output directory set to ${CMAKE_BINARY_DIR}/bin/$<CONFIG>")
endif()

# Install
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
)

