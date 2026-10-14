/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
#if HAVE_CONFIG_H
# include "config.h"
#endif

#include "mlopensubtitles.hpp"
#include "opensubtitles_url.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrlQuery>

namespace {
constexpr qsizetype maxJsonBytes = 2 * 1024 * 1024;
const QUrl apiUrl(QStringLiteral("https://api.opensubtitles.com/api/v1/"));

QString apiMessage(const QByteArray& body, const QString& fallback)
{
    const auto json = QJsonDocument::fromJson(body).object();
    const QString message = json.value(QStringLiteral("message")).toString();
    return message.isEmpty() ? fallback : message;
}

bool replyOk(QNetworkReply* reply)
{
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    return reply->error() == QNetworkReply::NoError && status >= 200 && status < 300;
}
}

QNetworkRequest MLOpenSubtitles::request(const QUrl& url, const QString& apiKey) const
{
    QNetworkRequest result(url);
    result.setRawHeader("Api-Key", apiKey.toUtf8());
    result.setRawHeader("User-Agent", "VLC-Redesign/1.0");
    result.setRawHeader("Accept", "application/json");
    result.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    result.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                        QNetworkRequest::NoLessSafeRedirectPolicy);
    result.setTransferTimeout(30000);
    return result;
}

void MLOpenSubtitles::begin(QNetworkReply* reply)
{
    m_reply = reply;
    m_busy = true;
    m_error.clear();
    emit changed();
}

void MLOpenSubtitles::fail(const QString& message)
{
    m_busy = false;
    m_error = message;
    emit changed();
}

void MLOpenSubtitles::cancel()
{
    ++m_revision;
    auto* reply = m_reply.data();
    m_reply = nullptr;
    if (reply)
        reply->abort();
    m_busy = false;
    m_error.clear();
    emit changed();
}

void MLOpenSubtitles::search(const QString& query, const QString& language,
                             const QString& apiKey)
{
    cancel();
    m_results.clear();
    if (apiKey.trimmed().isEmpty() || query.trimmed().isEmpty())
    {
        fail(tr("Enter an OpenSubtitles API key and a title to search."));
        return;
    }
    QUrl url = apiUrl.resolved(QUrl(QStringLiteral("subtitles")));
    QUrlQuery params;
    params.addQueryItem(QStringLiteral("query"), query.trimmed());
    if (!language.trimmed().isEmpty())
        params.addQueryItem(QStringLiteral("languages"), language.trimmed().toLower());
    url.setQuery(params);
    auto* reply = m_network.get(request(url, apiKey.trimmed()));
    begin(reply);
    const quint64 revision = m_revision;
    connect(reply, &QNetworkReply::finished, this, [this, reply, revision]() {
        reply->deleteLater();
        if (revision != m_revision || reply != m_reply)
            return;
        m_reply = nullptr;
        const QByteArray body = reply->read(maxJsonBytes + 1);
        if (!replyOk(reply) || body.size() > maxJsonBytes)
        {
            fail(apiMessage(body, tr("OpenSubtitles search failed. Check the API key and network.")));
            return;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(body);
        if (!doc.isObject())
        {
            fail(tr("OpenSubtitles returned an invalid search response."));
            return;
        }
        QVariantList results;
        for (const auto& entry : doc.object().value(QStringLiteral("data")).toArray())
        {
            const auto attributes = entry.toObject().value(QStringLiteral("attributes")).toObject();
            const auto files = attributes.value(QStringLiteral("files")).toArray();
            if (files.isEmpty())
                continue;
            const auto file = files.first().toObject();
            const int fileId = file.value(QStringLiteral("file_id")).toInt();
            if (fileId <= 0)
                continue;
            results.push_back(QVariantMap{
                {"fileId", fileId},
                {"filename", file.value(QStringLiteral("file_name")).toString()},
                {"language", attributes.value(QStringLiteral("language")).toString()},
                {"release", attributes.value(QStringLiteral("release")).toString()}
            });
        }
        m_results = results;
        m_busy = false;
        emit changed();
    });
}

void MLOpenSubtitles::download(int index, const QString& apiKey,
                               const QString& username, const QString& password)
{
    if (m_busy || index < 0 || index >= m_results.size())
        return;
    if (apiKey.trimmed().isEmpty() || username.trimmed().isEmpty() || password.isEmpty())
    {
        fail(tr("Enter your API key and OpenSubtitles account credentials to download."));
        return;
    }
    const auto choice = m_results[index].toMap();
    const int fileId = choice.value(QStringLiteral("fileId")).toInt();
    auto* login = m_network.post(request(apiUrl.resolved(QUrl(QStringLiteral("login"))), apiKey.trimmed()),
        QJsonDocument(QJsonObject{{"username", username.trimmed()}, {"password", password}})
            .toJson(QJsonDocument::Compact));
    begin(login);
    const quint64 revision = m_revision;
    connect(login, &QNetworkReply::finished, this,
            [this, login, revision, fileId, apiKey, choice]() {
        login->deleteLater();
        if (revision != m_revision || login != m_reply)
            return;
        m_reply = nullptr;
        const QByteArray body = login->read(maxJsonBytes + 1);
        if (!replyOk(login) || body.size() > maxJsonBytes)
        {
            fail(apiMessage(body, tr("OpenSubtitles login failed. Check your account credentials.")));
            return;
        }
        const auto loginData = QJsonDocument::fromJson(body).object();
        const QString token = loginData.value(QStringLiteral("token")).toString();
        const QUrl base = openSubtitlesApiBase(loginData.value(QStringLiteral("base_url")).toString());
        if (token.isEmpty() || base.isEmpty())
        {
            fail(tr("OpenSubtitles returned an invalid login session."));
            return;
        }
        QNetworkRequest downloadRequest = request(base.resolved(QUrl(QStringLiteral("download"))), apiKey.trimmed());
        downloadRequest.setRawHeader("Authorization", QByteArray("Bearer ") + token.toUtf8());
        auto* downloadReply = m_network.post(downloadRequest,
            QJsonDocument(QJsonObject{{"file_id", fileId}, {"sub_format", "srt"}})
                .toJson(QJsonDocument::Compact));
        begin(downloadReply);
        connect(downloadReply, &QNetworkReply::finished, this,
                [this, downloadReply, revision, choice]() {
            downloadReply->deleteLater();
            if (revision != m_revision || downloadReply != m_reply)
                return;
            m_reply = nullptr;
            const QByteArray body = downloadReply->read(maxJsonBytes + 1);
            if (!replyOk(downloadReply) || body.size() > maxJsonBytes)
            {
                fail(apiMessage(body, tr("OpenSubtitles download failed. Check your quota.")));
                return;
            }
            const auto payload = QJsonDocument::fromJson(body).object();
            const QUrl link(payload.value(QStringLiteral("link")).toString());
            QString filename = payload.value(QStringLiteral("file_name")).toString();
            if (filename.isEmpty())
                filename = choice.value(QStringLiteral("filename")).toString();
            if (link.scheme() != QStringLiteral("https") || link.host().isEmpty() || filename.isEmpty())
            {
                fail(tr("OpenSubtitles did not return a valid subtitle download link."));
                return;
            }
            m_busy = false;
            emit changed();
            emit fileReady(link, filename);
        });
    });
}
