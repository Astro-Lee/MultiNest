cmake_minimum_required(VERSION 3.10) 

#=============================================================================
# Copyright 2012 Brian Kloppenborg
#
# This code is licensed under the MIT License.  
#
# The MIT License
#
# License for the specific language governing rights and limitations under
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#=============================================================================

# Find required packages
FIND_PACKAGE(LAPACK REQUIRED)

# If we are compiling with gfortran, add -ffree-line-length-none
foreach(lang C CXX Fortran)
    if(CMAKE_${lang}_COMPILER_ID STREQUAL GNU)
        MESSAGE(STATUS "Detected gfortran, adding -ffree-line-length-none compiler flag.")
        set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-none")
	 if(CMAKE_${lang}_COMPILER_VERSION VERSION_GREATER 10)
            set(CMAKE_Fortran_FLAGS  "${CMAKE_Fortran_FLAGS} -std=legacy")
	    endif()		 
	break()
    endif()
endforeach()

# Emit a warning for gfortran < 4.3.6 and cwrapper.f90
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
 if(${CMAKE_C_COMPILER_VERSION} VERSION_LESS 4.3.7)
    message(WARNING "Insufficient gfortran version for the cwrapper module. PyMultiNest will not work automagically. Please refer to the PyMultiNest manual if you want to use it. https://johannesbuchner.github.io/PyMultiNest/install.html")
 endif()
endif()

# Enable optimization.
#LIST(APPEND CMAKE_Fortran_FLAGS "-O3")

# ============================
# Collect the source:
# ============================
FILE(GLOB MultiNest_SOURCE *.f90 *.F90)

# ============================
# Object library: compile source once, share objects across static/shared.
# Avoids Fortran .mod file race conditions in parallel builds.
# ============================
ADD_LIBRARY(multinest_obj OBJECT ${MultiNest_SOURCE})
SET_TARGET_PROPERTIES(multinest_obj PROPERTIES
    LINKER_LANGUAGE Fortran
    Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/src/modules
    POSITION_INDEPENDENT_CODE ON
)
TARGET_LINK_LIBRARIES(multinest_obj PUBLIC ${LAPACK_LIBRARIES})

# libmultinest.a
ADD_LIBRARY(multinest_static STATIC $<TARGET_OBJECTS:multinest_obj>)
SET_TARGET_PROPERTIES(multinest_static PROPERTIES LINKER_LANGUAGE Fortran
    VERSION ${MultiNest_VERSION} OUTPUT_NAME multinest
)
TARGET_LINK_LIBRARIES(multinest_static ${LAPACK_LIBRARIES})

# libmultinest.so
ADD_LIBRARY(multinest_shared SHARED $<TARGET_OBJECTS:multinest_obj>)
SET_TARGET_PROPERTIES(multinest_shared PROPERTIES LINKER_LANGUAGE Fortran
    VERSION ${MultiNest_VERSION} OUTPUT_NAME multinest
)
TARGET_LINK_LIBRARIES(multinest_shared ${LAPACK_LIBRARIES})

# Set the default library against which to link:
SET(MultiNest_LIBRARIES multinest_shared)

# ============================
# Build MPI-enabled libraries, if MPI is installed
# ============================
FIND_PACKAGE(MPI)
if(NOT MPI_Fortran_FOUND)
    MESSAGE(STATUS "MPI not found, only non-MPI MultiNest libraries will be built.")
else()
    ADD_LIBRARY(multinest_mpi_obj OBJECT ${MultiNest_SOURCE})
    SET_TARGET_PROPERTIES(multinest_mpi_obj PROPERTIES
        LINKER_LANGUAGE Fortran
        Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/src/modules_mpi
        POSITION_INDEPENDENT_CODE ON
    )
    TARGET_LINK_LIBRARIES(multinest_mpi_obj PUBLIC ${LAPACK_LIBRARIES} ${MPI_Fortran_LIBRARIES})
    TARGET_INCLUDE_DIRECTORIES(multinest_mpi_obj PRIVATE ${MPI_Fortran_INCLUDE_PATH})
    TARGET_COMPILE_DEFINITIONS(multinest_mpi_obj PRIVATE MPI)
    if(MPI_Fortran_COMPILE_FLAGS)
        TARGET_COMPILE_OPTIONS(multinest_mpi_obj PRIVATE ${MPI_Fortran_COMPILE_FLAGS})
    endif()

    ADD_LIBRARY(multinest_mpi_static STATIC $<TARGET_OBJECTS:multinest_mpi_obj>)
    SET_TARGET_PROPERTIES(multinest_mpi_static PROPERTIES LINKER_LANGUAGE Fortran VERSION ${MultiNest_VERSION} OUTPUT_NAME multinest_mpi)
    TARGET_LINK_LIBRARIES(multinest_mpi_static ${LAPACK_LIBRARIES} ${MPI_Fortran_LIBRARIES})

    ADD_LIBRARY(multinest_mpi_shared SHARED $<TARGET_OBJECTS:multinest_mpi_obj>)
    SET_TARGET_PROPERTIES(multinest_mpi_shared PROPERTIES LINKER_LANGUAGE Fortran VERSION ${MultiNest_VERSION} OUTPUT_NAME multinest_mpi)
    TARGET_LINK_LIBRARIES(multinest_mpi_shared ${LAPACK_LIBRARIES} ${MPI_Fortran_LIBRARIES})

    if(MPI_Fortran_LINK_FLAGS)
        SET_TARGET_PROPERTIES(multinest_mpi_static multinest_mpi_shared PROPERTIES LINK_FLAGS ${MPI_Fortran_LINK_FLAGS})
    endif()

    SET(MultiNest_LIBRARIES multinest_mpi_shared)
endif ()

# ============================
# After compilation, copy Fortran modules into the 'modules' directory.
# ============================
ADD_CUSTOM_COMMAND(
    TARGET multinest_static
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_SOURCE_DIR}/modules/
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_BINARY_DIR}/src/modules/ ${CMAKE_SOURCE_DIR}/modules/
)

# ============================
# Installation commands
# ============================

# We need to modify the RPATH between the compilation and installation phases.
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# When we install, switch the RPATH to the default system directory
LIST(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_PREFIX}/lib" isSystemDir)
IF("${isSystemDir}" STREQUAL "-1")
    SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
ENDIF("${isSystemDir}" STREQUAL "-1")

# Determine which libraries we will be installing.
SET(MultiNest_INSTALL_LIBS multinest_static multinest_shared)
if(MPI_Fortran_FOUND)
    LIST(APPEND MultiNest_INSTALL_LIBS multinest_mpi_static multinest_mpi_shared)
endif(MPI_Fortran_FOUND)

# Specify where compiled files should go
INSTALL(TARGETS ${MultiNest_INSTALL_LIBS} DESTINATION lib)
# Fortran modules
INSTALL(DIRECTORY ${CMAKE_BINARY_DIR}/src/modules/ DESTINATION modules)
# Install the multinest.h file
INSTALL(FILES ${CMAKE_SOURCE_DIR}/include/multinest.h DESTINATION include)
# Install the FindMultiNest.cmake script
INSTALL(FILES ${CMAKE_SOURCE_DIR}/CMakeModules/FindMultiNest.cmake DESTINATION CMakeModules)
# and ensure the chains directory is created too
INSTALL(DIRECTORY
    ${CMAKE_SOURCE_DIR}/bin/chains
    DESTINATION bin
)

