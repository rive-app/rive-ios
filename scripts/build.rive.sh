#!/bin/bash

set -ex

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
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/renderer
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/rive
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/pls
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
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
    
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
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
    
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
    cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/pls
    
    # Build rive_decoders.
    pushd $RIVE_RUNTIME_DIR/decoders
    premake5 --file=premake5_v2.lua --config=$1 --out=out/$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=macosx gmake2
    make -C out/$1 clean
    make -C out/$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_macos.a
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
*)
    usage
    ;;
esac
