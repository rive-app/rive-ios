#!/bin/bash
set -e

path=`readlink -f "${BASH_SOURCE:-$0}"`
DEV_SCRIPT_DIR=`dirname $path`

# hmm this'll be problematic, our caches overwrite each other, not a problem for the remotes
$DEV_SCRIPT_DIR/build.skia.sh -a x86 
$DEV_SCRIPT_DIR/build.skia.sh -a x86 
$DEV_SCRIPT_DIR/build.skia.sh -a x64
$DEV_SCRIPT_DIR/build.skia.sh -a arm
$DEV_SCRIPT_DIR/build.skia.sh -a arm64
$DEV_SCRIPT_DIR/build.skia.sh -a iossim_arm64

$DEV_SCRIPT_DIR/build.rive.sh $@