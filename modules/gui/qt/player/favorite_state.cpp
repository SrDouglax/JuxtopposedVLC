/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "favorite_state.hpp"
#include "maininterface/mainctx.hpp"
#include "medialibrary/medialib.hpp"
#include "medialibrary/mlhelper.hpp"

#include <vlc_media_library.h>

FavoriteState::FavoriteState(QObject *parent) : QObject(parent) {}

void FavoriteState::setCtx(MainCtx *ctx)
{
    if (m_ctx == ctx)
        return;
    m_ctx = ctx;
    emit ctxChanged();
    refresh();
}

void FavoriteState::setUrl(const QUrl &url)
{
    if (m_url == url)
        return;
    m_url = url;
    emit urlChanged();
    refresh();
}

void FavoriteState::refresh()
{
    const quint64 generation = ++m_generation;
    m_available = false;
    m_favorite = false;
    m_busy = false;
    m_error.clear();
    emit stateChanged();
    if (!m_ctx || !m_ctx->getMediaLibrary() || m_url.isEmpty())
        return;

    const QString mrl = m_url.toString(QUrl::FullyEncoded);
    struct Result { bool found = false; bool favorite = false; };
    m_ctx->getMediaLibrary()->runOnMLThread<Result>(this,
        [mrl](vlc_medialibrary_t *ml, Result &result) {
            ml_unique_ptr<vlc_ml_media_t> media{vlc_ml_get_media_by_mrl(ml, qtu(mrl))};
            if (media) {
                result.found = true;
                result.favorite = media->b_is_favorite;
            }
        },
        [this, generation](quint64, Result &result) {
            if (generation != m_generation)
                return;
            m_available = result.found;
            m_favorite = result.favorite;
            emit stateChanged();
        });
}

void FavoriteState::toggle()
{
    if (!m_available || m_busy || !m_ctx || !m_ctx->getMediaLibrary())
        return;
    const QString mrl = m_url.toString(QUrl::FullyEncoded);
    const bool wanted = !m_favorite;
    const quint64 generation = ++m_generation;
    m_busy = true;
    m_error.clear();
    emit stateChanged();
    struct Result { bool found = false; bool success = false; bool favorite = false; };
    m_ctx->getMediaLibrary()->runOnMLThread<Result>(this,
        [mrl, wanted](vlc_medialibrary_t *ml, Result &result) {
            ml_unique_ptr<vlc_ml_media_t> media{vlc_ml_get_media_by_mrl(ml, qtu(mrl))};
            if (!media)
                return;
            result.found = true;
            result.success = vlc_ml_media_set_favorite(ml, media->i_id, wanted) == VLC_SUCCESS;
            result.favorite = wanted;
        },
        [this, generation](quint64, Result &result) {
            if (generation != m_generation)
                return;
            m_busy = false;
            m_available = result.found;
            if (result.success)
                m_favorite = result.favorite;
            else
                m_error = tr("Could not update this favorite.");
            emit stateChanged();
        });
}

MainCtx *FavoriteState::ctx() const { return m_ctx; }
