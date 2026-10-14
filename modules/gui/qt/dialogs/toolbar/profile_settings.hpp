/****************************************************************************
 * profile_settings.hpp: Per-profile, non-secret interface configuration
 ****************************************************************************/
#ifndef VLC_QT_PROFILE_SETTINGS_HPP
#define VLC_QT_PROFILE_SETTINGS_HPP

#include <QVariantMap>
#include <QString>

class MainCtx;
class QSettings;

namespace ProfileSettings {
QVariantMap capture(MainCtx *ctx, QSettings *settings);
bool apply(MainCtx *ctx, QSettings *settings, const QVariantMap &target, QString *error);
}

#endif
