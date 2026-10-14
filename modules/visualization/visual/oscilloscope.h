/* Copyright (C) 2026 VLC authors and VideoLAN. LGPL version 2.1 or later. */
#ifndef VLC_VISUAL_OSCILLOSCOPE_H
#define VLC_VISUAL_OSCILLOSCOPE_H
int scope_Run(visual_effect_t *, vlc_object_t *, const block_t *, picture_t *);
int vuMeter_Run(visual_effect_t *, vlc_object_t *, const block_t *, picture_t *);
int waveform_Run(visual_effect_t *, vlc_object_t *, const block_t *, picture_t *);
#endif
