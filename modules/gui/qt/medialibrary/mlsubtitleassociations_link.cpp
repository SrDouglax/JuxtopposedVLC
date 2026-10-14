/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
#if HAVE_CONFIG_H
# include "config.h"
#endif

#include "mlsubtitleassociations.hpp"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSaveFile>
#include <QStandardPaths>
#include <memory>

#include <vlc_input_item.h>

namespace {
constexpr qint64 maxSubtitleBytes = 20 * 1024 * 1024;

bool isSubtitleName(const QString& name)
{
    enum slave_type type;
    const QByteArray encoded = QFile::encodeName(name);
    return input_item_slave_GetType(encoded.constData(), &type) && type == SLAVE_TYPE_SPU;
}
}

void MLSubtitleAssociations::addLink(const QUrl& url)
{
    addLinkWithName(url, QFileInfo(url.path()).fileName());
}

void MLSubtitleAssociations::addLinkWithName(const QUrl& url, const QString& filename)
{
    if (m_busy)
        return;
    const QString name = QFileInfo(filename).fileName();
    if (name != filename)
    {
        setError(tr("The subtitle filename is invalid."));
        return;
    }
    if (!url.isValid() || url.scheme() != QStringLiteral("https") || url.host().isEmpty() ||
        !url.userInfo().isEmpty() || !isSubtitleName(name))
    {
        setError(tr("Enter a direct HTTPS link to a subtitle file (.srt, .ass, .ssa, .sub, .vtt, .ttml or .smi)."));
        return;
    }

    if (!m_network)
        m_network = new QNetworkAccessManager(this);
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setMaximumRedirectsAllowed(5);
    request.setTransferTimeout(30000);
    request.setRawHeader("Accept", "text/plain, application/octet-stream, */*");

    auto* reply = m_network->get(request);
    m_download = reply;
    m_busy = true;
    m_error.clear();
    emit changed();
    const quint64 revision = m_revision;
    auto payload = std::make_shared<QByteArray>();
    auto tooLarge = std::make_shared<bool>(false);

    connect(reply, &QIODevice::readyRead, this, [reply, payload, tooLarge]() {
        payload->append(reply->readAll());
        if (payload->size() > maxSubtitleBytes)
        {
            *tooLarge = true;
            reply->abort();
        }
    });
    connect(reply, &QNetworkReply::finished, this,
            [this, reply, payload, tooLarge, revision, url, name]() {
        reply->deleteLater();
        if (revision != m_revision || reply != m_download)
            return;
        m_download = nullptr;
        m_busy = false;
        emit changed();

        if (*tooLarge || payload->size() > maxSubtitleBytes)
        {
            setError(tr("The subtitle exceeds the 20 MB download limit."));
            return;
        }
        if (reply->error() != QNetworkReply::NoError ||
            reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() != 200 ||
            reply->url().scheme() != QStringLiteral("https") || payload->isEmpty())
        {
            setError(tr("Could not download the subtitle: %1").arg(reply->errorString()));
            return;
        }

        const QString folder = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                               + QStringLiteral("/subtitles");
        if (!QDir().mkpath(folder))
        {
            setError(tr("Could not create the subtitle storage folder."));
            return;
        }
        const QString hash = QString::fromLatin1(QCryptographicHash::hash(
            url.toString(QUrl::FullyEncoded).toUtf8(), QCryptographicHash::Sha256).toHex());
        const QString path = folder + QLatin1Char('/') + hash + QLatin1Char('.')
                             + QFileInfo(name).suffix().toLower();
        QSaveFile file(path);
        if (!file.open(QIODevice::WriteOnly) || file.write(*payload) != payload->size() || !file.commit())
        {
            setError(tr("Could not save the downloaded subtitle."));
            return;
        }

        const QUrl local = QUrl::fromLocalFile(path);
        addFiles({local});
        for (auto& source : m_sources)
            if (source.url == local)
                source.label = name;
        match();
    });
}
