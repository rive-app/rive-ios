#!/bin/bash

BASEDIR=$(pwd)

CLEAR='\033[0m'
RED='\033[0;31m'

function usage() {
  if [ -n "$1" ]; then
    echo -e "${RED}👉 $1${CLEAR}\n";
  fi
  echo "Usage: $0 [-c configuration]"
  echo "  -c, --configuration      Configuration (Debug / Release)"
  echo ""
  echo "Example: $0 --target iphoneos --configuration Debug"
  exit 1
}

# parse params
while [[ "$#" > 0 ]]; do case $1 in
  -c|--configuration) CONFIGURATION="$2";shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

echo -e "Merge Rive Frameworks"
xcodebuild \
  -create-xcframework \
  -framework "${BASEDIR}/archive/Build/Products/${CONFIGURATION}-iphoneos/RiveRuntime.framework" \
  -framework "${BASEDIR}/archive/Build/Products/${CONFIGURATION}-iphonesimulator/RiveRuntime.framework" \
  -output "${BASEDIR}/archive/RiveRuntime.xcframework" | xcpretty