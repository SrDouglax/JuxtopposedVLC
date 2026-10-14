/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#pragma once
#include <QObject>
#include <QPointer>
#include <QVariantList>
#include <QVariantMap>
#include <QStringList>
class PlayerController;
Q_MOC_INCLUDE("player/player_controller.hpp")

class PlayerPanelState : public QObject
{
    Q_OBJECT
    Q_PROPERTY(PlayerController* player READ player WRITE setPlayer NOTIFY changed)
    Q_PROPERTY(bool showStatistics MEMBER m_showStatistics NOTIFY changed)
    Q_PROPERTY(bool showSubtitleTimeline MEMBER m_showSubtitleTimeline NOTIFY changed)
    Q_PROPERTY(QVariantMap statistics READ statistics NOTIFY changed)
    Q_PROPERTY(QVariantList cues READ cues NOTIFY changed)
    Q_PROPERTY(bool timelineAvailable READ timelineAvailable NOTIFY changed)
    Q_PROPERTY(QStringList subtitleSources READ subtitleSources NOTIFY changed)
public:
    explicit PlayerPanelState(QObject* parent = nullptr) : QObject(parent) {}
    PlayerController* player() const;
    void setPlayer(PlayerController* player);
    QVariantMap statistics() const { return m_statistics; }
    QVariantList cues() const { return m_cues; }
    bool timelineAvailable() const { return !m_cues.isEmpty(); }
    QStringList subtitleSources() const { return m_sources; }
    Q_INVOKABLE void reloadCues();
    Q_INVOKABLE QString cueAt(double seconds) const;
signals:
    void changed();
private:
    QPointer<PlayerController> m_player;
    QVariantMap m_statistics;
    QVariantList m_cues;
    QStringList m_sources;
    bool m_showStatistics = false;
    bool m_showSubtitleTimeline = false;
};
