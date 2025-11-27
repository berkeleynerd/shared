#!/bin/bash
###############################################################################
# fix_toolchain.sh - Repair GNAT 15.1.2 on modern macOS
#
# This script applies two fixes:
#   1) Remove broken GCC include-fixed headers shipped with the Alire toolchain
#   2) Point the hardcoded MacOSX14.sdk sysroot at an installed SDK (latest)
#
# It is safe to re-run; it will backup include-fixed once and refresh the SDK
# symlink if it points anywhere other than the chosen SDK.
###############################################################################

set -euo pipefail

TOOLCHAIN_DIR="$HOME/.local/share/alire/toolchains/gnat_native_15.1.2_60748c54"
INCLUDE_FIXED="$TOOLCHAIN_DIR/lib/gcc/aarch64-apple-darwin23.6.0/15.0.1/include-fixed"

SDK_SEARCH_DIRS=(
    "/Library/Developer/CommandLineTools/SDKs"
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs"
)
SDK_LINK_NAME="MacOSX14.sdk"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "This fix is intended for macOS toolchains only."
    exit 1
fi

echo "=== GNAT toolchain repair for macOS ==="

if [ ! -d "$TOOLCHAIN_DIR" ]; then
    echo "Error: GNAT toolchain not found at:"
    echo "  $TOOLCHAIN_DIR"
    echo "Run: alr toolchain --select gnat_native"
    exit 1
fi

if [ ! -d "$INCLUDE_FIXED" ]; then
    echo "Error: include-fixed directory not found at:"
    echo "  $INCLUDE_FIXED"
    exit 1
fi

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

choose_sdk_dir() {
    for dir in "${SDK_SEARCH_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

pick_best_sdk() {
    python3 - "$1" <<'PY'
import glob
import os
import sys

sdk_dir = sys.argv[1]
symlink = os.path.join(sdk_dir, "MacOSX.sdk")
if os.path.islink(symlink):
    target = os.path.realpath(symlink)
    if os.path.exists(target):
        print(target)
        sys.exit(0)

candidates = []
for path in glob.glob(os.path.join(sdk_dir, "MacOSX*.sdk")):
    base = os.path.basename(path)
    if base == "MacOSX.sdk":
        continue
    ver = base[len("MacOSX"):-len(".sdk")]
    parts = []
    for piece in ver.split("."):
        try:
            parts.append(int(piece))
        except ValueError:
            parts.append(piece)
    candidates.append((tuple(parts), path))

if not candidates:
    sys.exit(1)

candidates.sort()
print(candidates[-1][1])
PY
}

SDK_BASE_DIR="$(choose_sdk_dir)" || {
    echo "Error: No macOS SDK directory found. Install Command Line Tools or Xcode."
    exit 1
}

SDK_TARGET="$(pick_best_sdk "$SDK_BASE_DIR")" || {
    echo "Error: No MacOSX*.sdk found under $SDK_BASE_DIR"
    exit 1
}

SDK_LINK="$SDK_BASE_DIR/$SDK_LINK_NAME"

echo "SDK directory : $SDK_BASE_DIR"
echo "Chosen SDK    : $SDK_TARGET"
echo "Fixing link   : $SDK_LINK -> $SDK_TARGET"

if [ -e "$SDK_LINK" ] || [ -L "$SDK_LINK" ]; then
    EXISTING="$(/bin/ls -ld "$SDK_LINK" | awk '{print $NF}')"
    if python3 - "$SDK_LINK" "$SDK_TARGET" <<'PY'
import os, sys
link = sys.argv[1]
target = sys.argv[2]
if os.path.islink(link) and os.path.realpath(link) == os.path.realpath(target):
    sys.exit(0)
sys.exit(1)
PY
    then
        echo "SDK link already points to the chosen SDK."
    else
        echo "Updating SDK symlink (was: $EXISTING)..."
        if [ -d "$SDK_LINK" ] && [ ! -L "$SDK_LINK" ]; then
            BACKUP="$SDK_LINK.backup"
            echo "Existing path is a directory; moving to $BACKUP"
            $SUDO rm -rf "$BACKUP"
            $SUDO mv "$SDK_LINK" "$BACKUP"
        else
            $SUDO rm -f "$SDK_LINK"
        fi
        $SUDO ln -s "$SDK_TARGET" "$SDK_LINK"
    fi
else
    echo "Creating SDK symlink..."
    $SUDO ln -s "$SDK_TARGET" "$SDK_LINK"
fi

if [ ! -d "$INCLUDE_FIXED.backup" ]; then
    echo "Backing up include-fixed to include-fixed.backup ..."
    cp -r "$INCLUDE_FIXED" "$INCLUDE_FIXED.backup"
fi

echo "Removing broken include-fixed headers..."
rm -rf "$INCLUDE_FIXED"/*

echo "Fixed on $(date) by fix_toolchain.sh" > "$INCLUDE_FIXED/README"
echo "GCC will now use system headers and the refreshed SDK sysroot."

echo "Done."
