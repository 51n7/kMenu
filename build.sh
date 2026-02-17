#!/bin/bash
# Package the kMenu applet into kMenu.plasmoid
# Zips the package/ folder so metadata.json and contents/ at the archive root.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
OUTPUT="${1:-kMenu.plasmoid}"
cd package
zip -r "$SCRIPT_DIR/$OUTPUT" . -x "*.plasmoid"
cd "$SCRIPT_DIR"
echo "Created: $(realpath "$OUTPUT")"
