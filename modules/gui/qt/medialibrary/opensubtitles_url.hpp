/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#pragma once
#include <QUrl>
#include <QString>

// Login responses may contain a bare hostname or a full API URL.
// Accept only the documented API hosts before attaching the bearer token.
inline QUrl openSubtitlesApiBase(QString value)
{
    if (value.isEmpty()) value = QStringLiteral("api.opensubtitles.com");
    if (!value.contains(QStringLiteral("://"))) value.prepend(QStringLiteral("https://"));
    QUrl base(value);
    if (!base.isValid() || base.scheme() != QStringLiteral("https") ||
        (base.host() != QStringLiteral("api.opensubtitles.com") &&
         base.host() != QStringLiteral("vip-api.opensubtitles.com")) ||
        !base.userInfo().isEmpty() || base.port() != -1 ||
        base.hasQuery() || base.hasFragment()) return {};
    const QString path = base.path();
    if (!path.isEmpty() && path != QStringLiteral("/") &&
        path != QStringLiteral("/api/v1") && path != QStringLiteral("/api/v1/")) return {};
    base.setPath(QStringLiteral("/api/v1/"));
    return base;
}
