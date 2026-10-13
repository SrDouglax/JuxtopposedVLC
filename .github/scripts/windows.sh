#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"
triplet=x86_64-w64-mingw32
contrib_sha=$(extras/ci/get-contrib-sha.sh win64)
contrib_file="vlc-contrib-${triplet}-${contrib_sha}.tar.zst"
contrib_url="https://artifacts.videolan.org/vlc/win64/${contrib_file}"
contrib_checksum_url=https://artifacts.videolan.org/vlc/win64/SHA512SUM

# Check availability and an upstream checksum before any build or large download.
curl --fail --silent --show-error --location --head "$contrib_url"
checksums=$(curl --fail --silent --show-error --location "$contrib_checksum_url")
checksum=$(printf '%s\n' "$checksums" | awk -v name="./$contrib_file" '$2 == name {print $1}')
if [[ ! "$checksum" =~ ^[0-9a-f]{128}$ ]]; then
    echo "The official checksum does not cover ${contrib_file}; refusing contrib fallback." >&2
    exit 1
fi
printf 'Source: %s\nContrib: %s\nSHA512: %s\n' "$(git rev-parse HEAD)" "$contrib_url" "$checksum"
if [[ "${1:-}" == --check ]]; then
    exit 0
fi
if [[ $# != 0 ]]; then
    echo "Usage: $0 [--check]" >&2
    exit 2
fi

: "${JOBS:=2}"
: "${M0_OUTPUT:=$root/m0-artifacts}"
mkdir -p "$M0_OUTPUT" contrib/contrib-win64
M0_OUTPUT=$(cd "$M0_OUTPUT" && pwd)
archive="$root/contrib/contrib-win64/vlc-contrib-${triplet}-latest.tar.zst"
curl --fail --show-error --location --retry 3 "$contrib_url" --output "$archive"
printf '%s  %s\n' "$checksum" "$archive" | sha512sum --check -
tar --zstd -tf "$archive" > "$M0_OUTPUT/contrib-files.txt"

# Upstream -p normally rebuilds all contribs if prebuilt extraction fails.
# Use a temporary sibling (same SCRIPT_PATH) and fail instead of that fallback.
generated="$root/extras/package/win32/m0-build.generated.sh"
trap 'rm -f "$generated"' EXIT
python3 - "$root/extras/package/win32/build.sh" "$generated" <<'PY'
import pathlib
import sys
source = pathlib.Path(sys.argv[1]).read_text()
fallback = "|| PREBUILT_FAILED=yes"
if source.count(fallback) != 2:
    raise SystemExit("Upstream prebuilt handling changed; review before building")
pathlib.Path(sys.argv[2]).write_text(source.replace(fallback, "|| exit 1"))
PY
export JOBS VLC_PREBUILT_CONTRIBS_URL="$contrib_url"
{
    printf 'source_sha=%s\ncontrib_sha=%s\ncontrib_url=%s\ncontrib_sha512=%s\nimage=%s\njobs=%s\n' \
        "$(git rev-parse HEAD)" "$contrib_sha" "$contrib_url" "$checksum" "${M0_IMAGE:-unrecorded}" "$JOBS"
    x86_64-w64-mingw32-gcc --version
    make --version
    df -h .
    free -h
} > "$M0_OUTPUT/build-environment.txt"

# Autotools, full Qt GUI, portable package; no release installer or LTO.
# C plugins need the GCC runtime at final link too. The upstream CXXFLAGS
# already select static libgcc, but C link commands otherwise import a DLL
# that the restricted Windows plugin loader cannot search in the package.
export LDFLAGS="${LDFLAGS:-} -static-libgcc"
sh "$generated" -a x86_64 -p -x -o "$M0_OUTPUT/windows"
test -s "$M0_OUTPUT/windows/vlc.exe"
test -s "$M0_OUTPUT/windows/vlc-waveform.exe"
test -s "$M0_OUTPUT/windows/libvlc.dll"
test -s "$M0_OUTPUT/windows/libvlccore.dll"
test -s "$M0_OUTPUT/windows/plugins/gui/libqt_plugin.dll"
test -s "$M0_OUTPUT/windows/plugins/codec/libavcodec_plugin.dll"
for plugin in access/libaccess_srt_plugin.dll access_output/libaccess_output_srt_plugin.dll \
    codec/libx265_plugin.dll demux/libgme_plugin.dll; do
    imports=$(x86_64-w64-mingw32-objdump -p "$M0_OUTPUT/windows/plugins/$plugin")
    printf 'IMPORTS %s\n%s\n' "$plugin" "$imports" >> "$M0_OUTPUT/plugin-imports.txt"
    if printf '%s\n' "$imports" | grep -qi 'DLL Name: libgcc_s'; then
        echo "Dynamic GCC runtime remains in $plugin" >&2
        exit 1
    fi
done
file "$M0_OUTPUT/windows/vlc.exe" | tee "$M0_OUTPUT/executable.txt"
file "$M0_OUTPUT/windows/vlc.exe" | grep -q 'PE32+.*x86-64'
find "$M0_OUTPUT/windows" -type f -name '*.dll' -printf '%P\n' | sort > "$M0_OUTPUT/plugins.txt"
find "$M0_OUTPUT/windows" -type f \( -name '*.dll' -o -name '*.exe' \) \
    -exec x86_64-w64-mingw32-strip --strip-unneeded {} +
(cd "$M0_OUTPUT" && zip -q -r windows.zip windows)
sha256sum "$M0_OUTPUT/windows.zip" > "$M0_OUTPUT/windows.zip.sha256"

# Qt's official contrib uses qmake/CMake metadata, without Qt6Core.pc.
# Preserve the validated package before recording this supplementary metadata.
target_qt=$(awk '$1 == "#define" && $2 == "QTCORE_VERSION_STR" {gsub(/"/, "", $3); print $3}' \
    "$root/contrib/$triplet/include/QtCore/qtcoreversion.h")
[[ "$target_qt" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
printf 'target_header=%s\nhost_qmake=%s\n' "$target_qt" "$(qmake6 -query QT_VERSION)" \
    > "$M0_OUTPUT/qt-version.txt"
