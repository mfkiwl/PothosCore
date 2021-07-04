if(DEFINED INCLUDED_POTHOS_UTIL_CMAKE)
    return()
endif()
set(INCLUDED_POTHOS_UTIL_CMAKE TRUE)

########################################################################
## POTHOS_MODULE_UTIL - build and install modules for Pothos
##
## This utility can handle the build and installation operations
## for most Pothos user projects. Otherwise, please copy and modify.
##
## Arguments:
##
## TARGET - the name of the module to build
## The target name should be unique per project.
## If this target shares a destination with other modules,
## Then the target should also be unique among those modules.
##
## SOURCES - a list of c++ source files
## This list will primarily consist of c++ source files and not headers.
## However, if header files contain documentation markup for the GUI,
## then these header files should be included for markup parsing.
## See ENABLE_DOCS which is required to enable SOURCES for scanning.
##
## LIBRARIES - a list of libraries to link the module to
## The module will automatically link to Pothos and Poco libraries.
## This argument should be used to specify additional libraries.
##
## DESTINATION - relative destination path
## The destination path is relative to the module directory.
## Try to use destination paths that reflect the plugin registry path.
## Example: Suppose you are building a module for /blocks/foo/bar,
## Then the destination should be blocks/foo and the TARGET bar.
## However, this is simply a recomendation.
##
## DOC_SOURCES - an alternative list of sources to scan for docs
## This allows the user to explicitly specity the list of sources
## that are used exclusively for documentation markup for the GUI.
##
## ENABLE_DOCS - enable scanning of SOURCES for documentation markup.
## Pass this flag to the util function to enable scanning of SOURCES.
## This is required to scan SOURCES but not when DOC_SOURCES are used.
##
## PREFIX - override the default install prefix when specified
## The prefix modifies the destination with an absolute path
## to replace the typical CMAKE_INSTALL_PREFIX install rules.
##
## VERSION - specify a version string to build into this module
## When not specified, the util will fall-back to PROJECT_VERSION,
## and scanning the in-tree Changelog.txt file (if available).
## Packagers can pass PROJECT_VERSION_EXTRA for additional version info.
##
########################################################################
function(POTHOS_MODULE_UTIL)

    include(CMakeParseArguments)
    CMAKE_PARSE_ARGUMENTS(POTHOS_MODULE_UTIL "ENABLE_DOCS" "TARGET;DESTINATION;PREFIX;VERSION" "SOURCES;LIBRARIES;DOC_SOURCES" ${ARGN})

    #version not specified, try to use project version
    if (NOT POTHOS_MODULE_UTIL_VERSION AND PROJECT_VERSION)
        set(POTHOS_MODULE_UTIL_VERSION "${PROJECT_VERSION}")
    endif()

    #version not specified, try to use changelog entry
    if (NOT POTHOS_MODULE_UTIL_VERSION AND EXISTS "${PROJECT_SOURCE_DIR}/Changelog.txt")
        file(READ "${PROJECT_SOURCE_DIR}/Changelog.txt" changelog_txt)
        string(REGEX MATCH "Release ([-\\._0-9a-zA-Z]*) \\(" CHANGELOG_MATCH "${changelog_txt}")
        if(CHANGELOG_MATCH)
            set(POTHOS_MODULE_UTIL_VERSION "${CMAKE_MATCH_1}")
        endif(CHANGELOG_MATCH)
    endif()

    #additional version information when specified
    if (PROJECT_VERSION_EXTRA)
        if (POTHOS_MODULE_UTIL_VERSION)
            set(POTHOS_MODULE_UTIL_VERSION "${POTHOS_MODULE_UTIL_VERSION}-${PROJECT_VERSION_EXTRA}")
        else()
            set(POTHOS_MODULE_UTIL_VERSION "${PROJECT_VERSION_EXTRA}")
        endif()
    endif()

    #add git hash when possible
    if (EXISTS "${PROJECT_SOURCE_DIR}/.git")
        find_package(Git)
        if(GIT_FOUND)
            execute_process(
                COMMAND ${GIT_EXECUTABLE} -C "${PROJECT_SOURCE_DIR}" rev-parse --short HEAD
                OUTPUT_STRIP_TRAILING_WHITESPACE
                OUTPUT_VARIABLE GIT_HASH)
            if (GIT_HASH)
                if (POTHOS_MODULE_UTIL_VERSION)
                    set(POTHOS_MODULE_UTIL_VERSION "${POTHOS_MODULE_UTIL_VERSION}-${GIT_HASH}")
                else()
                    set(POTHOS_MODULE_UTIL_VERSION "${GIT_HASH}")
                endif()
            endif()
        endif(GIT_FOUND)
    endif()

    #setup module build and install rules
    add_library(${POTHOS_MODULE_UTIL_TARGET} MODULE ${POTHOS_MODULE_UTIL_SOURCES})
    target_link_libraries(${POTHOS_MODULE_UTIL_TARGET} PRIVATE Pothos ${POTHOS_MODULE_UTIL_LIBRARIES})
    set_target_properties(${POTHOS_MODULE_UTIL_TARGET} PROPERTIES DEBUG_POSTFIX "") #same name in debug mode

    #symbols are only exported from the module explicitly
    set_property(TARGET ${POTHOS_MODULE_UTIL_TARGET} PROPERTY C_VISIBILITY_PRESET hidden)
    set_property(TARGET ${POTHOS_MODULE_UTIL_TARGET} PROPERTY CXX_VISIBILITY_PRESET hidden)
    set_property(TARGET ${POTHOS_MODULE_UTIL_TARGET} PROPERTY VISIBILITY_INLINES_HIDDEN ON)

    #version specified, build into source file
    if (POTHOS_MODULE_UTIL_VERSION)
        message(STATUS "Module ${POTHOS_MODULE_UTIL_TARGET} configured with version: ${POTHOS_MODULE_UTIL_VERSION}")
        set(version_file "${CMAKE_CURRENT_BINARY_DIR}/Version.cpp")
        file(WRITE "${version_file}" "#include <Pothos/Plugin/Module.hpp>
            static const Pothos::ModuleVersion register${MODULE_TARGET}Version(\"${POTHOS_MODULE_UTIL_VERSION}\");
        ")
        target_sources(${POTHOS_MODULE_UTIL_TARGET} PRIVATE "${version_file}")
    endif()

    #always enable docs if user specifies doc sources
    if (POTHOS_MODULE_UTIL_DOC_SOURCES)
        set(POTHOS_MODULE_UTIL_ENABLE_DOCS TRUE)
    #otherwise doc sources come from the regular sources
    else()
        set(POTHOS_MODULE_UTIL_DOC_SOURCES ${POTHOS_MODULE_UTIL_SOURCES})
    endif()

    #setup json doc file generation and install
    if (POTHOS_MODULE_UTIL_ENABLE_DOCS)

        #turn sources into an absolute path
        unset(__POTHOS_SOURCES)
        foreach(source ${POTHOS_MODULE_UTIL_DOC_SOURCES})
            if (EXISTS ${source})
                list(APPEND __POTHOS_SOURCES ${source})
            else()
                list(APPEND __POTHOS_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/${source})
            endif()
        endforeach(source)
        set(POTHOS_MODULE_UTIL_DOC_SOURCES ${__POTHOS_SOURCES})

        set(cpp_doc_file ${CMAKE_CURRENT_BINARY_DIR}/${POTHOS_MODULE_UTIL_TARGET}Docs.cpp)
        add_custom_command(
            OUTPUT ${cpp_doc_file}
            COMMAND ${POTHOS_UTIL_EXE}
                --doc-parse ${POTHOS_MODULE_UTIL_DOC_SOURCES}
                --output ${cpp_doc_file}
            DEPENDS ${POTHOS_MODULE_UTIL_DOC_SOURCES}
            DEPENDS ${__POTHOS_UTIL_TARGET_NAME}
        )
        target_sources(${POTHOS_MODULE_UTIL_TARGET} PRIVATE ${cpp_doc_file})
        set_property(SOURCE ${cpp_doc_file} PROPERTY SKIP_AUTOMOC ON)
    endif()

    set(MODULE_DESTINATION ${CMAKE_INSTALL_LIBDIR}/Pothos/modules${POTHOS_ABI_VERSION}/${POTHOS_MODULE_UTIL_DESTINATION})

    #determine user-specified or automatic install prefix
    if (POTHOS_MODULE_UTIL_PREFIX)
        set(MODULE_DESTINATION ${POTHOS_MODULE_UTIL_PREFIX}/${MODULE_DESTINATION})
    endif()

    if(CMAKE_COMPILER_IS_GNUCXX)
        #force a compile-time error when symbols are missing
        #otherwise modules will cause a runtime error on load
        target_link_libraries(${POTHOS_MODULE_UTIL_TARGET} PRIVATE "-Wl,--no-undefined")
    endif()

    install(
        TARGETS ${POTHOS_MODULE_UTIL_TARGET}
        DESTINATION ${MODULE_DESTINATION}
    )

endfunction(POTHOS_MODULE_UTIL)
