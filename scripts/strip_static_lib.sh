#!/bin/bash
# usage: strip_static_lib.sh file.a
# Borrowed from:
# https://stackoverflow.com/questions/49630984/strip-remove-debug-symbols-and-archive-names-from-a-static-library
set -e

if [ -z "$1" ]; then
    echo "usage: strip_static_lib.sh file.a"
    exit 1
fi

path=$(readlink -f "${BASH_SOURCE:-$0}")
SCRIPT_DIR=$(dirname $path)
TMP_DIR="$SCRIPT_DIR/strip_static_lib_tmp"

if [ -d $TMP_DIR ]; then
    rm -rf $TMP_DIR
fi

BASENAME=${1##*/}
LIB=$(realpath $1)

mkdir $TMP_DIR
cp $LIB $TMP_DIR
pushd $TMP_DIR

ar xv $BASENAME
rm -f $BASENAME
i=1000
for p in *.o ; do
    strip -Sx $p -o ${i}.o
    rm $p
    ((i++))
done

ar crus $BASENAME *.o
mv $BASENAME $LIB

popd
rm -rf $TMP_DIR
exit 0
