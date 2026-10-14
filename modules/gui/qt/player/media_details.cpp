/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "media_details.hpp"
#include "maininterface/mainctx.hpp"
#include "qt.hpp"

#include <vlc_player.h>
#include <vlc_input_item.h>
#include <vlc_cxx_helpers.hpp>

#include <cstdlib>

using vlc_player_locker = vlc_locker<vlc_player_t, vlc_player_Lock, vlc_player_Unlock>;

PlayerMediaDetails::PlayerMediaDetails(QObject *parent) : QObject(parent) {}

void PlayerMediaDetails::setCtx(MainCtx *ctx)
{
    if (m_ctx == ctx)
        return;
    m_ctx = ctx;
    emit ctxChanged();
    refresh();
}

void PlayerMediaDetails::setUrl(const QUrl &url)
{
    if (m_url == url)
        return;
    m_url = url;
    emit urlChanged();
    refresh();
}

void PlayerMediaDetails::refresh()
{
    QString resolution;
    QString frameRate;
    if (m_ctx && m_ctx->getIntf() && m_ctx->getIntf()->p_player && !m_url.isEmpty()) {
        vlc_player_t *player = m_ctx->getIntf()->p_player;
        vlc_player_locker lock{player};
        input_item_t *media = vlc_player_GetCurrentMedia(player);
        char *mrl = media ? input_item_GetURI(media) : nullptr;
        const bool matches = mrl && QUrl::fromEncoded(QByteArray(mrl)) == m_url;
        free(mrl);
        if (matches) {
            const vlc_player_track *track = vlc_player_GetSelectedTrack(player, VIDEO_ES);
            if (track) {
                const video_format_t &video = track->fmt.video;
                const unsigned width = video.i_visible_width ? video.i_visible_width : video.i_width;
                const unsigned height = video.i_visible_height ? video.i_visible_height : video.i_height;
                if (width && height)
                    resolution = QStringLiteral("%1×%2").arg(width).arg(height);
                if (video.i_frame_rate && video.i_frame_rate_base) {
                    const double fps = double(video.i_frame_rate) / video.i_frame_rate_base;
                    frameRate = QString::number(fps, 'f', 2) + QStringLiteral(" fps");
                }
            }
        }
    }
    if (resolution == m_resolution && frameRate == m_frameRate)
        return;
    m_resolution = resolution;
    m_frameRate = frameRate;
    emit detailsChanged();
}

MainCtx *PlayerMediaDetails::ctx() const { return m_ctx; }
