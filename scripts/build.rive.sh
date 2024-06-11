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

if [[ -z "${RIVE_PLS_DIR}" ]]; then
    if [ -d "$RIVE_RUNTIME_DIR/../pls" ]; then
        # pls exists where we expected to find it
        export RIVE_PLS_DIR="$RIVE_RUNTIME_DIR/../pls"
    else
        # pls is not present -- build the null library instead
        export RIVE_PLS_DIR="$DEV_SCRIPT_DIR/../Source/Renderer/NullPLS"
    fi
fi

make_dependency_directories() {
    rm -fr $DEV_SCRIPT_DIR/../dependencies

    mkdir -p $DEV_SCRIPT_DIR/../dependencies
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/debug
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/release
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/skia
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/rive
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/pls
}

build_runtime() {
    # Build rive_skia_renderer renderer (also builds the runtime).
    pushd $RIVE_RUNTIME_DIR/skia/renderer
    ./build.sh -p ios clean
    ./build.sh -p ios $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/ios/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga.a
    cp -r $RIVE_RUNTIME_DIR/skia/renderer/build/ios/bin/$1/librive_skia_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_skia_renderer.a
    cp -r $RIVE_RUNTIME_DIR/skia/renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer
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
    premake5 --config=$1 --out=out/iphoneos_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --no-rive-decoders --os=ios gmake2
    make -C out/iphoneos_$1 clean
    make -C out/iphoneos_$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/iphoneos_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer.a
    $DEV_SCRIPT_DIR/strip_static_lib.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer.a
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
}

build_runtime_sim() {
    # NOTE: we do not currently use debug, so lets not build debug
    pushd $RIVE_RUNTIME_DIR/skia/renderer
    ./build.sh -p ios_sim clean
    ./build.sh -p ios_sim $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/ios_sim/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sim.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios_sim/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_sim.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios_sim/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_sim.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/ios_sim/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_sim.a
    cp -r $RIVE_RUNTIME_DIR/skia/renderer/build/ios_sim/bin/$1/librive_skia_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_skia_renderer_sim.a
    cp -r $RIVE_RUNTIME_DIR/skia/renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer
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
    premake5 --config=$1 --out=out/iphonesimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --no-rive-decoders --os=ios --variant=emulator gmake2
    make -C out/iphonesimulator_$1 clean
    make -C out/iphonesimulator_$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/iphonesimulator_$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_sim.a
    $DEV_SCRIPT_DIR/strip_static_lib_fat.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_sim.a arm64 x86_64
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
}

build_runtime_macosx() {
    # NOTE: we do not currently use debug, so lets not build debug
    pushd $RIVE_RUNTIME_DIR/skia/renderer
    ./build.sh -p macosx clean
    ./build.sh -p macosx $1
    popd
    cp -r $RIVE_RUNTIME_DIR/build/macosx/bin/$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_macos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/macosx/cache/bin/$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_macos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/macosx/cache/bin/$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_macos.a
    cp -r $RIVE_RUNTIME_DIR/dependencies/macosx/cache/bin/$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_macos.a
    cp -r $RIVE_RUNTIME_DIR/skia/renderer/build/macosx/bin/$1/librive_skia_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_skia_renderer_macos.a
    cp -r $RIVE_RUNTIME_DIR/skia/renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer
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
    premake5 --config=$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --no-rive-decoders --os=macosx gmake2
    make -C out/$1 clean
    make -C out/$1 -j12 rive_pls_renderer
    popd
    cp -r $RIVE_PLS_DIR/out/$1/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_macos.a
    $DEV_SCRIPT_DIR/strip_static_lib_fat.sh $DEV_SCRIPT_DIR/../dependencies/$1/librive_pls_renderer_macos.a arm64 x86_64
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
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
    build_runtime debug
    build_runtime release
    build_runtime_sim debug
    build_runtime_sim release
    build_runtime_macosx debug
    build_runtime_macosx release
    ;;
macosx)
    if (($# < 2)); then
        usage
    fi
    case $2 in
    release | debug)
        make_dependency_directories
        finalize_skia
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
        finalize_skia
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
        finalize_skia
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
*)
    usage
    ;;
esac
