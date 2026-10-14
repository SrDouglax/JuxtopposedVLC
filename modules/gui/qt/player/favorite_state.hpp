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

class FavoriteState : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MainCtx *ctx READ ctx WRITE setCtx NOTIFY ctxChanged)
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(bool available READ available NOTIFY stateChanged)
    Q_PROPERTY(bool favorite READ favorite NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)

public:
    explicit FavoriteState(QObject *parent = nullptr);
    MainCtx *ctx() const { return m_ctx; }
    void setCtx(MainCtx *ctx);
    QUrl url() const { return m_url; }
    void setUrl(const QUrl &url);
    bool available() const { return m_available; }
    bool favorite() const { return m_favorite; }
    bool busy() const { return m_busy; }
    QString error() const { return m_error; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void toggle();

signals:
    void ctxChanged();
    void urlChanged();
    void stateChanged();

private:
    QPointer<MainCtx> m_ctx;
    QUrl m_url;
    bool m_available = false;
    bool m_favorite = false;
    bool m_busy = false;
    QString m_error;
    quint64 m_generation = 0;
};
