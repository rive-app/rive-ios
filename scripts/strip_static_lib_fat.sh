#!/bin/bash
set -e

path=$(readlink -f "${BASH_SOURCE:-$0}")
SCRIPT_DIR=$(dirname $path)
TMP_DIR="$SCRIPT_DIR/strip_static_lib_fat_tmp"

BASENAME=${1##*/}
LIB=$(realpath $1)
shift

if [ -d $TMP_DIR ]; then
    rm -rf $TMP_DIR
fi

mkdir $TMP_DIR
cp $LIB $TMP_DIR
pushd $TMP_DIR

# Extract and strip each architecture.
for ARCH in "$@"
do
    lipo $BASENAME -thin $ARCH -output ${BASENAME}_${ARCH}.a
    $SCRIPT_DIR/strip_static_lib.sh ${BASENAME}_${ARCH}.a
done

# Repack the stripped libs.
lipo -create ${BASENAME}_*.a -output $LIB

popd
rm -rf $TMP_DIR
exit 0
