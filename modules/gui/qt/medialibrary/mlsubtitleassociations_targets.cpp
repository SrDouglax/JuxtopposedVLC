/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
#if HAVE_CONFIG_H
# include "config.h"
#endif

#include "mlsubtitleassociations.hpp"

#include <QFileInfo>
#include <QSet>

#include <vlc_media_library.h>

#include "medialib.hpp"
#include "mlhelper.hpp"

QVariantList MLSubtitleAssociations::targets() const
{
    QVariantList result;
    for (const auto& target : m_targets)
    {
        const QString kind = target.url.isValid() ? tr("File") :
                             target.id.type == VLC_ML_PARENT_FOLDER ? tr("Folder") :
                             target.id.type == VLC_ML_PARENT_PLAYLIST ? tr("Playlist") : tr("Media");
        result.push_back(QVariantMap{{"label", target.label}, {"kind", kind}});
    }
    return result;
}

void MLSubtitleAssociations::refreshTargets(const Target& initial)
{
    m_targets = {initial};
    m_selectedTarget = 0;
    emit targetsChanged();
    if (!m_ml)
        return;

    const quint64 revision = ++m_targetRevision;
    struct Entry { int64_t id; vlc_ml_parent_type type; QString name; };
    struct Context { QVector<Entry> entries; };
    m_ml->runOnMLThread<Context>(this,
        [](vlc_medialibrary_t* ml, Context& ctx) {
            vlc_ml_query_params_t query = vlc_ml_query_params_create();
            ml_unique_ptr<vlc_ml_playlist_list_t> playlists(
                vlc_ml_list_playlists(ml, &query, VLC_ML_PLAYLIST_TYPE_ALL));
            if (playlists)
                for (size_t i = 0; i < playlists->i_nb_items; ++i)
                {
                    const auto& item = playlists->p_items[i];
                    if (item.psz_name)
                        ctx.entries.push_back({item.i_id, VLC_ML_PARENT_PLAYLIST,
                                               QString::fromUtf8(item.psz_name)});
                }
            ml_unique_ptr<vlc_ml_folder_list_t> folders(vlc_ml_list_folders(ml, &query));
            if (folders)
                for (size_t i = 0; i < folders->i_nb_items; ++i)
                {
                    const auto& item = folders->p_items[i];
                    if (item.psz_mrl && QUrl::fromEncoded(item.psz_mrl).isLocalFile())
                        ctx.entries.push_back({item.i_id, VLC_ML_PARENT_FOLDER,
                            item.psz_name ? QString::fromUtf8(item.psz_name)
                                          : QFileInfo(QUrl::fromEncoded(item.psz_mrl).toLocalFile()).fileName()});
                }
        },
        [this, revision](quint64, Context& ctx) {
            if (revision != m_targetRevision)
                return;
            QSet<QString> seen;
            for (const auto& target : m_targets)
                if (target.id.isValid())
                    seen.insert(target.id.toString());
            for (const auto& entry : ctx.entries)
            {
                const MLItemId id(entry.id, entry.type);
                if (seen.contains(id.toString()))
                    continue;
                seen.insert(id.toString());
                m_targets.push_back({id, {}, entry.name});
            }
            emit targetsChanged();
        });
}

void MLSubtitleAssociations::selectTarget(int index)
{
    if (m_busy || index < 0 || index >= m_targets.size())
        return;
    m_selectedTarget = index;
    const auto target = m_targets[index];
    emit targetsChanged();
    if (target.url.isValid())
        loadUrlTarget(target.url);
    else
        loadTarget(target.id);
}
