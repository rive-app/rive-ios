#!/bin/bash

CLEAR='\033[0m'
RED='\033[0;31m'

function usage() {
  if [ -n "$1" ]; then
    echo -e "${RED}👉 $1${CLEAR}\n";
  fi
  echo "Usage: $0 [-t target] [-c configuration]"
  echo "  -t, --target              Target (iphoneos / iphonesimulator)"
  echo "  -c, --configuration      Configuration (Debug / Release)"
  echo ""
  echo "Example: $0 --target iphoneos --configuration Debug"
  exit 1
}

# parse params
while [[ "$#" > 0 ]]; do case $1 in
  -t|--target) TARGET="$2"; shift;shift;;
  -c|--configuration) CONFIGURATION="$2";shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

# verify params
if [ -z "$TARGET" ]; then usage "Target is not set"; fi;
if [ -z "$CONFIGURATION" ]; then usage "Configuration is not set."; fi;

echo -e "Build Rive Framework"
echo -e "Configuration -> ${CONFIGURATION}, target -> ${TARGET}"

xcodebuild -project RiveRuntime.xcodeproj -scheme RiveRuntime -sdk ${TARGET} -derivedDataPath archive -configuration ${CONFIGURATION} | xcpretty