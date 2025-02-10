#!/bin/bash

set -ex

path=$(readlink -f "${BASH_SOURCE:-$0}")
DEV_SCRIPT_DIR=$(dirname $path)

if [ -d "$DEV_SCRIPT_DIR/../submodules/rive-runtime" ]; then
    export RIVE_RUNTIME_DIR="$DEV_SCRIPT_DIR/../submodules/rive-runtime"
else
    export RIVE_RUNTIME_DIR="$DEV_SCRIPT_DIR/../../runtime"
fi

export RIVE_PLS_DIR="$RIVE_RUNTIME_DIR/renderer"

make_dependency_directories() {
    rm -fr $DEV_SCRIPT_DIR/../dependencies

    mkdir -p $DEV_SCRIPT_DIR/../dependencies
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/debug
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/release
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/rive
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/renderer
}

build_runtime() {
    # Build the rive runtime.
    pushd $RIVE_RUNTIME_DIR
    ./build.sh -p ios clean
    ./build.sh -p ios $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/ios/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga.a
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive

    # Build rive_cg_renderer.
    pushd $RIVE_RUNTIME_DIR/cg_renderer
    premake5 --config=$1 --out=out/iphoneos_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios gmake2
    make -C out/iphoneos_$1 clean
    make -C out/iphoneos_$1 -j12 rive_cg_renderer
    popd
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/out/iphoneos_$1/librive_cg_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_cg_renderer.a
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer

    # Build rive_pls_renderer.
    pushd $RIVE_PLS_DIR
    premake5 --config=$1 --out=out/iphoneos_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --os=ios gmake2
    make -C out/iphoneos_$1 clean
    make -C out/iphoneos_$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/iphoneos_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer.a
    $DEV_SCRIPT_DIR/strip_static_lib.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer.a
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    
    # Build rive_decoders.
    pushd $RIVE_RUNTIME_DIR/decoders
    premake5 --file=premake5_v2.lua --config=$1 --out=out/iphoneos_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios gmake2
    make -C out/iphoneos_$1 clean
    make -C out/iphoneos_$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/iphoneos_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders.a
}

build_runtime_sim() {
    # Build the rive runtime.
    pushd $RIVE_RUNTIME_DIR
    ./build.sh -p ios_sim clean
    ./build.sh -p ios_sim $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/ios_sim/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sim.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios_sim/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_sim.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios_sim/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_sim.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios_sim/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_sim.a
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive

    # Build rive_cg_renderer.
    pushd $RIVE_RUNTIME_DIR/cg_renderer
    premake5 --config=$1 --out=out/iphonesimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=emulator gmake2

    make -C out/iphonesimulator_$1 clean
    make -C out/iphonesimulator_$1 -j12 rive_cg_renderer
    popd
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/out/iphonesimulator_$1/librive_cg_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_cg_renderer_sim.a
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer

    # Build rive_pls_renderer.
    pushd $RIVE_PLS_DIR
    premake5 --config=$1 --out=out/iphonesimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --os=ios --variant=emulator gmake2
    make -C out/iphonesimulator_$1 clean
    make -C out/iphonesimulator_$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/iphonesimulator_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_sim.a
    $DEV_SCRIPT_DIR/strip_static_lib_fat.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_sim.a arm64 x86_64
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    
    # Build rive_decoders.
    pushd $RIVE_RUNTIME_DIR/decoders
    premake5 --file=premake5_v2.lua --config=$1 --out=out/iphonesimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=emulator gmake2
    make -C out/iphonesimulator_$1 clean
    make -C out/iphonesimulator_$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/iphonesimulator_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_sim.a
}

build_runtime_macosx() {
    # Build the rive runtime.
    pushd $RIVE_RUNTIME_DIR
    ./build.sh -p macosx clean
    ./build.sh -p macosx $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/macosx/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_macos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/macosx/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_macos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/macosx/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_macos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/macosx/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_macos.a
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive

    # Build rive_cg_renderer.
    pushd $RIVE_RUNTIME_DIR/cg_renderer
    premake5 --config=$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=macosx gmake2
    make -C out/$1 clean
    make -C out/$1 -j12 rive_cg_renderer
    popd
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/out/$1/librive_cg_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_cg_renderer_macos.a
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer

    # Build rive_pls_renderer.
    pushd $RIVE_PLS_DIR
    premake5 --config=$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --os=macosx gmake2
    make -C out/$1 clean
    make -C out/$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_macos.a
    $DEV_SCRIPT_DIR/strip_static_lib_fat.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_macos.a arm64 x86_64
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    
    # Build rive_decoders.
    pushd $RIVE_RUNTIME_DIR/decoders
    premake5 --file=premake5_v2.lua --config=$1 --out=out/$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=macosx gmake2
    make -C out/$1 clean
    make -C out/$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_macos.a
}

build_runtime_xros() {
    # Build the rive runtime.
    pushd $RIVE_RUNTIME_DIR
    ./build.sh -p xros clean
    ./build.sh -p xros $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/xros/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_xros.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/xros/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_xros.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/xros/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_xros.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/xros/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_xros.a
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive

    # Build rive_cg_renderer.
    pushd $RIVE_RUNTIME_DIR/cg_renderer
    premake5 --config=$1 --out=out/xros_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=xros gmake2
    make -C out/xros_$1 clean
    make -C out/xros_$1 -j12 rive_cg_renderer
    popd
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/out/xros_$1/librive_cg_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_cg_renderer_xros.a
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer

    # Build rive_pls_renderer.
    pushd $RIVE_PLS_DIR
    premake5 --config=$1 --out=out/xros_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --os=ios --variant=xros gmake2
    make -C out/xros_$1 clean
    make -C out/xros_$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/xros_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_xros.a
    $DEV_SCRIPT_DIR/strip_static_lib.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_xros.a
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer

    # Build rive_decoders.
    pushd $RIVE_RUNTIME_DIR/decoders
    premake5 --file=premake5_v2.lua --config=$1 --out=out/xros_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=xros gmake2
    make -C out/xros_$1 clean
    make -C out/xros_$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/xros_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_xros.a
}

build_runtime_xrsimulator() {
    # Build the rive runtime.
    pushd $RIVE_RUNTIME_DIR
    ./build.sh -p xrsimulator clean
    ./build.sh -p xrsimulator $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/xrsimulator/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_xrsimulator.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/xrsimulator/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_xrsimulator.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/xrsimulator/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_xrsimulator.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/xrsimulator/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_xrsimulator.a
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive

    # Build rive_cg_renderer.
    pushd $RIVE_RUNTIME_DIR/cg_renderer
    premake5 --config=$1 --out=out/xrsimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=xrsimulator gmake2

    make -C out/xrsimulator_$1 clean
    make -C out/xrsimulator_$1 -j12 rive_cg_renderer
    popd
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/out/xrsimulator_$1/librive_cg_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_cg_renderer_xrsimulator.a
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer

    # Build rive_pls_renderer.
    pushd $RIVE_PLS_DIR
    premake5 --config=$1 --out=out/xrsimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --os=ios --variant=xrsimulator gmake2
    make -C out/xrsimulator_$1 clean
    make -C out/xrsimulator_$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/xrsimulator_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_xrsimulator.a
    $DEV_SCRIPT_DIR/strip_static_lib_fat.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_xrsimulator.a arm64 x86_64
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer

    # Build rive_decoders.
    pushd $RIVE_RUNTIME_DIR/decoders
    premake5 --file=premake5_v2.lua --config=$1 --out=out/xrsimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=xrsimulator gmake2
    make -C out/xrsimulator_$1 clean
    make -C out/xrsimulator_$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/xrsimulator_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_xrsimulator.a
}

build_runtime_appletvos() {
    # Build the rive runtime.
    pushd $RIVE_RUNTIME_DIR
    ./build.sh -p appletvos clean
    ./build.sh -p appletvos $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/appletvos/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/appletvos/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/appletvos/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/appletvos/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive

    # Build rive_cg_renderer.
    pushd $RIVE_RUNTIME_DIR/cg_renderer
    premake5 --config=$1 --out=out/appletvos_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=appletvos gmake2
    make -C out/appletvos_$1 clean
    make -C out/appletvos_$1 -j12 rive_cg_renderer
    popd
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/out/appletvos_$1/librive_cg_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_cg_renderer_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer

    # Build rive_pls_renderer.
    pushd $RIVE_PLS_DIR
    premake5 --config=$1 --out=out/appletvos_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --os=ios --variant=appletvos gmake2
    make -C out/appletvos_$1 clean
    make -C out/appletvos_$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/appletvos_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_appletvos.a
    $DEV_SCRIPT_DIR/strip_static_lib.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_appletvos.a
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer

    # Build rive_decoders.
    pushd $RIVE_RUNTIME_DIR/decoders
    premake5 --file=premake5_v2.lua --config=$1 --out=out/appletvos_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=appletvos gmake2
    make -C out/appletvos_$1 clean
    make -C out/appletvos_$1 -j12 rive_decoders
    make -C out/appletvos_$1 -j12 libpng
    make -C out/appletvos_$1 -j12 zlib
    make -C out/appletvos_$1 -j12 libjpeg
    make -C out/appletvos_$1 -j12 libwebp
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvos_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvos_$1/liblibpng.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_png_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvos_$1/libzlib.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_zlib_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvos_$1/liblibjpeg.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_jpeg_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvos_$1/liblibwebp.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_webp_appletvos.a
}

build_runtime_appletvsimulator() {
    # Build the rive runtime.
    pushd $RIVE_RUNTIME_DIR
    ./build.sh -p appletvsimulator clean
    ./build.sh -p appletvsimulator $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/appletvsimulator/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/appletvsimulator/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/appletvsimulator/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/appletvsimulator/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive

    # Build rive_cg_renderer.
    pushd $RIVE_RUNTIME_DIR/cg_renderer
    premake5 --config=$1 --out=out/appletvsimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=appletvsimulator gmake2

    make -C out/appletvsimulator_$1 clean
    make -C out/appletvsimulator_$1 -j12 rive_cg_renderer
    popd
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/out/appletvsimulator_$1/librive_cg_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_cg_renderer_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/cg_renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer

    # Build rive_pls_renderer.
    pushd $RIVE_PLS_DIR
    premake5 --config=$1 --out=out/appletvsimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --os=ios --variant=appletvsimulator gmake2
    make -C out/appletvsimulator_$1 clean
    make -C out/appletvsimulator_$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/appletvsimulator_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_appletvsimulator.a
    $DEV_SCRIPT_DIR/strip_static_lib_fat.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_appletvsimulator.a arm64 x86_64
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer

    # Build rive_decoders.
    pushd $RIVE_RUNTIME_DIR/decoders
    premake5 --file=premake5_v2.lua --config=$1 --out=out/appletvsimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=appletvsimulator gmake2
    make -C out/appletvsimulator_$1 clean
    make -C out/appletvsimulator_$1 -j12 rive_decoders
    make -C out/appletvsimulator_$1 -j12 libpng
    make -C out/appletvsimulator_$1 -j12 zlib
    make -C out/appletvsimulator_$1 -j12 libjpeg
    make -C out/appletvsimulator_$1 -j12 libwebp
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvsimulator_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvsimulator_$1/liblibpng.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_png_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvsimulator_$1/libzlib.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_zlib_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvsimulator_$1/liblibjpeg.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_jpeg_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvsimulator_$1/liblibwebp.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_webp_appletvsimulator.a
}

usage() {
    echo "USAGE: $0 <all|ios|ios_sim|xros|xrsimulator|appletvos|appletvsimulator|macosx> <debug|release>"
    exit 1
}

if (($# < 1)); then
    usage
fi

build_all() {
    if [ "$1" != "debug" ] && [ "$1" != "release" ]; then
        usage
    fi
    
    build_runtime $1
    build_runtime_sim $1
    build_runtime_macosx $1
    build_runtime_xros $1
    build_runtime_xrsimulator $1
    build_runtime_appletvos $1
    build_runtime_appletvsimulator $1
}

case $1 in
all)
    case $2 in
        "debug")
            echo "Building all Apple runtimes in debug..."
            make_dependency_directories
            build_all debug
            ;;
        "release")
            echo "Building all Apple runtimes in release..."
            make_dependency_directories
            build_all release
            ;;
        "")
            echo "Building all Apple runtimes in debug and release..."
            make_dependency_directories
            build_all debug
            build_all release
            ;;
        *) 
            usage
            ;;
    esac
    ;;
macosx)
    if (($# < 2)); then
        usage
    fi
    case $2 in
    release | debug)
        make_dependency_directories
        build_runtime_macosx $2
        ;;
    *)
        usage
        ;;
    esac
    ;;
ios)
    if (($# < 2)); then
        usage
    fi
    case $2 in
    release | debug)
        make_dependency_directories
        build_runtime $2
        ;;
    *)
        usage
        ;;
    esac
    ;;
ios_sim)
    if (($# < 2)); then
        usage
    fi
    case $2 in
    release | debug)
        make_dependency_directories
        build_runtime_sim $2
        # TODO:
        # to build for the example you need debug, but to profile you need release.
        # each time you build, both version are removed. to imnprove this only remove
        # the version being built, or add a "both" option.
        # build_runtime_sim debug
        # build_runtime_sim release
        ;;
    *)
        usage
        ;;
    esac
    ;;
xros)
    if (($# < 2)); then
        usage
    fi
    case $2 in
    release | debug)
        make_dependency_directories
        build_runtime_xros $2
        ;;
    *)
        usage
        ;;
    esac
    ;;
xrsimulator)
    if (($# < 2)); then
        usage
    fi
    case $2 in
    release | debug)
        make_dependency_directories
        build_runtime_xrsimulator $2
        # TODO:
        # to build for the example you need debug, but to profile you need release.
        # each time you build, both version are removed. to imnprove this only remove
        # the version being built, or add a "both" option.
        # build_runtime_sim debug
        # build_runtime_sim release
        ;;
    *)
        usage
        ;;
    esac
    ;;
appletvos)
    if (($# < 2)); then
        usage
    fi
    case $2 in
    release | debug)
        make_dependency_directories
        build_runtime_appletvos $2
        ;;
    *)
        usage
        ;;
    esac
    ;;
appletvsimulator)
    if (($# < 2)); then
        usage
    fi
    case $2 in
    release | debug)
        make_dependency_directories
        build_runtime_appletvsimulator $2
        # TODO:
        # to build for the example you need debug, but to profile you need release.
        # each time you build, both version are removed. to imnprove this only remove
        # the version being built, or add a "both" option.
        # build_runtime_sim debug
        # build_runtime_sim release
        ;;
    *)
        usage
        ;;
    esac
    ;;
*)
    usage
    ;;
esac
