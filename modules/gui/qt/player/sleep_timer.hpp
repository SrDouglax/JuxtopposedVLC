/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License, version 2 or any
 * later version. See the COPYING file for details.
 *****************************************************************************/

#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QPointer>
#include <QTimer>

class PlayerController;
class PlaylistController;
Q_MOC_INCLUDE("player/player_controller.hpp")
Q_MOC_INCLUDE("playlist/playlist_controller.hpp")

class SleepTimerController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(PlayerController* player READ player WRITE setPlayer NOTIFY playerChanged FINAL)
    Q_PROPERTY(PlaylistController* playlist READ playlist WRITE setPlaylist NOTIFY playlistChanged FINAL)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged FINAL)
    Q_PROPERTY(int remainingSeconds READ remainingSeconds NOTIFY remainingSecondsChanged FINAL)
    Q_PROPERTY(Action action READ action NOTIFY actionChanged FINAL)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged FINAL)

public:
    enum Action { Stop, Pause };
    Q_ENUM(Action)

    explicit SleepTimerController(QObject* parent = nullptr);

    PlayerController* player() const;
    void setPlayer(PlayerController* player);
    PlaylistController* playlist() const;
    void setPlaylist(PlaylistController* playlist);
    bool active() const { return m_active; }
    int remainingSeconds() const { return m_remainingSeconds; }
    Action action() const { return m_action; }
    QString error() const { return m_error; }

    Q_INVOKABLE bool start(int seconds, Action action);
    Q_INVOKABLE void cancel();

signals:
    void playerChanged();
    void playlistChanged();
    void activeChanged();
    void remainingSecondsChanged();
    void actionChanged();
    void errorChanged();
    void expired(Action action);

private:
    void tick();
    void setError(const QString& error);
    void setRemainingSeconds(int seconds);

    QPointer<PlayerController> m_player;
    QPointer<PlaylistController> m_playlist;
    QMetaObject::Connection m_inputConnection;
    QTimer m_tick;
    QElapsedTimer m_elapsed;
    int m_durationSeconds = 0;
    int m_remainingSeconds = 0;
    Action m_action = Stop;
    bool m_active = false;
    QString m_error;
};
