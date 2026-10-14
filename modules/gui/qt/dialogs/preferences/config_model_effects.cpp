/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include "config_model.hpp"
#include "config_values.hpp"
#include "dialogs/extended/audio_effects.hpp"
#include "dialogs/extended/video_effects.hpp"
#include "maininterface/mainctx.hpp"

bool ConfigModel::applyWithEffects(AudioEffects *audio, VideoEffects *video)
{
    const auto cancelPreview = [audio, video]() {
        bool restored = true;
        if (audio && !audio->cancel()) restored = false;
        if (video && !video->cancel()) restored = false;
        return restored;
    };
    if (!m_ctx || !m_ctx->getIntf()) {
        setError(tr("VLC preferences are unavailable."));
        cancelPreview();
        return false;
    }
    if ((audio && audio->ctx() != m_ctx) || (video && video->ctx() != m_ctx)) {
        setError(tr("The effect preview belongs to another VLC window."));
        cancelPreview();
        return false;
    }

    QHash<QString, QVariant> values, expected;
    QVector<int> changed;
    for (int i = 0; i < m_entries.size(); ++i) {
        const Entry& entry = m_entries[i];
        if (entry.staged == entry.current) continue;
        if (readValue(entry) != entry.current) {
            setError(tr("%1 changed outside this dialog. Cancel and reopen preferences.").arg(entry.label));
            cancelPreview();
            return false;
        }
        changed.append(i);
        values.insert(entry.key, entry.staged);
        expected.insert(entry.key, entry.current);
    }
    if (audio && !audio->prepareConfiguration(values, expected)) {
        setError(audio->lastError());
        cancelPreview();
        return false;
    }
    if (video && !video->prepareConfiguration(values, expected)) {
        setError(video->lastError());
        cancelPreview();
        return false;
    }

    QString conflict;
    int result = 0;
    if (!ConfigValues::commit(m_ctx->getIntf(), values, expected, &conflict, &result)) {
        const bool restored = cancelPreview();
        if (result)
            setError(tr("Could not save VLC preferences (error %1). Configuration was restored in memory; verify the file.").arg(result)
                     + (restored ? QString() : tr(" The playback preview could not be restored.")));
        else
            setError(tr("%1 changed outside this dialog or is unavailable. Changes were not saved.").arg(conflict)
                     + (restored ? QString() : tr(" The playback preview could not be restored.")));
        return false;
    }
    if (audio) audio->finalizeConfiguration();
    if (video) video->finalizeConfiguration();
    for (int i : changed) {
        m_entries[i].current = m_entries[i].staged;
        notifyEntry(i);
    }
    if (!changed.isEmpty()) emit dirtyChanged();
    setError({});
    return true;
}
