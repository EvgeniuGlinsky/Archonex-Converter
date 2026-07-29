#!/usr/bin/env bash
#
# Wraps the Flutter Linux release bundle into a single runnable AppImage.
#
# The tarball the workflow also produces is the alternative, and it is kept —
# but it asks the recipient to unpack it somewhere sensible and find the binary
# inside. An AppImage is one file: chmod +x, double click, no package manager and
# no root. It carries the GTK app and its own `lib/` and `data/`, which is all the
# Flutter runner needs; only GTK 3 itself is expected from the host.
#
# Usage, from the repository root:
#   packaging/linux/build-appimage.sh <version> <output-dir>

set -euo pipefail

version="${1:?usage: build-appimage.sh <version> <output-dir>}"
outdir="${2:?usage: build-appimage.sh <version> <output-dir>}"

bundle="build/linux/x64/release/bundle"
binary="archonex_converter"

if [ ! -x "$bundle/$binary" ]; then
  echo "::error::$bundle/$binary is missing — run 'flutter build linux --release' first."
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
appdir="$workdir/AppDir"

# The whole bundle goes under usr/bin together, because the runner resolves
# `lib/` and `data/` relative to the executable and the link path is
# `$ORIGIN/lib`. Splitting it across the usual FHS directories would need a
# rebuild with a different RPATH, which buys nothing inside an AppImage.
mkdir -p "$appdir/usr/bin"
cp -a "$bundle/." "$appdir/usr/bin/"

# Both copies are deliberate. The pair at the AppDir root is what appimagetool
# reads to build the image; the pair under usr/share is what a desktop
# environment picks up if the user ever integrates the AppImage into their menu.
install -Dm644 packaging/linux/archonex-converter.desktop \
  "$appdir/archonex-converter.desktop"
install -Dm644 packaging/linux/archonex-converter.desktop \
  "$appdir/usr/share/applications/archonex-converter.desktop"
install -Dm644 docs/store/icon-512.png \
  "$appdir/archonex-converter.png"
install -Dm644 docs/store/icon-512.png \
  "$appdir/usr/share/icons/hicolor/512x512/apps/archonex-converter.png"

cat > "$appdir/AppRun" <<'LAUNCHER'
#!/bin/sh
# `readlink -f` rather than $0's directory: the AppImage runtime mounts itself
# somewhere under /tmp and invokes this through a path that may be a symlink.
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/archonex_converter" "$@"
LAUNCHER
chmod +x "$appdir/AppRun"

# appimagetool moved repositories; the old AppImageKit URL still serves a working
# build, so it is the fallback rather than the primary. Both are the project's own
# `continuous` release — there is no tagged one to pin to.
tool="$workdir/appimagetool"
urls=(
  "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
  "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
)
for url in "${urls[@]}"; do
  if curl -fsSL --retry 3 -o "$tool" "$url"; then
    echo "Fetched appimagetool from $url"
    break
  fi
  echo "::warning::could not fetch appimagetool from $url"
done
if [ ! -s "$tool" ]; then
  echo "::error::no appimagetool could be downloaded."
  exit 1
fi
chmod +x "$tool"

mkdir -p "$outdir"
target="$outdir/Archonex-Converter-$version-x86_64.AppImage"

# `--appimage-extract-and-run` because the runner has no FUSE, and an AppImage
# that cannot mount itself cannot run the tool inside it either.
ARCH=x86_64 "$tool" --appimage-extract-and-run "$appdir" "$target"

test -s "$target"
chmod +x "$target"
echo "Built $target"
