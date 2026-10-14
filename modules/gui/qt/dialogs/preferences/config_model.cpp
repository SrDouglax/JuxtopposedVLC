/****************************************************************************
 * config_model.cpp : Staged VLC configuration for QML preferences
 ****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "config_model.hpp"
#include "catalog.hpp"
#include "maininterface/mainctx.hpp"

#include <vlc_configuration.h>
#include <vlc_plugin.h>

#include <QVariantMap>
#include <cmath>
#include <cstdlib>
#include <limits>

ConfigModel::ConfigModel(QObject *parent) : QAbstractListModel(parent) {}

MainCtx *ConfigModel::ctx() const { return m_ctx.data(); }

void ConfigModel::setCtx(MainCtx *ctx)
{
    if (m_ctx == ctx)
        return;
    m_ctx = ctx;
    emit ctxChanged();
    reload();
}

void ConfigModel::setCategory(const QString &category)
{
    if (m_category == category)
        return;
    m_category = category;
    emit categoryChanged();
    rebuildRows();
}

void ConfigModel::setSearch(const QString &search)
{
    if (m_search == search)
        return;
    m_search = search;
    emit searchChanged();
    rebuildRows();
}

bool ConfigModel::dirty() const
{
    for (const Entry &entry : m_entries)
        if (entry.staged != entry.current)
            return true;
    return false;
}

QStringList ConfigModel::categories() const
{
    QStringList result;
    for (const Entry &entry : m_entries)
        if (!result.contains(entry.category))
            result.append(entry.category);
    return result;
}

int ConfigModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant ConfigModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size())
        return {};
    const Entry &entry = m_entries[m_rows[index.row()]];
    switch (role) {
    case KeyRole: return entry.key;
    case CategoryRole: return entry.category;
    case LabelRole: return entry.label;
    case HelpRole: return entry.help;
    case TypeRole: return entry.type;
    case ValueRole: return entry.staged;
    case CurrentRole: return entry.current;
    case DefaultRole: return entry.original;
    case MinimumRole: return entry.minimum;
    case MaximumRole: return entry.maximum;
    case ChoicesRole: return entry.choices;
    case DirtyRole: return entry.staged != entry.current;
    default: return {};
    }
}

QHash<int, QByteArray> ConfigModel::roleNames() const
{
    return {{KeyRole, "key"}, {CategoryRole, "category"},
            {LabelRole, "label"}, {HelpRole, "help"}, {TypeRole, "type"},
            {ValueRole, "value"}, {CurrentRole, "currentValue"},
            {DefaultRole, "defaultValue"}, {MinimumRole, "minimum"},
            {MaximumRole, "maximum"}, {ChoicesRole, "choices"},
            {DirtyRole, "dirty"}};
}

QString ConfigModel::keyAt(int visibleRow) const
{
    if (visibleRow < 0 || visibleRow >= m_rows.size())
        return {};
    return m_entries[m_rows[visibleRow]].key;
}

bool ConfigModel::visible(const Entry &entry) const
{
    if (!m_category.isEmpty() && entry.category != m_category)
        return false;
    return m_search.isEmpty()
        || entry.key.contains(m_search, Qt::CaseInsensitive)
        || entry.label.contains(m_search, Qt::CaseInsensitive)
        || entry.help.contains(m_search, Qt::CaseInsensitive);
}

void ConfigModel::rebuildRows()
{
    beginResetModel();
    m_rows.clear();
    for (int i = 0; i < m_entries.size(); ++i)
        if (visible(m_entries[i]))
            m_rows.append(i);
    endResetModel();
}

void ConfigModel::setError(const QString &error)
{
    if (m_error == error)
        return;
    m_error = error;
    emit errorChanged();
}

void ConfigModel::notifyEntry(int entryIndex)
{
    const int row = m_rows.indexOf(entryIndex);
    if (row >= 0)
        emit dataChanged(index(row), index(row), {ValueRole, DirtyRole});
}

QVariant ConfigModel::readValue(const Entry &entry)
{
    const QByteArray key = entry.key.toUtf8();
    if (entry.type == QLatin1String("boolean"))
        return config_GetInt(key.constData()) != 0;
    if (entry.type == QLatin1String("integer"))
        return QVariant::fromValue(config_GetInt(key.constData()));
    if (entry.type == QLatin1String("float"))
        return config_GetFloat(key.constData());
    char *value = config_GetPsz(key.constData());
    const QString result = QString::fromUtf8(value ? value : "");
    free(value);
    return result;
}

bool ConfigModel::normalize(const Entry &entry, const QVariant &value,
                            QVariant *normalized)
{
    if (!value.isValid() || value.isNull())
        return false;
    if (entry.type == QLatin1String("boolean")) {
        const QString text = value.toString().toLower();
        if (text != QLatin1String("true") && text != QLatin1String("false")
            && text != QLatin1String("0") && text != QLatin1String("1"))
            return false;
        *normalized = text == QLatin1String("true") || text == QLatin1String("1");
    } else if (entry.type == QLatin1String("integer")) {
        bool ok = false;
        const qlonglong number = value.toString().toLongLong(&ok);
        if (!ok || (entry.bounded && (number < entry.minimum.toLongLong()
                                      || number > entry.maximum.toLongLong())))
            return false;
        *normalized = QVariant::fromValue(static_cast<int64_t>(number));
    } else if (entry.type == QLatin1String("float")) {
        bool ok = false;
        const double number = value.toString().toDouble(&ok);
        if (!ok || !std::isfinite(number)
            || number < -std::numeric_limits<float>::max()
            || number > std::numeric_limits<float>::max()
            || (entry.bounded && (number < entry.minimum.toDouble()
                                  || number > entry.maximum.toDouble())))
            return false;
        *normalized = static_cast<float>(number);
    } else {
        *normalized = value.toString();
    }
    if (!entry.choices.isEmpty()) {
        bool found = false;
        for (const QVariant &choice : entry.choices)
            if (choice.toMap().value(QStringLiteral("value")) == *normalized) {
                found = true;
                break;
            }
        if (!found)
            return false;
    }
    return true;
}

bool ConfigModel::setValue(const QString &key, const QVariant &value)
{
    for (int i = 0; i < m_entries.size(); ++i) {
        Entry &entry = m_entries[i];
        if (entry.key != key)
            continue;
        QVariant normalized;
        if (!normalize(entry, value, &normalized)) {
            setError(tr("Invalid value for %1.").arg(entry.label));
            return false;
        }
        const bool wasDirty = dirty();
        entry.staged = normalized;
        notifyEntry(i);
        if (wasDirty != dirty())
            emit dirtyChanged();
        setError({});
        return true;
    }
    setError(tr("Setting %1 is unavailable.").arg(key));
    return false;
}

bool ConfigModel::setDirectoryUrl(const QString &key, const QUrl &url)
{
    for (const Entry &entry : m_entries) {
        if (entry.key != key)
            continue;
        if (entry.type != QLatin1String("directory") || !url.isLocalFile()
            || url.toLocalFile().isEmpty()) {
            setError(tr("Choose a local folder for %1.").arg(entry.label));
            return false;
        }
        return setValue(key, url.toLocalFile());
    }
    setError(tr("Setting %1 is unavailable.").arg(key));
    return false;
}

void ConfigModel::cancel()
{
    const bool wasDirty = dirty();
    for (int i = 0; i < m_entries.size(); ++i) {
        Entry &entry = m_entries[i];
        if (entry.staged == entry.current)
            continue;
        entry.staged = entry.current;
        notifyEntry(i);
    }
    if (wasDirty)
        emit dirtyChanged();
    setError({});
}

void ConfigModel::resetCategory()
{
    if (m_category.isEmpty()) {
        setError(tr("Select a category to reset."));
        return;
    }
    const bool wasDirty = dirty();
    for (int i = 0; i < m_entries.size(); ++i) {
        Entry &entry = m_entries[i];
        if (entry.category != m_category || entry.staged == entry.original)
            continue;
        entry.staged = entry.original;
        notifyEntry(i);
    }
    if (wasDirty != dirty())
        emit dirtyChanged();
    setError({});
}

bool ConfigModel::apply()
{
    return applyWithEffects(nullptr, nullptr);
}

void ConfigModel::reload()
{
    const bool wasDirty = dirty();
    beginResetModel();
    m_entries.clear();
    m_rows.clear();
    if (m_ctx) {
        for (size_t i = 0; i < PrefsCatalog::count(); ++i) {
            const PrefsCatalog::Option &option = PrefsCatalog::options()[i];
            module_config_t *config = config_FindConfig(option.name);
            if (!config || !config->psz_text || !*config->psz_text)
                continue;
            Entry entry;
            switch (CONFIG_CLASS(config->i_type)) {
            case CONFIG_ITEM_BOOL: entry.type = QStringLiteral("boolean"); break;
            case CONFIG_ITEM_INTEGER: entry.type = QStringLiteral("integer"); break;
            case CONFIG_ITEM_FLOAT: entry.type = QStringLiteral("float"); break;
            case CONFIG_ITEM_STRING:
                entry.type = config->i_type == CONFIG_ITEM_DIRECTORY
                    ? QStringLiteral("directory") : QStringLiteral("string");
                break;
            default: continue;
            }
            entry.key = QString::fromLatin1(option.name);
            entry.category = QString::fromLatin1(option.category);
            entry.label = tr(config->psz_text);
            entry.help = config->psz_longtext ? tr(config->psz_longtext) : QString();
            if (entry.type == QLatin1String("boolean")) {
                entry.original = config->orig.i != 0;
            } else if (entry.type == QLatin1String("integer")) {
                entry.original = QVariant::fromValue(config->orig.i);
                entry.bounded = config->min.i < config->max.i;
                if (entry.bounded) {
                    entry.minimum = QVariant::fromValue(config->min.i);
                    entry.maximum = QVariant::fromValue(config->max.i);
                }
            } else if (entry.type == QLatin1String("float")) {
                entry.original = config->orig.f;
                entry.bounded = config->min.f < config->max.f;
                if (entry.bounded) {
                    entry.minimum = config->min.f;
                    entry.maximum = config->max.f;
                }
            } else {
                entry.original = QString::fromUtf8(config->orig.psz ? config->orig.psz : "");
            }
            entry.current = readValue(entry);
            entry.staged = entry.current;
            if (entry.type == QLatin1String("integer")) {
                int64_t *values = nullptr;
                char **texts = nullptr;
                const ssize_t count = config_GetIntChoices(option.name, &values, &texts);
                for (ssize_t j = 0; j < count; ++j) {
                    const QString label = texts && texts[j] ? tr(texts[j]) : QString::number(values[j]);
                    entry.choices.append(QVariantMap{{QStringLiteral("value"), QVariant::fromValue(values[j])},
                                                     {QStringLiteral("label"), label}});
                    if (texts) free(texts[j]);
                }
                free(texts);
                free(values);
            } else if (entry.type == QLatin1String("string")) {
                char **values = nullptr;
                char **texts = nullptr;
                const ssize_t count = config_GetPszChoices(option.name, &values, &texts);
                for (ssize_t j = 0; j < count; ++j) {
                    const QString value = QString::fromUtf8(values[j] ? values[j] : "");
                    const QString label = texts && texts[j] ? tr(texts[j]) : value;
                    entry.choices.append(QVariantMap{{QStringLiteral("value"), value},
                                                     {QStringLiteral("label"), label}});
                    free(values[j]);
                    if (texts) free(texts[j]);
                }
                free(texts);
                free(values);
            }
            m_entries.append(entry);
        }
        for (int i = 0; i < m_entries.size(); ++i)
            if (visible(m_entries[i]))
                m_rows.append(i);
    }
    endResetModel();
    emit categoriesChanged();
    if (wasDirty)
        emit dirtyChanged();
    setError({});
}
