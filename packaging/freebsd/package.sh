#!/usr/bin/env bash
# Build and package DreamLab Canvas for FreeBSD:
#
#   $DIST/dreamlab-canvas-<version>-freebsd-x86_64.tar.gz   a /usr/local-style tree:
#       dreamlab-canvas-<version>-freebsd-x86_64/{bin, share/applications, share/icons, share/mime,
#       share/metainfo, share/doc/dreamlab-canvas}
#
# Install by copying the tree's contents into /usr/local:
#   tar -xzf dreamlab-canvas-<version>-freebsd-x86_64.tar.gz --strip-components 1 -C /usr/local
#
# Usage: packaging/freebsd/package.sh [--skip-build] [--dry-run]
#   --dry-run   stage the tree from stub binaries and list it, without building (works on any OS)
#
# Needs: bash, cargo, and the packages installed in .github/workflows/freebsd.yml.
set -euo pipefail
# shellcheck source=../env.sh
. "$(dirname "${BASH_SOURCE[0]}")/../env.sh"
LINUX="$ROOT/packaging/linux"
APP_ID=com.dreamlab.canvas

SKIP_BUILD=0
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-build) SKIP_BUILD=1; shift ;;
    --dry-run) DRY_RUN=1; SKIP_BUILD=1; shift ;;
    -h | --help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# FreeBSD's uname says amd64; release file names use x86_64 like the Linux and Windows ones.
MACHINE="$(uname -m)"
case "$MACHINE" in
  amd64 | x86_64) ARCH=x86_64 ;;
  arm64 | aarch64) ARCH=aarch64 ;;
  *) echo "unsupported architecture $MACHINE" >&2; exit 2 ;;
esac
if [ "$DRY_RUN" = 0 ] && [ "$(uname -s)" != FreeBSD ]; then
  echo "error: build on FreeBSD (or pass --dry-run to check the tree layout)" >&2
  exit 2
fi
BASENAME="dreamlab-canvas-$VERSION-freebsd-$ARCH"

echo "==> DreamLab Canvas $VERSION for FreeBSD $ARCH"

# The release VM has 12 GB; full parallelism on the biggest crates runs it out of memory.
export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-4}"
if [ "$SKIP_BUILD" = 0 ]; then
  (cd "$ROOT" && cargo build --release --locked -p dreamlab-canvas -p dreamlab-canvas-cli --features heif)
fi
WORK="$CARGO_TARGET_DIR/freebsd-package"
STAGE="$WORK/$BASENAME"
rm -rf "$WORK"
mkdir -p "$WORK"

BIN="$CARGO_TARGET_DIR/release"
OUT_DIR="$DIST"
if [ "$DRY_RUN" = 1 ]; then
  # Stub binaries, and the tarball stays in the work dir so dist/ only ever holds real builds.
  BIN="$WORK/stub-bin"
  OUT_DIR="$WORK"
  mkdir -p "$BIN"
  for b in dreamlab-canvas dreamlab-canvas-cli; do
    printf '#!/bin/sh\necho "%s %s (dry-run stub)"\n' "$b" "$VERSION" >"$BIN/$b"
    chmod 755 "$BIN/$b"
  done
fi

# ---- stage a /usr/local-style tree --------------------------------------------------------------
# FreeBSD's install(1) has no -D: create the directories first.
mkdir -p "$STAGE/bin" "$STAGE/share/applications" "$STAGE/share/mime/packages" \
  "$STAGE/share/metainfo" "$STAGE/share/icons" "$STAGE/share/doc/dreamlab-canvas"
install -m 755 "$BIN/dreamlab-canvas" "$BIN/dreamlab-canvas-cli" "$STAGE/bin/"
strip "$STAGE/bin/dreamlab-canvas" "$STAGE/bin/dreamlab-canvas-cli" 2>/dev/null || true
# The desktop entry, MIME type, metainfo and icons are the freedesktop files Linux ships.
install -m 644 "$LINUX/$APP_ID.desktop" "$STAGE/share/applications/$APP_ID.desktop"
install -m 644 "$LINUX/$APP_ID.mime.xml" "$STAGE/share/mime/packages/$APP_ID.xml"
sed -e "s/@VERSION@/$VERSION/g" -e "s/@DATE@/$DREAMLAB_CANVAS_BUILD_DATE/g" \
  "$LINUX/$APP_ID.metainfo.xml.in" >"$STAGE/share/metainfo/$APP_ID.metainfo.xml"
cp -R "$ROOT/assets/app-icon/hicolor" "$STAGE/share/icons/"
copy_docs "$STAGE/share/doc/dreamlab-canvas"
for f in NOTICE ATTRIBUTION.md; do
  if [ -f "$ROOT/$f" ]; then install -m 644 "$ROOT/$f" "$STAGE/share/doc/dreamlab-canvas/"; fi
done

for f in bin/dreamlab-canvas bin/dreamlab-canvas-cli "share/applications/$APP_ID.desktop" \
  "share/icons/hicolor/256x256/apps/$APP_ID.png" "share/icons/hicolor/scalable/apps/$APP_ID.svg" \
  share/doc/dreamlab-canvas/LICENSE-MIT share/doc/dreamlab-canvas/LICENSE-APACHE; do
  if [ ! -e "$STAGE/$f" ]; then echo "error: $f is missing from the package" >&2; exit 1; fi
done

# ---- .tar.gz ------------------------------------------------------------------------------------
mkdir -p "$OUT_DIR"
tar -C "$WORK" -czf "$OUT_DIR/$BASENAME.tar.gz" "$BASENAME"
echo "wrote $OUT_DIR/$BASENAME.tar.gz"

"$STAGE/bin/dreamlab-canvas-cli" --version
if [ "$DRY_RUN" = 1 ]; then
  echo "==> dry run: tarball contents"
  tar -tzvf "$OUT_DIR/$BASENAME.tar.gz"
fi
echo "==> done"
