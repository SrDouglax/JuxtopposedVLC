/****************************************************************************
 * shortcuts_model.cpp : Staged VLC keyboard shortcuts for QML
 ****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "shortcuts_model.hpp"
#include "maininterface/mainctx.hpp"
#include "util/vlchotkeyconverter.hpp"

#include <vlc_configuration.h>
#include <vlc_modules.h>
#include <vlc_plugin.h>

#include <QKeyEvent>
#include <QStringList>
#include <algorithm>
#include <cstdlib>
#include <cstring>

ShortcutsModel::ShortcutsModel(QObject *parent) : QAbstractListModel(parent) {}

MainCtx *ShortcutsModel::ctx() const { return m_ctx.data(); }

void ShortcutsModel::setCtx(MainCtx *ctx)
{
    if (m_ctx == ctx)
        return;
    m_ctx = ctx;
    emit ctxChanged();
    reload();
}

void ShortcutsModel::setSearch(const QString &search)
{
    if (m_search == search)
        return;
    m_search = search;
    emit searchChanged();
    rebuildRows();
}

void ShortcutsModel::setSearchField(const QString &field)
{
    if (m_searchField == field)
        return;
    m_searchField = field;
    emit searchFieldChanged();
    rebuildRows();
}

bool ShortcutsModel::dirty() const
{
    for (const Entry &entry : m_entries)
        if (entry.staged != entry.current || entry.globalStaged != entry.globalCurrent)
            return true;
    return false;
}

int ShortcutsModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant ShortcutsModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size())
        return {};
    const Entry &entry = m_entries[m_rows[index.row()]];
    switch (role) {
    case KeyRole: return entry.key;
    case ActionRole: return entry.action;
    case GroupRole: return entry.group;
    case HotkeyRole: return QString(entry.staged).replace(QLatin1Char('\t'), QStringLiteral(", "));
    case GlobalHotkeyRole: return QString(entry.globalStaged).replace(QLatin1Char('\t'), QStringLiteral(", "));
    case DirtyRole: return entry.staged != entry.current || entry.globalStaged != entry.globalCurrent;
    default: return {};
    }
}

QHash<int, QByteArray> ShortcutsModel::roleNames() const
{
    return {{KeyRole, "key"}, {ActionRole, "action"}, {GroupRole, "group"},
            {HotkeyRole, "hotkey"}, {GlobalHotkeyRole, "globalHotkey"},
            {DirtyRole, "dirty"}};
}

bool ShortcutsModel::visible(const Entry &entry) const
{
    if (m_search.isEmpty())
        return true;
    const auto match = [this](const QString &text) {
        return text.contains(m_search, Qt::CaseInsensitive);
    };
    if (m_searchField == QLatin1String("action"))
        return match(entry.action);
    if (m_searchField == QLatin1String("hotkey"))
        return match(entry.staged);
    if (m_searchField == QLatin1String("global"))
        return match(entry.globalStaged);
    return match(entry.action) || match(entry.staged) || match(entry.globalStaged);
}

void ShortcutsModel::rebuildRows()
{
    beginResetModel();
    m_rows.clear();
    for (int i = 0; i < m_entries.size(); ++i)
        if (visible(m_entries[i]))
            m_rows.append(i);
    endResetModel();
}

void ShortcutsModel::notifyEntry(int entryIndex)
{
    const int row = m_rows.indexOf(entryIndex);
    if (row >= 0)
        emit dataChanged(index(row), index(row), {HotkeyRole, GlobalHotkeyRole, DirtyRole});
}

void ShortcutsModel::setError(const QString &error)
{
    if (m_error == error)
        return;
    m_error = error;
    emit errorChanged();
}

int ShortcutsModel::findEntry(const QString &key) const
{
    for (int i = 0; i < m_entries.size(); ++i)
        if (m_entries[i].key == key)
            return i;
    return -1;
}

QString ShortcutsModel::readKey(const QString &key)
{
    const QByteArray name = key.toUtf8();
    char *value = config_GetPsz(name.constData());
    const QString result = QString::fromUtf8(value ? value : "");
    free(value);
    return result;
}

void ShortcutsModel::putKey(const QString &key, const QString &value)
{
    const QByteArray name = key.toUtf8();
    const QByteArray utf8 = value.toUtf8();
    config_PutPsz(name.constData(), utf8.constData());
}

QString ShortcutsModel::groupFor(const QString &key)
{
    if (key == QLatin1String("key-toggle-fullscreen")
        || key == QLatin1String("key-leave-fullscreen")
        || key == QLatin1String("key-position")
        || key == QLatin1String("key-intf-show"))
        return tr("Basic");
    if (key.contains(QLatin1String("vol-")) || key.contains(QLatin1String("audio")))
        return tr("Audio");
    if (key.contains(QLatin1String("sub")) || key.contains(QLatin1String("caption")))
        return tr("Subtitles");
    if (key.contains(QLatin1String("nav-")) || key.contains(QLatin1String("disc-")))
        return tr("Navigation");
    if (key.contains(QLatin1String("crop")) || key.contains(QLatin1String("zoom"))
        || key.contains(QLatin1String("aspect")) || key.contains(QLatin1String("deinterlace"))
        || key.contains(QLatin1String("snapshot")))
        return tr("Video");
    return tr("Playback");
}

int ShortcutsModel::groupOrder(const QString &group)
{
    if (group == tr("Basic")) return 0;
    if (group == tr("Playback")) return 1;
    if (group == tr("Audio")) return 2;
    if (group == tr("Video")) return 3;
    if (group == tr("Subtitles")) return 4;
    return 5;
}

void ShortcutsModel::reload()
{
    const bool wasDirty = dirty();
    beginResetModel();
    m_entries.clear();
    m_rows.clear();
    if (m_ctx) {
        module_t *main = module_get_main();
        if (main) {
            unsigned count = 0;
            module_config_t *configs = module_config_get(main, &count);
            if (configs) {
                for (unsigned i = 0; i < count; ++i) {
                    const module_config_t &item = configs[i];
                    if (item.i_type != CONFIG_ITEM_KEY || !item.psz_name
                        || !item.psz_text || !*item.psz_text
                        || strncmp(item.psz_name, "global-", 7) == 0)
                        continue;
                    Entry entry;
                    entry.key = QString::fromLatin1(item.psz_name);
                    entry.globalKey = QStringLiteral("global-") + entry.key;
                    if (!config_FindConfig(entry.globalKey.toUtf8().constData()))
                        entry.globalKey.clear();
                    entry.action = tr(item.psz_text);
                    entry.group = groupFor(entry.key);
                    entry.current = readKey(entry.key);
                    entry.staged = entry.current;
                    if (!entry.globalKey.isEmpty()) {
                        entry.globalCurrent = readKey(entry.globalKey);
                        entry.globalStaged = entry.globalCurrent;
                    }
                    m_entries.append(entry);
                }
                module_config_free(configs);
            }
        }
        const QStringList firstActions = {
            QStringLiteral("key-toggle-fullscreen"), QStringLiteral("key-leave-fullscreen"),
            QStringLiteral("key-position"), QStringLiteral("key-intf-show"),
            QStringLiteral("key-play-pause"), QStringLiteral("key-stop"),
            QStringLiteral("key-next"), QStringLiteral("key-prev"),
            QStringLiteral("key-program-sid-next")
        };
        std::stable_sort(m_entries.begin(), m_entries.end(), [&firstActions](const Entry &a, const Entry &b) {
            const int groupA = groupOrder(a.group), groupB = groupOrder(b.group);
            if (groupA != groupB)
                return groupA < groupB;
            const int firstA = firstActions.indexOf(a.key), firstB = firstActions.indexOf(b.key);
            return (firstA < 0 ? 100 : firstA) < (firstB < 0 ? 100 : firstB);
        });
        for (int i = 0; i < m_entries.size(); ++i)
            if (visible(m_entries[i]))
                m_rows.append(i);
    }
    endResetModel();
    if (wasDirty)
        emit dirtyChanged();
    setError({});
}

void ShortcutsModel::cancel()
{
    const bool wasDirty = dirty();
    for (int i = 0; i < m_entries.size(); ++i) {
        Entry &entry = m_entries[i];
        entry.staged = entry.current;
        entry.globalStaged = entry.globalCurrent;
        notifyEntry(i);
    }
    if (wasDirty)
        emit dirtyChanged();
    setError({});
    rebuildRows();
}

QVariantMap ShortcutsModel::stageKey(const QString &option, bool global,
                                     int qtKey, int modifiers, bool replaceConflict)
{
    const int target = findEntry(option);
    if (target < 0 || (global && m_entries[target].globalKey.isEmpty())) {
        setError(tr("This shortcut is unavailable."));
        return {{QStringLiteral("ok"), false}};
    }
    if (qtKey == Qt::Key_Tab || qtKey == Qt::Key_Shift || qtKey == Qt::Key_Control
        || qtKey == Qt::Key_Meta || qtKey == Qt::Key_Alt || qtKey == Qt::Key_AltGr)
        return {{QStringLiteral("ok"), false}, {QStringLiteral("modifierOnly"), true}};

    QKeyEvent event(QEvent::KeyPress, qtKey, Qt::KeyboardModifiers::fromInt(modifiers));
    const int vlcKey = qtEventToVLCKey(&event);
    const QString canonical = VLCKeyToString(vlcKey, false);
    if (vlcKey == 0 || canonical.isEmpty()) {
        setError(tr("This key combination cannot be used by VLC."));
        return {{QStringLiteral("ok"), false}};
    }
    setError({});
    QVector<int> conflicts;
    for (int i = 0; i < m_entries.size(); ++i) {
        if (i == target)
            continue;
        const QString &keys = global ? m_entries[i].globalStaged : m_entries[i].staged;
        if (keys.split(QLatin1Char('\t')).contains(canonical))
            conflicts.append(i);
    }
    if (!conflicts.isEmpty() && !replaceConflict)
        return {{QStringLiteral("ok"), false},
                {QStringLiteral("needsConfirmation"), true},
                {QStringLiteral("conflictAction"), m_entries[conflicts.first()].action},
                {QStringLiteral("key"), canonical}};

    const bool wasDirty = dirty();
    for (int i : conflicts) {
        QString &keys = global ? m_entries[i].globalStaged : m_entries[i].staged;
        QStringList parts = keys.split(QLatin1Char('\t'), Qt::SkipEmptyParts);
        parts.removeAll(canonical);
        keys = parts.join(QLatin1Char('\t'));
        notifyEntry(i);
    }
    QString &targetKeys = global ? m_entries[target].globalStaged : m_entries[target].staged;
    targetKeys = canonical;
    notifyEntry(target);
    if (wasDirty != dirty())
        emit dirtyChanged();
    setError({});
    rebuildRows();
    return {{QStringLiteral("ok"), true}, {QStringLiteral("key"), canonical}};
}

bool ShortcutsModel::clearKey(const QString &option, bool global)
{
    const int target = findEntry(option);
    if (target < 0 || (global && m_entries[target].globalKey.isEmpty())) {
        setError(tr("This shortcut is unavailable."));
        return false;
    }
    const bool wasDirty = dirty();
    QString &keys = global ? m_entries[target].globalStaged : m_entries[target].staged;
    keys.clear();
    notifyEntry(target);
    if (wasDirty != dirty())
        emit dirtyChanged();
    setError({});
    rebuildRows();
    return true;
}

bool ShortcutsModel::apply()
{
    if (!m_ctx || !m_ctx->getIntf()) {
        setError(tr("VLC preferences are unavailable."));
        return false;
    }
    QVector<Change> changes;
    for (const Entry &entry : m_entries) {
        if (entry.staged != entry.current)
            changes.append({entry.key, entry.current, entry.staged});
        if (!entry.globalKey.isEmpty() && entry.globalStaged != entry.globalCurrent)
            changes.append({entry.globalKey, entry.globalCurrent, entry.globalStaged});
    }
    for (const Change &change : changes) {
        if (readKey(change.key) != change.before) {
            setError(tr("%1 changed outside this dialog. Cancel and reopen shortcuts.")
                         .arg(change.key));
            return false;
        }
    }
    if (changes.isEmpty()) {
        setError({});
        return true;
    }
    for (const Change &change : changes) {
        putKey(change.key, change.after);
        if (readKey(change.key) != change.after) {
            for (const Change &rollback : changes)
                putKey(rollback.key, rollback.before);
            setError(tr("A shortcut could not be changed. Changes were reverted in memory."));
            return false;
        }
    }
    const int result = config_SaveConfigFile(m_ctx->getIntf());
    if (result != 0) {
        for (const Change &change : changes)
            putKey(change.key, change.before);
        setError(tr("Could not save shortcuts (error %1). Changes were reverted in memory; verify the configuration file.")
                     .arg(result));
        return false;
    }
    for (int i = 0; i < m_entries.size(); ++i) {
        Entry &entry = m_entries[i];
        entry.current = entry.staged;
        entry.globalCurrent = entry.globalStaged;
        notifyEntry(i);
    }
    emit dirtyChanged();
    setError({});
    return true;
}
