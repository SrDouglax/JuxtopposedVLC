#!/bin/bash
# Run inside the Linux build container, under dbus-run-session.
set -euo pipefail
cd /work
out=${SMOKE_OUT:-/work/build-m0/evidence}
profile=${SMOKE_PROFILE:-/work/build-m0/profile}
mkdir -p "$out" /work/build-m0/fixtures "$profile/runtime"
export XDG_CONFIG_HOME="$profile/config"
export XDG_CACHE_HOME="$profile/cache"
export XDG_DATA_HOME="$profile/data"
export XDG_RUNTIME_DIR="$profile/runtime"
chmod 700 "$XDG_RUNTIME_DIR"
export QT_QPA_PLATFORM=xcb DISPLAY=:98
# Xvfb has no physical GPU. This selects the Qt Quick test renderer only.
export QT_QUICK_BACKEND=${QT_QUICK_BACKEND:-software}
export LD_LIBRARY_PATH="/work/build-m0/deps/lib:${LD_LIBRARY_PATH:-}"
Xvfb :98 -screen 0 1280x800x24 -nolisten tcp > "$out/xvfb.log" 2>&1 &
xvfb_pid=$!
vlc_pid=
wm_pid=
cleanup() {
    if [[ -n "$vlc_pid" ]]; then
        kill "$vlc_pid" 2>/dev/null || true
        wait "$vlc_pid" 2>/dev/null || true
    fi
    [[ -z "$wm_pid" ]] || kill "$wm_pid" 2>/dev/null || true
    kill "$xvfb_pid" 2>/dev/null || true
    pulseaudio --kill 2>/dev/null || true
}
trap cleanup EXIT
pulseaudio --start --exit-idle-time=-1 --load='module-null-sink sink_name=m0'
pactl set-default-sink m0
fixture=/work/build-m0/fixtures/baseline.mkv
if [[ ! -s "$fixture" ]]; then
    ffmpeg -hide_banner -loglevel error -f lavfi -i testsrc2=size=640x360:rate=24 \
        -f lavfi -i sine=frequency=440:sample_rate=48000 -t 120 \
        -c:v libx264 -preset ultrafast -threads 2 -pix_fmt yuv420p \
        -c:a aac -y "$fixture"
fi
printf '1\n00:00:00,000 --> 00:02:00,000\nLegenda M0: reprodução real\n' \
    > /work/build-m0/fixtures/baseline.srt
sha256sum /work/build-m0/fixtures/baseline.* > "$out/fixtures.sha256"
sleep 1
openbox > "$out/openbox.log" 2>&1 &
wm_pid=$!
cd /work/build-m0/linux
decoration=()
[[ "${SMOKE_CSD:-0}" != 1 ]] || decoration+=(--no-qt-titlebar)
./vlc --ignore-config --no-qt-privacy-ask --no-one-instance --extraintf=dbus \
    --aout=pulse --sub-file=/work/build-m0/fixtures/baseline.srt \
    --qt-compositor=x11 --verbose=2 "${decoration[@]}" > "$out/vlc.log" 2>&1 &
vlc_pid=$!
bus=org.mpris.MediaPlayer2.vlc
path=/org/mpris/MediaPlayer2
player=org.mpris.MediaPlayer2.Player
call() { gdbus call --session --dest "$bus" --object-path "$path" --method "$@"; }
get() { call org.freedesktop.DBus.Properties.Get "$player" "$1"; }
window=
for attempt in $(seq 1 20); do
    window=$(xdotool search --onlyvisible --pid "$vlc_pid" --name 'VLC' | head -1 || true)
    [[ -z "$window" ]] || break
    kill -0 "$vlc_pid"
    sleep 1
done
[[ -n "$window" ]]
xdotool windowactivate --sync "$window"
sleep 1
import -window root "$out/empty.png"
call "$player.OpenUri" "file://$fixture" > "$out/open.txt"
for attempt in $(seq 1 40); do
    status=$(get PlaybackStatus 2>/dev/null || true)
    [[ "$status" != *Playing* ]] || break
    kill -0 "$vlc_pid"
    sleep 1
done
[[ "$status" == *Playing* ]]
sleep 2
import -window root "$out/playing.png"
get PlaybackStatus | tee "$out/playing.txt"
get Position | tee -a "$out/playing.txt"
ps -p "$vlc_pid" -o pid,comm,%cpu,rss,vsz,etime > "$out/resources.txt"
timeout 8 ffmpeg -hide_banner -loglevel error -f pulse -i m0.monitor \
    -t 2 -c:a pcm_s16le -y "$out/audio.wav"
python3 - "$out/audio.wav" <<'PY'
import array, math, sys, wave
with wave.open(sys.argv[1]) as stream:
    samples = array.array('h', stream.readframes(stream.getnframes()))
rms = math.sqrt(sum(v * v for v in samples) / len(samples))
print(f'Audio monitor PCM RMS: {rms:.2f}')
assert rms > 10, 'Audio output is silent'
PY
xdotool key space
sleep 1
get PlaybackStatus | tee "$out/paused.txt" | grep -q Paused
xdotool mousemove 640 740
sleep 1
import -window root "$out/paused.png"
before=$(get Position)
sleep 1
after=$(get Position)
[[ "$before" == "$after" ]]
xdotool key space
sleep 1
get PlaybackStatus | tee "$out/resumed.txt" | grep -q Playing
before=$(get Position)
call "$player.Seek" 15000000 > "$out/seek.txt"
seek_verified=false
for attempt in $(seq 1 10); do
    sleep 1
    after=$(get Position)
    printf '%s\n' "$after" >> "$out/seek.txt"
    if python3 - "$before" "$after" <<'PY'
import re, sys
positions = [int(re.search(r'int64 (\d+)', value)[1]) for value in sys.argv[1:]]
assert 15_000_000 <= positions[1] - positions[0] < 20_000_000, positions
PY
    then seek_verified=true; break; fi
done
[[ "$seek_verified" == true ]]
before_volume=$(get Volume)
xdotool key ctrl+Down
sleep 1
after_volume=$(get Volume)
printf 'before=%s\nafter=%s\n' "$before_volume" "$after_volume" > "$out/volume.txt"
[[ "$before_volume" != "$after_volume" ]]
xdotool key f
sleep 2
call org.freedesktop.DBus.Properties.Get org.mpris.MediaPlayer2 Fullscreen \
    | tee "$out/fullscreen.txt" | grep -q true
import -window root "$out/fullscreen.png"
xdotool key f
sleep 1
call org.freedesktop.DBus.Properties.Get org.mpris.MediaPlayer2 Fullscreen \
    | tee "$out/windowed.txt" | grep -q false
if [[ -n "${SMOKE_HOOK:-}" ]]; then
    source "$SMOKE_HOOK"
fi
call org.mpris.MediaPlayer2.Quit > "$out/quit.txt"
wait "$vlc_pid"
vlc_pid=
printf 'PASS: Qt window, video, PCM audio, subtitle fixture, pause/resume, seek, volume, fullscreen, exit\n' \
    | tee "$out/result.txt"
