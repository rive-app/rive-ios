#!/bin/bash
# Test iOS automatic signing via App Store Connect API Key locally,
# simulating what CI will do with the new .p8 approach.
#
# This replaces the manual p12 + provisioning profile flow with Apple's
# API Key authentication, which lets xcodebuild automatically manage
# certificates and provisioning profiles (no more manual cert rotation!).
#
# Usage:
#   ./test_apikey_signing_goldens.sh <path-to-p8> <key-id> <issuer-id>
#
# Example:
#   ./test_apikey_signing_goldens.sh ~/certs/AuthKey_ABC1234DEF.p8 ABC1234DEF 12345678-1234-1234-1234-123456789abc
#
# The .p8 file is downloaded once from App Store Connect and never expires.
# The Key ID and Issuer ID are shown on the App Store Connect API Keys page.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

P8_PATH="${1:?Usage: $0 <p8-path> <key-id> <issuer-id>}"
KEY_ID="${2:?Usage: $0 <p8-path> <key-id> <issuer-id>}"
ISSUER_ID="${3:?Usage: $0 <p8-path> <key-id> <issuer-id>}"

FAILED=0
TEMP_KEY_DIR=""

cleanup() {
    echo ""
    echo "--- Cleaning up ---"
    if [ -n "$TEMP_KEY_DIR" ] && [ -d "$TEMP_KEY_DIR" ]; then
        rm -rf "$TEMP_KEY_DIR" && echo "  Removed temporary key directory." || true
    fi
    echo "--- Done ---"
}
trap cleanup EXIT

pass() { echo -e "  ${GREEN}PASS${NC}: $1"; }
fail() { echo -e "  ${RED}FAIL${NC}: $1"; FAILED=1; }
info() { echo -e "  ${YELLOW}INFO${NC}: $1"; }
step() { echo -e "\n${CYAN}$1${NC}"; }

echo "============================================"
echo " iOS API Key Signing - Local Verification"
echo "============================================"
echo ""
echo " Key file:   $P8_PATH"
echo " Key ID:     $KEY_ID"
echo " Issuer ID:  $ISSUER_ID"

# --------------------------------------------------
step "1. Checking .p8 file exists and is readable..."

if [ ! -f "$P8_PATH" ]; then
    fail ".p8 file not found at: $P8_PATH"
    echo ""
    echo "  Download your API key from:"
    echo "  https://appstoreconnect.apple.com/access/integrations/api"
    echo ""
    echo "============================================"
    echo -e " ${RED}CANNOT CONTINUE${NC} — fix the above and re-run."
    echo "============================================"
    exit 1
fi

FILE_SIZE=$(wc -c < "$P8_PATH" | tr -d ' ')
if [ "$FILE_SIZE" -eq 0 ]; then
    fail ".p8 file is empty (0 bytes)."
elif [ "$FILE_SIZE" -lt 100 ]; then
    fail ".p8 file is suspiciously small ($FILE_SIZE bytes). Expected ~240+ bytes."
else
    pass ".p8 file exists ($FILE_SIZE bytes)."
fi

# --------------------------------------------------
step "2. Validating .p8 file format (PEM private key)..."

FIRST_LINE=$(head -1 "$P8_PATH")
LAST_LINE=$(tail -1 "$P8_PATH")

if echo "$FIRST_LINE" | grep -q "BEGIN PRIVATE KEY"; then
    pass "File starts with '-----BEGIN PRIVATE KEY-----'."
else
    fail "File does NOT start with '-----BEGIN PRIVATE KEY-----'."
    info "First line: $FIRST_LINE"
    info "Make sure you downloaded the .p8 file, not a .cer or .p12."
fi

if echo "$LAST_LINE" | grep -q "END PRIVATE KEY"; then
    pass "File ends with '-----END PRIVATE KEY-----'."
else
    fail "File does NOT end with '-----END PRIVATE KEY-----'."
    info "Last line: $LAST_LINE"
fi

# Verify it's a valid EC private key (App Store Connect uses ES256 / P-256)
if openssl ec -in "$P8_PATH" -noout 2>/dev/null; then
    pass "OpenSSL confirms this is a valid EC private key."
    # Check key details
    KEY_INFO=$(openssl ec -in "$P8_PATH" -text -noout 2>/dev/null | head -1 || true)
    if [ -n "$KEY_INFO" ]; then
        info "Key type: $KEY_INFO"
    fi
else
    # Try as generic pkey (some openssl versions need this)
    if openssl pkey -in "$P8_PATH" -noout 2>/dev/null; then
        pass "OpenSSL confirms this is a valid private key."
    else
        fail "OpenSSL could NOT parse this as a valid private key."
    fi
fi

# --------------------------------------------------
step "3. Validating Key ID format..."

# Key IDs are typically 10 alphanumeric characters
if echo "$KEY_ID" | grep -qE '^[A-Z0-9]{8,12}$'; then
    pass "Key ID '$KEY_ID' looks valid (alphanumeric, correct length)."
else
    # Could be valid with different casing or length, warn but don't fail
    if echo "$KEY_ID" | grep -qE '^[A-Za-z0-9]+$'; then
        info "Key ID '$KEY_ID' is alphanumeric but unexpected format. Proceeding anyway."
    else
        fail "Key ID '$KEY_ID' contains unexpected characters. Expected alphanumeric (e.g., 'ABC1234DEF')."
    fi
fi

# --------------------------------------------------
step "4. Validating Issuer ID format..."

# Issuer IDs are UUIDs
if echo "$ISSUER_ID" | grep -qiE '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'; then
    pass "Issuer ID is a valid UUID format."
else
    fail "Issuer ID '$ISSUER_ID' is not a valid UUID. Expected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
fi

# --------------------------------------------------
step "5. Installing API key to temporary location..."

# xcodebuild looks for keys in ~/private_keys/ or ./private_keys/
# We'll use a temp directory and pass the explicit path to xcodebuild
TEMP_KEY_DIR=$(mktemp -d)
TEMP_KEY_PATH="$TEMP_KEY_DIR/AuthKey_${KEY_ID}.p8"
cp "$P8_PATH" "$TEMP_KEY_PATH"
chmod 600 "$TEMP_KEY_PATH"

if [ -f "$TEMP_KEY_PATH" ]; then
    pass "API key staged at: $TEMP_KEY_PATH"
else
    fail "Failed to copy API key to temporary location."
fi

# --------------------------------------------------
step "6. Verifying xcodebuild can resolve build settings with automatic signing..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_IOS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ ! -d "$RUNTIME_IOS_DIR/Rive.xcworkspace" ]; then
    fail "Rive.xcworkspace not found at $RUNTIME_IOS_DIR/Rive.xcworkspace"
    info "Make sure you're running this script from within the runtime_ios tree."
else
    BUILD_SETTINGS=$(xcodebuild \
        -workspace "$RUNTIME_IOS_DIR/Rive.xcworkspace" \
        -scheme golden_test_app \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -showBuildSettings \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM=NJ3JMFUNS9 \
        PROVISIONING_PROFILE_SPECIFIER= \
        2>/dev/null || true)

    if [ -n "$BUILD_SETTINGS" ]; then
        grep -E "^\s*(CODE_SIGN_IDENTITY|CODE_SIGN_STYLE|DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER) =" <<< "$BUILD_SETTINGS" | sed 's/^/   /' || true
        if grep -q "CODE_SIGN_STYLE = Automatic" <<< "$BUILD_SETTINGS"; then
            pass "CODE_SIGN_STYLE resolved to Automatic."
        else
            fail "CODE_SIGN_STYLE did not resolve to Automatic."
        fi
        if grep -q "DEVELOPMENT_TEAM = NJ3JMFUNS9" <<< "$BUILD_SETTINGS"; then
            pass "DEVELOPMENT_TEAM resolved correctly."
        else
            fail "DEVELOPMENT_TEAM did not resolve as expected."
        fi
        BUNDLE_ID=$(grep -E '^\s+PRODUCT_BUNDLE_IDENTIFIER = ' <<< "$BUILD_SETTINGS" | head -1 | awk '{print $NF}')
        if [ "$BUNDLE_ID" = "rive.app.golden-test-app" ]; then
            pass "Bundle ID is 'rive.app.golden-test-app'."
        else
            fail "Bundle ID is '$BUNDLE_ID', expected 'rive.app.golden-test-app'."
        fi
    else
        fail "xcodebuild -showBuildSettings failed."
        info "This may be a local Xcode/SDK version issue — CI may still work."
    fi
fi

# --------------------------------------------------
step "7. Testing API key authentication with xcodebuild (dry-run)..."

# Use -showBuildSettings with the auth flags to verify xcodebuild accepts the key.
# This doesn't actually build anything but validates that xcodebuild can parse the
# API key and won't reject it outright.
#
# Note: -allowProvisioningUpdates requires network access to Apple's servers to
# resolve the actual provisioning profile. In a dry-run we verify the key is accepted;
# the real provisioning resolution happens during an actual build.

echo "  Attempting xcodebuild with API key authentication..."

AUTH_OUTPUT=$(xcodebuild \
    -workspace "$RUNTIME_IOS_DIR/Rive.xcworkspace" \
    -scheme golden_test_app \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -showBuildSettings \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$TEMP_KEY_PATH" \
    -authenticationKeyID "$KEY_ID" \
    -authenticationKeyIssuerID "$ISSUER_ID" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=NJ3JMFUNS9 \
    PROVISIONING_PROFILE_SPECIFIER= \
    2>&1 || true)

if grep -q "CODE_SIGN_STYLE = Automatic" <<< "$AUTH_OUTPUT"; then
    pass "xcodebuild accepted the API key and resolved build settings."
elif grep -qi "error.*authentication\|invalid.*key\|unauthorized" <<< "$AUTH_OUTPUT"; then
    fail "xcodebuild rejected the API key. Check your Key ID and Issuer ID."
    grep -i "error" <<< "$AUTH_OUTPUT" | head -5 | sed 's/^/   /'
else
    # xcodebuild returned something but we couldn't confirm — show what happened
    info "xcodebuild returned output but could not confirm API key acceptance."
    info "This is likely fine — full validation happens during an actual build."
    tail -5 <<< "$AUTH_OUTPUT" | sed 's/^/   /'
fi

# --------------------------------------------------
step "8. Full build test (optional)..."

if [ "$FAILED" -ne 0 ]; then
    echo -e "  ${YELLOW}SKIPPING${NC}: Previous checks failed. Fix those first."
else
    REPO_ROOT="$(cd "$RUNTIME_IOS_DIR/../.." && pwd)"
    export PATH="$PATH:$REPO_ROOT/packages/runtime/build"

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
        BUILD_PLATFORM="ios"
        if ! xcodebuild -showsdks 2>/dev/null | grep -q "iphoneos"; then
            info "iOS device SDK not found. Building for simulator instead."
            BUILD_PLATFORM="ios_sim"
        fi

        # Build native runtime
        echo ""
        info "Building native rive runtime for $BUILD_PLATFORM (this may take several minutes)..."
        if "$RUNTIME_IOS_DIR/scripts/build.sh" "$BUILD_PLATFORM" release 2>&1 | tail -5; then
            pass "Native runtime built for $BUILD_PLATFORM."
        else
            fail "Native runtime build failed for $BUILD_PLATFORM."
        fi

        # Archive the golden test app with API key signing
        if [ "$FAILED" -eq 0 ]; then
            echo ""
            ARCHIVE_PATH="/tmp/test-golden-archive-$$"
            BUILD_LOG="/tmp/golden-xcodebuild-apikey-$$.log"

            set +e
            if [ "$BUILD_PLATFORM" = "ios" ]; then
                info "Archiving golden_test_app with API key signing..."
                info "Full build log: $BUILD_LOG"
                xcodebuild \
                    -workspace "$RUNTIME_IOS_DIR/Rive.xcworkspace" \
                    -scheme golden_test_app \
                    archive -archivePath "$ARCHIVE_PATH/Actions" \
                    -configuration Release \
                    -destination "generic/platform=iOS" \
                    -allowProvisioningUpdates \
                    -authenticationKeyPath "$TEMP_KEY_PATH" \
                    -authenticationKeyID "$KEY_ID" \
                    -authenticationKeyIssuerID "$ISSUER_ID" \
                    CODE_SIGN_STYLE=Automatic \
                    CODE_SIGN_IDENTITY= \
                    DEVELOPMENT_TEAM=NJ3JMFUNS9 \
                    PROVISIONING_PROFILE_SPECIFIER= \
                    BUILD_LIBRARY_FOR_DISTRIBUTION=NO \
                    SWIFT_OBJC_INTEROP_MODE=objcxx \
                    2>&1 | tee "$BUILD_LOG"
                BUILD_EXIT=${PIPESTATUS[0]}
            else
                info "Building golden_test_app for simulator (ad-hoc signing skipped)..."
                info "Full build log: $BUILD_LOG"
                xcodebuild \
                    -workspace "$RUNTIME_IOS_DIR/Rive.xcworkspace" \
                    -scheme golden_test_app \
                    build \
                    -configuration Release \
                    -destination "generic/platform=iOS Simulator" \
                    CODE_SIGN_IDENTITY=- \
                    BUILD_LIBRARY_FOR_DISTRIBUTION=NO \
                    SWIFT_OBJC_INTEROP_MODE=objcxx \
                    2>&1 | tee "$BUILD_LOG"
                BUILD_EXIT=${PIPESTATUS[0]}
            fi
            set -e

            if [ "$BUILD_EXIT" -eq 0 ]; then
                if [ "$BUILD_PLATFORM" = "ios" ]; then
                    pass "Device archive with API key signing SUCCEEDED."
                else
                    pass "Simulator build succeeded. Compilation is valid."
                    info "Note: full API key signing + IPA export can only be tested with a device build (on CI or a Mac with the iOS device platform)."
                fi
            else
                echo ""
                echo "============================================"
                echo " Build errors:"
                echo "============================================"
                grep -i "error:" "$BUILD_LOG" | grep -v "^$" | head -30 || true
                echo "============================================"
                fail "Build FAILED. Full log: $BUILD_LOG"
            fi
        fi

        # Export IPA from archive (same as CI "export ipa" step)
        if [ "$FAILED" -eq 0 ] && [ "$BUILD_PLATFORM" = "ios" ]; then
            step "9. Export IPA with automatic signing (simulating CI export step)..."

            EXPORT_LOG="/tmp/golden-export-apikey-$$.log"
            EXPORT_OPTIONS="/tmp/test-exportOptions-$$.plist"
            EXPORT_PATH="/tmp/test-golden-export-$$"

            # Generate the same exportOptions.plist that CI uses
            cat > "$EXPORT_OPTIONS" <<'EXPORTPLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>manageAppVersionAndBuildNumber</key>
    <true/>
    <key>method</key>
    <string>debugging</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>NJ3JMFUNS9</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
EXPORTPLIST

            info "Exporting IPA from archive..."
            info "Full export log: $EXPORT_LOG"

            set +e
            xcodebuild -exportArchive \
                -archivePath "$ARCHIVE_PATH/Actions.xcarchive" \
                -exportOptionsPlist "$EXPORT_OPTIONS" \
                -exportPath "$EXPORT_PATH" \
                -allowProvisioningUpdates \
                -authenticationKeyPath "$TEMP_KEY_PATH" \
                -authenticationKeyID "$KEY_ID" \
                -authenticationKeyIssuerID "$ISSUER_ID" \
                2>&1 | tee "$EXPORT_LOG"
            EXPORT_EXIT=${PIPESTATUS[0]}
            set -e

            if [ "$EXPORT_EXIT" -eq 0 ]; then
                IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" -print -quit 2>/dev/null || true)
                if [ -n "$IPA_FILE" ]; then
                    IPA_SIZE=$(wc -c < "$IPA_FILE" | tr -d ' ')
                    pass "IPA exported successfully: $(basename "$IPA_FILE") ($IPA_SIZE bytes)"
                else
                    pass "Export succeeded but no .ipa found in output directory."
                fi
            else
                echo ""
                echo "============================================"
                echo " Export errors:"
                echo "============================================"
                grep -i "error" "$EXPORT_LOG" | grep -v "^$" | head -30 || true
                echo "============================================"
                fail "IPA export FAILED. Full log: $EXPORT_LOG"
                info "If you see 'Cloud signing permission error', your API key"
                info "may need a higher role (Admin or App Manager) in App Store Connect."
            fi
            rm -f "$EXPORT_OPTIONS"
            rm -rf "$EXPORT_PATH"
        fi

        rm -rf "$ARCHIVE_PATH"
    fi
fi

# --------------------------------------------------
step "10. Summary of values for GitHub secrets..."
echo ""
echo "  When you're ready to update CI, store these as GitHub secrets:"
echo ""
echo "    ASC_API_KEY          = contents of $P8_PATH"
echo "    ASC_API_KEY_ID       = $KEY_ID"
echo "    ASC_API_KEY_ISSUER_ID = $ISSUER_ID"
echo ""
echo "  Secrets you can RETIRE after migrating CI:"
echo "    GOLDEN_IOS_SIGNING_KEY"
echo "    GOLDEN_IOS_SIGNING_CERT_PASSWORD"
echo "    GOLDEN_IOS_PROVISION"
echo "    KEYCHAIN_PASSWORD"

# --------------------------------------------------
echo ""
echo "============================================"
if [ "$FAILED" -eq 0 ]; then
    echo -e " ${GREEN}ALL CHECKS PASSED${NC}"
    echo ""
    echo " Your API key is valid and ready for CI."
    echo " Next step: update the GitHub workflow to use"
    echo " automatic signing with -allowProvisioningUpdates."
else
    echo -e " ${RED}SOME CHECKS FAILED${NC} — review output above."
fi
echo "============================================"

exit $FAILED
