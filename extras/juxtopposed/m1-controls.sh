# Sourced by smoke.sh after its baseline playback/keyboard/fullscreen checks.
call "$player.Pause" >/dev/null
xdotool windowsize "$window" 1280 760 windowmove "$window" 0 20
sleep 1
eval "$(xdotool getwindowgeometry --shell "$window")"
py=$((Y+HEIGHT-27))
sx=$((X+520)); vx=$((X+WIDTH-230))
xdotool mousemove $((X+200)) "$py"
sleep 1
import -window root "$out/player-large.png"
# Locate the solid orange play button within the left group, independently
# of disabled previous/next controls and their native minimum widths.
px=$(python3 - "$out/player-large.png" "$X" "$py" <<'PY'
import subprocess, sys
pixels = subprocess.check_output(['convert', sys.argv[1], '-crop',
    f'220x1+{sys.argv[2]}+{sys.argv[3]}', '-depth', '8', 'rgb:-'])
matches = [i // 3 for i in range(0, len(pixels), 3)
           if pixels[i:i+3] == bytes((211, 121, 24))]
assert len(matches) >= 20, 'Play button accent not rendered'
print(int(sys.argv[2]) + (matches[0] + matches[-1]) // 2)
PY
)
xdotool mousemove "$px" "$py"
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

# Four real audio states: click the cone, then toggle mute without losing gain.
for state in low medium high; do
    case "$state" in
        low) tx=$((X+WIDTH-243));;
        medium) tx=$((X+WIDTH-225));;
        high) tx=$((X+WIDTH-190));;
    esac
    xdotool mousemove "$tx" "$py" click 1
    sleep 0.4
    get Volume > "$out/volume-$state.txt"
    xdotool mousemove $((X+500)) $((py-100))
    sleep 0.3
    import -window root "$out/volume-$state.png"
done
xdotool mousemove $((X+WIDTH-282)) "$py" click 1
sleep 0.4
get Volume > "$out/volume-muted.txt"
xdotool mousemove $((X+500)) $((py-100))
sleep 0.3
import -window root "$out/volume-muted.png"
python3 - "$out" $((X+WIDTH-294)) $((py-12)) <<'PY_STATES'
import re, subprocess, sys
from pathlib import Path
out = Path(sys.argv[1])
icons = []
for state, lower, upper in [('low', 0, .33), ('medium', .33, .66), ('high', .66, 1.25)]:
    volume = float(re.search(r'<([0-9.]+)>', (out / f'volume-{state}.txt').read_text())[1])
    assert lower <= volume <= upper, (state, volume)
for state in ['low', 'medium', 'high', 'muted']:
    icons.append(subprocess.check_output(['convert', str(out / f'volume-{state}.png'),
                 '-crop', f'24x24+{sys.argv[2]}+{sys.argv[3]}', '-depth', '8', 'rgb:-']))
assert len(set(icons)) == 4, 'Audio states must render four distinct icons'
assert (out / 'volume-high.txt').read_text() == (out / 'volume-muted.txt').read_text(), 'Mute must preserve gain'
print('PASS: four distinct audio icons and real volume levels; mute preserves gain')
PY_STATES
xdotool mousemove $((X+WIDTH-282)) "$py" click 1

xdotool mousemove $((X+WIDTH-54)) $((Y+20)) click 1
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
# Complete the existing Unicode filename through Qt. Xvfb's synthetic key
# mapping does not reliably inject accented characters with xdotool type.
xdotool type --clearmodifiers --delay 1 '/work/build-m0/fixtures/V'
sleep 1
xdotool key Down
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
grep -q 'V%C3%ADdeo%20M1.mkv' "$out/open-dialog-metadata.txt"
import -window root "$out/dialog-playing.png"

call "$player.OpenUri" 'file:///work/build-m0/fixtures/does-not-exist.mkv' >/dev/null
sleep 2
get PlaybackStatus | tee "$out/invalid-status.txt" | grep -q Stopped
kill -0 "$vlc_pid"
import -window root "$out/invalid-file.png"
xdotool key Escape
# Exercise both video destinations and history after restoring
# history. These checks cover the PageLoader forwarding contract.
xdotool windowsize "$window" 1280 760
sleep 1
xdotool mousemove 22 40 click 1
xdotool mousemove 40 140 click 1
sleep 1
import -window root "$out/video-all.png"
call "$player.OpenUri" "file://$fixture" >/dev/null
sleep 2
get PlaybackStatus | grep -q Playing
call "$player.OpenUri" 'file:///work/build-m0/fixtures/does-not-exist.mkv' >/dev/null
sleep 2
get PlaybackStatus | grep -q Stopped
import -window root "$out/video-all-restored.png"
xdotool mousemove 40 232 click 1
sleep 1
import -window root "$out/video-playlists-switch.png"
xdotool mousemove 57 40 click 1
sleep 1
import -window root "$out/video-all-back.png"
printf 'PASS: mouse playback, seek click/drag, volume, fullscreen, resize, file dialog, missing file; navigation captures recorded\n' \
    | tee "$out/ui-result.txt"
