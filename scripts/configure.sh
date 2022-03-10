#!/bin/bash
set -e

# https://stackoverflow.com/questions/3878624/how-do-i-programmatically-determine-if-there-are-uncommitted-changes
require_clean_work_tree () {
    # Update the index
    git update-index -q --ignore-submodules --refresh
    err=0

    # Disallow unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules --
    then
        echo >&2 "cannot $1: you have unstaged changes."
        git diff-files --name-status -r --ignore-submodules -- >&2
        err=1
    fi

    # Disallow uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules --
    then
        echo >&2 "cannot $1: your index contains uncommitted changes."
        git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
        err=1
    fi

    if [ $err = 1 ]
    then
        echo >&2 "Please commit or stash them."
        echo "FALSE"
    else 
        echo "TRUE"
    fi

}

# get rive-cpp commit hash, as key for pre built archives.
pushd submodules/rive-cpp
RIVE_CPP_CLEAN="$(require_clean_work_tree "get dependencies for $COMMIT_HASH")"
COMMIT_HASH=$(git rev-parse HEAD)
popd

COMMIT_HASH_FILE=dependencies/rive-cpp-commit-hash
CACHED_COMMIT_HASH=$(cat $COMMIT_HASH_FILE) || true 
TAR_FILE_NAME="i386_x86_64_arm64_armv7.tar.gz"
KEY="$COMMIT_HASH/$TAR_FILE_NAME"
ARCHIVE_URL="https://cdn.2dimensions.com/archives/$KEY"

mkdir -p dependencies
mkdir -p cache

build() {
    ./scripts/build_dependencies.sh
}

cached_build() {
    echo "Running cached build, checking $ARCHIVE_URL"
    if curl --output /dev/null --head --silent --fail $ARCHIVE_URL
        then
            echo "$ARCHIVE_URL exists, downloading..."
            curl --output cache/$TAR_FILE_NAME $ARCHIVE_URL 
            rm -rf dependencies/* 
            tar -xf cache/$TAR_FILE_NAME -C dependencies/
        else
            echo "$ARCHIVE_URL does not exist, building locally..."
            
            build

            echo $COMMIT_HASH > $COMMIT_HASH_FILE
            
            # cd into dependencies and add everything to the archive cache/i386_x86_64_arm64_armv7.tar.gz
            tar -C dependencies -cf cache/$TAR_FILE_NAME .

            # if we're configured to upload the archive back into our cache, lets do it! 
            if [ "$RIVE_UPLOAD_IOS_ARCHIVE" == "TRUE" ]
                then
                    echo "Configured to upload caches, uploading!"
                    aws s3 cp cache/$TAR_FILE_NAME s3://2d-public/archives/$KEY
            fi 
    fi
}

update_dependencies () {
    if [ "$RIVE_CPP_CLEAN" == "TRUE" ]
        then
            cached_build 
        else 
            echo "Rive-cpp has changes, cannot use cached builds"
            build
    fi 
}

check_dependencies () {
    if [ "$COMMIT_HASH" == "$CACHED_COMMIT_HASH" ] && [ "$RIVE_CPP_CLEAN" == "TRUE" ]
    then 
        echo "Cache is up to date & rive_cpp is clean. no need to do anything"
    else  
        update_dependencies
    fi
}

check_dependencies


