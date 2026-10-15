/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#if HAVE_CONFIG_H
# include "config.h"
#endif
#include "medialib.hpp"
#include <utility>
#include "mlhelper.hpp"
#include "playlist/playlist_controller.hpp"
#include "util/shared_input_item.hpp"

void MediaLib::playFromPlaylist(const MLItemId& itemId, const MLItemId& playlistId)
{
    if (playlistId.type != VLC_ML_PARENT_PLAYLIST) {
        addAndPlay(itemId);
        return;
    }
    struct Context { QVector<vlc::playlist::Media> medias; };
    runOnMLThread<Context>(this,
        [itemId, playlistId](vlc_medialibrary_t* ml, Context& ctx) {
            SharedInputItem item(vlc_ml_get_input_item(ml, itemId.id), false);
            ml_unique_ptr<vlc_ml_playlist_t> source(vlc_ml_get_playlist(ml, playlistId.id));
            if (!item || !source) return;
            vlc::playlist::Media media(item.get());
            input_item_SetMetaExtra(media.raw(), "vlc-source-playlist", source->psz_name ? source->psz_name : "");
            input_item_SetMetaExtra(media.raw(), "vlc-source-playlist-id", playlistId.toString().toUtf8().constData());
            ctx.medias.push_back(std::move(media));
        },
        [this](quint64, Context& ctx) {
            if (!ctx.medias.empty()) m_playlistController->append(ctx.medias, true);
        });
}
