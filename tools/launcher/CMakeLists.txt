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
# Disable vcpkg's applocal feature completely to prevent wildcard issues
if(CMAKE_TOOLCHAIN_FILE AND EXISTS "${CMAKE_TOOLCHAIN_FILE}")
    # Set property to disable vcpkg applocal deps (prevents wildcard DLL copying)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        VS_USER_PROPS ""
        VCPKG_APPLOCAL_DEPS OFF
    )
    # Also set as directory property
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VCPKG_APPLOCAL_DEPS OFF)
endif()

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

# Already disabled above

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
        
        # Don't copy OpenSSL DLLs - Qt5 on Windows uses native SSL, not OpenSSL
        # This avoids vcpkg wildcard issues with libcrypto-*-x64.dll patterns
        # If OpenSSL is needed later, it can be added explicitly without wildcards
        
        # Copy only Qt5 DLLs (no OpenSSL)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${LAUNCHER_OUTPUT_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${QT5_CORE_DLL}"
                "${QT5_WIDGETS_DLL}"
                "${QT5_NETWORK_DLL}"
                "${LAUNCHER_OUTPUT_DIR}/"
            COMMENT "Copying Qt5 DLLs to launcher folder..."
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

# Fix vcpkg wildcard issue: Remove wildcard patterns from .vcxproj files
# vcpkg adds automatic dependency copying with wildcards that break MSBuild
# The wildcard is injected via vcpkg.applocal.props which MSBuild imports
# We need to remove it both PRE_BUILD (before MSBuild reads it) and after configure
if(CMAKE_TOOLCHAIN_FILE AND EXISTS "${CMAKE_TOOLCHAIN_FILE}" AND WIN32)
    set(VCXPROJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.vcxproj")
    
    # Create a PowerShell script to remove wildcards
    # Use double quotes and escape properly to avoid PowerShell parsing issues
    set(FIX_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/fix_vcpkg_wildcards.ps1")
    file(WRITE "${FIX_SCRIPT}" 
        "$vcxproj = '${VCXPROJ_FILE}'\n"
        "if (Test-Path $vcxproj) {\n"
        "  $content = Get-Content $vcxproj -Raw\n"
        "  # CRITICAL: Remove vcpkg.applocal.props import to prevent wildcard injection\n"
        "  $content = $content -replace '(?s)<Import[^>]*vcpkg[^>]*applocal[^>]*/>', ''\n"
        "  $content = $content -replace '(?s)<Import[^>]*Project=\"[^\"]*vcpkg[^\"]*applocal[^\"]*\"[^>]*/>', ''\n"
        "  # Remove entire ItemGroup sections with wildcards\n"
        "  $content = $content -replace '(?s)<ItemGroup[^>]*>.*?libcrypto-[^*]*\\*[^<]*</ItemGroup>', ''\n"
        "  $content = $content -replace '(?s)<ItemGroup[^>]*>.*?libssl-[^*]*\\*[^<]*</ItemGroup>', ''\n"
        "  # Remove Files Include with wildcards\n"
        "  $content = $content -replace '<Files[^>]*Include=\"[^\"]*libcrypto-[^*]*\\*[^\"]*\"[^>]*/>', ''\n"
        "  $content = $content -replace '<Files[^>]*Include=\"[^\"]*libssl-[^*]*\\*[^\"]*\"[^>]*/>', ''\n"
        "  # Remove any remaining wildcard patterns (escape < properly)\n"
        "  $content = $content -replace 'libcrypto-[^*]*\\*[^\"\\x3C]*', ''\n"
        "  $content = $content -replace 'libssl-[^*]*\\*[^\"\\x3C]*', ''\n"
        "  Set-Content $vcxproj -Value $content -NoNewline\n"
        "}\n"
        "$userFile = \"$vcxproj.user\"\n"
        "if (Test-Path $userFile) {\n"
        "  $content = Get-Content $userFile -Raw\n"
        "  $content = $content -replace '(?s)<Import[^>]*vcpkg[^>]*applocal[^>]*/>', ''\n"
        "  $content = $content -replace '(?s)<ItemGroup[^>]*>.*?libcrypto-[^*]*\\*[^<]*</ItemGroup>', ''\n"
        "  $content = $content -replace '(?s)<ItemGroup[^>]*>.*?libssl-[^*]*\\*[^<]*</ItemGroup>', ''\n"
        "  $content = $content -replace 'libcrypto-[^*]*\\*[^\"\\x3C]*', ''\n"
        "  $content = $content -replace 'libssl-[^*]*\\*[^\"\\x3C]*', ''\n"
        "  Set-Content $userFile -Value $content -NoNewline\n"
        "}\n"
    )
    
    # Run PRE_BUILD to remove wildcards before MSBuild processes the file
    add_custom_command(TARGET ${PROJECT_NAME} PRE_BUILD
        COMMAND powershell -ExecutionPolicy Bypass -File "${FIX_SCRIPT}"
        COMMENT "Removing vcpkg wildcard patterns from project files..."
        VERBATIM
    )
    
    # Also run after configure (when .vcxproj is first generated)
    add_custom_command(TARGET ${PROJECT_NAME} PRE_LINK
        COMMAND powershell -ExecutionPolicy Bypass -File "${FIX_SCRIPT}"
        COMMENT "Cleaning vcpkg wildcards after configure..."
        VERBATIM
    )
endif()

# Install
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
)


