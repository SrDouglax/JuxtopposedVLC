#!/bin/bash
# Exercise the real VLC QML in a separate Wayland application and profile.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
mode=${1:-panels}
[[ "$mode" == panels || "$mode" == mini ]] || { echo 'Use panels or mini' >&2; exit 2; }
builder=${M0_BUILD_CONTAINER:-juxtopposed-vlc-m0-linux}
image=${M0_IMAGE:-juxtopposed-vlc-m0-linux}
out="$root/build-m3/ui-test-$mode"
runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
socket="$runtime/${WAYLAND_DISPLAY:-wayland-0}"
[[ -S "$socket" ]] || { echo 'An accessible Wayland session is required' >&2; exit 1; }
[[ -f "$root/build-m0/fixtures/baseline.mkv" ]] || { echo 'Run the M0 media smoke first' >&2; exit 1; }
mkdir -p "$out/profile"/{config,cache,data,runtime/pulse}
chmod 700 "$out/profile/runtime"
if [[ ! -d "$out/profile/config/vlc" ]]; then
    cp -a "$root/build-m0/desktop/config/vlc" "$out/profile/config/"
fi
docker start "$builder" >/dev/null
docker update --memory 2g --memory-swap 2g --cpus 1 "$builder" >/dev/null
docker exec "$builder" bash -c '
    set -e
    includes=()
    version=$(pkg-config --modversion Qt6Quick)
    base=$(pkg-config --variable=includedir Qt6Quick)
    for module in Quick Qml QmlModels Core Gui; do
        includes+=(-I"$base/Qt$module/$version" -I"$base/Qt$module/$version/Qt$module")
    done
    nice -n19 g++ -std=c++17 -fPIC -shared /work/extras/juxtopposed/player-ui-probe.cpp \
        "${includes[@]}" $(pkg-config --cflags --libs Qt6Quick Qt6Qml Qt6Test) -o "$1/probe.so"
' bash "/work/build-m3/ui-test-$mode"
container_out="/work/build-m3/ui-test-$mode"
args=(--rm --init --memory 2g --memory-swap 2g --cpus 1
    --user "$(id -u):$(id -g)" --workdir /work/build-m0/linux
    --volume "$root:/work" --volume "$socket:/run/m0/wayland-0"
    --volume "$out/profile/runtime:/run/m0"
    --env XDG_RUNTIME_DIR=/run/m0 --env WAYLAND_DISPLAY=wayland-0
    --env QT_QPA_PLATFORM=wayland --env QT_QUICK_BACKEND=software
    --env "XDG_CONFIG_HOME=$container_out/profile/config"
    --env "XDG_CACHE_HOME=$container_out/profile/cache"
    --env "XDG_DATA_HOME=$container_out/profile/data"
    --env LD_LIBRARY_PATH=/work/build-m0/deps/lib
    --env "LD_PRELOAD=$container_out/probe.so"
    --env "MINI_PROBE_IMAGE=$container_out/result.png")
[[ "$mode" != panels ]] || args+=(--env MINI_PROBE_PANELS=1)
if [[ -S "$runtime/pulse/native" ]]; then
    args+=(--volume "$runtime/pulse/native:/run/m0/pulse/native" --env PULSE_SERVER=unix:/run/m0/pulse/native)
fi
timeout 75s docker run "${args[@]}" "$image" dbus-run-session -- ./vlc \
    --no-one-instance --no-hw-dec --no-qt-titlebar --qt-compositor=wayland \
    --no-qt-video-autoresize --verbose=2 /work/build-m0/fixtures/baseline.mkv > "$out/vlc.log" 2>&1
rg 'MINI-PROBE' "$out/vlc.log"
! rg -q 'MINI-PROBE.*FAIL' "$out/vlc.log"
rg -q 'MINI-PROBE (PANELS )?RESULT PASS' "$out/vlc.log"
