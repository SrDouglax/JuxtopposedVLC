#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out=${1:-"$root/build-m3/rounding-test"}
mkdir -p "$out"
qt_version=$(pkg-config --modversion Qt6Quick)
qt_include=$(pkg-config --variable=includedir Qt6Quick)
qt_libexec=$(pkg-config --variable=libexecdir Qt6Core)
native="$root/modules/gui/qt/widgets/native"
includes=(-I"$native")
for module in Quick Qml Core Gui; do
    includes+=(-I"$qt_include/Qt$module/$qt_version"
               -I"$qt_include/Qt$module/$qt_version/Qt$module")
done
"$qt_libexec/moc" "$native/softwareimage.hpp" -o "$out/moc.cpp"
read -ra qt_flags <<< "$(pkg-config --cflags --libs Qt6Quick)"
nice -n19 "${CXX:-g++}" -std=c++17 "$root/extras/juxtopposed/rounding-test.cpp" \
    "$native/softwareimage.cpp" "$out/moc.cpp" "${includes[@]}" \
    "${qt_flags[@]}" -o "$out/probe"
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    "$out/probe" "$root" "$out" "${@:2}"
