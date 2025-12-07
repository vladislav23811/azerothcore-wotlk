#
# This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
#
# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY, to the extent permitted by law; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#

CollectSourceFiles(
  ${CMAKE_CURRENT_SOURCE_DIR}
  PRIVATE_SOURCES
  # Exclude
  ${CMAKE_CURRENT_SOURCE_DIR}/PrecompiledHeaders)

# Add ExtraDatabase sources conditionally (similar to PlayerbotsDatabase)
# Check if mod-progressive-systems exists (may be processed after database, so check file existence)
set(EXTRA_DATABASE_PATH "${CMAKE_SOURCE_DIR}/modules/mod-progressive-systems/src/AzerothShardModules/mod-as-common/src/game/ExtraDatabase.cpp")
set(EXTRA_DATABASE_DIR "${CMAKE_SOURCE_DIR}/modules/mod-progressive-systems/src/AzerothShardModules/mod-as-common/src/game")
if(EXISTS "${EXTRA_DATABASE_PATH}")
  list(APPEND PRIVATE_SOURCES "${EXTRA_DATABASE_PATH}")
endif()

if(USE_COREPCH)
  set(PRIVATE_PCH_HEADER PrecompiledHeaders/databasePCH.h)
endif()

# Group sources
GroupSources(${CMAKE_CURRENT_SOURCE_DIR})

add_library(database
  ${PRIVATE_SOURCES})

# Do NOT add any extra include directory unless it does not create unneeded extra dependencies,
# and specially, not add any dependency to neither of these: shared, game, scripts
# This way we ensure that if either a PR does that without modifying this file,
# a compile error will be generated, either this file will be modified so it
# is detected more easily.
# While it is OK to include files from other libs as long as they don't require
# linkage (enums, defines...) it is discouraged to do so unless necessary, as it will pullute
# include_directories leading to further unnoticed dependency aditions
# Linker Depencency requirements: common
CollectIncludeDirectories(
  ${CMAKE_CURRENT_SOURCE_DIR}
  PUBLIC_INCLUDES
  # Exclude
  ${CMAKE_CURRENT_SOURCE_DIR}/PrecompiledHeaders)

target_include_directories(database
  PUBLIC
    ${PUBLIC_INCLUDES}
  PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR})

# Add ExtraDatabase include directory if the file exists
# This is needed for DatabaseWorkerPool.cpp when MOD_PROGRESSIVE_SYSTEMS is defined
# Check both the header file and the source file to ensure the module is present
if(EXISTS "${EXTRA_DATABASE_PATH}" AND EXISTS "${EXTRA_DATABASE_DIR}/ExtraDatabase.h")
  target_include_directories(database
    PRIVATE
      ${EXTRA_DATABASE_DIR})
  message(STATUS "ExtraDatabase: Added include directory ${EXTRA_DATABASE_DIR}")
elseif(NOT EXISTS "${EXTRA_DATABASE_PATH}")
  # Module not found - this is OK if mod-progressive-systems is not installed
  message(STATUS "ExtraDatabase: mod-progressive-systems not found, skipping ExtraDatabase support")
endif()

target_link_libraries(database
  PRIVATE
    acore-core-interface
    mysql
  PUBLIC
    common)

set_target_properties(database
  PROPERTIES
    FOLDER
      "server")

# Generate precompiled header
if(USE_COREPCH)
  add_cxx_pch(database ${PRIVATE_PCH_HEADER})
endif()
