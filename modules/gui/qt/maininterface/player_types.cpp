/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include "mainui.hpp"
#include "player/player_controlbar_model.hpp"
#include "player/control_list_model.hpp"
#include "player/control_list_filter.hpp"
#include "dialogs/toolbar/controlbar_profile_model.hpp"
#include "dialogs/toolbar/controlbar_profile.hpp"
#include "player/media_details.hpp"
#include "player/favorite_state.hpp"

void MainUI::registerPlayerControlTypes()
{
    {
        const char* uri = "VLC.PlayerControls";
        const int versionMajor = 1;
        const int versionMinor = 0;

        qmlRegisterType<PlayerMediaDetails>(uri, versionMajor, versionMinor, "PlayerMediaDetails");
        qmlRegisterType<FavoriteState>(uri, versionMajor, versionMinor, "FavoriteState");
        // @uri VLC.PlayerControls
        qmlRegisterUncreatableType<ControlbarProfileModel>(uri, versionMajor, versionMinor, "ControlbarProfileModel", "");
        qmlRegisterUncreatableType<ControlbarProfile>(uri, versionMajor, versionMinor, "ControlbarProfile", "");
        qmlRegisterUncreatableType<PlayerControlbarModel>(uri, versionMajor, versionMinor, "PlayerControlbarModel", "");
        qmlRegisterUncreatableType<ControlListModel>( uri, versionMajor, versionMinor, "ControlListModel", "" );
        qmlRegisterType<ControlListFilter>(uri, versionMajor, versionMinor, "ControlListFilter");
        qmlRegisterSingletonType(uri, versionMajor, versionMinor, "PlayerListModel", PlayerControlbarModel::getPlaylistIdentifierListModel);


        qmlRegisterModule(uri, versionMajor, versionMinor);
        qmlProtectModule(uri, versionMajor);
    }

}
