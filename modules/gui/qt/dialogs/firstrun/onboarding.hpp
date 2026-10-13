/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *****************************************************************************/

#pragma once

#include <QObject>
#include <QPointer>
#include <QUrl>
#include <QVariantList>

#include "medialibrary/mlfoldersmodel.hpp"

class MainCtx;
Q_MOC_INCLUDE("maininterface/mainctx.hpp")

// QML-facing bridge for the existing VLC first-run configuration and library.
// The dialog owns presentation; this class owns preview rollback and commit.
class OnboardingController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MainCtx* ctx READ ctx WRITE setCtx NOTIFY ctxChanged FINAL)
    Q_PROPERTY(bool needsSetup READ needsSetup NOTIFY needsSetupChanged FINAL)
    Q_PROPERTY(int themeIndex READ themeIndex NOTIFY themeIndexChanged FINAL)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged FINAL)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged FINAL)

public:
    explicit OnboardingController(QObject* parent = nullptr);
    ~OnboardingController() override;

    MainCtx* ctx() const;
    void setCtx(MainCtx* ctx);

    bool needsSetup() const;
    int themeIndex() const;
    bool busy() const { return m_busy; }
    QString error() const { return m_error; }

    Q_INVOKABLE bool begin();
    Q_INVOKABLE bool previewTheme(int index);
    Q_INVOKABLE bool cancel();
    Q_INVOKABLE bool finish(const QVariantList& folderUrls, bool metadataNetworkAccess);
    Q_INVOKABLE bool skip();
    Q_INVOKABLE QVariantList activeShortcuts() const;

signals:
    void ctxChanged();
    void needsSetupChanged();
    void themeIndexChanged();
    void busyChanged();
    void errorChanged();
    void completed();

private:
    void setBusy(bool busy);
    void setError(const QString& error);
    void restoreTheme();
    bool validateFolders(const QVariantList& values, QList<QUrl>* folders);
    bool folderExists(const QUrl& folder) const;
    void checkPendingFolders();
    bool commit();

    QPointer<MainCtx> m_ctx;
    MLFoldersModel m_folders;
    QList<QUrl> m_requestedFolders;
    int m_initialTheme = -1;
    bool m_previewActive = false;
    bool m_busy = false;
    bool m_completed = false;
    bool m_metadataNetworkAccess = false;
    QString m_error;
};
