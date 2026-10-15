/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include "mlplaylistlistmodel.hpp"
#include "mlhelper.hpp"
#include "qt.hpp"
#include "playlist/playlist_controller.hpp"
#include <QSettings>
#include <QFileInfo>

namespace {
std::unique_ptr<QSettings> playlistSettings()
{
    return std::make_unique<QSettings>(
#ifdef _WIN32
        QSettings::IniFormat,
#else
        QSettings::NativeFormat,
#endif
        QSettings::UserScope, "vlc", "vlc-qt-interface");
}
QString coverKey(qint64 id) { return QStringLiteral("redesign/playlist-covers/%1").arg(id); }
void appendMediaIntoPlaylist(vlc_medialibrary_t* ml, int64_t playlistId, const std::vector<MLItemId>& itemList)
{
    vlc_ml_query_params_t query = vlc_ml_query_params_create();

    for (auto itemId : itemList)
    {
        // NOTE: When we have a parent it's a collection of media(s).
        if (itemId.type != VLC_ML_PARENT_UNKNOWN)
        {
            ml_unique_ptr<vlc_ml_media_list_t> list;

            list.reset(vlc_ml_list_media_of(ml, &query, itemId.type, itemId.id));

            if (!list)
                continue;

            for (const vlc_ml_media_t & media : ml_range_iterate<vlc_ml_media_t>(list))
                vlc_ml_playlist_append(ml, playlistId, &media.i_id, 1);
        }
        // NOTE: Otherwise we add the media directly.
        else
            vlc_ml_playlist_append(ml, playlistId, &itemId.id, 1);
    }
}

}

QString MLPlaylistListModel::customCover(qint64 id) const
{
    const QUrl url(playlistSettings()->value(coverKey(id)).toString());
    return url.isLocalFile() && QFileInfo::exists(url.toLocalFile()) ? url.toString() : QString();
}

/* Q_INVOKABLE */ void MLPlaylistListModel::create(const QString & name, const QVariantList& initialItems, const QUrl& cover)
{
    assert(m_mediaLib);

    struct Ctx {
        MLItemId createdPlaylistId;
    };

    setTransactionPending(true);

    m_mediaLib->runOnMLThread<Ctx>(this,
    //ML thread
    [name](vlc_medialibrary_t* ml, Ctx& ctx)
    {
        vlc_ml_playlist_t * playlist = vlc_ml_playlist_create(ml, qtu(name));
        if (playlist)
        {
            ctx.createdPlaylistId = MLItemId(playlist->i_id, VLC_ML_PARENT_UNKNOWN);
            vlc_ml_playlist_release(playlist);
        }
    },
    [this, initialItems, cover](quint64, const Ctx& ctx) {
        endTransaction(); // this is intentionally called here and not after `append()`

        if (ctx.createdPlaylistId.id)
        {
            if (cover.isLocalFile()) {
                auto settings = playlistSettings();
                settings->setValue(coverKey(ctx.createdPlaylistId.id), cover.toString(QUrl::FullyEncoded));
            }
            if (!initialItems.isEmpty()) append(ctx.createdPlaylistId, initialItems);
        }
        emit creationFinished(ctx.createdPlaylistId.id != 0);
    });
}

/* Q_INVOKABLE */ void MLPlaylistListModel::append(const MLItemId     & playlistId,
                                                   const QVariantList & ids)
{
    assert(m_mediaLib);
    assert(ids.size() > 0);

    if (unlikely(!setTransactionPending(true)))
        return;

    m_mediaLib->runOnMLThread(this,
    //ML thread
    [playlistId, ids](vlc_medialibrary_t* ml) {
        std::vector<MLItemId> mlItemIdVector;
        mlItemIdVector.reserve(ids.size());

        if (ids.at(0).canConvert<MLItemId>())
        {
            for (const QVariant& id : ids)
            {
                // Do not mix types. This is currently not possible
                // in the application anyway.
                assert(id.canConvert<MLItemId>());

                mlItemIdVector.push_back(id.value<MLItemId>());
            }

            appendMediaIntoPlaylist(ml, playlistId.id, mlItemIdVector);
        }
        else
        {
            QVector<vlc::playlist::Media> medias = vlc::playlist::toMediaList(ids);

            for (const auto& media : medias)
            {
                assert(media.raw());

                const char * const uri = media.raw()->psz_uri;

                vlc_ml_media_t * ml_media = vlc_ml_get_media_by_mrl(ml, uri);

                if (ml_media == nullptr)
                {
                    ml_media = vlc_ml_new_external_media(ml, uri);
                    if (ml_media == nullptr)
                        continue;
                }

                vlc_ml_playlist_append(ml, playlistId.id, &ml_media->i_id, 1);
                vlc_ml_media_release(ml_media);
            }
        }
    },
    //UI thread
    [this]() {
        endTransaction();
    });
}
