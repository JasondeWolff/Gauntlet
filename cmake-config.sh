#!/bin/sh
sudo apt-get update && sudo apt-get install -y cmake build-essential libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libgl1-mesa-dev libasound2-dev git
cmake mkdir build
cmake -B build -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc -DCMAKE_BUILD_TYPE=Debug -S .