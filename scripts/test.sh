set -eo pipefail

test_ios_simulator() {
    echo "=== Running tests on iOS Simulator ==="
    # Test RiveRuntime on a iOS simulator
    xcodebuild -workspace Rive.xcworkspace \
        -scheme RiveRuntime \
        -destination platform=iOS\ Simulator,name=iPhone\ 16 \
        clean test | xcpretty
}

test_visionos_simulator() {
    echo "=== Running tests on visionOS Simulator ==="
    # Test RiveRuntime on a visionOS simulator
    xcodebuild -workspace Rive.xcworkspace \
        -scheme RiveRuntime \
        -destination platform=visionOS\ Simulator,name=Apple\ Vision\ Pro \
        clean test | xcpretty
}

test_tvos_simulator() {
    echo "=== Running tests on tvOS Simulator ==="
    # Test RiveRuntime on a tvOS simulator
    xcodebuild -workspace Rive.xcworkspace \
        -scheme RiveRuntime \
        -destination platform=tvOS\ Simulator,name=Apple\ TV\ 4K\ \(3rd\ generation\) \
        clean test | xcpretty
}

test_maccatalyst() {
    echo "=== Running tests on Mac Catalyst ==="
    # Test RiveRuntime on Mac Catalyst
    xcodebuild -workspace Rive.xcworkspace \
        -scheme "RiveRuntime (Catalyst)" \
        -destination "platform=macOS,variant=Mac Catalyst" \
        clean test | xcpretty
}

usage() {
    echo "USAGE: $0 ios_sim|xrsimulator|appletvsimulator|maccatalyst"
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

case $1 in
ios_sim)
    test_ios_simulator
    ;;
xrsimulator)
    test_visionos_simulator
    ;;
appletvsimulator)
    test_tvos_simulator
    ;;
maccatalyst)
    test_maccatalyst
    ;;
*)
    usage
    ;;
esac
