# generate Xcode project
set (CMAKE_GENERATOR "Xcode" CACHE INTERNAL "" FORCE)

if (NOT DEFINED ENV{USD_PATH}) 
  message(FATAL_ERROR "USD_PATH variable must be set.")
endif()

set (USD_BUILT_PATH "$ENV{USD_PATH}" CACHE INTERNAL "" FORCE)

#set (CMAKE_TOOLCHAIN_FILE "${USD_BUILT_PATH}/cmake/ios.toolchain.cmake" CACHE INTERNAL "" FORCE)
