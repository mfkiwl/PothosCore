///
/// \file Pothos/Config.hpp
///
/// Common macro definitions for library API export.
///
/// \copyright
/// Copyright (c) 2013-2021 Josh Blum
/// SPDX-License-Identifier: BSL-1.0
///

#pragma once
// http://gcc.gnu.org/wiki/Visibility
// Generic helper definitions for shared library support
#if defined _WIN32 || defined __CYGWIN__
  #define POTHOS_HELPER_DLL_IMPORT __declspec(dllimport)
  #define POTHOS_HELPER_DLL_EXPORT __declspec(dllexport)
  #define POTHOS_HELPER_DLL_LOCAL
#else
  #if __GNUC__ >= 4
    #define POTHOS_HELPER_DLL_IMPORT __attribute__ ((visibility ("default")))
    #define POTHOS_HELPER_DLL_EXPORT __attribute__ ((visibility ("default")))
    #define POTHOS_HELPER_DLL_LOCAL  __attribute__ ((visibility ("hidden")))
  #else
    #define POTHOS_HELPER_DLL_IMPORT
    #define POTHOS_HELPER_DLL_EXPORT
    #define POTHOS_HELPER_DLL_LOCAL
  #endif
#endif

// Now we use the generic helper definitions above to define POTHOS_API and POTHOS_LOCAL.
// POTHOS_API is used for the public API symbols. It either DLL imports or DLL exports (or does nothing for static build)
// POTHOS_LOCAL is used for non-api symbols.

#define POTHOS_DLL //always building a DLL

#ifdef POTHOS_DLL // defined if POTHOS is compiled as a DLL
  #ifdef POTHOS_DLL_EXPORTS // defined if we are building the POTHOS DLL (instead of using it)
    #define POTHOS_API POTHOS_HELPER_DLL_EXPORT
    #define POTHOS_EXTERN
  #else
    #define POTHOS_API POTHOS_HELPER_DLL_IMPORT
    #define POTHOS_EXTERN extern
  #endif // POTHOS_DLL_EXPORTS
  #define POTHOS_LOCAL POTHOS_HELPER_DLL_LOCAL
#else // POTHOS_DLL is not defined: this means POTHOS is a static lib.
  #define POTHOS_API
  #define POTHOS_LOCAL
  #define POTHOS_EXTERN
#endif // POTHOS_DLL

// Explicit template specialization can be exported on gnu platforms
// Required on apple clang for consistent type ids in archive system
#if defined _WIN32 || defined __CYGWIN__
  #define POTHOS_TEMPLATE_API
#elif __GNUC__ >= 4
  #define POTHOS_TEMPLATE_API POTHOS_API
#else
  #define POTHOS_TEMPLATE_API
#endif

#ifdef _MSC_VER
  #ifndef _USE_MATH_DEFINES
    #define _USE_MATH_DEFINES //math.h M_* constants
  #endif //_USE_MATH_DEFINES
#endif //_MSC_VER

//deprecated macro for causing warnings on old calls
#ifdef __has_cpp_attribute
#  if __has_cpp_attribute(deprecated)
#    define POTHOS_DEPRECATED(msg) [[deprecated(msg)]]
#  endif
#endif

//fall-back compiler specific support for deprecated
#ifndef POTHOS_DEPRECATED
#  if defined(__GNUC__)
#    define POTHOS_DEPRECATED(msg) __attribute__((deprecated(msg)))
#  elif defined(_MSC_VER)
#    define POTHOS_DEPRECATED(msg) __declspec(deprecated(msg))
#  else
#   pragma message("WARNING: You need to implement DEPRECATED for this compiler")
#   define POTHOS_DEPRECATED(msg)
#  endif
#endif

/*!
 * The function tuple emits a string name + function pointer tuple.
 * This macro simplifies specifying a function name more than once
 * for API calls that take a string name and function pointer.
 *
 * Example:
 * To simplify this->register("foo", &MyNamespace::MyClass::foo),
 * this->register(POTHOS_FCN_TUPLE(MyNamespace::MyClass, foo));
 *
 * \param classPath the colon separated namespace and class name
 * \param functionName the name of a function within the specified classPath
 */
#define POTHOS_FCN_TUPLE(classPath, functionName) \
    #functionName, &classPath::functionName

#include <ciso646>
