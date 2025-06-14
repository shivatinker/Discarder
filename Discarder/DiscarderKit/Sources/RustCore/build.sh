#!/usr/bin/env bash
set -euxo pipefail

# Check if --release flag is provided
RELEASE_MODE=false
BUILD_DIR="debug"

for arg in "$@"; do
    case $arg in
        --release)
            RELEASE_MODE=true
            BUILD_DIR="release"
            shift
            ;;
        *)
            ;;
    esac
done

# Build with appropriate flags
if [ "$RELEASE_MODE" = true ]; then
    cargo build --release
else
    cargo build
fi

cbindgen --config cbindgen.toml --output include/rust_core.h

rm -rf RustCore.xcframework

xcodebuild -create-xcframework \
           -library target/${BUILD_DIR}/librust_core.a \
           -headers include \
           -output RustCore.xcframework

