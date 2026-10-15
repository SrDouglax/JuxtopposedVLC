/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#pragma once
#include "qt.hpp"
#include "player/player_controller.hpp"
#include <vlc_variables.h>

// Audio outputs may restore their own previous volume. Apply the user's fixed
// startup preference once the first output reports a usable native volume.
inline void initializeStartupVolume(qt_intf_t *intf)
{
    if (var_InheritBool(intf->intf, "volume-save")) return;
    auto *player = intf->p_mainPlayerController;
    const float volume = var_InheritInteger(intf->intf, "qt-startup-volume") / 100.f;
    // Outputs such as PulseAudio accept a pending volume before their first
    // stream reports one. Do not wait for that report to initialize them.
    player->setVolume(volume);
    if (player->getVolume() >= 0.f) {
        return;
    }
    QObject::connect(player, &PlayerController::volumeChanged, player,
        [player, volume, applied = false](float current) mutable {
            if (applied || current < 0.f) return;
            applied = true;
            player->setVolume(volume);
        });
}
