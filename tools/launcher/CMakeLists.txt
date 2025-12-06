cmake_minimum_required(VERSION 3.15)

# Check if this is being built as a subdirectory (from main CMakeLists.txt)
# or standalone (from tools/launcher directory)
# If CMAKE_SOURCE_DIR != CMAKE_CURRENT_SOURCE_DIR, we're a subdirectory
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    # Being built standalone
    set(IS_STANDALONE_BUILD TRUE)
else()
    # Being built as part of main project
    set(IS_STANDALONE_BUILD FALSE)
endif()

project(WoWLauncher)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt6 or Qt5
# Try Qt6 first, then Qt5
# If vcpkg is being used, try to find Qt5 from vcpkg first
if(CMAKE_TOOLCHAIN_FILE AND EXISTS "${CMAKE_TOOLCHAIN_FILE}")
    # vcpkg toolchain is being used, try to find Qt5 in vcpkg
    set(VCPKG_ROOT "")
    # Try common vcpkg locations
    if(EXISTS "C:/vcpkg")
        set(VCPKG_ROOT "C:/vcpkg")
    elseif(DEFINED ENV{VCPKG_ROOT})
        set(VCPKG_ROOT "$ENV{VCPKG_ROOT}")
    elseif(EXISTS "${CMAKE_CURRENT_LIST_DIR}/../../../../vcpkg")
        set(VCPKG_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../vcpkg")
    endif()
    
    if(VCPKG_ROOT)
        # Qt5Config.cmake is typically in share/cmake/Qt5/ (not share/qt5/)
        if(EXISTS "${VCPKG_ROOT}/installed/x64-windows/share/cmake/Qt5/Qt5Config.cmake")
            set(Qt5_DIR "${VCPKG_ROOT}/installed/x64-windows/share/cmake/Qt5")
            message(STATUS "Launcher: Found Qt5 in vcpkg at ${Qt5_DIR}")
        elseif(EXISTS "${VCPKG_ROOT}/installed/x64-windows/share/qt5/Qt5Config.cmake")
            set(Qt5_DIR "${VCPKG_ROOT}/installed/x64-windows/share/qt5")
            message(STATUS "Launcher: Found Qt5 in vcpkg at ${Qt5_DIR}")
        endif()
    endif()
endif()

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
        # Qt not found - try to help user install it
        if(WIN32)
            message("")
            message(WARNING "Launcher: Qt not found!")
            message("")
            message("=== Qt Installation Required ===")
            message("")
            message("Option 1: Install via vcpkg (Recommended)")
            message("   vcpkg install qt5-base qt5-widgets qt5-network --triplet x64-windows")
            message("   Then configure with: -DCMAKE_TOOLCHAIN_FILE=[vcpkg]/scripts/buildsystems/vcpkg.cmake")
            message("")
            message("Option 2: Run installation helper script")
            message("   powershell -ExecutionPolicy Bypass -File tools/launcher/install_qt.ps1")
            message("")
            message("Option 3: Download Qt Installer")
            message("   Qt6: https://www.qt.io/download-qt-installer")
            message("   Qt5: https://www.qt.io/offline-installers")
            message("")
            message("After installing, set Qt_DIR:")
            message("   cmake .. -DQt6_DIR=\"C:/Qt/6.x.x/msvc2019_64/lib/cmake/Qt6\"")
            message("   OR")
            message("   cmake .. -DQt5_DIR=\"C:/Qt/5.x.x/msvc2019_64/lib/cmake/Qt5\"")
            message("")
        endif()
        
        if(NOT IS_STANDALONE_BUILD)
            # If built as subdirectory and Qt not found, just skip (don't fail main build)
            message(WARNING "Launcher: Skipping launcher build (Qt not found). Server will still build.")
            message(WARNING "Launcher: Run 'powershell -ExecutionPolicy Bypass -File tools/launcher/install_qt.ps1' to install Qt")
            return()
        else()
            # If built standalone, Qt is required
            message(FATAL_ERROR "Launcher: Qt5 or Qt6 is required but not found.")
            message(FATAL_ERROR "Launcher: Run 'powershell -ExecutionPolicy Bypass -File install_qt.ps1' to install Qt")
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

# Disable vcpkg's automatic DLL copying (it uses wildcards which break MSBuild)
# We'll manually copy the DLLs we need instead
# Note: vcpkg adds automatic dependency copying via .props files, which we'll clean up post-configure

# Enable Qt MOC (Meta-Object Compiler) for Q_OBJECT macros
# AUTOMOC automatically processes Q_OBJECT macros
set_target_properties(${PROJECT_NAME} PROPERTIES
    AUTOMOC ON
)

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

# Disable vcpkg's automatic DLL copying AFTER linking (it uses wildcards which break MSBuild)
# We'll manually copy the DLLs we need instead
if(CMAKE_TOOLCHAIN_FILE AND EXISTS "${CMAKE_TOOLCHAIN_FILE}")
    # Remove vcpkg's automatic post-build step by clearing VS_USER_PROPS
    set_target_properties(${PROJECT_NAME} PROPERTIES
        VS_USER_PROPS ""
    )
endif()

# Windows-specific settings
if(WIN32)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
    
    # Copy Qt DLLs to launcher output directory (for distribution)
    if(NOT IS_STANDALONE_BUILD)
        set(LAUNCHER_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/RelWithDebInfo/wowlauncher")
    else()
        set(LAUNCHER_OUTPUT_DIR "$<TARGET_FILE_DIR:${PROJECT_NAME}>")
    endif()
    
    if(QT_VERSION_MAJOR EQUAL 6)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${LAUNCHER_OUTPUT_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_FILE:Qt6::Core>
                $<TARGET_FILE:Qt6::Widgets>
                $<TARGET_FILE:Qt6::Network>
                "${LAUNCHER_OUTPUT_DIR}/"
            COMMENT "Copying Qt6 DLLs to launcher folder..."
        )
    elseif(QT_VERSION_MAJOR EQUAL 5)
        # For Qt5, manually copy DLLs
        # Get Qt5 DLL paths explicitly (no wildcards)
        get_target_property(QT5_CORE_DLL Qt5::Core LOCATION)
        get_target_property(QT5_WIDGETS_DLL Qt5::Widgets LOCATION)
        get_target_property(QT5_NETWORK_DLL Qt5::Network LOCATION)
        
        # Get the directory where Qt5 DLLs are located
        get_filename_component(QT5_BIN_DIR "${QT5_CORE_DLL}" DIRECTORY)
        
        # Try to find OpenSSL DLLs explicitly (if they exist, copy them)
        # Qt5 from vcpkg may depend on OpenSSL, but we'll only copy if they exist
        # Note: Qt5 can work without OpenSSL on Windows (uses Windows native SSL)
        # Search for OpenSSL DLLs with explicit version numbers (no wildcards)
        # Check both Qt5 bin dir and vcpkg bin dir
        set(OPENSSL_DLLS "")
        set(VCPKG_BIN_DIR "")
        if(CMAKE_TOOLCHAIN_FILE AND EXISTS "${CMAKE_TOOLCHAIN_FILE}")
            # Try to find vcpkg bin directory
            if(EXISTS "C:/vcpkg/installed/x64-windows/bin")
                set(VCPKG_BIN_DIR "C:/vcpkg/installed/x64-windows/bin")
            elseif(DEFINED ENV{VCPKG_ROOT})
                set(VCPKG_BIN_DIR "$ENV{VCPKG_ROOT}/installed/x64-windows/bin")
            endif()
        endif()
        
        # Try common OpenSSL names in both locations
        foreach(OSSLLIB crypto ssl)
            foreach(BIN_DIR ${QT5_BIN_DIR} ${VCPKG_BIN_DIR})
                if(BIN_DIR)
                    # Try 3-x64 (OpenSSL 3.x - most recent)
                    if(EXISTS "${BIN_DIR}/lib${OSSLLIB}-3-x64.dll")
                        list(APPEND OPENSSL_DLLS "${BIN_DIR}/lib${OSSLLIB}-3-x64.dll")
                        break()
                    # Try 1_1-x64 (OpenSSL 1.1.x)
                    elseif(EXISTS "${BIN_DIR}/lib${OSSLLIB}-1_1-x64.dll")
                        list(APPEND OPENSSL_DLLS "${BIN_DIR}/lib${OSSLLIB}-1_1-x64.dll")
                        break()
                    # Try 1_0_2-x64 (older version)
                    elseif(EXISTS "${BIN_DIR}/lib${OSSLLIB}-1_0_2-x64.dll")
                        list(APPEND OPENSSL_DLLS "${BIN_DIR}/lib${OSSLLIB}-1_0_2-x64.dll")
                        break()
                    endif()
                endif()
            endforeach()
        endforeach()
        
        # Copy Qt5 DLLs and OpenSSL DLLs together (if found)
        set(ALL_DLLS "${QT5_CORE_DLL}" "${QT5_WIDGETS_DLL}" "${QT5_NETWORK_DLL}")
        if(OPENSSL_DLLS)
            list(APPEND ALL_DLLS ${OPENSSL_DLLS})
        endif()
        
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${LAUNCHER_OUTPUT_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${ALL_DLLS}
                "${LAUNCHER_OUTPUT_DIR}/"
            COMMENT "Copying Qt5 and OpenSSL DLLs to launcher folder..."
        )
    endif()
endif()

# Set output directory to dedicated launcher folder
if(NOT IS_STANDALONE_BUILD)
    # Output to build/bin/RelWithDebInfo/wowlauncher/ for easy identification
    set(LAUNCHER_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/RelWithDebInfo/wowlauncher")
    set_target_properties(${PROJECT_NAME} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/Debug/wowlauncher"
        RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/bin/Debug/wowlauncher"
        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/bin/Release/wowlauncher"
        RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/bin/RelWithDebInfo/wowlauncher"
        RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}/bin/MinSizeRel/wowlauncher"
    )
    message(STATUS "Launcher: Output directory set to ${LAUNCHER_OUTPUT_DIR}")
endif()

# Fix vcpkg wildcard issue: Remove wildcard patterns from .vcxproj after generation
# vcpkg adds automatic dependency copying with wildcards that break MSBuild
# This runs automatically before build
if(CMAKE_TOOLCHAIN_FILE AND EXISTS "${CMAKE_TOOLCHAIN_FILE}" AND WIN32)
    set(VCXPROJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.vcxproj")
    # Use inline PowerShell command to avoid file generation escaping issues
    # This directly filters the .vcxproj file to remove wildcard patterns
    add_custom_command(TARGET ${PROJECT_NAME} PRE_BUILD
        COMMAND powershell -ExecutionPolicy Bypass -Command "if (Test-Path '${VCXPROJ_FILE}') { $content = Get-Content '${VCXPROJ_FILE}'; $filtered = $content | Where-Object { $_ -notmatch 'libcrypto-\\*' -and $_ -notmatch 'libssl-\\*' }; $filtered | Set-Content '${VCXPROJ_FILE}' }"
        COMMENT "Fixing vcpkg wildcard patterns in .vcxproj..."
        VERBATIM
    )
endif()

# Install
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
)


