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

if [ -z "${RIVE_PREMAKE_ARGS+null_detector_string}" ]; then
    RIVE_PREMAKE_ARGS="--with_rive_layout"
fi

NO_AUDIO=false
NO_TEXT=false
PLATFORM=""
CONFIG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-audio)
            NO_AUDIO=true
            shift
            ;;
        --no-text)
            NO_TEXT=true
            shift
            ;;
        all|macosx|ios|ios_sim|xros|xrsimulator|appletvos|appletvsimulator|maccatalyst)
            PLATFORM="$1"
            shift
            ;;
        debug|release)
            CONFIG="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Add audio flag to RIVE_PREMAKE_ARGS if --no-audio is not passed
if [ "$NO_AUDIO" = false ]; then
    RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS --with_rive_audio=system"
fi

# Add text flag to RIVE_PREMAKE_ARGS if --no-text is not passed
if [ "$NO_TEXT" = false ]; then
    RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS --with_rive_text"
fi

# Handle preprocessor definitions for audio and text
# Build the definitions string
DEFINITIONS=""
if [ "$NO_AUDIO" = false ]; then
    DEFINITIONS="$DEFINITIONS WITH_RIVE_AUDIO"
fi
if [ "$NO_TEXT" = false ]; then
    DEFINITIONS="$DEFINITIONS WITH_RIVE_TEXT"
fi

# Set the preprocessor definitions line
if [ -n "$DEFINITIONS" ]; then
    # Remove leading space
    DEFINITIONS=$(echo "$DEFINITIONS" | sed 's/^ //')
    # Update the active GCC_PREPROCESSOR_DEFINITIONS line (not commented ones)
    sed -i '' "/^GCC_PREPROCESSOR_DEFINITIONS = /s/= .*/= \$(inherited) $DEFINITIONS/" $DEV_SCRIPT_DIR/../Config/Base.xcconfig
    # Update the active SWIFT_ACTIVE_COMPILATION_CONDITIONS line (not commented ones)
    sed -i '' "/^SWIFT_ACTIVE_COMPILATION_CONDITIONS = /s/= .*/= \$(inherited) $DEFINITIONS/" $DEV_SCRIPT_DIR/../Config/Base.xcconfig
else
    # Update the active GCC_PREPROCESSOR_DEFINITIONS line (not commented ones)
    sed -i '' '/^GCC_PREPROCESSOR_DEFINITIONS = /s/= .*/= $(inherited)/' $DEV_SCRIPT_DIR/../Config/Base.xcconfig
    # Update the active SWIFT_ACTIVE_COMPILATION_CONDITIONS line (not commented ones)
    sed -i '' '/^SWIFT_ACTIVE_COMPILATION_CONDITIONS = /s/= .*/= $(inherited)/' $DEV_SCRIPT_DIR/../Config/Base.xcconfig
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
    mkdir -p $DEV_SCRIPT_DIR/../dependencies/includes/renderer
}

build_runtime() {
    # Build the rive runtime.
    RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS" build_rive.sh --file=$RIVE_RUNTIME_DIR/premake5_v2.lua ios $1 $AUDIO_FLAG universal clean

    cp -r out/ios_universal_$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz.a
    cp -r out/ios_universal_$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga.a
    cp -r out/ios_universal_$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi.a
    cp -r out/ios_universal_$1/libminiaudio.a $DEV_SCRIPT_DIR/../dependencies/$1/libminiaudio.a
    cp -r out/ios_universal_$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive.a
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
    premake5 --file=premake5_v2.lua --config=$1 --out=out/iphoneos_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --no_rive_jpeg --no_rive_png --no_rive_webp gmake2
    make -C out/iphoneos_$1 clean
    make -C out/iphoneos_$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/iphoneos_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders.a
}

build_runtime_sim() {
    # Build the rive runtime.
    RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS" build_rive.sh --file=$RIVE_RUNTIME_DIR/premake5_v2.lua iossim $1 $AUDIO_FLAG clean

    cp -r out/iossim_universal_$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_sim.a
    cp -r out/iossim_universal_$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_sim.a
    cp -r out/iossim_universal_$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_sim.a
    cp -r out/iossim_universal_$1/libminiaudio.a $DEV_SCRIPT_DIR/../dependencies/$1/libminiaudio_sim.a
    cp -r out/iossim_universal_$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sim.a
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
    premake5 --file=premake5_v2.lua --config=$1 --out=out/iphonesimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=emulator --no_rive_jpeg --no_rive_png --no_rive_webp gmake2
    make -C out/iphonesimulator_$1 clean
    make -C out/iphonesimulator_$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/iphonesimulator_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_sim.a
}

build_runtime_macosx() {
    # Build the rive runtime.
    RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS" build_rive.sh --file=$RIVE_RUNTIME_DIR/premake5_v2.lua $1 universal $AUDIO_FLAG clean

    cp -r out/universal_$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_macos.a
    cp -r out/universal_$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_macos.a
    cp -r out/universal_$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_macos.a
    cp -r out/universal_$1/libminiaudio.a $DEV_SCRIPT_DIR/../dependencies/$1/libminiaudio_macos.a
    cp -r out/universal_$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_macos.a
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
    premake5 --file=premake5_v2.lua --config=$1 --out=out/$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=macosx --no_rive_jpeg --no_rive_png --no_rive_webp gmake2
    make -C out/$1 clean
    make -C out/$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_macos.a
}

build_runtime_xros() {
    # Build the rive runtime.
    RIVE_OUT=out/xros_$1 RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS" build_rive.sh --file=$RIVE_RUNTIME_DIR/premake5_v2.lua xros $1 $AUDIO_FLAG clean

    cp -r out/xros_$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_xros.a
    cp -r out/xros_$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_xros.a
    cp -r out/xros_$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_xros.a
    cp -r out/xros_$1/libminiaudio.a $DEV_SCRIPT_DIR/../dependencies/$1/libminiaudio_xros.a
    cp -r out/xros_$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_xros.a
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
    premake5 --file=premake5_v2.lua --config=$1 --out=out/xros_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=xros --no_rive_jpeg --no_rive_png --no_rive_webp gmake2
    make -C out/xros_$1 clean
    make -C out/xros_$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/xros_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_xros.a
}

build_runtime_xrsimulator() {
    # Build the rive runtime.
    RIVE_OUT=out/xrsimulator_universal_$1 RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS" build_rive.sh --file=$RIVE_RUNTIME_DIR/premake5_v2.lua xrsimulator $1 $AUDIO_FLAG clean

    cp -r out/xrsimulator_universal_$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_xrsimulator.a
    cp -r out/xrsimulator_universal_$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_xrsimulator.a
    cp -r out/xrsimulator_universal_$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_xrsimulator.a
    cp -r out/xrsimulator_universal_$1/libminiaudio.a $DEV_SCRIPT_DIR/../dependencies/$1/libminiaudio_xrsimulator.a
    cp -r out/xrsimulator_universal_$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_xrsimulator.a
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
    premake5 --file=premake5_v2.lua --config=$1 --out=out/xrsimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=xrsimulator --no_rive_jpeg --no_rive_png --no_rive_webp gmake2
    make -C out/xrsimulator_$1 clean
    make -C out/xrsimulator_$1 -j12 rive_decoders
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/xrsimulator_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_xrsimulator.a
}

build_runtime_appletvos() {
    RIVE_OUT=out/appletvos_$1 RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS" build_rive.sh --file=$RIVE_RUNTIME_DIR/premake5_v2.lua appletvos $1 $AUDIO_FLAG clean

    cp -r out/appletvos_$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_appletvos.a
    cp -r out/appletvos_$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_appletvos.a
    cp -r out/appletvos_$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_appletvos.a
    cp -r out/appletvos_$1/libminiaudio.a $DEV_SCRIPT_DIR/../dependencies/$1/libminiaudio_appletvos.a
    cp -r out/appletvos_$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_appletvos.a
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
    premake5 --file=premake5_v2.lua --config=$1 --out=out/appletvos_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=appletvos --no_rive_jpeg --no_rive_png gmake2
    make -C out/appletvos_$1 clean
    make -C out/appletvos_$1 -j12 rive_decoders
    make -C out/appletvos_$1 -j12 libwebp
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvos_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_appletvos.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvos_$1/liblibwebp.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_webp_appletvos.a
}

build_runtime_appletvsimulator() {
    RIVE_OUT=out/appletvsimulator_universal_$1 RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS" build_rive.sh --file=$RIVE_RUNTIME_DIR/premake5_v2.lua appletvsimulator $1 $AUDIO_FLAG clean

    cp -r out/appletvsimulator_universal_$1/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_harfbuzz_appletvsimulator.a
    cp -r out/appletvsimulator_universal_$1/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_yoga_appletvsimulator.a
    cp -r out/appletvsimulator_universal_$1/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_sheenbidi_appletvsimulator.a
    cp -r out/appletvsimulator_universal_$1/libminiaudio.a $DEV_SCRIPT_DIR/../dependencies/$1/libminiaudio_appletvsimulator.a
    cp -r out/appletvsimulator_universal_$1/librive.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_appletvsimulator.a
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
    premake5 --file=premake5_v2.lua --config=$1 --out=out/appletvsimulator_$1 --arch=universal --scripts=$RIVE_RUNTIME_DIR/build --os=ios --variant=appletvsimulator --no_rive_jpeg --no_rive_png gmake2
    make -C out/appletvsimulator_$1 clean
    make -C out/appletvsimulator_$1 -j12 rive_decoders
    make -C out/appletvsimulator_$1 -j12 libwebp
    popd
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvsimulator_$1/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_decoders_appletvsimulator.a
    cp -r $RIVE_RUNTIME_DIR/decoders/out/appletvsimulator_$1/liblibwebp.a $DEV_SCRIPT_DIR/../dependencies/$1/librive_webp_appletvsimulator.a
}

build_runtime_maccatalyst() {
    _build_runtime_maccatalyst() {
        local config=$1
        local arch=$2
        
        # Build the rive runtime.
        RIVE_OUT=out/maccatalyst_${arch}_${config} RIVE_PREMAKE_ARGS="$RIVE_PREMAKE_ARGS" build_rive.sh --file=$RIVE_RUNTIME_DIR/premake5_v2.lua ${config} ${arch} $AUDIO_FLAG --variant=maccatalyst clean

        cp -r out/maccatalyst_${arch}_${config}/librive_harfbuzz.a $DEV_SCRIPT_DIR/../dependencies/${config}/librive_harfbuzz_maccatalyst_${arch}.a
        cp -r out/maccatalyst_${arch}_${config}/librive_yoga.a $DEV_SCRIPT_DIR/../dependencies/${config}/librive_yoga_maccatalyst_${arch}.a
        cp -r out/maccatalyst_${arch}_${config}/librive_sheenbidi.a $DEV_SCRIPT_DIR/../dependencies/${config}/librive_sheenbidi_maccatalyst_${arch}.a
        cp -r out/maccatalyst_${arch}_${config}/libminiaudio.a $DEV_SCRIPT_DIR/../dependencies/${config}/libminiaudio_maccatalyst_${arch}.a
        cp -r out/maccatalyst_${arch}_${config}/librive.a $DEV_SCRIPT_DIR/../dependencies/${config}/librive_maccatalyst_${arch}.a
        cp -r $RIVE_RUNTIME_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/rive

        # Build rive_cg_renderer.
        pushd $RIVE_RUNTIME_DIR/cg_renderer
        premake5 --config=${config} --out=out/maccatalyst_${arch}_${config} --arch=${arch} --scripts=$RIVE_RUNTIME_DIR/build --os=macosx --variant=maccatalyst gmake2
        make -C out/maccatalyst_${arch}_${config} clean
        make -C out/maccatalyst_${arch}_${config} -j12 rive_cg_renderer
        popd
        cp -r $RIVE_RUNTIME_DIR/cg_renderer/out/maccatalyst_${arch}_${config}/librive_cg_renderer.a $DEV_SCRIPT_DIR/../dependencies/${config}/librive_cg_renderer_maccatalyst_${arch}.a
        cp -r $RIVE_RUNTIME_DIR/cg_renderer/include $DEV_SCRIPT_DIR/../dependencies/includes/cg_renderer

        # Build rive_pls_renderer.
        pushd $RIVE_PLS_DIR
        premake5 --config=${config} --out=out/maccatalyst_${arch}_${config} --arch=${arch} --scripts=$RIVE_RUNTIME_DIR/build --file=premake5_pls_renderer.lua --os=macosx --variant=maccatalyst gmake2
        make -C out/maccatalyst_${arch}_${config} clean
        make -C out/maccatalyst_${arch}_${config} -j12 rive_pls_renderer
        popd
        cp -r $RIVE_PLS_DIR/out/maccatalyst_${arch}_${config}/librive_pls_renderer.a $DEV_SCRIPT_DIR/../dependencies/${config}/librive_pls_renderer_maccatalyst_${arch}.a
        cp -r $RIVE_PLS_DIR/include $DEV_SCRIPT_DIR/../dependencies/includes/renderer

        # Build rive_decoders.
        pushd $RIVE_RUNTIME_DIR/decoders
        premake5 --file=premake5_v2.lua --config=${config} --out=out/maccatalyst_${arch}_${config} --arch=${arch} --scripts=$RIVE_RUNTIME_DIR/build --os=macosx --no_rive_jpeg --no_rive_png --no_rive_webp --variant=maccatalyst gmake2
        make -C out/maccatalyst_${arch}_${config} clean
        make -C out/maccatalyst_${arch}_${config} -j12 rive_decoders
        popd
        cp -r $RIVE_RUNTIME_DIR/decoders/out/maccatalyst_${arch}_${config}/librive_decoders.a $DEV_SCRIPT_DIR/../dependencies/${config}/librive_decoders_maccatalyst_${arch}.a
    }

    _create_universal_libraries() {
        local config=$1
        local deps_dir="$DEV_SCRIPT_DIR/../dependencies/${config}"

        # List of libraries to merge
        local libs=(
            "librive_harfbuzz_maccatalyst"
            "librive_yoga_maccatalyst"
            "librive_sheenbidi_maccatalyst"
            "libminiaudio_maccatalyst"
            "librive_maccatalyst"
            "librive_cg_renderer_maccatalyst"
            "librive_pls_renderer_maccatalyst"
            "librive_decoders_maccatalyst"
        )

        # Create universal binaries for each library
        for lib in "${libs[@]}"; do
            lipo -create \
                "${deps_dir}/${lib}_arm64.a" \
                "${deps_dir}/${lib}_x64.a" \
                -output "${deps_dir}/${lib}.a"
            
            # Clean up architecture-specific files
            rm "${deps_dir}/${lib}_arm64.a" "${deps_dir}/${lib}_x64.a"
        done
    }
    
    _build_runtime_maccatalyst "$1" "arm64"
    _build_runtime_maccatalyst "$1" "x64"
    _create_universal_libraries "$1"
}

usage() {
    echo "USAGE: $0 [--no-audio] <all|ios|ios_sim|xros|xrsimulator|appletvos|appletvsimulator|macosx|maccatalyst> <debug|release>"
    exit 1
}

if [ -z "$PLATFORM" ]; then
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
    build_runtime_maccatalyst $1
}

case $PLATFORM in
all)
    case $CONFIG in
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
    if [ -z "$CONFIG" ]; then
        usage
    fi
    case $CONFIG in
    release | debug)
        make_dependency_directories
        build_runtime_macosx $CONFIG
        ;;
    *)
        usage
        ;;
    esac
    ;;
ios)
    if [ -z "$CONFIG" ]; then
        usage
    fi
    case $CONFIG in
    release | debug)
        make_dependency_directories
        build_runtime $CONFIG
        ;;
    *)
        usage
        ;;
    esac
    ;;
ios_sim)
    if [ -z "$CONFIG" ]; then
        usage
    fi
    case $CONFIG in
    release | debug)
        make_dependency_directories
        build_runtime_sim $CONFIG
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
    if [ -z "$CONFIG" ]; then
        usage
    fi
    case $CONFIG in
    release | debug)
        make_dependency_directories
        build_runtime_xros $CONFIG
        ;;
    *)
        usage
        ;;
    esac
    ;;
xrsimulator)
    if [ -z "$CONFIG" ]; then
        usage
    fi
    case $CONFIG in
    release | debug)
        make_dependency_directories
        build_runtime_xrsimulator $CONFIG
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
    if [ -z "$CONFIG" ]; then
        usage
    fi
    case $CONFIG in
    release | debug)
        make_dependency_directories
        build_runtime_appletvos $CONFIG
        ;;
    *)
        usage
        ;;
    esac
    ;;
appletvsimulator)
    if [ -z "$CONFIG" ]; then
        usage
    fi
    case $CONFIG in
    release | debug)
        make_dependency_directories
        build_runtime_appletvsimulator $CONFIG
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
maccatalyst)
    if [ -z "$CONFIG" ]; then
        usage
    fi
    case $CONFIG in
    release | debug)
        make_dependency_directories
        build_runtime_maccatalyst $CONFIG
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
