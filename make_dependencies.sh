#!/bin/bash
set -e

cd submodules/rive-cpp
pushd skia/dependencies
./make_skia.sh
popd
pushd skia/renderer
./build.sh -p ios clean
./build.sh -p ios debug
./build.sh -p ios release
popd
