/****************************************************************************
 * catalog.cpp : Core and Qt options confirmed for the redesign settings
 ****************************************************************************/
#include "catalog.hpp"

namespace PrefsCatalog
{
static const Option entries[] = {
    {"general", "verbose"}, {"general", "stats"},
    {"general", "qt-error-dialogs"}, {"general", "qt-updates-notif"},
    {"general", "file-logging"}, {"general", "logfile"},
    {"general", "log-verbose"},
    {"interface", "embedded-video"}, {"interface", "qt-video-autoresize"},
    {"interface", "qt-fullscreen-screennumber"},
    {"interface", "qt-opacity"}, {"interface", "qt-auto-raise"},
    {"interface", "qt-notification"},
    {"privacy", "save-recentplay"}, {"privacy", "restore-playback-pos"},
    {"privacy", "restore-playback-states"}, {"privacy", "metadata-network-access"},
    {"playback", "playlist-autostart"}, {"playback", "rate"},
    {"playback", "preferred-resolution"}, {"playback", "menu-language"},
    {"playback", "audio-track"}, {"playback", "sub-track"},
    {"playback", "repeat"}, {"playback", "loop"}, {"playback", "random"},
    {"playback", "play-and-stop"}, {"playback", "start-paused"},
    {"playback", "short-jump-size"},
    {"video", "video"}, {"video", "fullscreen"},
    {"video", "disable-screensaver"}, {"video", "video-wallpaper"},
    {"video", "video-on-top"}, {"video", "deinterlace"},
    {"video", "deinterlace-mode"}, {"video", "aspect-ratio"},
    {"video", "snapshot-format"}, {"video", "snapshot-preview"},
    {"audio", "audio"}, {"audio", "qt-max-volume"},
    {"audio", "volume-save"}, {"audio", "volume-step"},
    {"audio", "audio-replay-gain-mode"},
    {"audio", "audio-replay-gain-preamp"}, {"audio", "audio-time-stretch"},
    {"subtitles", "spu"}, {"subtitles", "sub-language"},
    {"subtitles", "sub-autodetect-file"},
    {"subtitles", "sub-autodetect-fuzzy"},
    {"subtitles", "sub-autodetect-path"},
    {"subtitles", "sub-text-scale"}, {"subtitles", "sub-delay"},
    {"controls", "hotkeys-y-wheel-mode"},
    {"controls", "hotkeys-x-wheel-mode"},
    {"library", "media-library"}, {"library", "auto-preparse"},
    {"library", "recursive"}, {"library", "show-hiddenfiles"},
    {"network", "file-caching"}, {"network", "disc-caching"},
    {"network", "network-caching"}, {"network", "live-caching"},
    {"network", "ipv4-timeout"},
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
