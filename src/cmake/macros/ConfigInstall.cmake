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

#
# Use it like:
# CopyApplicationConfig(${APP_PROJECT_NAME} ${APPLICATION_NAME})
#

function(CopyApplicationConfig projectName appName)
  GetPathToApplication(${appName} SOURCE_APP_PATH)

  if(WIN32)
    if("${CMAKE_MAKE_PROGRAM}" MATCHES "MSBuild")
      add_custom_command(TARGET ${projectName}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/bin/$(ConfigurationName)/configs")
      add_custom_command(TARGET ${projectName}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${SOURCE_APP_PATH}/${appName}.conf.dist" "${CMAKE_BINARY_DIR}/bin/$(ConfigurationName)/configs")
    elseif(MINGW)
      add_custom_command(TARGET ${servertype}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/bin/configs")
      add_custom_command(TARGET ${servertype}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${SOURCE_APP_PATH}/${appName}.conf.dist ${CMAKE_BINARY_DIR}/bin/configs")
    endif()
  endif()

  if(UNIX)
    install(FILES "${SOURCE_APP_PATH}/${appName}.conf.dist" DESTINATION "${CONF_DIR}")
  elseif(WIN32)
    install(FILES "${SOURCE_APP_PATH}/${appName}.conf.dist" DESTINATION "${CMAKE_INSTALL_PREFIX}/configs")
  endif()
endfunction()

function(CopyToolConfig projectName appName)
  GetPathToTool(${appName} SOURCE_APP_PATH)

  if(WIN32)
    if("${CMAKE_MAKE_PROGRAM}" MATCHES "MSBuild")
      add_custom_command(TARGET ${projectName}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/bin/$(ConfigurationName)/configs")
      add_custom_command(TARGET ${projectName}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${SOURCE_APP_PATH}/${appName}.conf.dist" "${CMAKE_BINARY_DIR}/bin/$(ConfigurationName)/configs")
    elseif(MINGW)
      add_custom_command(TARGET ${servertype}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/bin/configs")
      add_custom_command(TARGET ${servertype}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${SOURCE_APP_PATH}/${appName}.conf.dist ${CMAKE_BINARY_DIR}/bin/configs")
    endif()
  endif()

  if(UNIX)
    install(FILES "${SOURCE_APP_PATH}/${appName}.conf.dist" DESTINATION "${CONF_DIR}")
  elseif(WIN32)
    install(FILES "${SOURCE_APP_PATH}/${appName}.conf.dist" DESTINATION "${CMAKE_INSTALL_PREFIX}/configs")
  endif()
endfunction()

#
# Use it like:
# CopyModuleConfig("acore.conf.dist")
#

function(CopyModuleConfig configDir)
  set(postPath "configs/modules")
  
  # Get the filename without path
  get_filename_component(configFileName "${configDir}" NAME)
  # Remove .dist extension to get the actual config filename
  string(REGEX REPLACE "\.dist$" "" configFileNameNoDist "${configFileName}")

  if(WIN32)
    if("${CMAKE_MAKE_PROGRAM}" MATCHES "MSBuild")
      add_custom_command(TARGET modules
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/bin/$(ConfigurationName)/${postPath}")
      add_custom_command(TARGET modules
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${configDir}" "${CMAKE_BINARY_DIR}/bin/$(ConfigurationName)/${postPath}")
      # Also copy as .conf (without .dist) if it doesn't exist - for automatic config setup
      add_custom_command(TARGET modules
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${configDir}" "${CMAKE_BINARY_DIR}/bin/$(ConfigurationName)/${postPath}/${configFileNameNoDist}")
    elseif(MINGW)
      add_custom_command(TARGET modules
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/bin/${postPath}")
      add_custom_command(TARGET modules
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${configDir}" "${CMAKE_BINARY_DIR}/bin/${postPath}")
      add_custom_command(TARGET modules
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${configDir}" "${CMAKE_BINARY_DIR}/bin/${postPath}/${configFileNameNoDist}")
    endif()
  endif()

  if(UNIX)
    install(FILES "${configDir}" DESTINATION "${CONF_DIR}/modules")
    # Also install as .conf (without .dist) if it doesn't exist - preserves user edits
    install(CODE "
      if(NOT EXISTS \"${CONF_DIR}/modules/${configFileNameNoDist}\")
        file(COPY \"${configDir}\" DESTINATION \"${CONF_DIR}/modules\" RENAME \"${configFileNameNoDist}\")
      endif()
    ")
  elseif(WIN32)
    install(FILES "${configDir}" DESTINATION "${CMAKE_INSTALL_PREFIX}/${postPath}")
    # Also install as .conf (without .dist) if it doesn't exist - ensures new users have working configs
    install(CODE "
      if(NOT EXISTS \"${CMAKE_INSTALL_PREFIX}/${postPath}/${configFileNameNoDist}\")
        file(COPY \"${configDir}\" DESTINATION \"${CMAKE_INSTALL_PREFIX}/${postPath}\" RENAME \"${configFileNameNoDist}\")
        message(STATUS \"Created module config: ${CMAKE_INSTALL_PREFIX}/${postPath}/${configFileNameNoDist}\")
      endif()
    ")
  endif()
  unset(postPath)
endfunction()
