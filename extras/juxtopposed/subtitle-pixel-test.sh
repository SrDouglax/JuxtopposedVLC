#!/bin/bash
# Render actual FreeType subtitles through VLC's native transcoder.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
builder=${M0_BUILD_CONTAINER:-juxtopposed-vlc-m0-linux}
out="$root/build-m3/pixel-probe"
mkdir -p "$out"/{config,data,cache}
docker start "$builder" >/dev/null
docker update --memory 2g --memory-swap 2g --cpus 1 "$builder" >/dev/null
trap 'docker stop "$builder" >/dev/null' EXIT
docker exec "$builder" bash -c '
    set -e
    cd /work/build-m0/linux
    export XDG_CONFIG_HOME=/work/build-m3/pixel-probe/config XDG_DATA_HOME=/work/build-m3/pixel-probe/data XDG_CACHE_HOME=/work/build-m3/pixel-probe/cache
    export LD_LIBRARY_PATH=/work/build-m0/deps/lib
    out=/work/build-m3/pixel-probe
    printf "1\n00:00:00,001 --> 00:00:05,000\nMMMMMMMM\n" > "$out/text.srt"
    for resolution in 640x360 1280x720; do
        nice -n19 ionice -c3 ffmpeg -y -hide_banner -loglevel error -f lavfi -i "color=c=black:s=$resolution:r=25" -t 1.2 -c:v mpeg4 -q:v 4 "$out/$resolution.mp4"
        for size in 32 64; do
            [[ "$resolution" != 1280x720 || "$size" != 64 ]] || continue
            name="$resolution-$size"
            timeout 20s nice -n19 ionice -c3 ./vlc --intf=dummy --no-one-instance --no-hw-dec --no-audio --no-video-title-show --no-sub-autodetect-file \
                --freetype-absolute-size="$size" --sub-text-scale=100 --freetype-font="DejaVu Sans" --no-freetype-bold --freetype-outline-thickness=0 --freetype-shadow-opacity=0 \
                --sub-file="$out/text.srt" --sout="#transcode{vcodec=mp2v,vb=4000,soverlay}:std{access=file,mux=ts,dst=$out/$name.ts}" \
                --play-and-exit "$out/$resolution.mp4" >"$out/$name.log" 2>&1
            nice -n19 ionice -c3 ffmpeg -y -hide_banner -loglevel error -ss 0.3 -i "$out/$name.ts" -frames:v 1 "$out/$name.png"
        done
    done
'
python3 - "$out" <<'PY'
import json,sys
from pathlib import Path
from PIL import Image
out=Path(sys.argv[1]); boxes={}
for name in ['640x360-32','640x360-64','1280x720-32']:
    image=Image.open(out/(name+'.png')).convert('RGB')
    mask=image.point(lambda value: 255 if value>200 else 0).convert('L')
    box=mask.getbbox()
    assert box, f'No rendered subtitle in {name}'
    boxes[name]={'box':box,'width':box[2]-box[0],'height':box[3]-box[1]}
small=boxes['640x360-32']['height']; large=boxes['640x360-64']['height']; other=boxes['1280x720-32']['height']
assert 1.8<large/small<2.2, boxes
assert abs(small-other)<=1, boxes
result={'result':'PASS','renderer':'native VLC transcoder + FreeType','glyphs':boxes,'em_sizes':[32,64], 'proof':'Doubling the configured pixel size doubles visible glyph height; the same pixel size stays constant across video resolutions.'}
(out/'result.json').write_text(json.dumps(result,indent=2)+'\n'); print(json.dumps(result))
PY
