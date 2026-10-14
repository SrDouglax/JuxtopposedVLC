# Local waveform helper contract

`waveform.c` is a standalone C executable linked to **LibVLC**, not to the Qt
plugin. Install it beside the VLC application binary as `vlc-waveform` (or
`vlc-waveform.exe` on Windows). The Qt `Waveform` object launches it with
`QProcess` and one absolute local file path argument. Neither component adds a
LibVLC link dependency to the Qt plugin. Autotools and Meson register the helper and install it beside VLC. The Windows
package check requires its executable; Windows compilation is still pending.

Linux build against this repository's existing VLC 4 build, inside the
`juxtopposed-vlc-m0-linux` container:

```sh
gcc -std=c11 -D_DEFAULT_SOURCE -O2 -Wall -Wextra -I/work/include \
  /work/extras/juxtopposed/waveform.c \
  -L/work/build-m0/linux/lib/.libs \
  -Wl,-rpath,/work/build-m0/linux/lib/.libs \
  -Wl,-rpath,/work/build-m0/linux/src/.libs \
  -lvlc -lm -o /work/build-m3/waveform/vlc-waveform
VLC_PLUGIN_PATH=/work/build-m0/linux/modules \
  /work/build-m3/waveform/vlc-waveform /work/build-m3/waveform/three-minute.wav
```

For a packaged build, use its own LibVLC headers/import library, runtime
library, plugin directory and install RPATH/runtime search path. The helper
uses VLC 4's media-player callback struct; it is not source-compatible with
unmodified VLC 3 headers. Windows source has a UTF-16 command-line entrypoint,
but Windows compilation and playback have not been verified.

Successful stdout is one JSON object with `version: 1`, `durationUs`,
`sampleRate: 48000`, `playbackRate: 16`, `decodedFrames`, `elapsedMs` and 512
nonnegative `bins`. Each bin contains the peak absolute amplitude of actual
decoded FL32 audio over that fraction of the *complete* decoded stream. The
callback PTS belongs to the audio-output clock, so bin placement uses decoded
frame order normalized over the media duration after EOS. At 16x, VLC emits
about 1/16 the frames of normal playback; this is a real sampled envelope,
not sample-perfect peak capture. A failed/incomplete run writes no JSON and
exits nonzero. It is safe to cancel by killing the helper process.

The helper accepts only regular local files up to 1 GiB, finite duration up
to eight minutes, and enforces a 30-second wall deadline plus a fixed 512 KiB
chunk allocation. The Qt model also gates on local file, duration and size,
checks JSON shape and duration, and caches at most eight items in memory by
canonical path, size and modification time. Network streams, unknown duration
and failures fall back to the existing seek slider.

Proof in ignored `build-m3/waveform`:

| Input | Result |
| --- | --- |
| 1.98-second local WAV | 512 bins, 7,200 decoded frames at 16x, 0.10 s wall |
| 120-second AAC/H.264 fixture (`--no-video`) | 512 bins, 360,000 decoded frames, 7.56 s wall |
| 180-second local WAV with a one-second opening tone | 512 bins, 542,400 decoded frames, 11.22 s wall; only first six bins nonzero |

The integrated Qt build and waveform rendering were verified in the native
Linux application; Windows execution remains unverified. The Canvas component subclasses `SliderBar`, so
it retains its seek action through `Player.position`; it displays the original
slider until a valid envelope is ready.
