/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License, version 2 or any
 * later version. See the COPYING file for details.
 *****************************************************************************/

#include "sleep_timer.hpp"

#include "player/player_controller.hpp"
#include "playlist/playlist_controller.hpp"

#include <algorithm>

SleepTimerController::SleepTimerController(QObject* parent)
    : QObject(parent)
{
    m_tick.setInterval(250);
    connect(&m_tick, &QTimer::timeout, this, &SleepTimerController::tick);
}

PlayerController* SleepTimerController::player() const
{
    return m_player;
}

void SleepTimerController::setPlayer(PlayerController* player)
{
    if (m_player == player)
        return;
    cancel();
    disconnect(m_inputConnection);
    m_player = player;
    if (m_player) {
        m_inputConnection = connect(m_player, &PlayerController::inputChanged,
                                    this, [this](bool) {
            if (!m_active)
                return;
            cancel();
            setError(tr("Sleep timer canceled because the media changed."));
        });
    }
    emit playerChanged();
}

vlc::playlist::PlaylistController* SleepTimerController::playlist() const
{
    return m_playlist;
}

void SleepTimerController::setPlaylist(vlc::playlist::PlaylistController* playlist)
{
    if (m_playlist == playlist)
        return;
    cancel();
    m_playlist = playlist;
    emit playlistChanged();
}

void SleepTimerController::setError(const QString& error)
{
    if (m_error == error)
        return;
    m_error = error;
    emit errorChanged();
}

void SleepTimerController::setRemainingSeconds(int seconds)
{
    if (m_remainingSeconds == seconds)
        return;
    m_remainingSeconds = seconds;
    emit remainingSecondsChanged();
}

bool SleepTimerController::start(int seconds, Action action)
{
    setError({});
    if (!m_player || !m_playlist || !m_player->isStarted()) {
        setError(tr("Start playback before setting a sleep timer."));
        return false;
    }
    // Limit both the UI and direct QML callers to a practical 24 hours.
    if (seconds < 1 || seconds > 24 * 60 * 60 ||
        (action != Stop && action != Pause)) {
        setError(tr("Choose a duration between one second and 24 hours."));
        return false;
    }

    m_tick.stop();
    m_durationSeconds = seconds;
    if (m_action != action) {
        m_action = action;
        emit actionChanged();
    }
    setRemainingSeconds(seconds);
    m_elapsed.start();
    if (!m_active) {
        m_active = true;
        emit activeChanged();
    }
    m_tick.start();
    return true;
}

void SleepTimerController::cancel()
{
    if (!m_active)
        return;
    m_tick.stop();
    m_elapsed.invalidate();
    m_durationSeconds = 0;
    m_active = false;
    setRemainingSeconds(0);
    emit activeChanged();
    setError({});
}

void SleepTimerController::tick()
{
    if (!m_active)
        return;
    if (!m_player || !m_playlist || !m_player->isStarted()) {
        cancel();
        setError(tr("Sleep timer canceled because playback ended."));
        return;
    }

    const qint64 millisecondsLeft = qint64(m_durationSeconds) * 1000 - m_elapsed.elapsed();
    if (millisecondsLeft > 0) {
        setRemainingSeconds(int((millisecondsLeft + 999) / 1000));
        return;
    }

    const Action finishingAction = m_action;
    cancel();
    if (finishingAction == Stop)
        m_playlist->stop();
    else
        m_playlist->pause();
    emit expired(finishingAction);
}
