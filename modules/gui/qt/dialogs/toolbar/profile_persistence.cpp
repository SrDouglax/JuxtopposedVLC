/****************************************************************************
 * profile_persistence.cpp: Controlbar profiles and settings snapshots on disk
 ****************************************************************************/
#include "controlbar_profile_model.hpp"
#include "profile_settings.hpp"
#include "maininterface/mainctx.hpp"
#include "player/player_controlbar_model.hpp"
#include <QChar>
#include <QMap>
#include <QStringBuilder>
#include <algorithm>

// NOTE: QSettings started to accept QAnyStringView with Qt 6.4,
//       so instead of a QString(Literal), use QLatin1String(View):
constexpr QLatin1String SETTINGS_KEY_SELECTEDPROFILE {"SelectedProfile"};
constexpr QLatin1String SETTINGS_ARRAYNAME_PROFILES {"Profiles"};
constexpr QLatin1String SETTINGS_KEY_NAME {"Name"};
constexpr QLatin1String SETTINGS_KEY_MODEL {"Model"};
constexpr QLatin1String SETTINGS_KEY_SETTINGS {"Settings"};

constexpr QChar SETTINGS_CONTROL_SEPARATOR {','};
constexpr QChar SETTINGS_CONFIGURATION_SEPARATOR {'|'};
constexpr QChar SETTINGS_PROFILE_SEPARATOR {'$'};

bool ControlbarProfileModel::save(bool clearDirty)
{
    if (auto *profile = currentModel())
        profile->m_settingsSnapshot = ProfileSettings::capture(
            qobject_cast<MainCtx *>(parent()), m_settings);
    const auto groupName = metaObject()->className();

    m_settings->beginGroup(groupName);
    QMap<QString, QVariant> previous;
    for (const QString &key : m_settings->allKeys())
        previous.insert(key, m_settings->value(key));
    m_settings->remove(""); // clear the group before save

    m_settings->setValue(SETTINGS_KEY_SELECTEDPROFILE, selectedProfile());

    m_settings->beginWriteArray(SETTINGS_ARRAYNAME_PROFILES);

    for (int i = 0; i < m_profiles.size(); ++i)
    {
        m_settings->setArrayIndex(i);

        const auto& ptrModelMap = m_profiles.at(i)->m_models;

        QString val;
        for (auto it = ptrModelMap.constBegin(); it != ptrModelMap.end(); ++it)
        {
            const int identifier = it.key();

            const auto serializedModels = m_profiles.at(i)->getModelData(identifier);

            static const auto join = [](const QVector<int>& list) {
                QString ret;
                for (auto i : list)
                {
                    ret += QString::number(i) + SETTINGS_CONTROL_SEPARATOR;
                }
                if (!ret.isEmpty())
                    ret.chop(1);
                return ret;
            };

            val += SETTINGS_PROFILE_SEPARATOR %
                   QString::number(identifier) %
                   SETTINGS_CONFIGURATION_SEPARATOR %
                   join(serializedModels[0]) %
                   SETTINGS_CONFIGURATION_SEPARATOR %
                   join(serializedModels[1]) %
                   SETTINGS_CONFIGURATION_SEPARATOR %
                   join(serializedModels[2]);
        }

        m_settings->setValue(SETTINGS_KEY_NAME, m_profiles.at(i)->name());
        m_settings->setValue(SETTINGS_KEY_MODEL, val);
        m_settings->setValue(SETTINGS_KEY_SETTINGS, m_profiles.at(i)->m_settingsSnapshot);
    }

    m_settings->endArray();
    m_settings->endGroup();
    m_settings->sync();
    if (m_settings->status() != QSettings::NoError) {
        m_settings->beginGroup(groupName);
        m_settings->remove("");
        for (auto it = previous.cbegin(); it != previous.cend(); ++it)
            m_settings->setValue(it.key(), it.value());
        m_settings->endGroup();
        m_settings->sync();
        m_lastError = tr("Could not save the selected profile.");
        emit errorChanged();
        return false;
    }
    if (clearDirty)
        for (auto *profile : m_profiles) profile->resetDirty();
    if (!m_lastError.isEmpty()) {
        m_lastError.clear();
        emit errorChanged();
    }
    return true;
}

bool ControlbarProfileModel::reload()
{
    const auto groupName = metaObject()->className();

    m_settings->beginGroup(groupName);

    const int size = m_settings->beginReadArray(SETTINGS_ARRAYNAME_PROFILES);

    if (size <= 0)
    {
        m_settings->endArray();
        m_settings->endGroup();

        return false;
    }

    decltype (m_profiles) profiles;
    for (int i = 0; i < size; ++i)
    {
        m_settings->setArrayIndex(i);

        const QString modelValue = m_settings->value(SETTINGS_KEY_MODEL).toString();
        if (modelValue.isEmpty())
            continue;

        QStringView modelValueStringView(modelValue);
        const auto val = modelValueStringView.split(SETTINGS_PROFILE_SEPARATOR);
        if (val.isEmpty())
            continue;

        const auto ptrNewProfile = new ControlbarProfile(this);
        ptrNewProfile->setName(m_settings->value(SETTINGS_KEY_NAME).toString());
        ptrNewProfile->m_settingsSnapshot =
            m_settings->value(SETTINGS_KEY_SETTINGS).toMap();

        for (auto j : val)
        {
            if (j.isEmpty())
                continue;

            const auto alignments = j.split(SETTINGS_CONFIGURATION_SEPARATOR);

            if (alignments.length() != 4)
                continue;

            bool ok = false;
            int identifier = alignments[0].toInt(&ok);
            if (!ok || identifier < 0)
                continue;

            static const auto split = [](auto ref) {
                QVector<int> list;

                if (ref.isEmpty())
                    return list;

                for (auto i : ref.split(SETTINGS_CONTROL_SEPARATOR))
                {
                    bool ok = false;
                    int k = i.toInt(&ok);

                    if (ok)
                        list.append(k);
                }
                return list;
            };

            const std::array<QVector<int>, 3> data { split(alignments[1]),
                                                     split(alignments[2]),
                                                     split(alignments[3]) };

            ptrNewProfile->setModelData(identifier, data);
            ptrNewProfile->resetDirty(); // Newly loaded model can not be dirty
        }

        profiles.append(ptrNewProfile);
    }

    m_settings->endArray();

    bool ok = false;
    int index = m_settings->value(SETTINGS_KEY_SELECTEDPROFILE).toInt(&ok);
    m_settings->endGroup();
    if (!ok || index < 0 || index >= profiles.size()) index = 0;
    if (profiles.isEmpty()) return false;
    if (auto *ctx = qobject_cast<MainCtx *>(parent())) {
        QString error;
        if (!ProfileSettings::apply(ctx, m_settings,
                                    profiles[index]->m_settingsSnapshot, &error)) {
            for (auto *profile : profiles) delete profile;
            m_lastError = error;
            emit errorChanged();
            return false;
        }
    }

    beginResetModel();
    m_selectedProfile = -1;
    std::for_each(m_profiles.begin(), m_profiles.end(), [](auto i) { delete i; });

    m_profiles = std::move(profiles);

    endResetModel();

    m_skipNextApply = true;
    setSelectedProfile(index);
    m_skipNextApply = false;

    return true;
}
