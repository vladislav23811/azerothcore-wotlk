/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Affero General Public License as published by the
 * Free Software Foundation; either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef ACORE_DEFINE_H
#define ACORE_DEFINE_H

#include "CompilerDefs.h"

// Compatibility layer for integer types
#if AC_COMPILER == AC_COMPILER_MICROSOFT
    // MSVC compatibility - define types manually (most reliable)
    #ifndef _STDINT_H
        #ifndef _STDINT_H_
            #ifndef _MSC_STDINT_H_
                // Define in global namespace
                typedef signed __int8     int8_t;
                typedef signed __int16    int16_t;
                typedef signed __int32    int32_t;
                typedef signed __int64    int64_t;
                typedef unsigned __int8   uint8_t;
                typedef unsigned __int16  uint16_t;
                typedef unsigned __int32  uint32_t;
                typedef unsigned __int64 uint64_t;
                // Also put in std namespace for compatibility
                namespace std {
                    using ::int8_t;
                    using ::int16_t;
                    using ::int32_t;
                    using ::int64_t;
                    using ::uint8_t;
                    using ::uint16_t;
                    using ::uint32_t;
                    using ::uint64_t;
                }
                #define _STDINT_H_
            #endif
        #endif
    #endif
    // Define cinttypes macros manually for MSVC (most reliable approach)
    // Try to include inttypes.h first if available (VS 2013+), then define only what's missing
    #if _MSC_VER >= 1800
        // Visual Studio 2013+ has inttypes.h, include it first
        #include <inttypes.h>
    #endif
    // Suppress macro redefinition warnings - these macros may be defined by system headers
    #ifdef _MSC_VER
        #pragma warning(push)
        #pragma warning(disable: 4005) // macro redefinition
    #endif
    // Define only macros that aren't already defined
    #ifndef PRId64
        #define PRId64 "I64d"
    #endif
    #ifndef PRIu64
        #define PRIu64 "I64u"
    #endif
    #ifndef PRIx64
        #define PRIx64 "I64x"
    #endif
    #ifndef PRIX64
        #define PRIX64 "I64X"
    #endif
    #ifndef PRId32
        #define PRId32 "d"
    #endif
    #ifndef PRIu32
        #define PRIu32 "u"
    #endif
    #ifndef PRIx32
        #define PRIx32 "x"
    #endif
    #ifndef PRId16
        #define PRId16 "d"
    #endif
    #ifndef PRIu16
        #define PRIu16 "u"
    #endif
    #ifndef PRId8
        #define PRId8 "d"
    #endif
    #ifndef PRIu8
        #define PRIu8 "u"
    #endif
    #ifdef _MSC_VER
        #pragma warning(pop)
    #endif
#else
    // GCC/Clang - use standard headers
    #include <cinttypes>
#endif

// Define essential limits constants manually for maximum compatibility
// MSVC should have these in limits.h, include it first if available
#if AC_COMPILER == AC_COMPILER_MICROSOFT
    #include <limits.h>
#endif
// Only define constants that aren't already defined
#ifndef CHAR_BIT
    #define CHAR_BIT 8
#endif
#ifndef SCHAR_MIN
    #define SCHAR_MIN (-128)
#endif
#ifndef SCHAR_MAX
    #define SCHAR_MAX 127
#endif
#ifndef UCHAR_MAX
    #define UCHAR_MAX 255
#endif
#ifndef SHRT_MIN
    #define SHRT_MIN (-32768)
#endif
#ifndef SHRT_MAX
    #define SHRT_MAX 32767
#endif
#ifndef USHRT_MAX
    #define USHRT_MAX 65535
#endif
#ifndef INT_MIN
    #define INT_MIN (-2147483647 - 1)
#endif
#ifndef INT_MAX
    #define INT_MAX 2147483647
#endif
#ifndef UINT_MAX
    #define UINT_MAX 0xffffffffU
#endif
#ifndef LONG_MIN
    #define LONG_MIN (-2147483647L - 1)
#endif
#ifndef LONG_MAX
    #define LONG_MAX 2147483647L
#endif
#ifndef ULONG_MAX
    #define ULONG_MAX 0xffffffffUL
#endif
#ifndef LLONG_MIN
    #define LLONG_MIN (-9223372036854775807LL - 1)
#endif
#ifndef LLONG_MAX
    #define LLONG_MAX 9223372036854775807LL
#endif
#ifndef ULLONG_MAX
    #define ULLONG_MAX 0xffffffffffffffffULL
#endif

#define ACORE_LITTLEENDIAN 0
#define ACORE_BIGENDIAN    1

#if !defined(ACORE_ENDIAN)
#  if defined (BOOST_BIG_ENDIAN)
#    define ACORE_ENDIAN ACORE_BIGENDIAN
#  else
#    define ACORE_ENDIAN ACORE_LITTLEENDIAN
#  endif
#endif

#if AC_PLATFORM == AC_PLATFORM_WINDOWS
#  define ACORE_PATH_MAX MAX_PATH
#  define _USE_MATH_DEFINES
#else //AC_PLATFORM != AC_PLATFORM_WINDOWS
#  define ACORE_PATH_MAX PATH_MAX
#endif //AC_PLATFORM

#if !defined(COREDEBUG)
#  define ACORE_INLINE inline
#else //COREDEBUG
#  if !defined(ACORE_DEBUG)
#    define ACORE_DEBUG
#  endif //ACORE_DEBUG
#  define ACORE_INLINE
#endif //!COREDEBUG

#if AC_COMPILER == AC_COMPILER_GNU
#  define ATTR_PRINTF(F, V) __attribute__ ((format (printf, F, V)))
#else //AC_COMPILER != AC_COMPILER_GNU
#  define ATTR_PRINTF(F, V)
#endif //AC_COMPILER == AC_COMPILER_GNU

#ifdef ACORE_API_USE_DYNAMIC_LINKING
#  if AC_COMPILER == AC_COMPILER_MICROSOFT
#    define AC_API_EXPORT __declspec(dllexport)
#    define AC_API_IMPORT __declspec(dllimport)
#  elif AC_COMPILER == AC_COMPILER_GNU
#    define AC_API_EXPORT __attribute__((visibility("default")))
#    define AC_API_IMPORT
#  else
#    error compiler not supported!
#  endif
#else
#  define AC_API_EXPORT
#  define AC_API_IMPORT
#endif

#ifdef ACORE_API_EXPORT_COMMON
#  define AC_COMMON_API AC_API_EXPORT
#else
#  define AC_COMMON_API AC_API_IMPORT
#endif

#ifdef ACORE_API_EXPORT_DATABASE
#  define AC_DATABASE_API AC_API_EXPORT
#else
#  define AC_DATABASE_API AC_API_IMPORT
#endif

#ifdef ACORE_API_EXPORT_SHARED
#  define AC_SHARED_API AC_API_EXPORT
#else
#  define AC_SHARED_API AC_API_IMPORT
#endif

#ifdef ACORE_API_EXPORT_GAME
#  define AC_GAME_API AC_API_EXPORT
#else
#  define AC_GAME_API AC_API_IMPORT
#endif

#define UI64LIT(N) UINT64_C(N)
#define SI64LIT(N) INT64_C(N)

#define STRING_VIEW_FMT_ARG(str) static_cast<int>((str).length()), (str).data()

typedef std::int64_t int64;
typedef std::int32_t int32;
typedef std::int16_t int16;
typedef std::int8_t int8;
typedef std::uint64_t uint64;
typedef std::uint32_t uint32;
typedef std::uint16_t uint16;
typedef std::uint8_t uint8;

#endif //ACORE_DEFINE_H
