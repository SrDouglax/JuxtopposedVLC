/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QPointer>
#include <QVariantList>
#include <QUrl>

class QNetworkReply;
class QNetworkRequest;

class MLOpenSubtitles : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList results READ results NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)

public:
    explicit MLOpenSubtitles(QObject* parent = nullptr) : QObject(parent) {}
    QVariantList results() const { return m_results; }
    QString error() const { return m_error; }
    bool busy() const { return m_busy; }

    Q_INVOKABLE void search(const QString& query, const QString& language, const QString& apiKey);
    Q_INVOKABLE void download(int index, const QString& apiKey,
                              const QString& username, const QString& password);
    Q_INVOKABLE void cancel();

signals:
    void changed();
    void fileReady(const QUrl& url, const QString& filename);

private:
    void begin(QNetworkReply* reply);
    void fail(const QString& message);
    QNetworkRequest request(const QUrl& url, const QString& apiKey) const;
    QNetworkAccessManager m_network;
    QPointer<QNetworkReply> m_reply;
    QVariantList m_results;
    QString m_error;
    bool m_busy = false;
    quint64 m_revision = 0;
};
