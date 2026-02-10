set -eo pipefail

test_ios_simulator() {
    echo "=== Running tests on iOS Simulator ==="
    # xcodebuild test requires a concrete device (generic "Any iOS Simulator" is not allowed).
    # Discover the first available iOS Simulator for this workspace/scheme.
    echo "Discovering available iOS Simulator destination..."
    DEST=$(xcodebuild -showdestinations -workspace Rive.xcworkspace -scheme RiveRuntime 2>/dev/null | \
        grep "platform:iOS Simulator" | grep -v "placeholder" | grep "id:" | head -1)
    echo "Matched destination line: ${DEST:-(none)}"
    DEST_ID=$(echo "$DEST" | sed 's/.*id: *\([^,}]*\).*/\1/' | tr -d ' ')
    if [[ -z "$DEST_ID" ]]; then
        echo "No iOS Simulator destination found (could not parse id). Available iOS Simulator destinations:"
        xcodebuild -showdestinations -workspace Rive.xcworkspace -scheme RiveRuntime 2>/dev/null | grep "platform:iOS Simulator" || true
        exit 1
    fi
    echo "Using iOS Simulator destination id: $DEST_ID"
    xcodebuild -workspace Rive.xcworkspace \
        -scheme RiveRuntime \
        -destination "id=$DEST_ID" \
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
