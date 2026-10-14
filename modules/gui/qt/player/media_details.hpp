/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
#pragma once

#include <QObject>
#include <QPointer>
#include <QString>
#include <QUrl>

class MainCtx;
Q_MOC_INCLUDE("maininterface/mainctx.hpp")

class PlayerMediaDetails : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MainCtx *ctx READ ctx WRITE setCtx NOTIFY ctxChanged)
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QString resolution READ resolution NOTIFY detailsChanged)
    Q_PROPERTY(QString frameRate READ frameRate NOTIFY detailsChanged)

public:
    explicit PlayerMediaDetails(QObject *parent = nullptr);
    MainCtx *ctx() const;
    void setCtx(MainCtx *ctx);
    QUrl url() const { return m_url; }
    void setUrl(const QUrl &url);
    QString resolution() const { return m_resolution; }
    QString frameRate() const { return m_frameRate; }
    Q_INVOKABLE void refresh();

signals:
    void ctxChanged();
    void urlChanged();
    void detailsChanged();

private:
    QPointer<MainCtx> m_ctx;
    QUrl m_url;
    QString m_resolution;
    QString m_frameRate;
};
