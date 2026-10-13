#!/bin/bash
# Open the isolated development build on the user's Linux desktop.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
image=${M0_IMAGE:-juxtopposed-vlc-m0-linux}
runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
profile="$root/build-m0/desktop"
[[ -x "$root/build-m0/linux/bin/vlc-static" ]] || {
    echo 'Build missing. Run extras/juxtopposed/linux.sh in the build container first.' >&2
    exit 1
}
mkdir -p "$profile"/{config,cache,data,runtime/pulse}
chmod 700 "$profile/runtime"
args=(--rm --init --user "$(id -u):$(id -g)" --workdir /work/build-m0/linux
    --volume "$root:/work" --volume "$HOME:/media/home:ro"
    --volume "$profile/runtime:/run/m0"
    --env XDG_RUNTIME_DIR=/run/m0 --env XDG_CONFIG_HOME=/work/build-m0/desktop/config
    --env XDG_CACHE_HOME=/work/build-m0/desktop/cache
    --env XDG_DATA_HOME=/work/build-m0/desktop/data
    --env LD_LIBRARY_PATH=/work/build-m0/deps/lib
    --env "QT_QUICK_BACKEND=${QT_QUICK_BACKEND:-software}")
[[ -z "${M0_CONTAINER:-}" ]] || args+=(--name "$M0_CONTAINER")
if [[ -S "$runtime/${WAYLAND_DISPLAY:-wayland-0}" ]]; then
    args+=(--volume "$runtime/${WAYLAND_DISPLAY:-wayland-0}:/run/m0/wayland-0"
        --env WAYLAND_DISPLAY=wayland-0 --env QT_QPA_PLATFORM=wayland)
    compositor=wayland
elif [[ -n "${DISPLAY:-}" && -f "${XAUTHORITY:-}" ]]; then
    args+=(--volume /tmp/.X11-unix:/tmp/.X11-unix:ro
        --volume "$XAUTHORITY:/run/m0/xauthority:ro"
        --env "DISPLAY=$DISPLAY" --env XAUTHORITY=/run/m0/xauthority
        --env QT_QPA_PLATFORM=xcb)
    compositor=x11
else
    echo 'No accessible Wayland or authenticated X11 display.' >&2
    exit 1
fi
if [[ -S "$runtime/pulse/native" ]]; then
    args+=(--volume "$runtime/pulse/native:/run/m0/pulse/native"
        --env PULSE_SERVER=unix:/run/m0/pulse/native)
fi
media=()
for item in "$@"; do
    if [[ -f "$item" ]]; then
        item=$(realpath "$item")
        case "$item" in
            "$root"/*) item="/work/${item#"$root"/}" ;;
            "$HOME"/*) item="/media/home/${item#"$HOME"/}" ;;
            *) args+=(--volume "$(dirname "$item"):$(dirname "$item"):ro") ;;
        esac
    fi
    media+=("$item")
done
exec docker run "${args[@]}" "$image" dbus-run-session -- ./vlc \
    --ignore-config --no-one-instance --no-qt-privacy-ask --no-hw-dec --no-qt-titlebar \
    "--qt-compositor=$compositor" "${media[@]}"
