/*****************************************************************************
 * audio_effects.cpp: Live audio effects for the Qt Quick player
 *****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "audio_effects.hpp"
#include "maininterface/mainctx.hpp"
#include "qt.hpp"
#include "../../../../audio_filter/equalizer_presets.h"

#include <QLocale>
#include <cmath>
#include <cstdlib>
#include <vlc_aout.h>
#include <vlc_configuration.h>
#include <vlc_modules.h>
#include <vlc_player.h>
#include <vlc_plugin.h>
#include <vlc_variables.h>

namespace {
const QStringList filters = {"equalizer", "compressor", "spatializer", "stereo_widen"};
const QStringList compressor = {"compressor-rms-peak", "compressor-attack", "compressor-release",
                                "compressor-threshold", "compressor-ratio", "compressor-knee",
                                "compressor-makeup-gain"};
const QStringList spatializer = {"spatializer-roomsize", "spatializer-width", "spatializer-wet",
                                 "spatializer-dry", "spatializer-damp"};
const QStringList widener = {"stereowiden-delay", "stereowiden-feedback",
                             "stereowiden-crossfeed", "stereowiden-dry-mix"};
const QStringList equalizer = {"equalizer-preset", "equalizer-bands", "equalizer-preamp",
                               "equalizer-2pass", "equalizer-vlcfreqs"};

QString fromVlc(char* value)
{
    const QString result = value ? QString::fromUtf8(value) : QString();
    free(value);
    return result;
}

QStringList chainItems(const QString& chain)
{
    return chain.split(':', Qt::SkipEmptyParts);
}

QString presetBands(int index)
{
    QStringList items;
    for (int i = 0; i < EQZ_BANDS_MAX; ++i)
        items << QLocale::c().toString(eqz_preset_10b[index].f_amp[i], 'f', 7);
    return items.join(' ');
}
}

AudioEffects::AudioEffects(QObject* parent) : QObject(parent) {}
AudioEffects::~AudioEffects()
{
    if (m_transactionActive) cancel();
}

MainCtx* AudioEffects::ctx() const { return m_ctx; }

void AudioEffects::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx)
        return;
    if (m_transactionActive) cancel();
    m_ctx = ctx;
    m_transactionActive = false;
    m_snapshotValues.clear();
    emit ctxChanged(ctx);
    emit stateChanged();
}

bool AudioEffects::available() const
{
    return m_ctx && m_ctx->getIntf() && m_ctx->getIntf()->p_player;
}

bool AudioEffects::activeAudio() const
{
    if (!available())
        return false;
    audio_output_t* aout = vlc_player_aout_Hold(m_ctx->getIntf()->p_player);
    if (!aout)
        return false;
    aout_Release(aout);
    return true;
}

quintptr AudioEffects::aoutToken() const
{
    if (!available()) return 0;
    audio_output_t* aout = vlc_player_aout_Hold(m_ctx->getIntf()->p_player);
    const quintptr token = reinterpret_cast<quintptr>(aout);
    if (aout) aout_Release(aout);
    return token;
}

bool AudioEffects::validFilter(const QString& filter)
{
    return filters.contains(filter);
}

bool AudioEffects::filterAvailable(const QString& filter) const
{
    if (!available() || !validFilter(filter))
        return false;
    const QByteArray id = filter.toUtf8();
    module_t* module = module_find(id.constData());
    return module && module_provides(module, "audio filter");
}

QStringList AudioEffects::optionNames(const QString& filter)
{
    if (filter == "equalizer") return equalizer;
    if (filter == "compressor") return compressor;
    if (filter == "spatializer") return spatializer;
    if (filter == "stereo_widen") return widener;
    return {};
}

bool AudioEffects::validOption(const QString& name)
{
    for (const QString& filter : filters)
        if (optionNames(filter).contains(name))
            return true;
    return false;
}

QVariant AudioEffects::defaultValue(const QString& name)
{
    const QByteArray id = name.toUtf8();
    const module_config_t* option = config_FindConfig(id.constData());
    if (!option) return {};
    if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_FLOAT) return option->orig.f;
    if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_BOOL) return bool(option->orig.i);
    if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_STRING) return QString::fromUtf8(option->orig.psz ? option->orig.psz : "");
    return {};
}

QString AudioEffects::chain() const
{
    if (!available()) return {};
    audio_output_t* aout = vlc_player_aout_Hold(m_ctx->getIntf()->p_player);
    if (!aout) return {};
    const QString value = fromVlc(var_GetString(aout, "audio-filter"));
    aout_Release(aout);
    return value;
}

bool AudioEffects::filterEnabled(const QString& filter) const
{
    return validFilter(filter) && chainItems(chain()).contains(filter);
}

QVariant AudioEffects::readValue(const QString& name) const
{
    if (!available() || !validOption(name)) return {};
    const QByteArray id = name.toUtf8();
    const module_config_t* option = config_FindConfig(id.constData());
    if (!option) return {};
    audio_output_t* aout = vlc_player_aout_Hold(m_ctx->getIntf()->p_player);
    QVariant value;
    if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_FLOAT)
        value = aout && var_Type(aout, id.constData()) ? var_GetFloat(aout, id.constData()) : config_GetFloat(id.constData());
    else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_BOOL)
        value = bool(aout && var_Type(aout, id.constData()) ? var_GetBool(aout, id.constData()) : config_GetInt(id.constData()));
    else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_STRING)
        value = aout && var_Type(aout, id.constData()) ? fromVlc(var_GetString(aout, id.constData()))
                                                       : fromVlc(config_GetPsz(id.constData()));
    if (aout) aout_Release(aout);
    return value;
}

QVariant AudioEffects::parameterValue(const QString& name) const { return readValue(name); }
double AudioEffects::preamp() const { return readValue("equalizer-preamp").toDouble(); }
bool AudioEffects::twoPass() const { return readValue("equalizer-2pass").toBool(); }
QString AudioEffects::preset() const
{
    const QString id = readValue("equalizer-preset").toString();
    const QString saved = readValue("equalizer-bands").toString();
    if (saved.isEmpty()) return id;
    const QVariantList current = bands();
    for (int i = 0; i < NB_PRESETS; ++i) {
        if (id != QString::fromUtf8(preset_list[i])) continue;
        for (int band = 0; band < EQZ_BANDS_MAX; ++band)
            if (std::abs(current[band].toDouble() - eqz_preset_10b[i].f_amp[band]) > 0.01)
                return {};
        return std::abs(preamp() - eqz_preset_10b[i].f_preamp) <= 0.01 ? id : QString();
    }
    return {};
}

QVariantList AudioEffects::presets() const
{
    QVariantList result;
    for (int i = 0; i < NB_PRESETS; ++i) {
        QVariantList gains;
        for (int band = 0; band < EQZ_BANDS_MAX; ++band)
            gains << eqz_preset_10b[i].f_amp[band];
        result << QVariantMap{{"id", QString::fromUtf8(preset_list[i])},
                              {"name", qtr(preset_list_text[i])},
                              {"bands", gains}};
    }
    return result;
}

QVariantList AudioEffects::frequencies() const
{
    const bool vlcBands = readValue("equalizer-vlcfreqs").toBool();
    const float* table = vlcBands ? f_vlc_frequency_table_10b : f_iso_frequency_table_10b;
    QVariantList result;
    for (int i = 0; i < EQZ_BANDS_MAX; ++i) result << table[i];
    return result;
}

QVariantList AudioEffects::bands() const
{
    QStringList values = readValue("equalizer-bands").toString().split(' ', Qt::SkipEmptyParts);
    const QString id = readValue("equalizer-preset").toString();
    int presetIndex = -1;
    for (int i = 0; i < NB_PRESETS; ++i)
        if (id == QString::fromUtf8(preset_list[i])) { presetIndex = i; break; }
    QVariantList result;
    for (int i = 0; i < EQZ_BANDS_MAX; ++i) {
        if (i < values.size()) result << QLocale::c().toDouble(values[i]);
        else result << (presetIndex >= 0 ? eqz_preset_10b[presetIndex].f_amp[i] : 0.0);
    }
    return result;
}

QVariantList AudioEffects::parameters(const QString& filter) const
{
    QVariantList result;
    if (!filterAvailable(filter)) return result;
    for (const QString& name : optionNames(filter)) {
        const QByteArray id = name.toUtf8();
        const module_config_t* option = config_FindConfig(id.constData());
        if (!option) continue;
        QVariantMap item{{"id", name}, {"name", QString::fromUtf8(option->psz_text ? option->psz_text : id.constData())},
                         {"value", readValue(name)}, {"default", defaultValue(name)}};
        if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_FLOAT) {
            item["type"] = "float";
            if (option->min.f != option->max.f) {
                item["minimum"] = option->min.f;
                item["maximum"] = option->max.f;
            }
        } else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_BOOL) item["type"] = "bool";
        else item["type"] = "string";
        result << item;
    }
    return result;
}

bool AudioEffects::fail(const QString& reason)
{
    m_lastError = reason;
    emit errorChanged();
    return false;
}

void AudioEffects::clearError()
{
    if (m_lastError.isEmpty()) return;
    m_lastError.clear();
    emit errorChanged();
}

bool AudioEffects::requirePreview()
{
    if (!m_transactionActive) return fail(tr("Open audio effects before changing them."));
    if (!activeAudio()) return fail(tr("No active audio output is available."));
    if (aoutToken() != m_snapshotAout) return fail(tr("Audio output changed during the preview."));
    return true;
}

bool AudioEffects::begin()
{
    if (!activeAudio()) return fail(tr("No active audio output is available."));
    if (m_transactionActive && aoutToken() == m_snapshotAout) return true;
    m_snapshotChain = chain();
    m_snapshotAout = aoutToken();
    m_snapshotValues.clear();
    for (const QString& filter : filters)
        for (const QString& name : optionNames(filter))
            m_snapshotValues.insert(name, readValue(name));
    m_transactionActive = true;
    clearError();
    emit stateChanged();
    return true;
}

bool AudioEffects::writeValue(const QString& name, const QVariant& value)
{
    if (!requirePreview() || !validOption(name)) return false;
    const QByteArray id = name.toUtf8();
    const module_config_t* option = config_FindConfig(id.constData());
    if (!option) return fail(tr("Audio effect option is unavailable."));
    audio_output_t* aout = vlc_player_aout_Hold(m_ctx->getIntf()->p_player);
    if (!aout) return fail(tr("No active audio output is available."));
    const int type = config_GetType(id.constData());
    if (var_Type(aout, id.constData()) == 0 && var_Create(aout, id.constData(), type | VLC_VAR_DOINHERIT) != VLC_SUCCESS) {
        aout_Release(aout);
        return fail(tr("The audio effect value could not be prepared."));
    }
    int result = VLC_EGENERIC;
    if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_FLOAT) {
        const double number = value.toDouble();
        if (std::isfinite(number) && (option->min.f == option->max.f ||
                                      (number >= option->min.f && number <= option->max.f)))
            result = var_SetFloat(aout, id.constData(), float(number));
    } else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_BOOL)
        result = var_SetBool(aout, id.constData(), value.toBool());
    else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_STRING) {
        const QByteArray bytes = value.toString().toUtf8();
        result = var_SetString(aout, id.constData(), bytes.constData());
    }
    aout_Release(aout);
    if (result != VLC_SUCCESS) return fail(tr("The audio effect value could not be applied."));
    clearError();
    emit stateChanged();
    return true;
}

bool AudioEffects::setParameter(const QString& name, double value)
{
    if (!validOption(name) || config_GetType(name.toUtf8().constData()) != VLC_VAR_FLOAT)
        return fail(tr("Unknown audio effect parameter."));
    return writeValue(name, value);
}

bool AudioEffects::setFilterEnabled(const QString& filter, bool enabled)
{
    if (!filterAvailable(filter)) return fail(tr("Audio filter is unavailable."));
    if (!requirePreview()) return false;
    if (filterEnabled(filter) == enabled) return true;
    // Materialize the real bands before loading the filter. The VLC module
    // rejects an empty bands string even when a preset exists.
    if (enabled && filter == "equalizer" && readValue("equalizer-bands").toString().isEmpty()) {
        QStringList values;
        for (const QVariant& value : bands()) values << QLocale::c().toString(value.toDouble(), 'f', 3);
        if (!writeValue("equalizer-bands", values.join(' '))) return false;
    }
    const QByteArray id = filter.toUtf8();
    if (vlc_player_aout_EnableFilter(m_ctx->getIntf()->p_player, id.constData(), enabled) != VLC_SUCCESS
        || filterEnabled(filter) != enabled)
        return fail(tr("The audio filter could not be applied."));
    clearError();
    emit stateChanged();
    return true;
}

bool AudioEffects::setPreset(const QString& name)
{
    int index = -1;
    for (int i = 0; i < NB_PRESETS; ++i)
        if (name == QString::fromUtf8(preset_list[i])) { index = i; break; }
    if (index < 0) return fail(tr("Unknown equalizer preset."));
    if (!writeValue("equalizer-preset", name)) return false;
    if (!writeValue("equalizer-preamp", eqz_preset_10b[index].f_preamp)) return false;
    return writeValue("equalizer-bands", presetBands(index));
}

bool AudioEffects::setBand(int index, double value)
{
    if (index < 0 || index >= EQZ_BANDS_MAX || !std::isfinite(value) || value < -20 || value > 20)
        return fail(tr("Equalizer band is outside its range."));
    if (!requirePreview()) return false;
    QStringList values;
    for (const QVariant& band : bands())
        values << QLocale::c().toString(band.toDouble(), 'f', 3);
    values[index] = QLocale::c().toString(value, 'f', 3);
    return writeValue("equalizer-bands", values.join(' '));
}

bool AudioEffects::setPreamp(double value)
{
    if (!std::isfinite(value))
        return fail(tr("Equalizer preamp must be finite."));
    return writeValue("equalizer-preamp", value);
}

bool AudioEffects::setTwoPass(bool enabled) { return writeValue("equalizer-2pass", enabled); }

bool AudioEffects::resetDefaults(const QString& filter)
{
    if (!filterAvailable(filter) || !requirePreview()) return false;
    if (filter == "equalizer") {
        // The module default is the flat preset. Its callback also supplies ten bands.
        if (!setPreset(defaultValue("equalizer-preset").toString())) return false;
    }
    for (const QString& name : optionNames(filter)) {
        if (filter == "equalizer" && (name == "equalizer-preset" || name == "equalizer-bands")) continue;
        if (!writeValue(name, defaultValue(name))) return false;
    }
    return true;
}

bool AudioEffects::cancel()
{
    if (!m_transactionActive) return true;
    if (!activeAudio() || aoutToken() != m_snapshotAout) {
        m_transactionActive = false;
        m_snapshotValues.clear();
        emit stateChanged();
        return fail(tr("Audio output changed; the previous preview can no longer be restored."));
    }
    // Restore the original effect values before restoring the original chain.
    for (const QString& filter : filters)
        for (const QString& name : optionNames(filter)) {
            const QVariant value = m_snapshotValues.value(name);
            if (value.isValid() && !writeValue(name, value)) return false;
        }
    audio_output_t* aout = vlc_player_aout_Hold(m_ctx->getIntf()->p_player);
    if (!aout) return fail(tr("No active audio output is available."));
    const QByteArray bytes = m_snapshotChain.toUtf8();
    const int result = var_SetString(aout, "audio-filter", bytes.constData());
    aout_Release(aout);
    if (result != VLC_SUCCESS) return fail(tr("Audio filter preview could not be restored."));
    m_transactionActive = false;
    m_snapshotValues.clear();
    clearError();
    emit stateChanged();
    return true;
}

bool AudioEffects::save()
{
    if (!requirePreview()) return false;
    QHash<QString, QVariant> configBefore;
    const auto putConfig = [](const QString& name, const QVariant& value) {
        const QByteArray id = name.toUtf8();
        const module_config_t* option = config_FindConfig(id.constData());
        if (!option || !value.isValid()) return;
        if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_FLOAT) config_PutFloat(id.constData(), value.toFloat());
        else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_BOOL) config_PutInt(id.constData(), value.toBool());
        else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_STRING) {
            const QByteArray bytes = value.toString().toUtf8();
            config_PutPsz(id.constData(), bytes.constData());
        }
    };
    for (const QString& filter : filters) {
        for (const QString& name : optionNames(filter)) {
            const QVariant value = readValue(name);
            const QByteArray id = name.toUtf8();
            const module_config_t* option = config_FindConfig(id.constData());
            if (!option || !value.isValid()) continue;
            if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_FLOAT) configBefore.insert(name, config_GetFloat(id.constData()));
            else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_BOOL) configBefore.insert(name, bool(config_GetInt(id.constData())));
            else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_STRING) configBefore.insert(name, fromVlc(config_GetPsz(id.constData())));
            putConfig(name, value);
        }
    }
    const QString oldFilters = fromVlc(config_GetPsz("audio-filter"));
    const QByteArray filtersBytes = chain().toUtf8();
    config_PutPsz("audio-filter", filtersBytes.constData());
    if (config_SaveConfigFile(m_ctx->getIntf()) != 0) {
        for (auto it = configBefore.cbegin(); it != configBefore.cend(); ++it)
            putConfig(it.key(), it.value());
        const QByteArray oldBytes = oldFilters.toUtf8();
        config_PutPsz("audio-filter", oldBytes.constData());
        return fail(tr("Audio effect settings could not be saved."));
    }
    m_transactionActive = false;
    m_snapshotValues.clear();
    clearError();
    emit stateChanged();
    return true;
}
