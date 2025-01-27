# Finds Lapack, tests, and if not found or broken, autobuild Lapack
include(ExternalProject)

if(intsize64)
  if(MKL IN_LIST LAPACK_COMPONENTS)
    list(APPEND LAPACK_COMPONENTS MKL64)
  else()
    if(NOT (OpenBLAS IN_LIST LAPACK_COMPONENTS
      OR Netlib IN_LIST LAPACK_COMPONENTS
      OR Atlas IN_LIST LAPACK_COMPONENTS
      OR MKL IN_LIST LAPACK_COMPONENTS))
      if(DEFINED ENV{MKLROOT})
        list(APPEND LAPACK_COMPONENTS MKL MKL64)
      endif()
    endif()
  endif()
endif()

if(NOT lapack_external)
  if(autobuild)
    find_package(LAPACK COMPONENTS ${LAPACK_COMPONENTS})
  else()
    find_package(LAPACK REQUIRED COMPONENTS ${LAPACK_COMPONENTS})
  endif()
endif()

if(LAPACK_FOUND OR TARGET LAPACK::LAPACK)
  return()
endif()

set(lapack_external true CACHE BOOL "build Lapack")

if(BUILD_SHARED_LIBS)
  if(WIN32)
    set(LAPACK_IMPLIB
    ${CMAKE_INSTALL_PREFIX}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}lapack${CMAKE_SHARED_LIBRARY_SUFFIX}${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${CMAKE_INSTALL_PREFIX}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}blas${CMAKE_SHARED_LIBRARY_SUFFIX}${CMAKE_STATIC_LIBRARY_SUFFIX}
    )
    set(LAPACK_LIBRARIES
    ${CMAKE_INSTALL_PREFIX}/bin/${CMAKE_SHARED_LIBRARY_PREFIX}lapack${CMAKE_SHARED_LIBRARY_SUFFIX}
    ${CMAKE_INSTALL_PREFIX}/bin/${CMAKE_SHARED_LIBRARY_PREFIX}blas${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
  else()
    set(LAPACK_LIBRARIES
    ${CMAKE_INSTALL_PREFIX}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}lapack${CMAKE_SHARED_LIBRARY_SUFFIX}
    ${CMAKE_INSTALL_PREFIX}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}blas${CMAKE_SHARED_LIBRARY_SUFFIX}
    )
  endif()
else()
  set(LAPACK_LIBRARIES
  ${CMAKE_INSTALL_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}lapack${CMAKE_STATIC_LIBRARY_SUFFIX}
  ${CMAKE_INSTALL_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}blas${CMAKE_STATIC_LIBRARY_SUFFIX}
  )
endif()

set(lapack_cmake_args
-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
-DCMAKE_BUILD_TYPE=Release
-DBUILD_TESTING:BOOL=false
)

ExternalProject_Add(LAPACK
GIT_REPOSITORY ${lapack_git}
GIT_TAG ${lapack_tag}
CMAKE_ARGS ${lapack_cmake_args}
CMAKE_GENERATOR ${EXTPROJ_GENERATOR}
CMAKE_CACHE_ARGS -Darith:STRING=${arith}
BUILD_BYPRODUCTS ${LAPACK_LIBRARIES}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD ON
)

add_library(LAPACK::LAPACK INTERFACE IMPORTED)
target_link_libraries(LAPACK::LAPACK INTERFACE "${LAPACK_LIBRARIES}")

# race condition for linking without this
add_dependencies(LAPACK::LAPACK LAPACK)
