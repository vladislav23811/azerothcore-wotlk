# Progressive Systems Module
# CMake configuration for infinite progression system

set(MODULE_NAME "progressive-systems")
set(MODULE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

# Source files (only include files that actually exist)
set(PROGRESSIVE_SYSTEMS_SOURCES
    src/ProgressiveSystems.cpp
    src/ProgressiveSystems.h
    src/DifficultyScaling.cpp
    src/DifficultyScaling.h
    src/ProgressiveSystemsLoader.cpp
    src/ProgressiveSystemsAddon.cpp
    src/ProgressiveSystemsAddon.h
    src/ProgressiveSystemsDatabase.cpp
    src/ProgressiveSystemsDatabase.h
    src/ProgressiveSystemsAddonScript.cpp
    src/ProgressiveSystemsAddonScript.h
    src/ProgressiveSystemsCache.cpp
    src/ProgressiveSystemsCache.h
    src/ProgressiveSystemsCommands.cpp
    src/ProgressiveSystemsCommands.h
)

# Create library
add_library(${MODULE_NAME} STATIC ${PROGRESSIVE_SYSTEMS_SOURCES})

# Set C++ standard (required for std::optional)
set_target_properties(${MODULE_NAME} PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
)

# Include directories
target_include_directories(${MODULE_NAME}
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src/server/game
        ${CMAKE_SOURCE_DIR}/src/server/game/Scripting
        ${CMAKE_SOURCE_DIR}/src/server/game/Scripting/ScriptDefines
        ${CMAKE_SOURCE_DIR}/src/server/game/Entities
        ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Player
        ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Item
        ${CMAKE_SOURCE_DIR}/src/server/game/Entities/Unit
        ${CMAKE_SOURCE_DIR}/src/server/game/Spells
        ${CMAKE_SOURCE_DIR}/src/server/game/World
        ${CMAKE_SOURCE_DIR}/src/server/game/Arena
        ${CMAKE_SOURCE_DIR}/src/server/game/Battlegrounds
        ${CMAKE_SOURCE_DIR}/src/server/game/Achievements
        ${CMAKE_SOURCE_DIR}/src/server/game/Chat
        ${CMAKE_SOURCE_DIR}/src/server/game/Chat/ChatCommands
        ${CMAKE_SOURCE_DIR}/src/server/game/DataStores
        ${CMAKE_SOURCE_DIR}/src/server/scripts
        ${CMAKE_SOURCE_DIR}/src/server/shared
        ${CMAKE_SOURCE_DIR}/src/server/shared/DataStores
        ${CMAKE_SOURCE_DIR}/src/server/database
        ${CMAKE_SOURCE_DIR}/src/server/database/Database
        ${CMAKE_SOURCE_DIR}/src/common
        ${CMAKE_SOURCE_DIR}/src/common/Utilities
        ${CMAKE_SOURCE_DIR}/deps/fmt/include
)

# Link libraries - use interface targets to get all includes
target_link_libraries(${MODULE_NAME}
    PRIVATE
        acore-core-interface
    PUBLIC
        game-interface
)

# Module is automatically registered by the modules system
# No need to call CU_ADD_MODULE - it's handled by modules/CMakeLists.txt

