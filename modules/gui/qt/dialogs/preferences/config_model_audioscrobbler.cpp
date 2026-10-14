/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include "config_model.hpp"

#include <vlc_modules.h>

QVariant ConfigModel::valueFor(const QString& key) const
{
    for (const Entry& entry : m_entries)
        if (entry.key == key) return entry.staged;
    return {};
}

bool ConfigModel::hasOption(const QString& key) const
{
    return valueFor(key).isValid();
}

bool ConfigModel::audioscrobblerAvailable() const
{
    return module_exists("audioscrobbler") && hasOption(QStringLiteral("lastfm-username"))
        && hasOption(QStringLiteral("lastfm-password"))
        && hasOption(QStringLiteral("scrobbler-url"))
        && hasOption(QStringLiteral("extraintf"))
        && hasOption(QStringLiteral("control"));
}

bool ConfigModel::audioscrobblerEnabled() const
{
    const auto contains = [](const QString& list) {
        return list.split(':', Qt::SkipEmptyParts).contains(QStringLiteral("audioscrobbler"));
    };
    return contains(valueFor(QStringLiteral("extraintf")).toString())
        || contains(valueFor(QStringLiteral("control")).toString());
}

bool ConfigModel::setAudioscrobblerEnabled(bool enabled)
{
    if (!audioscrobblerAvailable()) {
        setError(tr("Last.fm is unavailable in this VLC installation."));
        return false;
    }
    const QString extra = valueFor(QStringLiteral("extraintf")).toString();
    const QString control = valueFor(QStringLiteral("control")).toString();
    if (enabled) {
        if (audioscrobblerEnabled()) return true;
        return setValue(QStringLiteral("extraintf"),
                        extra.isEmpty() ? QStringLiteral("audioscrobbler")
                                        : extra + QStringLiteral(":audioscrobbler"));
    }
    const auto withoutScrobbler = [](const QString& list) {
        QStringList parts = list.split(':', Qt::KeepEmptyParts);
        parts.removeAll(QStringLiteral("audioscrobbler"));
        return parts.join(':');
    };
    if (!setValue(QStringLiteral("extraintf"), withoutScrobbler(extra))) return false;
    if (!setValue(QStringLiteral("control"), withoutScrobbler(control))) {
        setValue(QStringLiteral("extraintf"), extra);
        return false;
    }
    return true;
}
