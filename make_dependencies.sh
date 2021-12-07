#!/bin/bash
set -e

pushd submodules/rive-cpp
pushd skia/dependencies
./make_skia.sh
popd
pushd skia/renderer
./build.sh -p ios clean
./build.sh -p ios debug
./build.sh -p ios release
popd
popd

rm -fr dependencies
mkdir dependencies
cp -r submodules/rive-cpp/build/ios* dependencies
cp -r submodules/rive-cpp/skia/renderer/build/ios* dependencies