/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#include "player_controller.hpp"
#include "player_controller_p.hpp"
#include <vlc_input_item.h>
#include <vlc_player.h>
#include <cstdlib>

QString PlayerController::getPlaylistName() const
{
    vlc_player_locker lock{getPlayer()};
    input_item_t *item = vlc_player_GetCurrentMedia(getPlayer());
    if (!item) return {};
    char *name = input_item_GetMetaExtra(item, "vlc-source-playlist");
    const QString result = name ? QString::fromUtf8(name) : QString();
    free(name);
    return result;
}

void PlayerController::jumpSeconds(int seconds)
{
    Q_D(PlayerController);
    vlc_player_locker lock{getPlayer()};
    if (!d->isCurrentItemSynced()) return;
    vlc_player_JumpTime(getPlayer(), vlc_tick_from_sec(seconds));
}

QString PlayerController::getPlaylistId() const
{
    vlc_player_locker lock{getPlayer()};
    input_item_t *item = vlc_player_GetCurrentMedia(getPlayer());
    if (!item) return {};
    char *id = input_item_GetMetaExtra(item, "vlc-source-playlist-id");
    const QString result = id ? QString::fromUtf8(id) : QString();
    free(id);
    return result;
}
