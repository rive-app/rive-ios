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
mkdir dependencies/debug
mkdir dependencies/release

cp -r submodules/rive-cpp/build/ios/bin/debug/librive.a dependencies/debug/librive.a
cp -r submodules/rive-cpp/build/ios/bin/release/librive.a dependencies/release/librive.a
cp -r submodules/rive-cpp/build/ios_sim/bin/debug/librive.a dependencies/debug/librive_sim.a
cp -r submodules/rive-cpp/build/ios_sim/bin/release/librive.a dependencies/release/librive_sim.a

cp -r submodules/rive-cpp/skia/renderer/build/ios/bin/debug/librive_skia_renderer.a dependencies/debug/librive_skia_renderer.a
cp -r submodules/rive-cpp/skia/renderer/build/ios/bin/release/librive_skia_renderer.a dependencies/release/librive_skia_renderer.a
cp -r submodules/rive-cpp/skia/renderer/build/ios_sim/bin/debug/librive_skia_renderer.a dependencies/debug/librive_skia_renderer_sim.a
cp -r submodules/rive-cpp/skia/renderer/build/ios_sim/bin/release/librive_skia_renderer.a dependencies/release/librive_skia_renderer_sim.a

cp -r submodules/rive-cpp/skia/dependencies/skia/out/libskia_ios.a dependencies
cp -r submodules/rive-cpp/skia/dependencies/skia/out/libskia_ios_sim.a dependencies