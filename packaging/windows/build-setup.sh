#!/usr/bin/env bash
# Build dist/release/dreamlab-canvas-<version>-windows-x64-setup.exe from Linux (or WSL/macOS with NSIS).
#
# Cross-compiles dreamlab-canvas.exe and dreamlab-canvas-cli.exe for x86_64-pc-windows-gnu with MinGW-w64,
# then packages them with NSIS (packaging/windows/nsis/dreamlab-canvas.nsi).
#
# Needs: Rust (stable), MinGW-w64 (x86_64-w64-mingw32-gcc, -windres), NSIS (makensis), python3.
#   Ubuntu/Debian: sudo apt install mingw-w64 nsis cmake nasm
#   Rust target:   rustup target add x86_64-pc-windows-gnu
# If the Rust target can't be downloaded (offline mirrors), set BUILD_STD=1 with the rust-src
# component (or a matching library/ checkout) in the toolchain's sysroot: std is then built from source.
#
#   packaging/windows/build-setup.sh            # build + package
#   SKIP_BUILD=1 packaging/windows/build-setup.sh
#   WITH_CLI=1 packaging/windows/build-setup.sh    # put the CLI in setup.exe too (larger)
#
# Writes to dist/release/: the setup.exe, a portable zip of the app, and the CLI as its own zip.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
TARGET=x86_64-pc-windows-gnu
VERSION="${DREAMLAB_CANVAS_VERSION:-$(awk '/^\[workspace.package\]/{p=1;next} /^\[/{p=0} p && /^version/{gsub(/[" ]/,"",$0); split($0,a,"="); print a[2]; exit}' Cargo.toml)}"
DIST="${DIST:-$ROOT/dist/release}"
STAGE="$ROOT/target/setup-stage"
echo "DreamLab Canvas $VERSION: Windows x64 setup.exe"

if [ -z "${SKIP_BUILD:-}" ]; then
  export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc
  # Static libgcc/winpthread: the .exe files need no MinGW DLLs beside them.
  export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C target-feature=+crt-static"
  export CC_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc CXX_x86_64_pc_windows_gnu=x86_64-w64-mingw32-g++
  export AR_x86_64_pc_windows_gnu=x86_64-w64-mingw32-ar
  export DREAMLAB_CANVAS_REQUIRE_WINRES=1
  extra=()
  if [ -n "${BUILD_STD:-}" ]; then
    export RUSTC_BOOTSTRAP=1
    extra=(-Zbuild-std=std,panic_unwind)
  fi
  cargo build --release "${extra[@]}" --target "$TARGET" -p dreamlab-canvas -p dreamlab-canvas-cli
fi

BIN="$ROOT/target/$TARGET/release"
rm -rf "$STAGE" && mkdir -p "$STAGE" "$DIST"
cp "$BIN/dreamlab-canvas.exe" "$BIN/dreamlab-canvas-cli.exe" "$STAGE/"
x86_64-w64-mingw32-strip "$STAGE/"*.exe || true
cp assets/app-icon/dreamlab-canvas.ico "$STAGE/"
# Text files with Windows line endings, so Notepad shows them properly.
crlf() { sed 's/\r$//; s/$/\r/' "$1" > "$2"; }
crlf LICENSE-MIT "$STAGE/LICENSE-MIT.txt"
crlf LICENSE-APACHE "$STAGE/LICENSE-APACHE.txt"
crlf NOTICE "$STAGE/NOTICE.txt"

OUT="$DIST/dreamlab-canvas-$VERSION-windows-x64-setup.exe"
nsis_cli=()
[ -n "${WITH_CLI:-}" ] && nsis_cli=(-DWITH_CLI)
(cd packaging/windows/nsis && makensis -V2 "${nsis_cli[@]}" -DVERSION="$VERSION" -DSTAGE="$STAGE" -DOUTFILE="$OUT" dreamlab-canvas.nsi)

# Portable app (portable.txt keeps settings beside the exe) and the CLI, each as its own zip.
PORT="$ROOT/target/portable"
rm -rf "$PORT" && mkdir -p "$PORT/app/dreamlab-canvas-$VERSION-windows-x64-portable" "$PORT/cli/dreamlab-canvas-cli-$VERSION-windows-x64"
cp "$STAGE/dreamlab-canvas.exe" "$STAGE/"*.txt "$PORT/app/dreamlab-canvas-$VERSION-windows-x64-portable/"
crlf packaging/windows/portable.txt "$PORT/app/dreamlab-canvas-$VERSION-windows-x64-portable/portable.txt"
cp "$STAGE/dreamlab-canvas-cli.exe" "$STAGE/"*.txt "$PORT/cli/dreamlab-canvas-cli-$VERSION-windows-x64/"
rm -f "$DIST/dreamlab-canvas-$VERSION-windows-x64-portable.zip" "$DIST/dreamlab-canvas-cli-$VERSION-windows-x64.zip"
(cd "$PORT/app" && zip -q -9 -r "$DIST/dreamlab-canvas-$VERSION-windows-x64-portable.zip" .)
(cd "$PORT/cli" && zip -q -9 -r "$DIST/dreamlab-canvas-cli-$VERSION-windows-x64.zip" .)
(cd "$DIST" && sha256sum dreamlab-canvas-*"$VERSION"-windows-x64* | grep -v '\.sha256' > "SHA256SUMS-$VERSION-windows-x64.txt")
rm -f "$OUT.sha256"
ls -la "$DIST"
