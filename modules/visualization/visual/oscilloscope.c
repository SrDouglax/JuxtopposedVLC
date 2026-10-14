/* Copyright (C) 2002-2026 VLC authors and VideoLAN.
 * Scope and VU meter extracted unchanged from effects.c.
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include <vlc_common.h>
#include <vlc_picture.h>
#include <vlc_block.h>
#include <math.h>
#include "visual.h"
#include "oscilloscope.h"
#define GRAD_ANGLE_MIN 0.2
#define GRAD_ANGLE_MAX 0.5
#define GRAD_INCR 0.01

/*****************************************************************************
 * scope_Run: scope effect
 *****************************************************************************/
int scope_Run(visual_effect_t * p_effect, vlc_object_t *p_aout,
                     const block_t * p_buffer , picture_t * p_picture)
{
    VLC_UNUSED(p_aout);

    int i_index;
    float *p_sample ;
    uint8_t *ppp_area[2][3];

    for( i_index = 0 ; i_index < 2 ; i_index++ )
    {
        for( int j = 0 ; j < 3 ; j++ )
        {
            ppp_area[i_index][j] =
                p_picture->p[j].p_pixels + (i_index * 2 + 1) * p_picture->p[j].i_lines
                / 4 * p_picture->p[j].i_pitch;
        }
    }

    for( i_index = 0, p_sample = (float *)p_buffer->p_buffer;
            i_index < __MIN( p_effect->i_width, (int)p_buffer->i_nb_samples );
            i_index++ )
    {
        int8_t i_value;

        /* Left channel */
        i_value =  p_sample[p_effect->i_idx_left] * 127;
        *(ppp_area[0][0]
                + p_picture->p[0].i_pitch * i_index / p_effect->i_width
                + p_picture->p[0].i_lines * i_value / 512
                * p_picture->p[0].i_pitch) = 0xbf;
        *(ppp_area[0][1]
                + p_picture->p[1].i_pitch * i_index / p_effect->i_width
                + p_picture->p[1].i_lines * i_value / 512
                * p_picture->p[1].i_pitch) = 0xff;


        /* Right channel */
        i_value = p_sample[p_effect->i_idx_right] * 127;
        *(ppp_area[1][0]
                + p_picture->p[0].i_pitch * i_index / p_effect->i_width
                + p_picture->p[0].i_lines * i_value / 512
                * p_picture->p[0].i_pitch) = 0x9f;
        *(ppp_area[1][2]
                + p_picture->p[2].i_pitch * i_index / p_effect->i_width
                + p_picture->p[2].i_lines * i_value / 512
                * p_picture->p[2].i_pitch) = 0xdd;

        p_sample += p_effect->i_nb_chans;
    }
    return 0;
}


/*****************************************************************************
 * vuMeter_Run: vu meter effect
 *****************************************************************************/
int vuMeter_Run(visual_effect_t * p_effect, vlc_object_t *p_aout,
                       const block_t * p_buffer , picture_t * p_picture)
{
    VLC_UNUSED(p_aout);
    float i_value_l = 0;
    float i_value_r = 0;

    /* Compute the peak values */
    for ( unsigned i = 0 ; i < p_buffer->i_nb_samples; i++ )
    {
        const float *p_sample = (float *)p_buffer->p_buffer;
        float ch;

        ch = p_sample[p_effect->i_idx_left] * 256;
        if (ch > i_value_l)
            i_value_l = ch;

        ch = p_sample[p_effect->i_idx_right] * 256;
        if (ch > i_value_r)
            i_value_r = ch;

        p_sample += p_effect->i_nb_chans;
    }

    i_value_l = fabsf(i_value_l);
    i_value_r = fabsf(i_value_r);

    /* Stay under maximum value admitted */
    if ( i_value_l > 200 * M_PI_2 )
        i_value_l = 200 * M_PI_2;
    if ( i_value_r > 200 * M_PI_2 )
        i_value_r = 200 * M_PI_2;

    float *i_value;

    if( !p_effect->p_data )
    {
        /* Allocate memory to save hand positions */
        p_effect->p_data = vlc_alloc( 2, sizeof(float) );
        i_value = p_effect->p_data;
        i_value[0] = i_value_l;
        i_value[1] = i_value_r;
    }
    else
    {
        /* Make the hands go down slowly if the current values are slower
           than the previous */
        i_value = p_effect->p_data;

        if ( i_value_l > i_value[0] - 6 )
            i_value[0] = i_value_l;
        else
            i_value[0] = i_value[0] - 6;

        if ( i_value_r > i_value[1] - 6 )
            i_value[1] = i_value_r;
        else
            i_value[1] = i_value[1] - 6;
    }

    int x, y;
    float teta;
    float teta_grad;

    int start_x = p_effect->i_width / 2 - 120; /* i_width.min = 532 (visual.c) */

    for ( int j = 0; j < 2; j++ )
    {
        /* Draw the two scales */
        int k = 0;
        teta_grad = GRAD_ANGLE_MIN;
        for ( teta = -M_PI_4; teta <= M_PI_4; teta = teta + 0.003 )
        {
            for ( unsigned i = 140; i <= 150; i++ )
            {
                y = i * cos(teta) + 20;
                x = i * sin(teta) + start_x + 240 * j;
                /* Compute the last color for the gradation */
                if (teta >= teta_grad + GRAD_INCR && teta_grad <= GRAD_ANGLE_MAX)
                {
                    teta_grad = teta_grad + GRAD_INCR;
                    k = k + 5;
                }
                *(p_picture->p[0].p_pixels +
                        (p_picture->p[0].i_lines - y - 1 ) * p_picture->p[0].i_pitch
                        + x ) = 0x45;
                *(p_picture->p[1].p_pixels +
                        (p_picture->p[1].i_lines - y / 2 - 1 ) * p_picture->p[1].i_pitch
                        + x / 2 ) = 0x0;
                *(p_picture->p[2].p_pixels +
                        (p_picture->p[2].i_lines - y / 2 - 1 ) * p_picture->p[2].i_pitch
                        + x / 2 ) = 0x4D + k;
            }
        }

        /* Draw the two hands */
        teta = (float)i_value[j] / 200 - M_PI_4;
        for ( int i = 0; i <= 150; i++ )
        {
            y = i * cos(teta) + 20;
            x = i * sin(teta) + start_x + 240 * j;
            *(p_picture->p[0].p_pixels +
                    (p_picture->p[0].i_lines - y - 1 ) * p_picture->p[0].i_pitch
                    + x ) = 0xAD;
            *(p_picture->p[1].p_pixels +
                    (p_picture->p[1].i_lines - y / 2 - 1 ) * p_picture->p[1].i_pitch
                    + x / 2 ) = 0xFC;
            *(p_picture->p[2].p_pixels +
                    (p_picture->p[2].i_lines - y / 2 - 1 ) * p_picture->p[2].i_pitch
                    + x / 2 ) = 0xAC;
        }

        /* Draw the hand bases */
        for ( teta = -M_PI_2; teta <= M_PI_2 + 0.01; teta = teta + 0.003 )
        {
            for ( int i = 0; i < 10; i++ )
            {
                y = i * cos(teta) + 20;
                x = i * sin(teta) + start_x + 240 * j;
                *(p_picture->p[0].p_pixels +
                        (p_picture->p[0].i_lines - y - 1 ) * p_picture->p[0].i_pitch
                        + x ) = 0xFF;
                *(p_picture->p[1].p_pixels +
                        (p_picture->p[1].i_lines - y / 2 - 1 ) * p_picture->p[1].i_pitch
                        + x / 2 ) = 0x80;
                *(p_picture->p[2].p_pixels +
                        (p_picture->p[2].i_lines - y / 2 - 1 ) * p_picture->p[2].i_pitch
                        + x / 2 ) = 0x80;
            }
        }

    }

    return 0;
}

/* Draw the actual PCM min/max envelope in each output column. No synthetic
 * samples or time-dependent randomness: silence is a flat centre line. */
int waveform_Run(visual_effect_t *effect, vlc_object_t *aout,
                 const block_t *block, picture_t *picture)
{
    VLC_UNUSED(aout);
    const int width = __MIN(effect->i_width, picture->p[0].i_visible_pitch);
    const int height = __MIN(effect->i_height, picture->p[0].i_visible_lines);
    const unsigned channels = effect->i_nb_chans;
    const size_t frames = block->i_nb_samples;
    if (width <= 0 || height <= 0 || !channels || !frames ||
        frames > block->i_buffer / sizeof(float) / channels)
        return 0;
    const float *pcm = (const float *)block->p_buffer;
    for (int x = 0; x < width; ++x) {
        const size_t begin = (size_t)x * frames / width;
        const size_t end = __MIN(frames, __MAX(begin + 1, (size_t)(x + 1) * frames / width));
        float low = 1.f, high = -1.f;
        for (size_t frame = begin; frame < end; ++frame) {
            float value = 0.f;
            for (unsigned channel = 0; channel < channels; ++channel)
                value += pcm[frame * channels + channel] / channels;
            if (!isfinite(value)) value = 0.f;
            value = __MAX(-1.f, __MIN(1.f, value));
            low = fminf(low, value);
            high = fmaxf(high, value);
        }
        int top = (int)((1.f - high) * (height - 1) / 2.f);
        int bottom = (int)((1.f - low) * (height - 1) / 2.f);
        for (int y = top; y <= bottom; ++y) {
            picture->p[0].p_pixels[y * picture->p[0].i_pitch + x] = 126;
            for (int plane = 1; plane < 3; ++plane) {
                if (y / 2 < picture->p[plane].i_visible_lines &&
                    x / 2 < picture->p[plane].i_visible_pitch)
                    picture->p[plane].p_pixels[(y / 2) * picture->p[plane].i_pitch + x / 2]
                        = plane == 1 ? 71 : 173;
            }
        }
    }
    return 0;
}
