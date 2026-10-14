/* Copyright (C) 2026 VLC authors and VideoLAN. LGPL version 2.1 or later. */
/* Standalone regression test: compile with oscilloscope.c and --gc-sections. */
#include <vlc_common.h>
#include <vlc_block.h>
#include <vlc_picture.h>
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include "modules/visualization/visual/visual.h"
#include "modules/visualization/visual/oscilloscope.h"

int main(void)
{
    enum { width = 32, height = 18, guard = 16, frames = 64 };
    uint8_t storage[3][width * height + 2 * guard];
    picture_t picture = {0};
    for (int plane = 0; plane < 3; ++plane) {
        memset(storage[plane], 0xa5, sizeof(storage[plane]));
        const int w = plane ? width / 2 : width;
        const int h = plane ? height / 2 : height;
        picture.p[plane] = (plane_t){.p_pixels = storage[plane] + guard,
            .i_pitch = w, .i_visible_pitch = w, .i_lines = h, .i_visible_lines = h};
        memset(picture.p[plane].p_pixels, 0, w * h);
    }
    float samples[frames * 2] = {0};
    block_t block = {.p_buffer = (uint8_t *)samples, .i_buffer = sizeof(samples),
                     .i_nb_samples = frames};
    visual_effect_t effect = {.i_width = width, .i_height = height, .i_nb_chans = 2};
    waveform_Run(&effect, NULL, &block, &picture);
    unsigned silence = 0;
    for (int i = 0; i < width * height; ++i)
        silence += picture.p[0].p_pixels[i] != 0;
    assert(silence == width);
    for (int frame = 0; frame < frames; ++frame) {
        samples[frame * 2] = samples[frame * 2 + 1] = frame % 2 ? 1.f : -1.f;
    }
    waveform_Run(&effect, NULL, &block, &picture);
    for (int i = 0; i < width * height; ++i) assert(picture.p[0].p_pixels[i] == 126);
    samples[0] = NAN; samples[1] = INFINITY;
    effect.i_width = width * 4; effect.i_height = height * 4;
    waveform_Run(&effect, NULL, &block, &picture);
    for (int plane = 0; plane < 3; ++plane) {
        const int size = picture.p[plane].i_pitch * picture.p[plane].i_lines;
        for (int i = 0; i < guard; ++i) {
            assert(storage[plane][i] == 0xa5);
            assert(storage[plane][guard + size + i] == 0xa5);
        }
    }
    memset(picture.p[0].p_pixels, 0, width * height);
    block.i_nb_samples = frames + 1; // rejects a truncated PCM block
    waveform_Run(&effect, NULL, &block, &picture);
    for (int i = 0; i < width * height; ++i) assert(picture.p[0].p_pixels[i] == 0);
    puts("PASS: silence, PCM envelope, nonfinite samples, bounds, truncated block");
}
