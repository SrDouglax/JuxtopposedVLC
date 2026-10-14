/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#include "modules/gui/qt/medialibrary/opensubtitles_url.hpp"
#include <cassert>
#include <cstdio>
int main()
{
    for (const auto &value : {QString(), QStringLiteral("api.opensubtitles.com"),
        QStringLiteral("https://api.opensubtitles.com"),
        QStringLiteral("https://api.opensubtitles.com/api/v1/")})
        assert(openSubtitlesApiBase(value).resolved(QUrl(QStringLiteral("download"))) ==
               QUrl(QStringLiteral("https://api.opensubtitles.com/api/v1/download")));
    assert(openSubtitlesApiBase(QStringLiteral("vip-api.opensubtitles.com")).host() ==
           QStringLiteral("vip-api.opensubtitles.com"));
    for (const auto &value : {QStringLiteral("http://api.opensubtitles.com"),
        QStringLiteral("https://untrusted.example"), QStringLiteral("https://api.opensubtitles.com/other"),
        QStringLiteral("https://api.opensubtitles.com?x=1"),
        QStringLiteral("https://user:pass@api.opensubtitles.com")})
        assert(openSubtitlesApiBase(value).isEmpty());
    puts("PASS: hostname/full URL/VIP normalization and invalid session rejection");
}
