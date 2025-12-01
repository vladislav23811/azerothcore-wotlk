# Progressive Systems Module
# CMake configuration for infinite progression system
#
# NOTE: For static modules, the module system automatically collects source files
# and includes them in the main 'modules' library. This CMakeLists.txt should
# only set up compile options, include directories, and other configuration.
# Do NOT create a library here for static modules.

# Set C++ standard for this module's sources
# The module system will apply this when collecting sources
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories that will be collected by the module system
# These are added to PUBLIC_INCLUDES via CollectIncludeDirectories
# Note: The module system handles most includes automatically via interface targets

# Module is automatically registered by the modules system
# Sources are collected via CollectSourceFiles()
# Include directories are collected via CollectIncludeDirectories()
# No need to create a library - the module system handles that

