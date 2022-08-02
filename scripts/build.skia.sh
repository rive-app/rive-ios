#!/bin/bash
set -ex

ARCH_X86=x86
ARCH_X64=x64
ARCH_ARM=arm
ARCH_ARM64=arm64
ARCH_SIM_ARM64=iossim_arm64

usage() {
    printf "Usage: %s -a arch\n" "$0"
    printf "\t-a Specify an architecture (i.e. '%s', '%s', '%s', '%s', '%s')\n" $ARCH_X86 $ARCH_X64 $ARCH_ARM $ARCH_ARM64 $ARCH_SIM_ARM64
    exit 1 # Exit script after printing help
}

while getopts "a:cd" opt; do
    case "$opt" in
    a) ARCH_NAME="$OPTARG" ;;
    \?) usage ;; # Print usage in case parameter is non-existent
    esac
done

if [ -z "$ARCH_NAME" ]; then
    echo "No architecture specified"
    usage
fi

path=`readlink -f "${BASH_SOURCE:-$0}"`
DEV_SCRIPT_DIR=`dirname $path`

export SKIA_REPO="https://github.com/rive-app/skia"
export SKIA_BRANCH="rive"
export COMPILE_TARGET="ios_$EXPECTED_NDK_VERSION_$ARCH_NAME"
export CACHE_NAME="rive_skia_ios"
export MAKE_SKIA_FILE="make_skia_ios.sh"
export SKIA_DIR_NAME="skia"
# we can have multiple at the same time...
export ARCHIVE_CONTENTS_NAME="archive_contents_$ARCH_NAME"

if [ -d "$DEV_SCRIPT_DIR/../submodules/rive-cpp" ];
then
    export RIVE_RUNTIME_DIR="$DEV_SCRIPT_DIR/../submodules/rive-cpp"
else
    export RIVE_RUNTIME_DIR="$DEV_SCRIPT_DIR/../../runtime" 
fi

# Build skia
pushd "$RIVE_RUNTIME_DIR"/skia/dependencies
./make_skia_ios.sh $ARCH_NAME
popd