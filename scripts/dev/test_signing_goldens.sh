#!/bin/bash
# Test iOS code signing locally for our Golden Tests app, simulating the CI environment.
#
# Usage:
#   ./test_signing_goldens.sh <path-to-p12> <p12-password> <path-to-mobileprovision>
#
# Example:
#   ./test_signing_goldens.sh ~/certs/Goldens.p12 "<p12-password>" ~/certs/Goldens.mobileprovision

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

P12_PATH="${1:?Usage: $0 <p12-path> <p12-password> <mobileprovision-path>}"
P12_PASSWORD="${2:?Usage: $0 <p12-path> <p12-password> <mobileprovision-path>}"
PP_PATH="${3:?Usage: $0 <p12-path> <p12-password> <mobileprovision-path>}"

KEYCHAIN_PATH="/tmp/test-signing-$$.keychain-db"
INSTALLED_PP=""
FAILED=0

# shellcheck disable=SC2329
cleanup() {
    echo ""
    echo "--- Cleaning up ---"
    if security list-keychains | grep -q "$KEYCHAIN_PATH"; then
        security delete-keychain "$KEYCHAIN_PATH" 2>/dev/null && echo "  Deleted test keychain." || true
    fi
    if [ -n "$INSTALLED_PP" ] && [ -f "$INSTALLED_PP" ]; then
        rm -f "$INSTALLED_PP" && echo "  Removed installed provisioning profile." || true
    fi
    # Restore default keychain search list
    security list-keychain -d user -s ~/Library/Keychains/login.keychain-db 2>/dev/null || true
    echo "--- Done ---"
}
trap cleanup EXIT

pass() { echo -e "  ${GREEN}PASS${NC}: $1"; }
fail() { echo -e "  ${RED}FAIL${NC}: $1"; FAILED=1; }
info() { echo -e "  ${YELLOW}INFO${NC}: $1"; }

echo "============================================"
echo " iOS Code Signing - Local Verification"
echo "============================================"

# --------------------------------------------------
echo ""
echo "1. Verifying p12 password..."
if openssl pkcs12 -in "$P12_PATH" -noout -passin pass:"$P12_PASSWORD" -legacy 2>/dev/null; then
    pass "p12 password is correct."
else
    fail "p12 password is WRONG."
fi

# --------------------------------------------------
echo ""
echo "2. Checking p12 contains both certificate and private key..."
P12_CONTENTS=$(openssl pkcs12 -in "$P12_PATH" -passin pass:"$P12_PASSWORD" -passout pass: -legacy 2>/dev/null || true)
if echo "$P12_CONTENTS" | grep -q "BEGIN CERTIFICATE"; then
    pass "p12 contains a certificate."
else
    fail "p12 does NOT contain a certificate. Re-export from Keychain Access."
fi
if echo "$P12_CONTENTS" | grep -q "PRIVATE KEY"; then
    pass "p12 contains a private key."
else
    fail "p12 does NOT contain a private key."
fi

# --------------------------------------------------
echo ""
echo "3. Checking certificate expiry..."
CERT_DATES=$(openssl pkcs12 -in "$P12_PATH" -clcerts -nokeys -passin pass:"$P12_PASSWORD" -passout pass: -legacy 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || true)
if [ -n "$CERT_DATES" ]; then
    NOT_AFTER=$(echo "$CERT_DATES" | grep notAfter | cut -d= -f2)
    info "Certificate expires: $NOT_AFTER"
    # Check if expired (date comparison)
    EXPIRY_EPOCH=$(date -jf "%b %d %T %Y %Z" "$NOT_AFTER" +%s 2>/dev/null || date -d "$NOT_AFTER" +%s 2>/dev/null || echo 0)
    NOW_EPOCH=$(date +%s)
    if [ "$EXPIRY_EPOCH" -gt "$NOW_EPOCH" ] 2>/dev/null; then
        pass "Certificate is not expired."
    else
        fail "Certificate appears to be EXPIRED."
    fi
else
    fail "Could not read certificate dates from p12."
fi

# --------------------------------------------------
echo ""
echo "4. Extracting fingerprints..."
P12_FINGERPRINT=$(openssl pkcs12 -in "$P12_PATH" -clcerts -nokeys -passin pass:"$P12_PASSWORD" -passout pass: -legacy 2>/dev/null | openssl x509 -fingerprint -noout 2>/dev/null || true)
if [ -n "$P12_FINGERPRINT" ]; then
    info "p12 certificate: $P12_FINGERPRINT"
else
    fail "Could not extract fingerprint from p12."
fi

PP_FINGERPRINT=$(security cms -D -i "$PP_PATH" 2>/dev/null | plutil -extract DeveloperCertificates.0 raw -o - - 2>/dev/null | base64 --decode 2>/dev/null | openssl x509 -inform DER -fingerprint -noout 2>/dev/null || true)
if [ -n "$PP_FINGERPRINT" ]; then
    info "Provisioning profile certificate: $PP_FINGERPRINT"
else
    fail "Could not extract fingerprint from provisioning profile."
fi

if [ -n "$P12_FINGERPRINT" ] && [ -n "$PP_FINGERPRINT" ]; then
    if [ "$P12_FINGERPRINT" = "$PP_FINGERPRINT" ]; then
        pass "Fingerprints MATCH. Certificate and provisioning profile are compatible."
    else
        fail "Fingerprints DO NOT MATCH. Certificate and provisioning profile are from different certs."
    fi
fi

# --------------------------------------------------
echo ""
echo "5. Checking provisioning profile expiry..."
PP_EXPIRY=$(security cms -D -i "$PP_PATH" 2>/dev/null | plutil -extract ExpirationDate raw -o - - 2>/dev/null || true)
if [ -n "$PP_EXPIRY" ]; then
    info "Provisioning profile expires: $PP_EXPIRY"
else
    fail "Could not read provisioning profile expiry."
fi

# --------------------------------------------------
echo ""
echo "6. Checking provisioning profile bundle ID..."
PP_APP_ID=$(security cms -D -i "$PP_PATH" 2>/dev/null | plutil -extract Entitlements.application-identifier raw -o - - 2>/dev/null || true)
if [ -n "$PP_APP_ID" ]; then
    info "App identifier: $PP_APP_ID"
    if echo "$PP_APP_ID" | grep -q "rive.app.golden-test-app"; then
        pass "Bundle ID matches golden_test_app."
    else
        fail "Bundle ID does NOT contain 'rive.app.golden-test-app'."
    fi
else
    fail "Could not extract app identifier from provisioning profile."
fi

# --------------------------------------------------
echo ""
echo "7. Setting up temporary keychain (simulating CI)..."
KEYCHAIN_PASSWORD="test-keychain-password"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

if security import "$P12_PATH" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH" 2>&1; then
    pass "p12 imported into keychain successfully."
else
    fail "p12 import into keychain FAILED."
fi

security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" >/dev/null 2>&1 || true
security list-keychain -d user -s "$KEYCHAIN_PATH"

echo ""
echo "   Signing identities in keychain:"
security find-identity -v -p codesigning "$KEYCHAIN_PATH" 2>/dev/null | sed 's/^/   /'

# --------------------------------------------------
echo ""
echo "8. Installing provisioning profile..."
UUID=$(grep UUID -A1 -a "$PP_PATH" | grep -io "[-A-F0-9]\{36\}" | head -1)
if [ -n "$UUID" ]; then
    info "Profile UUID: $UUID"
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    INSTALLED_PP="$HOME/Library/MobileDevice/Provisioning Profiles/$UUID.mobileprovision"
    cp "$PP_PATH" "$INSTALLED_PP"
    pass "Provisioning profile installed."
else
    fail "Could not extract UUID from provisioning profile."
fi

# --------------------------------------------------
echo ""
echo "9. Verifying xcodebuild resolves signing settings..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_IOS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

BUILD_SETTINGS=$(xcodebuild \
    -workspace "$RUNTIME_IOS_DIR/Rive.xcworkspace" \
    -scheme golden_test_app \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -showBuildSettings \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    2>/dev/null || true)

if [ -n "$BUILD_SETTINGS" ]; then
    echo "$BUILD_SETTINGS" | grep -E "^\s*(CODE_SIGN_IDENTITY|CODE_SIGN_STYLE|PROVISIONING_PROFILE)" | sed 's/^/   /'
    if echo "$BUILD_SETTINGS" | grep -q "CODE_SIGN_IDENTITY = Apple Distribution"; then
        pass "CODE_SIGN_IDENTITY resolved correctly."
    else
        fail "CODE_SIGN_IDENTITY did not resolve as expected."
    fi
    if echo "$BUILD_SETTINGS" | grep -q "CODE_SIGN_STYLE = Manual"; then
        pass "CODE_SIGN_STYLE resolved correctly."
    else
        fail "CODE_SIGN_STYLE did not resolve as expected."
    fi
else
    fail "xcodebuild -showBuildSettings failed (this may be a local Xcode/SDK version issue — CI may still work)."
fi

# --------------------------------------------------
echo ""
echo "10. Build native dependencies + archive (full CI build)..."
if [ "$FAILED" -ne 0 ]; then
    echo -e "  ${YELLOW}SKIPPING${NC}: Previous checks failed. Fix those first."
else
    REPO_ROOT="$(cd "$RUNTIME_IOS_DIR/../.." && pwd)"

    # Add build scripts to PATH (same as CI "Add rive_build.sh to PATH" step)
    export PATH="$PATH:$REPO_ROOT/packages/runtime/build"

    # Check prerequisites
    MISSING_PREREQS=0
    if ! command -v premake5 &>/dev/null; then
        fail "premake5 not found. Install with: brew install premake"
        MISSING_PREREQS=1
    fi
    if ! command -v build_rive.sh &>/dev/null; then
        fail "build_rive.sh not found on PATH. Check that packages/runtime/build exists."
        MISSING_PREREQS=1
    fi

    if [ "$MISSING_PREREQS" -eq 0 ]; then
        # Determine which platform to build for.
        # Try device (ios) first — matches CI exactly.
        # Fall back to simulator (ios_sim) if the iOS device platform isn't installed.
        BUILD_PLATFORM="ios"

        # Check if the iOS device platform is available
        if ! xcodebuild -showsdks 2>/dev/null | grep -q "iphoneos"; then
            info "iOS device SDK not found. Building for simulator instead."
            BUILD_PLATFORM="ios_sim"
        fi

        # Step 10a: Build native runtime
        echo ""
        info "Building native rive runtime for $BUILD_PLATFORM (this may take several minutes)..."
        if "$RUNTIME_IOS_DIR/scripts/build.sh" "$BUILD_PLATFORM" release 2>&1 | tail -5; then
            pass "Native runtime built for $BUILD_PLATFORM."
        else
            fail "Native runtime build failed for $BUILD_PLATFORM."
        fi

        # Step 10b: Archive / build the golden test app
        if [ "$FAILED" -eq 0 ]; then
            echo ""
            ARCHIVE_PATH="/tmp/test-golden-archive-$$"
            BUILD_LOG="/tmp/golden-xcodebuild-$$.log"
            info "Building golden_test_app ($XCODE_ACTION for $BUILD_PLATFORM)..."
            info "Full build log: $BUILD_LOG"

            # Temporarily disable errexit so we can capture the exit code
            set +e
            if [ "$BUILD_PLATFORM" = "ios" ]; then
                xcodebuild \
                    -workspace "$RUNTIME_IOS_DIR/Rive.xcworkspace" \
                    -scheme golden_test_app \
                    archive -archivePath "$ARCHIVE_PATH/Actions" \
                    -configuration Release \
                    -destination "generic/platform=iOS" \
                    CODE_SIGN_STYLE=Manual \
                    CODE_SIGN_IDENTITY="Apple Distribution" \
                    BUILD_LIBRARY_FOR_DISTRIBUTION=NO \
                    2>&1 | tee "$BUILD_LOG"
                BUILD_EXIT=${PIPESTATUS[0]}
            else
                xcodebuild \
                    -workspace "$RUNTIME_IOS_DIR/Rive.xcworkspace" \
                    -scheme golden_test_app \
                    build \
                    -configuration Release \
                    -destination "generic/platform=iOS Simulator" \
                    CODE_SIGN_IDENTITY=- \
                    BUILD_LIBRARY_FOR_DISTRIBUTION=NO \
                    2>&1 | tee "$BUILD_LOG"
                BUILD_EXIT=${PIPESTATUS[0]}
            fi
            set -e

            if [ "$BUILD_EXIT" -eq 0 ]; then
                if [ "$BUILD_PLATFORM" = "ios" ]; then
                    pass "Full device archive succeeded (same as CI)."
                else
                    pass "Simulator build succeeded. Compilation is valid."
                    info "Note: full device archive + signing can only be tested on CI or a Mac with the iOS device platform installed."
                fi
            else
                echo ""
                echo "============================================"
                echo " Build errors:"
                echo "============================================"
                grep -i "error:" "$BUILD_LOG" | grep -v "^$" | head -30 || true
                echo "============================================"
                if [ "$BUILD_PLATFORM" = "ios" ]; then
                    fail "Device archive build FAILED. Full log: $BUILD_LOG"
                else
                    fail "Simulator build FAILED. Full log: $BUILD_LOG"
                fi
            fi
            rm -rf "$ARCHIVE_PATH"
        fi
    fi
fi

# --------------------------------------------------
echo ""
echo "============================================"
if [ "$FAILED" -eq 0 ]; then
    echo -e " ${GREEN}ALL CHECKS PASSED${NC}"
else
    echo -e " ${RED}SOME CHECKS FAILED${NC} — review output above."
fi
echo "============================================"

exit $FAILED
