cmake_minimum_required(VERSION 3.10)
project(hydraplayer)

# pull in the USD generated cmake
include(${USD_BUILT_PATH}/pxrConfig.cmake)
include_directories(${PXR_INCLUDE_DIRS})

set(USD_DRAWING_SOURCES
    source/UsdDrawing.h
    source/UsdDrawing.cpp)

set(SOURCES
    source/CommandLineArgs.h
    source/CommandLineArgs.cpp
    source/PerfLog.h
    source/PerfLog.cpp
    ${USD_DRAWING_SOURCES})

set(RESOURCES)

set(HD_DEFAULT_RENDERER "Storm")

add_definitions(-DMACOS)
add_definitions(-DPXR_METAL_SUPPORT_ENABLED)

find_library(METAL_LIBRARY Metal)
find_library(METALKIT_LIBRARY MetalKit)
set(CORE_IMAGE "-framework CoreImage")
set(IMAGEIO "-framework ImageIO")
set(CORE_GRAPHICS "-framework CoreGraphics")
set(UNIFORMTYPEIDENTIFIERS_LIBRARY "-framework UniformTypeIdentifiers")

set(METAL_SOURCE source/BlitShaders.metal)
set_source_files_properties(${METAL_SOURCE} PROPERTIES LANGUAGE METAL)

# CMake pre-3.16:
set_source_files_properties(${USD_DRAWING_SOURCES} PROPERTIES COMPILE_FLAGS "-x objective-c++")
# CMake 3.16+:
# set_source_files_properties(${USD_DRAWING_SOURCES} PROPERTIES LANGUAGE OBJCXX)


set(SOURCES
                        source/AAPLCamera.mm
                        source/AAPLCamera.h
                        source/AAPLRenderer.mm
                        source/AAPLRenderer.h
                        source/AAPLAppDelegate.mm
                        source/AAPLAppDelegate.h
                        source/AAPLViewController.mm
                        source/AAPLViewController.h
                        source/main.mm

                        ${METAL_SOURCE})
            
set(RESOURCES
                        source/Base.lproj/Main.storyboard
                        source/Assets.xcassets)

add_executable(hydraplayer MACOSX_BUNDLE ${SOURCES} ${RESOURCES})

set(EMBEDDED_BINARIES_PLUGIN)
file(GLOB_RECURSE temp
    "${PXR_CMAKE_DIR}/plugin/*.dylib"
    "${PXR_CMAKE_DIR}/plugin/*.glslfx"
    "${PXR_CMAKE_DIR}/plugin/*.oso"
    "${PXR_CMAKE_DIR}/plugin/*.json"
    "${PXR_CMAKE_DIR}/plugin/*.usda")

foreach (_item ${temp}) # Iterate over list of absolute paths
    file(RELATIVE_PATH _t "${PXR_CMAKE_DIR}/plugin/" ${_item})
    list(APPEND EMBEDDED_BINARIES_PLUGIN ${_t})
endforeach()

set(EMBEDDED_BINARIES_LIB)
file(GLOB temp "${PXR_CMAKE_DIR}/lib/*.dylib")
foreach (_item ${temp}) # Iterate over list of absolute paths
    get_filename_component(_t ${_item} NAME)
    list(APPEND EMBEDDED_BINARIES_LIB ${_t})
endforeach()

set(EMBEDDED_BINARIES_LIB_USD)
file(GLOB_RECURSE temp "${PXR_CMAKE_DIR}/lib/usd/*.*")
foreach (_item ${temp}) # Iterate over list of absolute paths
    file(RELATIVE_PATH _t "${PXR_CMAKE_DIR}/lib/" ${_item})
    list(APPEND EMBEDDED_BINARIES_LIB_USD ${_t})
endforeach()

set(PATHS "@executable_path/plugin/usd @executable_path/lib @executable_path/lib/usd")

link_directories(${CMAKE_SOURCE_DIR}/lib)
set(PLIST_TEMPLATE ${CMAKE_CURRENT_SOURCE_DIR}/source/Info.plist.in)

set_target_properties(hydraplayer PROPERTIES    
    MACOSX_BUNDLE TRUE
    RESOURCE "${RESOURCES}"
    MACOSX_BUNDLE_INFO_PLIST ${PLIST_TEMPLATE}
    PUBLIC_HEADER "${HYD_PUBLIC_HEADERS}"
    XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS "${PATHS}"
    XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.apple.sample-code.HydraPlayer"
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES)
    
set(LIB_FILE_MASK "*.dylib")

add_custom_command(TARGET hydraplayer PRE_BUILD
        # Create destination directory structure
        COMMAND ${CMAKE_COMMAND} -E make_directory
                $<TARGET_FILE_DIR:hydraplayer>/lib
        COMMAND ${CMAKE_COMMAND} -E make_directory
                $<TARGET_FILE_DIR:hydraplayer>/plugin
        COMMAND ${CMAKE_COMMAND} -E make_directory
                $<TARGET_FILE_DIR:hydraplayer>/plugin/usd

        # Copy the default USD dylibs into the package
        COMMAND ${CMAKE_COMMAND} -E copy
                ${PXR_CMAKE_DIR}/lib/${LIB_FILE_MASK} $<TARGET_FILE_DIR:hydraplayer>/lib

        # Copy the hydra dylib plugins to the package too
        COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${PXR_CMAKE_DIR}/plugin/usd $<TARGET_FILE_DIR:hydraplayer>/plugin/usd

        # And finally, copy the usd plugin resources into the package
        COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${PXR_CMAKE_DIR}/lib/usd $<TARGET_FILE_DIR:hydraplayer>/lib/usd
    )

    if (DEFINED ENV{HYDRA_PLAYER_FORCE_AD_HOC})
        set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-")
        set(CODE_SIGN_IDENTITY "-")
        set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "")
    elseif (DEFINED ENV{XCODE_ATTRIBUTE_CODE_SIGN_ID} AND NOT "$ENV{XCODE_ATTRIBUTE_CODE_SIGN_ID}" STREQUAL "-")
        execute_process(COMMAND security find-identity -v -p codesigning OUTPUT_VARIABLE codeSignIDs)
        string(REGEX MATCHALL $ENV{XCODE_ATTRIBUTE_CODE_SIGN_ID} ID_MATCHES "${codeSignIDs}")
        list(LENGTH ID_MATCHES NUM_MATCHES)

        if (NOT NUM_MATCHES EQUAL 1) 
            message(FATAL_ERROR "Unable to identify code signing identity $ENV{XCODE_ATTRIBUTE_CODE_SIGN_ID}. "
            "Please specify by setting the XCODE_ATTRIBUTE_CODE_SIGN_ID environment " 
            "variable to the one you'd like to use. Options are:\n${codeSignIDs}")
        endif()

        set(CODE_SIGN_IDENTITY $ENV{XCODE_ATTRIBUTE_CODE_SIGN_ID})
    else()
        set(CODE_SIGN_IDENTITY "-")
    endif()


set(RESOURCE "${RESOURCES}")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")

set(PXR_LIBRARY_NAMES)
foreach (_item ${PXR_LIBRARIES}) # Iterate over list of absolute paths
    get_filename_component(_t ${_item} NAME)
    list(APPEND PXR_LIBRARY_NAMES ${_t})
endforeach()

target_link_libraries(hydraplayer LINK_PUBLIC ${METAL_LIBRARY}
                                  ${METALKIT_LIBRARY}
                                  ${UNIFORMTYPEIDENTIFIERS_LIBRARY}
                                  ${PXR_LIBRARY_NAMES}
                                  ${CORE_IMAGE}
                                  ${CORE_GRAPHICS}
                                  ${IMAGEIO})
foreach (_item ${EMBEDDED_BINARIES_LIB})
add_custom_command(TARGET hydraplayer PRE_BUILD COMMAND codesign --remove-signature $<TARGET_FILE_DIR:hydraplayer>/lib/${_item})
add_custom_command(TARGET hydraplayer PRE_BUILD COMMAND codesign -f -s ${CODE_SIGN_IDENTITY} $<TARGET_FILE_DIR:hydraplayer>/lib/${_item})
endforeach() 

foreach (_item ${EMBEDDED_BINARIES_LIB_USD})
add_custom_command(TARGET hydraplayer PRE_BUILD COMMAND codesign --remove-signature $<TARGET_FILE_DIR:hydraplayer>/lib/${_item})
add_custom_command(TARGET hydraplayer PRE_BUILD COMMAND codesign -f -s ${CODE_SIGN_IDENTITY} $<TARGET_FILE_DIR:hydraplayer>/lib/${_item})
endforeach()

foreach (_item ${EMBEDDED_BINARIES_PLUGIN})
add_custom_command(TARGET hydraplayer PRE_BUILD COMMAND codesign --remove-signature $<TARGET_FILE_DIR:hydraplayer>/plugin/${_item})
add_custom_command(TARGET hydraplayer PRE_BUILD COMMAND codesign -f -s ${CODE_SIGN_IDENTITY} $<TARGET_FILE_DIR:hydraplayer>/plugin/${_item})
endforeach()


