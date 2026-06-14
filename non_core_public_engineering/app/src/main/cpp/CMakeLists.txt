cmake_minimum_required(VERSION 3.22.1)

project("yolo")

# Native camera, inference, ROI, and dependency wiring are omitted from this public shell.

add_library(${CMAKE_PROJECT_NAME}
        SHARED
        jni/native-lib.cpp
)

target_link_libraries(${CMAKE_PROJECT_NAME}
        PRIVATE
        android
        log
)
