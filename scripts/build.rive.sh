#!/bin/bash

set -ex
# split in two so build.skia can be done by multiple workers.
# assumes all skia's have been built

path=$(readlink -f "${BASH_SOURCE:-$0}")
DEV_SCRIPT_DIR=$(dirname $path)

if [ -d "$DEV_SCRIPT_DIR/../submodules/rive-cpp" ]; then
    export RIVE_RUNTIME_DIR="$DEV_SCRIPT_DIR/../submodules/rive-cpp"
else
    export RIVE_RUNTIME_DIR="$DEV_SCRIPT_DIR/../../runtime"
fi

RIVE_PLS_DIR=$RIVE_RUNTIME_DIR/../pls

make_dependency_directories() {
    rm -fr $DEV_SCRIPT_DIR/../dependencies

    mkdir -p $DEV_SCRIPT_DIR/../dependencies
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/debug
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/release
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/skia
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/rive
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/pls
}

build_skia_renderer() {
    # NOTE: we do not currently use debug, so lets not build debug
    pushd $RIVE_RUNTIME_DIR/skia/renderer
    ./build.sh -p ios clean
    ./build.sh -p ios $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/ios/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi.a
    cp -r $RIVE_RUNTIME_DIR/skia/renderer/build/ios/bin/$1/librive_skia_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_skia_renderer.a

    cp -r $RIVE_RUNTIME_DIR/skia/renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive
}

build_skia_renderer_sim() {
    # NOTE: we do not currently use debug, so lets not build debug
    pushd $RIVE_RUNTIME_DIR/skia/renderer
    ./build.sh -p ios_sim clean
    ./build.sh -p ios_sim $1
    popd

    cp -r $RIVE_RUNTIME_DIR/build/ios_sim/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sim.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios_sim/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_sim.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios_sim/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_sim.a
    cp -r $RIVE_RUNTIME_DIR/skia/renderer/build/ios_sim/bin/$1/librive_skia_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_skia_renderer_sim.a

    cp -r $RIVE_RUNTIME_DIR/skia/renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive
}

build_skia_renderer_macosx() {
    # NOTE: we do not currently use debug, so lets not build debug
    pushd $RIVE_RUNTIME_DIR/skia/renderer
    ./build.sh -p macosx clean
    ./build.sh -p macosx $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/macosx/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_macos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/macosx/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_macos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/macosx/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_macos.a
    cp -r $RIVE_RUNTIME_DIR/skia/renderer/build/macosx/bin/$1/librive_skia_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_skia_renderer_macos.a

    cp -r $RIVE_RUNTIME_DIR/skia/renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive
}

build_pls_renderer() {
    if [ -d "$RIVE_PLS_DIR" ]; then
        pushd $RIVE_PLS_DIR/out
        premake5 --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --no-rive-decoders --os=ios gmake2
        make config=$1 clean
        make config=$1 -j12 rive_pls_renderer
        popd

        cp -r $RIVE_PLS_DIR/out/iphoneos_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer.a

        cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
    else
        # TODO: this fixes the compile without PLS, but linking will still fail because it won't
        # find librive_pls_renderer.a.
        cp -r $DEV_SCRIPT_DIR/../Source/Renderer/NullPLS/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
    fi
}

build_pls_renderer_sim() {
    if [ -d "$RIVE_PLS_DIR" ]; then
        pushd $RIVE_PLS_DIR/out
        premake5 --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --no-rive-decoders --os=ios --variant=simulator gmake2
        make config=$1 clean
        make config=$1 -j12 rive_pls_renderer
        popd

        cp -r $RIVE_PLS_DIR/out/iphonesimulator_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_sim.a

        cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
    else
        # TODO: this fixes the compile without PLS, but linking will still fail because it won't
        # find librive_pls_renderer_sim.a.
        cp -r $DEV_SCRIPT_DIR/../Source/Renderer/NullPLS/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
    fi
}

build_pls_renderer_macosx() {
    if [ -d "$RIVE_PLS_DIR" ]; then
        pushd $RIVE_PLS_DIR/out
        premake5 --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --no-rive-decoders --os=macosx gmake2
        make config=$1 clean
        make config=$1 -j12 rive_pls_renderer
        popd

        cp -r $RIVE_PLS_DIR/out/$1/librive_pls_renderer_macos.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer.a

        cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
    else
        # TODO: this fixes the compile without PLS, but linking will still fail because it won't
        # find librive_pls_renderer_macosx.a.
        cp -r $DEV_SCRIPT_DIR/../Source/Renderer/NullPLS/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
    fi
}

finalize_skia() {
    # COMBINE SKIA
    # make fat library, note that the ios64 library is already fat with arm64 and arm64e so we don't specify arch there.

    pwd
    pushd $RIVE_RUNTIME_DIR/skia/dependencies/skia
    xcrun -sdk macosx lipo -create -arch x86_64 out/macosx/x64/libskia.a -arch arm64 out/macosx/arm64/libskia.a -output out/macosx/libskia_macos.a
    xcrun -sdk iphoneos lipo -create -arch armv7 out/ios/arm/libskia.a out/ios/arm64/libskia.a -output out/ios/libskia_ios.a
    xcrun -sdk iphoneos lipo -create -arch x86_64 out/ios/x64/libskia.a -arch i386 out/ios/x86/libskia.a out/ios/iossim_arm64/libskia.a -output out/ios/libskia_ios_sim.a
    popd

    # copy skia outputs from ld'in skia!
    cp -r $RIVE_RUNTIME_DIR/skia/dependencies/skia/out/ios/libskia_ios.a $DEV_SCRIPT_DIR/../dependencies
    cp -r $RIVE_RUNTIME_DIR/skia/dependencies/skia/out/ios/libskia_ios_sim.a $DEV_SCRIPT_DIR/../dependencies
    cp -r $RIVE_RUNTIME_DIR/skia/dependencies/skia/out/macosx/libskia_macos.a $DEV_SCRIPT_DIR/../dependencies
    # note we purposefully put the skia include folder into dependencies/includes/skia, skia includes headers from include/core/name.h
    cp -r $RIVE_RUNTIME_DIR/skia/dependencies/skia/include $DEV_SCRIPT_DIR/../dependencies/includes/skia
}

usage() {
    echo "USAGE: $0 <all|ios|ios_sim|macosx> <debug|release>"
    exit 1
}

if (($# < 1)); then
    usage
fi

case $1 in
all)
    make_dependency_directories
    finalize_skia
    build_skia_renderer debug
    build_skia_renderer release
    build_skia_renderer_sim debug
    build_skia_renderer_sim release
    build_skia_renderer_macosx debug
    build_skia_renderer_macosx release
    build_pls_renderer debug
    build_pls_renderer release
    build_pls_renderer_sim debug
    build_pls_renderer_sim release
    build_pls_renderer_macosx debug
    build_pls_renderer_macosx release
    ;;
macosx)
    if (($# < 2)); then
        usage
    fi
    case $2 in
    release | debug)
        make_dependency_directories
        finalize_skia
        build_skia_renderer_macosx $2
        build_pls_renderer_macosx $2
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
        finalize_skia
        build_skia_renderer $2
        build_pls_renderer $2
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
        finalize_skia
        build_skia_renderer_sim $2
        build_pls_renderer_sim $2
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
