/*****************************************************************************
 * video_effects.cpp: Transactional video effects for the Qt Quick player
 *****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "video_effects.hpp"
#include "maininterface/mainctx.hpp"
#include "qt.hpp"
#include "dialogs/preferences/config_values.hpp"

#include <QByteArray>
#include <cmath>
#include <cstdlib>
#include <limits>
#include <vlc_configuration.h>
#include <vlc_modules.h>
#include <vlc_player.h>
#include <vlc_plugin.h>
#include <vlc_variables.h>
#include <vlc_vout.h>

namespace {
const QStringList filters = {"adjust", "sharpen", "gradfun", "grain", "extract", "colorthres",
                             "invert", "posterize", "gradient", "sepia"};
const QStringList cropSides = {"top", "bottom", "left", "right"};
const QHash<QString, QStringList> options = {
    {"adjust", {"hue", "brightness", "contrast", "saturation", "gamma"}},
    {"sharpen", {"sharpen-sigma"}}, {"gradfun", {"gradfun-radius"}},
    {"grain", {"grain-variance"}}, {"extract", {"extract-component"}},
    {"colorthres", {"colorthres-color", "colorthres-saturationthres", "colorthres-similaritythres"}},
    {"invert", {}}, {"posterize", {"posterize-level"}},
    {"gradient", {"gradient-mode", "gradient-color", "gradient-cartoon"}},
    {"sepia", {"sepia-intensity"}}
};
QString own(char* bytes)
{
    const QString result = bytes ? QString::fromUtf8(bytes) : QString();
    free(bytes);
    return result;
}
QString cropName(const QString& side) { return "crop-" + side; }
}

VideoEffects::VideoEffects(QObject* parent) : QObject(parent) {}
VideoEffects::~VideoEffects() { if (m_transactionActive) cancel(); }
MainCtx* VideoEffects::ctx() const { return m_ctx; }
void VideoEffects::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx) return;
    if (m_transactionActive) cancel();
    m_ctx = ctx;
    m_transactionActive = false;
    m_snapshotValues.clear();
    m_configSnapshot.clear();
    emit ctxChanged(ctx);
    changed();
}
bool VideoEffects::available() const { return m_ctx && m_ctx->getIntf() && m_ctx->getIntf()->p_player; }
bool VideoEffects::activeVideo() const
{
    if (!available()) return false;
    size_t count = 0;
    vout_thread_t** vouts = vlc_player_vout_HoldAll(m_ctx->getIntf()->p_player, &count);
    for (size_t i = 0; i < count; ++i) vout_Release(vouts[i]);
    free(vouts);
    return count > 0;
}
quintptr VideoEffects::voutToken() const
{
    if (!available()) return 0;
    vout_thread_t* vout = vlc_player_vout_Hold(m_ctx->getIntf()->p_player);
    const quintptr token = reinterpret_cast<quintptr>(vout);
    if (vout) vout_Release(vout);
    return token;
}
bool VideoEffects::validFilter(const QString& filter) { return filters.contains(filter); }
QStringList VideoEffects::optionNames(const QString& filter) { return options.value(filter); }
bool VideoEffects::validOption(const QString& name)
{
    for (const QString& filter : filters)
        if (optionNames(filter).contains(name)) return true;
    return false;
}
bool VideoEffects::validSide(const QString& side) { return cropSides.contains(side); }
bool VideoEffects::filterAvailable(const QString& filter) const
{
    if (!available() || !validFilter(filter)) return false;
    const QByteArray id = filter.toUtf8();
    module_t* module = module_find(id.constData());
    return module && module_provides(module, "video filter");
}
QString VideoEffects::filterChain() const
{
    if (!available()) return {};
    vout_thread_t* vout = vlc_player_vout_Hold(m_ctx->getIntf()->p_player);
    if (!vout) return {};
    const QString value = own(var_GetString(vout, "video-filter"));
    vout_Release(vout);
    return value;
}
bool VideoEffects::filterEnabled(const QString& filter) const
{
    return validFilter(filter) && filterChain().split(':', Qt::SkipEmptyParts).contains(filter);
}
QVariant VideoEffects::getConfig(const QString& name)
{
    const QByteArray id = name.toUtf8();
    const module_config_t* option = config_FindConfig(id.constData());
    if (!option) return {};
    switch (CONFIG_CLASS(option->i_type)) {
        case CONFIG_ITEM_FLOAT: return config_GetFloat(id.constData());
        case CONFIG_ITEM_BOOL: return bool(config_GetInt(id.constData()));
        case CONFIG_ITEM_INTEGER: return qlonglong(config_GetInt(id.constData()));
        case CONFIG_ITEM_STRING: return own(config_GetPsz(id.constData()));
        default: return {};
    }
}
QVariant VideoEffects::defaultValue(const QString& name)
{
    const QByteArray id = name.toUtf8();
    const module_config_t* option = config_FindConfig(id.constData());
    if (!option) return {};
    switch (CONFIG_CLASS(option->i_type)) {
        case CONFIG_ITEM_FLOAT: return option->orig.f;
        case CONFIG_ITEM_BOOL: return bool(option->orig.i);
        case CONFIG_ITEM_INTEGER: return qlonglong(option->orig.i);
        case CONFIG_ITEM_STRING: return QString::fromUtf8(option->orig.psz ? option->orig.psz : "");
        default: return {};
    }
}
QVariant VideoEffects::readValue(const QString& name) const
{
    if (!available() || !validOption(name)) return {};
    const QByteArray id = name.toUtf8();
    const int type = config_GetType(id.constData());
    vout_thread_t* vout = vlc_player_vout_Hold(m_ctx->getIntf()->p_player);
    if (!vout) return {};
    const bool present = var_Type(vout, id.constData()) != 0;
    QVariant value;
    if (present && type == VLC_VAR_FLOAT) value = var_GetFloat(vout, id.constData());
    else if (present && type == VLC_VAR_BOOL) value = var_GetBool(vout, id.constData());
    else if (present && type == VLC_VAR_INTEGER) value = qlonglong(var_GetInteger(vout, id.constData()));
    else if (present && type == VLC_VAR_STRING) value = own(var_GetString(vout, id.constData()));
    else value = getConfig(name);
    vout_Release(vout);
    return value;
}
QVariant VideoEffects::parameterValue(const QString& name) const { return readValue(name); }
QVariantList VideoEffects::choices(const QString& name) const
{
    QVariantList result;
    if (!validOption(name)) return result;
    const QByteArray id = name.toUtf8();
    const module_config_t* option = config_FindConfig(id.constData());
    if (!option) return result;
    for (int i = 0; i < option->list_count; ++i) {
        const char* label = option->list_text ? option->list_text[i] : nullptr;
        if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_STRING)
            result << QVariantMap{{"id", QString::fromUtf8(option->list.psz[i])},
                                  {"name", qtr(label ? label : option->list.psz[i])}};
        else if (CONFIG_CLASS(option->i_type) == CONFIG_ITEM_INTEGER)
            result << QVariantMap{{"id", option->list.i[i]}, {"name", qtr(label ? label : "")}};
    }
    return result;
}
QVariantList VideoEffects::parameters(const QString& filter) const
{
    QVariantList result;
    if (!filterAvailable(filter)) return result;
    for (const QString& name : optionNames(filter)) {
        const QByteArray id = name.toUtf8();
        const module_config_t* option = config_FindConfig(id.constData());
        if (!option) continue;
        QVariantMap item{{"id", name}, {"name", qtr(option->psz_text ? option->psz_text : id.constData())},
                         {"value", readValue(name)}, {"default", defaultValue(name)}};
        switch (CONFIG_CLASS(option->i_type)) {
            case CONFIG_ITEM_FLOAT:
                item["type"] = "float";
                if (option->min.f != option->max.f) {
                    item["minimum"] = option->min.f;
                    item["maximum"] = option->max.f;
                }
                break;
            case CONFIG_ITEM_INTEGER:
                item["type"] = option->i_type == CONFIG_ITEM_RGB || name == "extract-component" ? "color" : "integer";
                if (option->min.i != option->max.i) {
                    item["minimum"] = qlonglong(option->min.i);
                    item["maximum"] = qlonglong(option->max.i);
                }
                break;
            case CONFIG_ITEM_BOOL: item["type"] = "bool"; break;
            case CONFIG_ITEM_STRING: item["type"] = "choice"; break;
        }
        result << item;
    }
    return result;
}
int VideoEffects::cropValue(const QString& side) const
{
    if (!available() || !validSide(side)) return 0;
    vout_thread_t* vout = vlc_player_vout_Hold(m_ctx->getIntf()->p_player);
    if (!vout) return 0;
    const QByteArray id = cropName(side).toUtf8();
    const int value = int(var_GetInteger(vout, id.constData()));
    vout_Release(vout);
    return value;
}
bool VideoEffects::fail(const QString& reason) { m_lastError = reason; emit errorChanged(); return false; }
void VideoEffects::clearError() { if (!m_lastError.isEmpty()) { m_lastError.clear(); emit errorChanged(); } }
void VideoEffects::changed() { ++m_revision; emit stateChanged(); }
bool VideoEffects::requirePreview()
{
    if (!m_transactionActive) return fail(tr("Open video effects before changing them."));
    if (!activeVideo()) return fail(tr("No active video output is available."));
    if (voutToken() != m_snapshotVout) return fail(tr("Video output changed during the preview."));
    return true;
}
bool VideoEffects::begin()
{
    if (!activeVideo()) return fail(tr("No active video output is available."));
    if (m_transactionActive && voutToken() == m_snapshotVout) return true;
    m_snapshotVout = voutToken();
    m_snapshotChain = filterChain();
    if (vout_thread_t* vout = vlc_player_vout_Hold(m_ctx->getIntf()->p_player)) {
        m_snapshotCropString = own(var_GetString(vout, "crop"));
        vout_Release(vout);
    }
    m_snapshotValues.clear();
    m_snapshotCrop.clear();
    m_configSnapshot.clear();
    for (const QString& filter : filters)
        for (const QString& name : optionNames(filter)) m_snapshotValues.insert(name, readValue(name));
    for (const QString& name : m_snapshotValues.keys()) {
        const QVariant value = getConfig(name);
        if (value.isValid()) m_configSnapshot.insert(name, value);
    }
    m_configSnapshot.insert("video-filter", getConfig("video-filter"));
    m_configSnapshot.insert("crop", getConfig("crop"));
    for (const QString& side : cropSides) m_snapshotCrop.insert(side, cropValue(side));
    m_transactionActive = true;
    clearError(); changed();
    return true;
}
bool VideoEffects::writeValue(const QString& name, const QVariant& value)
{
    if (!requirePreview() || !validOption(name)) return false;
    const QByteArray id = name.toUtf8();
    const module_config_t* option = config_FindConfig(id.constData());
    if (!option) return fail(tr("Video effect option is unavailable."));
    const int type = config_GetType(id.constData());
    vout_thread_t* vout = vlc_player_vout_Hold(m_ctx->getIntf()->p_player);
    if (!vout) return fail(tr("No active video output is available."));
    if (var_Type(vout, id.constData()) == 0 && var_Create(vout, id.constData(), type | VLC_VAR_DOINHERIT) != VLC_SUCCESS) {
        vout_Release(vout);
        return fail(tr("The video effect value could not be prepared."));
    }
    int result = VLC_EGENERIC;
    const auto cls = CONFIG_CLASS(option->i_type);
    if (cls == CONFIG_ITEM_FLOAT) {
        const double number = value.toDouble();
        if (std::isfinite(number) && (option->min.f == option->max.f ||
                                      (number >= option->min.f && number <= option->max.f)))
            result = var_SetFloat(vout, id.constData(), float(number));
    } else if (cls == CONFIG_ITEM_BOOL)
        result = var_SetBool(vout, id.constData(), value.toBool());
    else if (cls == CONFIG_ITEM_INTEGER) {
        bool ok = false;
        const qlonglong number = value.toLongLong(&ok);
        if (ok && (option->min.i == option->max.i || (number >= option->min.i && number <= option->max.i)))
            result = var_SetInteger(vout, id.constData(), number);
    } else if (cls == CONFIG_ITEM_STRING) {
        const QString candidate = value.toString();
        bool allowed = option->list_count == 0;
        for (int i = 0; i < option->list_count; ++i)
            allowed |= candidate == QString::fromUtf8(option->list.psz[i]);
        if (allowed) {
            const QByteArray bytes = candidate.toUtf8();
            result = var_SetString(vout, id.constData(), bytes.constData());
        }
    }
    vout_Release(vout);
    if (result != VLC_SUCCESS) return fail(tr("The video effect value could not be applied."));
    clearError(); changed();
    return true;
}
bool VideoEffects::setParameter(const QString& name, const QVariant& value) { return writeValue(name, value); }
bool VideoEffects::setFilterEnabled(const QString& filter, bool enabled)
{
    if (!filterAvailable(filter)) return fail(tr("Video filter is unavailable."));
    if (!requirePreview()) return false;
    if (filterEnabled(filter) == enabled) return true;
    QStringList chain = filterChain().split(':', Qt::SkipEmptyParts);
    if (enabled) chain << filter;
    else chain.removeAll(filter);
    const QByteArray value = chain.join(':').toUtf8();
    vout_thread_t* vout = vlc_player_vout_Hold(m_ctx->getIntf()->p_player);
    if (!vout) return fail(tr("No active video output is available."));
    const int result = var_SetString(vout, "video-filter", value.constData());
    vout_Release(vout);
    if (result != VLC_SUCCESS || filterEnabled(filter) != enabled)
        return fail(tr("The video filter could not be applied."));
    clearError(); changed();
    return true;
}
bool VideoEffects::setCrop(const QString& side, int pixels)
{
    if (!validSide(side) || pixels < 0) return fail(tr("Invalid crop value."));
    if (!requirePreview()) return false;
    size_t count = 0;
    vout_thread_t** vouts = vlc_player_vout_HoldAll(m_ctx->getIntf()->p_player, &count);
    if (!vouts || count == 0) { free(vouts); return fail(tr("No active video output is available.")); }
    const QByteArray id = cropName(side).toUtf8();
    bool ok = true;
    for (size_t i = 0; i < count; ++i) {
        ok &= var_SetInteger(vouts[i], id.constData(), pixels) == VLC_SUCCESS;
        vout_Release(vouts[i]);
    }
    free(vouts);
    if (!ok) return fail(tr("Crop could not be applied to every video output."));
    clearError(); changed();
    return true;
}
bool VideoEffects::resetDefaults(const QString& filter)
{
    if (!filterAvailable(filter) || !requirePreview()) return false;
    for (const QString& name : optionNames(filter))
        if (!writeValue(name, defaultValue(name))) return false;
    return true;
}
bool VideoEffects::cancel()
{
    if (!m_transactionActive) return true;
    if (!activeVideo() || voutToken() != m_snapshotVout) {
        m_transactionActive = false; m_snapshotValues.clear(); m_snapshotCrop.clear();
        m_configSnapshot.clear(); changed();
        return fail(tr("Video output changed; the previous preview can no longer be restored."));
    }
    for (const QString& filter : filters)
        for (const QString& name : optionNames(filter)) {
            const QVariant value = m_snapshotValues.value(name);
            if (value.isValid() && !writeValue(name, value)) return false;
        }
    for (const QString& side : cropSides)
        if (!setCrop(side, m_snapshotCrop.value(side))) return false;
    vout_thread_t* vout = vlc_player_vout_Hold(m_ctx->getIntf()->p_player);
    if (!vout) return fail(tr("No active video output is available."));
    const QByteArray chain = m_snapshotChain.toUtf8();
    const int result = var_SetString(vout, "video-filter", chain.constData());
    const QByteArray crop = m_snapshotCropString.toUtf8();
    const int cropResult = var_SetString(vout, "crop", crop.constData());
    vout_Release(vout);
    if (result != VLC_SUCCESS || cropResult != VLC_SUCCESS)
        return fail(tr("Video preview could not be restored."));
    m_transactionActive = false; m_snapshotValues.clear(); m_snapshotCrop.clear();
    m_configSnapshot.clear();
    clearError(); changed();
    return true;
}
bool VideoEffects::prepareConfiguration(QHash<QString, QVariant>& values,
                                        QHash<QString, QVariant>& expected)
{
    if (!requirePreview()) return false;
    vout_thread_t* vout = vlc_player_vout_Hold(m_ctx->getIntf()->p_player);
    if (!vout) return fail(tr("No active video output is available."));
    const QString crop = own(var_GetString(vout, "crop"));
    vout_Release(vout);
    for (auto it = m_configSnapshot.cbegin(); it != m_configSnapshot.cend(); ++it) {
        const QVariant value = it.key() == "video-filter" ? QVariant(filterChain())
                             : it.key() == "crop" ? QVariant(crop) : readValue(it.key());
        if (!value.isValid()) return fail(tr("A video effect value is unavailable."));
        values.insert(it.key(), value);
        expected.insert(it.key(), it.value());
    }
    return true;
}

void VideoEffects::finalizeConfiguration()
{
    m_transactionActive = false; m_snapshotValues.clear(); m_snapshotCrop.clear();
    m_configSnapshot.clear();
    clearError(); changed();
}

bool VideoEffects::save()
{
    QHash<QString, QVariant> values, expected;
    if (!prepareConfiguration(values, expected)) return false;
    QString conflict;
    int result = 0;
    if (!ConfigValues::commit(m_ctx->getIntf(), values, expected, &conflict, &result))
        return fail(result ? tr("Video effect settings could not be saved (error %1).").arg(result)
                           : tr("Video effect setting %1 changed outside this dialog.").arg(conflict));
    finalizeConfiguration();
    return true;
}
