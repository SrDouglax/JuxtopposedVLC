/****************************************************************************
 * catalog.cpp : Core and Qt options confirmed for the redesign settings
 ****************************************************************************/
#include "catalog.hpp"

namespace PrefsCatalog
{
static const Option entries[] = {
    {"general", "verbose"}, {"general", "stats"},
    {"interface", "qt-opacity"}, {"interface", "qt-video-autoresize"},
    {"interface", "qt-notification"}, {"interface", "qt-auto-raise"},
    {"privacy", "save-recentplay"}, {"privacy", "restore-playback-pos"},
    {"privacy", "restore-playback-states"}, {"privacy", "metadata-network-access"},
    {"playback", "random"}, {"playback", "loop"}, {"playback", "repeat"},
    {"playback", "start-paused"}, {"playback", "short-jump-size"},
    {"video", "video"}, {"video", "fullscreen"},
    {"video", "video-on-top"}, {"video", "snapshot-format"},
    {"video", "snapshot-preview"},
    {"audio", "audio"}, {"audio", "volume-step"},
    {"audio", "volume-save"}, {"audio", "audio-time-stretch"},
    {"audio", "audio-replay-gain-mode"},
    {"subtitles", "spu"}, {"subtitles", "sub-language"},
    {"subtitles", "sub-autodetect-file"},
    {"subtitles", "sub-autodetect-fuzzy"}, {"subtitles", "sub-text-scale"},
    {"controls", "hotkeys-y-wheel-mode"},
    {"controls", "hotkeys-x-wheel-mode"},
    {"library", "media-library"}, {"library", "auto-preparse"},
    {"library", "recursive"}, {"library", "show-hiddenfiles"},
    {"network", "file-caching"}, {"network", "live-caching"},
    {"network", "network-caching"}, {"network", "ipv4-timeout"},
    {"performance", "hw-dec"}, {"performance", "drop-late-frames"},
    {"performance", "clock-jitter"}, {"performance", "high-priority"},
    {"recording", "input-record-path"},
    {"recording", "input-record-native"},
    {"recording", "sout-display"}, {"recording", "sout-audio"},
    {"recording", "sout-video"},
};

const Option *options() { return entries; }
size_t count() { return sizeof(entries) / sizeof(entries[0]); }
}
