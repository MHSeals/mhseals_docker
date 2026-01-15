cmake_minimum_required(VERSION 3.8)
project(epsilon_control)

# Default to C++14
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)

add_executable(motor
  src/motor.cpp
)

ament_target_dependencies(motor
  rclcpp
)

target_link_libraries(motor
)

install(TARGETS
  motor
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()