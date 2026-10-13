# Sourced by smoke.sh after its baseline playback/keyboard/fullscreen checks.
call "$player.Pause" >/dev/null
xdotool windowsize "$window" 1280 760 windowmove "$window" 0 20
sleep 1
eval "$(xdotool getwindowgeometry --shell "$window")"
px=$((X+55)); py=$((Y+HEIGHT-27))
sx=$((X+470)); vx=$((X+957))
xdotool mousemove "$px" "$py"
sleep 1
import -window root "$out/player-large.png"
xdotool click 1
sleep 1
get PlaybackStatus | tee "$out/mouse-play.txt" | grep -q Playing
xdotool click 1
sleep 1
get PlaybackStatus | tee "$out/mouse-pause.txt" | grep -q Paused

position_in_range() {
    # VLC's MPRIS Position is stale while paused; refresh its playing clock
    # after the mouse action before asserting the actual new media position.
    call "$player.Play" >/dev/null
    sleep 2
    call "$player.Pause" >/dev/null
    get Position | tee -a "$out/mouse-seek.txt"
    python3 - "$(get Position)" "$1" "$2" <<'PY'
import re, sys
value = int(re.search(r'int64 (\d+)', sys.argv[1])[1])
assert int(sys.argv[2]) <= value <= int(sys.argv[3]), value
PY
}
xdotool mousemove "$sx" "$py" click 1
position_in_range 45000000 70000000
xdotool mousemove "$sx" "$py" mousedown 1 mousemove $((sx+80)) "$py" mouseup 1
position_in_range 65000000 90000000
before_volume=$(get Volume)
xdotool mousemove "$vx" "$py" click 1
sleep 1
after_volume=$(get Volume)
printf 'before=%s\nafter=%s\n' "$before_volume" "$after_volume" > "$out/mouse-volume.txt"
[[ "$before_volume" != "$after_volume" ]]
import -window root "$out/player-controls.png"

xdotool mousemove $((X+WIDTH-32)) "$py" click 1
sleep 1
call org.freedesktop.DBus.Properties.Get org.mpris.MediaPlayer2 Fullscreen \
    | tee "$out/mouse-fullscreen.txt" | grep -q true
xdotool mousemove 640 775
sleep 1
import -window root "$out/fullscreen-controls.png"
xdotool key f
sleep 1
call org.freedesktop.DBus.Properties.Get org.mpris.MediaPlayer2 Fullscreen \
    | tee "$out/mouse-windowed.txt" | grep -q false
xdotool windowsize "$window" 580 480
sleep 1
import -window root "$out/player-small.png"

call "$player.Stop" >/dev/null
xdotool key Escape
xdotool windowsize "$window" 1280 760
sleep 1
import -window root "$out/shell-large.png"
xdotool mousemove 22 40 click 1
sleep 1
import -window root "$out/sidebar-toggled.png"
xdotool mousemove 30 140 click 1
sleep 1
xdotool key Tab Down Return
sleep 1
import -window root "$out/navigation-keyboard.png"
xdotool windowsize "$window" 580 480
sleep 1
import -window root "$out/shell-small.png"
xdotool key Escape

# Open the real Qt file dialog, including a Unicode/space-containing name.
ln -sf baseline.mkv /work/build-m0/fixtures/'Vídeo M1.mkv'
xdotool key ctrl+o
sleep 1
dialog=$(xdotool search --onlyvisible --name 'Select one or more files to open' | tail -1)
[[ -n "$dialog" ]]
xdotool windowactivate --sync "$dialog"
import -window root "$out/open-dialog.png"
xdotool key ctrl+a
xdotool type --clearmodifiers --delay 1 '/work/build-m0/fixtures/Vídeo M1.mkv'
import -window root "$out/open-dialog-filled.png"
xdotool key Return
for attempt in $(seq 1 10); do
    sleep 1
    status=$(get PlaybackStatus)
    [[ "$status" != *Playing* ]] || break
done
if [[ "$status" != *Playing* ]]; then
    xdotool key Escape
    sleep 1
    echo 'File dialog did not start playback' >&2
    exit 1
fi
get Metadata > "$out/open-dialog-metadata.txt"
import -window root "$out/dialog-playing.png"

call "$player.OpenUri" 'file:///work/build-m0/fixtures/does-not-exist.mkv' >/dev/null
sleep 2
get PlaybackStatus | tee "$out/invalid-status.txt" | grep -q Stopped
kill -0 "$vlc_pid"
import -window root "$out/invalid-file.png"
xdotool key Escape
printf 'PASS: mouse playback, seek click/drag, volume, fullscreen, resize, file dialog, missing file; navigation captures recorded\n' \
    | tee "$out/ui-result.txt"
