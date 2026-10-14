/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#include "panel_state.hpp"
#include "player_controller.hpp"
#include "input_models.hpp"
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QTimer>
#include <vlc_input_item.h>
#include <vlc_player.h>

PlayerController* PlayerPanelState::player() const { return m_player; }
void PlayerPanelState::setPlayer(PlayerController* player)
{
    if (m_player == player) return;
    if (m_player) disconnect(m_player, nullptr, this, nullptr);
    m_player = player;
    if (player) {
        connect(player, &PlayerController::statisticsUpdated, this, [this](const input_stats_t& s) {
            m_statistics = {{"decodedVideo", qulonglong(s.i_decoded_video)}, {"displayedVideo", qulonglong(s.i_displayed_pictures)},
                            {"lostVideo", qulonglong(s.i_lost_pictures)}, {"decodedAudio", qulonglong(s.i_decoded_audio)},
                            {"bitrate", s.f_input_bitrate * 8000}};
            emit changed();
        });
        connect(player, &PlayerController::inputChanged, this, [this] {
            m_cues.clear(); m_sources.clear(); m_statistics.clear(); m_showSubtitleTimeline = false;
            emit changed();
            QTimer::singleShot(500, this, &PlayerPanelState::reloadCues);
        });
    }
    reloadCues();
}
void PlayerPanelState::reloadCues()
{
    m_cues.clear(); m_sources.clear();
    if (!m_player) { emit changed(); return; }
    // Never guess between multiple subtitle sources. Only a single external SRT
    // (or a matching companion file) can provide an accurate timeline here.
    QStringList paths;
    auto core = m_player->getPlayer();
    vlc_player_Lock(core);
    auto media = vlc_player_GetCurrentMedia(core);
    if (media) input_item_Hold(media);
    vlc_player_Unlock(core);
    if (media) {
        vlc_mutex_lock(&media->lock);
        for (int i = 0; i < media->i_slaves; ++i) {
            auto slave = media->pp_slaves[i];
            if (slave->i_type == SLAVE_TYPE_SPU) {
                const auto url = QUrl(QString::fromUtf8(slave->psz_uri));
                if (url.isLocalFile())
                    paths << url.toLocalFile();
            }
        }
        vlc_mutex_unlock(&media->lock);
        input_item_Release(media);
    }
    if (paths.isEmpty() && m_player->getUrl().isLocalFile()) {
        const QFileInfo info(m_player->getUrl().toLocalFile());
        const QString path = info.path() + '/' + info.completeBaseName() + ".srt";
        if (QFile::exists(path)) paths << path;
    }
    paths.removeDuplicates();
    m_sources = paths;
    if (paths.size() != 1 || !paths.front().endsWith(".srt", Qt::CaseInsensitive) || m_player->getSubtitleTracks()->rowCount() > 1) { emit changed(); return; }
    QFile file(paths.front());
    if (file.size() > 4 * 1024 * 1024 || !file.open(QIODevice::ReadOnly)) { emit changed(); return; }
    const QString text = QString::fromUtf8(file.readAll()).replace("\r\n", "\n");
    const QRegularExpression pattern("(\\d{2}):(\\d{2}):(\\d{2})[,.:](\\d{3})\\s*-->\\s*(\\d{2}):(\\d{2}):(\\d{2})[,.:](\\d{3})[^\\n]*\\n([^\\n]*(?:\\n(?!\\s*\\n)[^\\n]+)*)");
    auto matches = pattern.globalMatch(text);
    while (matches.hasNext() && m_cues.size() < 20000) {
        const auto match = matches.next();
        auto time = [&match](int offset) {
            return match.captured(offset).toInt() * 3600.0 + match.captured(offset+1).toInt() * 60.0
                 + match.captured(offset+2).toInt() + match.captured(offset+3).toInt() / 1000.0;
        };
        const double start = time(1), end = time(5);
        if (end > start)
            m_cues << QVariantMap{{"start", start}, {"end", end}, {"text", match.captured(9).simplified()}};
    }
    emit changed();
}
QString PlayerPanelState::cueAt(double seconds) const
{
    for (const auto& cue : m_cues) {
        const auto value = cue.toMap();
        if (seconds >= value["start"].toDouble() && seconds < value["end"].toDouble()) return value["text"].toString();
    }
    return {};
}
