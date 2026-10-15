/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include "config_model.hpp"
#include <QGuiApplication>
#include <QScreen>

#include <vlc_common.h>
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

bool ConfigModel::setFileUrl(const QString& key, const QUrl& url)
{
    return url.isLocalFile() && setValue(key, url.toLocalFile());
}

bool ConfigModel::moduleAvailable(const QString& name) const
{
    return module_exists(name.toUtf8().constData());
}

QVariantMap ConfigModel::optionFor(const QString& key) const
{
    for (const Entry& entry : m_entries)
        if (entry.key == key)
            return {{"key", entry.key}, {"type", entry.type}, {"value", entry.staged},
                    {"defaultValue", entry.original}, {"minimum", entry.minimum},
                    {"maximum", entry.maximum}, {"choices", entry.choices},
                    {"help", entry.help}, {"label", entry.label}};
    return {};
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

QVariantList ConfigModel::screenChoices() const
{
    QVariantList result;
    result.append(QVariantMap{{"label", tr("Current screen")}, {"value", -1}});
    const auto screens = QGuiApplication::screens();
    for (int i = 0; i < screens.size(); ++i)
        result.append(QVariantMap{{"label", tr("Screen %1 (%2)").arg(i + 1).arg(screens[i]->name())}, {"value", i}});
    return result;
}
