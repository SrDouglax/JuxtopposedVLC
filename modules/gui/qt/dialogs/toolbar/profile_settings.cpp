/****************************************************************************
 * profile_settings.cpp: Transactional per-profile preferences
 ****************************************************************************/
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "profile_settings.hpp"
#include "dialogs/preferences/catalog.hpp"
#include "dialogs/preferences/config_values.hpp"
#include "maininterface/mainctx.hpp"
#include "util/color_scheme_model.hpp"
#include "qt.hpp"

#include <QSettings>
#include <QSet>
#include <QColor>
#include <vlc_aout.h>
#include <vlc_modules.h>
#include <vlc_player.h>
#include <vlc_variables.h>
#include <vlc_vout.h>
#include <cstdlib>
#include <cstring>

namespace {
// Accounts, credentials, endpoints, file locations, remote control and process
// integration are owned by the installation, never by a toolbar profile.
const QSet<QString> globalKeys {
    "lastfm-username", "lastfm-password", "scrobbler-url", "http-proxy",
    "http-proxy-pwd", "logfile", "sub-autodetect-path", "input-record-path",
    "extraintf", "control", "file-logging", "one-instance",
    "one-instance-when-started-from-file"
};

const QStringList audioOptions {
    "audio-filter", "equalizer-preset", "equalizer-bands", "equalizer-preamp",
    "equalizer-2pass", "equalizer-vlcfreqs", "compressor-rms-peak",
    "compressor-attack", "compressor-release", "compressor-threshold",
    "compressor-ratio", "compressor-knee", "compressor-makeup-gain",
    "spatializer-roomsize", "spatializer-width", "spatializer-wet",
    "spatializer-dry", "spatializer-damp", "stereowiden-delay",
    "stereowiden-feedback", "stereowiden-crossfeed", "stereowiden-dry-mix"
};
const QStringList videoOptions {
    "video-filter", "crop", "crop-top", "crop-bottom", "crop-left", "crop-right",
    "hue", "brightness", "contrast", "saturation", "gamma", "sharpen-sigma",
    "gradfun-radius", "grain-variance", "extract-component", "colorthres-color",
    "colorthres-saturationthres", "colorthres-similaritythres", "posterize-level",
    "gradient-mode", "gradient-color", "gradient-cartoon", "sepia-intensity"
};

QStringList profileKeys()
{
    QStringList keys;
    for (size_t i = 0; i < PrefsCatalog::count(); ++i) {
        const QString key = QString::fromLatin1(PrefsCatalog::options()[i].name);
        if (!globalKeys.contains(key)) keys.append(key);
    }
    keys.append(audioOptions);
    keys.append(videoOptions);
    // The shortcut editor exposes both local and global hotkeys as settings.
    if (module_t *main = module_get_main()) {
        unsigned count = 0;
        module_config_t *items = module_config_get(main, &count);
        for (unsigned i = 0; items && i < count; ++i) {
            const module_config_t &item = items[i];
            if (item.i_type != CONFIG_ITEM_KEY || !item.psz_name
                || !item.psz_text || !*item.psz_text
                || strncmp(item.psz_name, "global-", 7) == 0)
                continue;
            const QString key = QString::fromLatin1(item.psz_name);
            keys.append(key);
            const QString global = QStringLiteral("global-") + key;
            if (config_FindConfig(global.toUtf8().constData())) keys.append(global);
        }
        if (items) module_config_free(items);
    }
    keys.removeDuplicates();
    return keys;
}

bool safeOption(const QString &key)
{
    const QByteArray id = key.toUtf8();
    const module_config_t *option = config_FindConfig(id.constData());
    if (!option || option->i_type == CONFIG_ITEM_DIRECTORY
        || option->i_type == CONFIG_ITEM_LOADFILE
        || option->i_type == CONFIG_ITEM_SAVEFILE
        || option->i_type == CONFIG_ITEM_PASSWORD)
        return false;
    return ConfigValues::read(key).isValid();
}

bool setLive(vlc_object_t *output, const QString &key, const QVariant &value)
{
    const QByteArray id = key.toUtf8();
    if (!output || !var_Type(output, id.constData())) return true;
    switch (var_Type(output, id.constData()) & VLC_VAR_TYPE) {
    case VLC_VAR_BOOL: return var_SetBool(output, id.constData(), value.toBool()) == VLC_SUCCESS;
    case VLC_VAR_INTEGER: return var_SetInteger(output, id.constData(), value.toLongLong()) == VLC_SUCCESS;
    case VLC_VAR_FLOAT: return var_SetFloat(output, id.constData(), value.toFloat()) == VLC_SUCCESS;
    case VLC_VAR_STRING: {
        const QByteArray bytes = value.toString().toUtf8();
        return var_SetString(output, id.constData(), bytes.constData()) == VLC_SUCCESS;
    }
    default: return true;
    }
}

bool applyLive(MainCtx *ctx, const QVariantMap &values)
{
    if (!ctx || !ctx->getIntf() || !ctx->getIntf()->p_player) return true;
    auto *player = ctx->getIntf()->p_player;
    audio_output_t *aout = vlc_player_aout_Hold(player);
    vout_thread_t *vout = vlc_player_vout_Hold(player);
    bool ok = true;
    for (auto it = values.cbegin(); it != values.cend() && ok; ++it) {
        if (it.key() == QLatin1String("audio-filter")
            || it.key() == QLatin1String("video-filter")) continue;
        if (aout && audioOptions.contains(it.key()))
            ok = setLive(VLC_OBJECT(aout), it.key(), it.value());
        else if (vout && videoOptions.contains(it.key()))
            ok = setLive(VLC_OBJECT(vout), it.key(), it.value());
    }
    if (ok && aout && values.contains("audio-filter")) {
        char *chain = var_GetString(aout, "audio-filter");
        const QStringList oldFilters = QString::fromUtf8(chain ? chain : "")
                                           .split(':', Qt::SkipEmptyParts);
        free(chain);
        const QStringList nextFilters = values.value("audio-filter").toString()
                                            .split(':', Qt::SkipEmptyParts);
        for (const QString &filter : oldFilters) {
            if (!nextFilters.contains(filter)) {
                const QByteArray id = filter.toUtf8();
                if (vlc_player_aout_EnableFilter(player, id.constData(), false) != VLC_SUCCESS)
                    ok = false;
            }
        }
        for (const QString &filter : nextFilters) {
            if (!oldFilters.contains(filter)) {
                const QByteArray id = filter.toUtf8();
                if (vlc_player_aout_EnableFilter(player, id.constData(), true) != VLC_SUCCESS)
                    ok = false;
            }
        }
    }
    if (ok && vout && values.contains("video-filter"))
        ok = setLive(VLC_OBJECT(vout), "video-filter", values.value("video-filter"));
    if (aout) aout_Release(aout);
    if (vout) vout_Release(vout);
    return ok;
}
}

QVariantMap ProfileSettings::capture(MainCtx *ctx, QSettings *settings)
{
    QVariantMap values;
    for (const QString &key : profileKeys())
        if (safeOption(key)) values.insert(key, ConfigValues::read(key));
    return {{"version", 1}, {"config", values},
            {"accent", settings->value("redesign/accent", "#D37918")},
            {"developerMode", settings->value("redesign/developer-mode", false)},
            {"theme", ctx ? ctx->getColorScheme()->currentIndex() : 0}};
}

bool ProfileSettings::apply(MainCtx *ctx, QSettings *settings,
                            const QVariantMap &target, QString *error)
{
    if (target.isEmpty()) return true; // Profiles saved before this feature inherit current settings.
    if (!ctx || !ctx->getIntf() || target.value("version").toInt() != 1) {
        if (error) *error = QStringLiteral("Profile settings are unavailable or incompatible.");
        return false;
    }
    const QVariantMap targetConfig = target.value("config").toMap();
    const QStringList allowed = profileKeys();
    QVariantMap before;
    QVariantMap changes;
    for (auto it = targetConfig.cbegin(); it != targetConfig.cend(); ++it) {
        if (!allowed.contains(it.key()) || !safeOption(it.key())) {
            if (error) *error = QStringLiteral("Profile contains an unavailable setting: %1").arg(it.key());
            return false;
        }
        const QVariant current = ConfigValues::read(it.key());
        if (current != it.value()) {
            before.insert(it.key(), current);
            changes.insert(it.key(), it.value());
        }
    }
    const QVariant oldAccent = settings->value("redesign/accent", "#D37918");
    const QVariant oldDeveloperMode = settings->value("redesign/developer-mode", false);
    const int oldTheme = ctx->getColorScheme()->currentIndex();
    const QString accent = target.value("accent").toString();
    const int theme = target.value("theme").toInt();
    if (!QColor::isValidColor(accent) || theme < 0
        || theme >= ctx->getColorScheme()->rowCount()) {
        if (error) *error = QStringLiteral("Profile appearance is invalid.");
        return false;
    }

    const bool appearanceChanged = oldAccent.toString() != accent
        || oldTheme != theme
        || oldDeveloperMode != target.value("developerMode", false);
    if (appearanceChanged) {
        settings->setValue("redesign/accent", accent);
        settings->setValue("redesign/developer-mode", target.value("developerMode", false));
        settings->setValue("MainWindow/color-scheme-index", theme);
        settings->sync();
    }
    if (settings->status() != QSettings::NoError) {
        settings->setValue("redesign/accent", oldAccent);
        settings->setValue("redesign/developer-mode", oldDeveloperMode);
        settings->setValue("MainWindow/color-scheme-index", oldTheme);
        if (error) *error = QStringLiteral("Could not save profile appearance.");
        return false;
    }
    bool ok = true;
    for (auto it = changes.cbegin(); it != changes.cend(); ++it)
        if (!ConfigValues::put(it.key(), it.value())) { ok = false; break; }
    if (ok) ok = applyLive(ctx, changes);
    if (ok && !changes.isEmpty()) ok = config_SaveConfigFile(ctx->getIntf()) == 0;
    if (!ok) {
        for (auto it = before.cbegin(); it != before.cend(); ++it)
            ConfigValues::put(it.key(), it.value());
        applyLive(ctx, before);
        config_SaveConfigFile(ctx->getIntf());
        settings->setValue("redesign/accent", oldAccent);
        settings->setValue("redesign/developer-mode", oldDeveloperMode);
        settings->setValue("MainWindow/color-scheme-index", oldTheme);
        settings->sync();
        if (error) *error = QStringLiteral("Could not apply profile settings; previous values restored.");
        return false;
    }
    ctx->getColorScheme()->setCurrentIndex(theme);
    return true;
}
