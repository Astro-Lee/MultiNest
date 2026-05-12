cmake_minimum_required(VERSION 3.10) 

# In a normal application you would do:
# FIND_LIBRARY(MultiNest)
# INCLUDE_DIRECTORIES(${MultiNest_INCLUDE_PATH})

FILE(GLOB SOURCE *.c)
add_executable(eggboxC ${SOURCE})
target_link_libraries(eggboxC ${MultiNest_LIBRARIES})
if(UNIX AND NOT APPLE)
    target_link_libraries(eggboxC m)
endif()

# Set install directory
INSTALL(TARGETS eggboxC DESTINATION bin)
