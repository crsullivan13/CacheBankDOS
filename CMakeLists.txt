cmake_minimum_required(VERSION 3.22)

project(BkPLL)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "-Wall")

add_executable(BkPLL
        src/BkPLL.cpp
        src/util.c
        src/arch.c
        src/wrmsr.c
        src/rdmsr.c
        )