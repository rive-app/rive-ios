set -eo pipefail

# test RiveRuntime on a simulator
xcodebuild -workspace Rive.xcworkspace \
    -scheme RiveRuntime \
    -destination platform=iOS\ Simulator,name=iPhone\ 15 \
    clean test | xcpretty
