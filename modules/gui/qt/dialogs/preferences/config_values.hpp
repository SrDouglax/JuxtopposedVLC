/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
#ifndef VLC_QT_PREFERENCES_CONFIG_VALUES_HPP
#define VLC_QT_PREFERENCES_CONFIG_VALUES_HPP

#include <QHash>
#include <QByteArray>
#include <QString>
#include <QVariant>
#include <vlc_configuration.h>
#include <vlc_plugin.h>
#include <cstdlib>

namespace ConfigValues {
inline QVariant read(const QString& name)
{
    const QByteArray id = name.toUtf8();
    const module_config_t* option = config_FindConfig(id.constData());
    if (!option) return {};
    switch (CONFIG_CLASS(option->i_type)) {
    case CONFIG_ITEM_FLOAT: return config_GetFloat(id.constData());
    case CONFIG_ITEM_BOOL: return bool(config_GetInt(id.constData()));
    case CONFIG_ITEM_INTEGER: return qlonglong(config_GetInt(id.constData()));
    case CONFIG_ITEM_STRING: {
        char* value = config_GetPsz(id.constData());
        const QString result = QString::fromUtf8(value ? value : "");
        free(value);
        return result;
    }
    default: return {};
    }
}

inline bool put(const QString& name, const QVariant& value)
{
    const QByteArray id = name.toUtf8();
    const module_config_t* option = config_FindConfig(id.constData());
    if (!option || !value.isValid()) return false;
    switch (CONFIG_CLASS(option->i_type)) {
    case CONFIG_ITEM_FLOAT: config_PutFloat(id.constData(), value.toFloat()); return true;
    case CONFIG_ITEM_BOOL: config_PutInt(id.constData(), value.toBool()); return true;
    case CONFIG_ITEM_INTEGER: config_PutInt(id.constData(), value.toLongLong()); return true;
    case CONFIG_ITEM_STRING: {
        const QByteArray bytes = value.toString().toUtf8();
        config_PutPsz(id.constData(), bytes.constData());
        return true;
    }
    default: return false;
    }
}

// The caller validates its live output token before entering this synchronous commit.
template<class Intf>
bool commit(Intf* intf, const QHash<QString, QVariant>& values,
            const QHash<QString, QVariant>& expected, QString* conflict, int* saveResult)
{
    if (saveResult) *saveResult = 0;
    if (conflict) conflict->clear();
    for (auto it = values.cbegin(); it != values.cend(); ++it) {
        if (!expected.contains(it.key()) || !it.value().isValid()
                || ConfigValues::read(it.key()) != expected.value(it.key())) {
            if (conflict) *conflict = it.key();
            return false;
        }
    }
    if (values.isEmpty()) return true;
    QHash<QString, QVariant> written;
    for (auto it = values.cbegin(); it != values.cend(); ++it) {
        if (!put(it.key(), it.value())) {
            if (conflict) *conflict = it.key();
            for (auto old = written.cbegin(); old != written.cend(); ++old) put(old.key(), old.value());
            return false;
        }
        written.insert(it.key(), expected.value(it.key()));
    }
    const int result = config_SaveConfigFile(intf);
    if (result != 0) {
        for (auto old = written.cbegin(); old != written.cend(); ++old) put(old.key(), old.value());
        if (saveResult) *saveResult = result;
        return false;
    }
    return true;
}
}
#endif
