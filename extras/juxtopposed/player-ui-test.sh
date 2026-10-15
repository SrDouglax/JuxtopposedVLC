#!/bin/bash
# Exercise real VLC QML in a private X11 display and profile by default.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
mode=${1:-panels}
[[ "$mode" == panels || "$mode" == mini || "$mode" == settings || "$mode" == forms || "$mode" == audit || "$mode" == geometry || "$mode" == onboarding || "$mode" == associations ]] || { echo 'Use panels, mini, settings, forms, audit, geometry, onboarding or associations' >&2; exit 2; }
builder=${M0_BUILD_CONTAINER:-juxtopposed-vlc-m0-linux}
image=${M0_IMAGE:-juxtopposed-vlc-m0-linux}
out="$root/build-m3/ui-test-$mode${M3_UI_SCALE:+-$M3_UI_SCALE}"
platform=${M3_UI_PLATFORM:-x11}
[[ "$platform" == x11 || "$platform" == wayland ]] || exit 2
runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
socket="$runtime/${WAYLAND_DISPLAY:-wayland-0}"
if [[ "$platform" == wayland && ! -S "$socket" ]]; then
    echo 'An accessible Wayland session is required' >&2; exit 1
fi
[[ -f "$root/build-m0/fixtures/baseline.mkv" ]] || { echo 'Run the M0 media smoke first' >&2; exit 1; }
mkdir -p "$out/profile"/{config,cache,data,runtime/pulse} "$root/build-m3/probe"
# The audit owns a generated fixture-only database; start each run isolated.
if [[ "$mode" == audit || "$mode" == associations ]]; then
    python3 - "$out/profile/data/vlc/ml/ml.db" <<'PYDB'
from pathlib import Path
import sys
for suffix in ('', '-shm', '-wal'):
    path = Path(sys.argv[1] + suffix)
    if path.exists(): path.unlink()
PYDB
fi
chmod 700 "$out/profile/runtime"
if [[ ! -d "$out/profile/config/vlc" ]]; then
    cp -a "$root/build-m0/desktop/config/vlc" "$out/profile/config/"
fi
if [[ "$mode" == audit || "$mode" == associations ]]; then
    cp "$root/build-m0/desktop/config/vlc/vlc-qt-interface.conf" "$out/profile/config/vlc/vlc-qt-interface.conf"
    openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj /CN=api.opensubtitles.com \
        -addext 'subjectAltName=DNS:api.opensubtitles.com,DNS:downloads.fixture.test' \
        -keyout "$root/build-m3/fixtures/api.key" -out "$root/build-m3/fixtures/api.crt" >/dev/null 2>&1
fi
docker start "$builder" >/dev/null
docker update --memory 2g --memory-swap 2g --cpus 1 "$builder" >/dev/null
probe="$root/build-m3/probe/probe.so"
needs_probe=false
[[ -f "$probe" ]] || needs_probe=true
[[ "$root/extras/juxtopposed/player-ui-test.sh" -ot "$probe" ]] || needs_probe=true
for source in player-ui-probe.cpp forms-ui-probe.cpp audit-ui-probe.cpp geometry-ui-probe.cpp onboarding-ui-probe.cpp settings-ui-probe.cpp associations-ui-probe.cpp; do
    [[ "$root/extras/juxtopposed/$source" -ot "$probe" ]] || needs_probe=true
done
if [[ "$needs_probe" == true ]]; then
docker exec "$builder" bash -c '
    set -e
    includes=()
    version=$(pkg-config --modversion Qt6Quick)
    base=$(pkg-config --variable=includedir Qt6Quick)
    for module in Quick Qml QmlModels Core Gui; do
        includes+=(-I"$base/Qt$module/$version" -I"$base/Qt$module/$version/Qt$module")
    done
    flags="objects-v1|$version|$(g++ -dumpfullversion)|$(pkg-config --cflags --libs Qt6Quick Qt6Qml Qt6Test Qt6Widgets)"
    previous=$(cat "$1/toolchain.txt" 2>/dev/null || true)
    objects=()
    for name in player-ui-probe forms-ui-probe audit-ui-probe geometry-ui-probe onboarding-ui-probe settings-ui-probe associations-ui-probe; do
        source="/work/extras/juxtopposed/$name.cpp"
        object="$1/$name.o"
        if [[ "$flags" != "$previous" || ! -f "$object" || "$source" -nt "$object" ]]; then
            nice -n19 g++ -std=c++17 -fPIC -c "$source" "${includes[@]}" \
                $(pkg-config --cflags Qt6Quick Qt6Qml Qt6Test Qt6Widgets) -o "$object"
        fi
        objects+=("$object")
    done
    nice -n19 g++ -shared "${objects[@]}" \
        $(pkg-config --libs Qt6Quick Qt6Qml Qt6Test Qt6Widgets) -o "$1/probe.so"
    printf "%s\n" "$flags" >"$1/toolchain.txt"
' bash "/work/build-m3/probe"
fi
cp "$probe" "$out/probe.so"
docker stop "$builder" >/dev/null
container_out="/work/build-m3/ui-test-$mode${M3_UI_SCALE:+-$M3_UI_SCALE}"
args=(--rm --init --memory 2g --memory-swap 2g --cpus 1
    --user "$(id -u):$(id -g)" --workdir /work/build-m0/linux
    --volume "$root:/work"
    --volume "$out/profile/runtime:/run/m0"
    --env XDG_RUNTIME_DIR=/run/m0 --env QT_QUICK_BACKEND=software --env LP_NUM_THREADS=1 --env "QT_SCALE_FACTOR=${M3_UI_SCALE:-1}"
    --env "XDG_CONFIG_HOME=$container_out/profile/config"
    --env "XDG_CACHE_HOME=$container_out/profile/cache"
    --env "XDG_DATA_HOME=$container_out/profile/data"
    --env LD_LIBRARY_PATH=/work/build-m0/deps/lib

    --env "MINI_PROBE_IMAGE=$container_out/result.png")
[[ "$mode" != panels ]] || args+=(--env MINI_PROBE_PANELS=1)
[[ "$mode" != settings ]] || args+=(--env MINI_PROBE_SETTINGS=1)
[[ "$mode" != forms ]] || args+=(--env MINI_PROBE_FORMS=1)
[[ "$mode" != associations ]] || args+=(--env MINI_PROBE_ASSOCIATIONS=1)
[[ "$mode" != onboarding ]] || args+=(--env MINI_PROBE_ONBOARDING=1)
[[ "$mode" != audit ]] || args+=(--env MINI_PROBE_AUDIT=1)
[[ "${M3_AUDIT_FOCUS:-}" != customization ]] || args+=(--env MINI_PROBE_CUSTOMIZATION_ONLY=1)
if [[ "$platform" == wayland ]]; then
    args+=(--volume "$socket:/run/m0/wayland-0" --env WAYLAND_DISPLAY=wayland-0 --env QT_QPA_PLATFORM=wayland)
else
    args+=(--env DISPLAY=:96 --env QT_QPA_PLATFORM=xcb)
fi
test_timeout=90
timeout "${test_timeout}s" docker run "${args[@]}" "$image" dbus-run-session -- bash -c '
    set -e
    if [[ "$1" == x11 ]]; then
        Xvfb :96 -screen 0 1920x1080x24 -nolisten tcp >"$2/xvfb.log" 2>&1 &
        sleep 0.5
        openbox >"$2/openbox.log" 2>&1 &
        sleep 0.5
    fi
    if [[ "$3" == forms ]]; then
        python3 -m http.server 18787 --bind 127.0.0.1 --directory /work/build-m0/fixtures >"$2/http.log" 2>&1 &
    fi
    audio=dummy
    startup=()
    if [[ "$3" == audit || "$3" == associations ]]; then
        python3 /work/extras/juxtopposed/subtitle-api-fixture.py /work/build-m3/fixtures/api.crt /work/build-m3/fixtures/api.key >"$2/api-fixture.log" 2>&1 &
        rm -f /run/m0/pulse/native /run/m0/pulse/pid
        pulseaudio -n --daemonize=yes --exit-idle-time=-1 --load=module-null-sink \
            --load="module-native-protocol-unix socket=/run/m0/pulse/native auth-anonymous=1" >"$2/pulse.log" 2>&1
        export PULSE_SERVER=unix:/run/m0/pulse/native
        audio=pulse
        startup=(--no-volume-save --qt-startup-volume=50)
    fi
    export LD_PRELOAD="$2/probe.so"
    if [[ "$3" == geometry ]]; then
        for phase in 1 2 3; do
            remember=--qt-remember-window-position
            [[ $phase != 3 ]] || remember=--no-qt-remember-window-position
            MINI_PROBE_GEOMETRY_PHASE=$phase ./vlc --no-one-instance --no-hw-dec --no-qt-titlebar \
                --qt-compositor="$1" --no-qt-video-autoresize --aout=dummy "$remember" \
                --verbose=2 /work/build-m0/fixtures/baseline.mkv
        done
        exit
    fi
    exec ./vlc --no-one-instance --no-hw-dec --no-qt-titlebar --qt-compositor="$1" \
        --no-qt-video-autoresize --aout="$audio" "${startup[@]}" --verbose=2 /work/build-m0/fixtures/baseline.mkv
' bash "$platform" "$container_out" "$mode" > "$out/vlc.log" 2>&1
rg 'MINI-PROBE' "$out/vlc.log"
! rg -q 'MINI-PROBE.*FAIL' "$out/vlc.log"
rg -q 'MINI-PROBE ((PANELS|SETTINGS|FORMS|AUDIT|GEOMETRY|ONBOARDING|ASSOCIATIONS) )?RESULT PASS' "$out/vlc.log"
