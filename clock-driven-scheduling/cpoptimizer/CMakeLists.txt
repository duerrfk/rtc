cmake_minimum_required (VERSION 3.13)

# CPLEX-specific directories
set(CPLEX_INCL_DIRECTORY /opt/ibm/ILOG/CPLEX_Studio221/concert/include /opt/ibm/ILOG/CPLEX_Studio221/cpoptimizer/include /opt/ibm/ILOG/CPLEX_Studio221/cplex/include)
set(CPLEX_LIB_DIRECTORY /opt/ibm/ILOG/CPLEX_Studio221/cpoptimizer/lib/x86-64_linux/static_pic /opt/ibm/ILOG/CPLEX_Studio221/concert/lib/x86-64_linux/static_pic /opt/ibm/ILOG/CPLEX_Studio221/cplex/lib/x86-64_linux/static_pic)
#include_directories(${CPLEX_INCL_DIRECTORY})
#link_directories(${CPLEX_LIB_DIRECTORY})

set(CMAKE_CXX_STANDARD 17)

project(clock_driven_scheduling)

add_executable(clock_driven_scheduling_cp clock_driven_scheduling_cp.cc)
target_include_directories(clock_driven_scheduling_cp PRIVATE ${CPLEX_INCL_DIRECTORY})
target_link_directories(clock_driven_scheduling_cp PRIVATE ${CPLEX_LIB_DIRECTORY})
target_link_libraries(clock_driven_scheduling_cp cp)
target_link_libraries(clock_driven_scheduling_cp cplex)
target_link_libraries(clock_driven_scheduling_cp concert)
