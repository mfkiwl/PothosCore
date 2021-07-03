if(DEFINED INCLUDED_POTHOS_STANDARD_FLAGS_CMAKE)
    return()
endif()
set(INCLUDED_POTHOS_STANDARD_FLAGS_CMAKE TRUE)

########################################################################
# Provide add_compile_options() when not available
########################################################################
if(CMAKE_VERSION VERSION_LESS "2.8.12")
    function(add_compile_options)
        add_definitions(${ARGN})
    endfunction(add_compile_options)
endif()

########################################################################
# Compiler flags that are generally always a good idea to set
# or sensible to use because of the project's constraints.
########################################################################

#C++11 is a required language feature for this project
set(CMAKE_CXX_STANDARD 11)

if(CMAKE_COMPILER_IS_GNUCXX)

    #enable C++11 on older versions of cmake
    if (CMAKE_VERSION VERSION_LESS "3.1")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
    endif()

    #these warnings are caused by static warnings used throughout the code
    add_compile_options(-Wno-unused-local-typedefs)

    #common warnings to help encourage good coding practices
    add_compile_options(-Wall)
    add_compile_options(-Wextra)
    add_compile_options(-Wnon-virtual-dtor)

    #symbols are only exported from libraries/modules explicitly
    add_compile_options(-fvisibility=hidden)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility-inlines-hidden")
endif()

if(APPLE)
    #fixes issue with duplicate module registry when using application bundle
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -flat_namespace")
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -flat_namespace")
endif()

if(MSVC)
    #C++11 is a required language feature for this project
    if (${MSVC_VERSION} LESS 1700)
        message(FATAL_ERROR "the build requires MSVC 2012 or newer for C++11 support")
    endif()

    #we always want to use multiple cores for compilation
    add_compile_options(/MP)

    #projects should be cross-platform and standard stl functions should work
    add_definitions(-DNOMINMAX) #enables std::min and std::max

    #suppress the following warnings which are commonly caused by project headers
    add_compile_options(/wd4251) #disable 'identifier' : class 'type' needs to have dll-interface to be used by clients of class 'type2'
    add_compile_options(/wd4275) #disable non – DLL-interface classkey 'identifier' used as base for DLL-interface classkey 'identifier'
    add_compile_options(/wd4503) #'identifier' : decorated name length exceeded, name was truncated

else(MSVC)
    #define _DEBUG for debug mode flags (used by some macros)
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -D_DEBUG")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -D_DEBUG")

endif(MSVC)

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")
    add_compile_options(-stdlib=libc++)
endif()
