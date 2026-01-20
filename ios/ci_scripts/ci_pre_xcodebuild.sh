#!/bin/sh

# Xcode Cloud CI script - runs before xcodebuild
# This script ensures Flutter is in PATH for Xcode build phases

set -e

echo "=== Flutter CI Pre-Xcodebuild Script ==="

# Set Flutter path
FLUTTER_PATH="$HOME/flutter"

if [ -d "$FLUTTER_PATH" ]; then
    echo "Flutter found at $FLUTTER_PATH"
    export PATH="$PATH:$FLUTTER_PATH/bin"
    flutter --version
else
    echo "ERROR: Flutter not found at $FLUTTER_PATH"
    echo "Installing Flutter..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_PATH"
    export PATH="$PATH:$FLUTTER_PATH/bin"
fi

# Make sure Flutter is accessible
which flutter
flutter --version

echo "=== CI Pre-Xcodebuild Complete ==="
