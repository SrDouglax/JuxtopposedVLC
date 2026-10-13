/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *****************************************************************************/

#include "onboarding.hpp"

#include "maininterface/mainctx.hpp"
#include "medialibrary/medialib.hpp"
#include "util/color_scheme_model.hpp"
#include "qt.hpp"

#include <QDir>
#include <QFileInfo>
#include <QSettings>
#include <QVariantMap>

#include <vlc_configuration.h>

#include <cstdlib>

OnboardingController::OnboardingController(QObject* parent)
    : QObject(parent)
{
    connect(&m_folders, &QAbstractItemModel::modelReset,
            this, &OnboardingController::checkPendingFolders);
    connect(&m_folders, &MLFoldersBaseModel::operationFailed, this,
            [this](int operation, const QUrl& url) {
        if (!m_busy || operation != MLFoldersBaseModel::Add ||
            !m_requestedFolders.contains(url))
            return;
        m_requestedFolders.clear();
        setBusy(false);
        setError(tr("Could not add the media folder: %1").arg(url.toDisplayString()));
    });
}

OnboardingController::~OnboardingController()
{
    restoreTheme();
}

MainCtx* OnboardingController::ctx() const
{
    return m_ctx;
}

void OnboardingController::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx)
        return;
    // MLFoldersModel binds its event subscription to one MainCtx for life.
    if (m_ctx || !ctx)
        return;
    m_ctx = ctx;
    if (m_ctx && m_ctx->getMediaLibrary())
        m_folders.setCtx(m_ctx);
    emit ctxChanged();
    emit needsSetupChanged();
    emit themeIndexChanged();
}

bool OnboardingController::needsSetup() const
{
    return m_ctx && !m_completed && var_InheritBool(m_ctx->getIntf(), "qt-privacy-ask");
}

int OnboardingController::themeIndex() const
{
    return m_ctx ? m_ctx->getColorScheme()->currentIndex() : -1;
}

void OnboardingController::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void OnboardingController::setError(const QString& error)
{
    if (m_error == error)
        return;
    m_error = error;
    emit errorChanged();
}

bool OnboardingController::begin()
{
    if (!m_ctx || m_busy)
        return false;
    if (m_previewActive)
        return true;
    setError({});
    m_initialTheme = themeIndex();
    m_previewActive = true;
    return true;
}

bool OnboardingController::previewTheme(int index)
{
    if (!m_ctx || !m_previewActive || m_busy || index < 0 ||
        index >= m_ctx->getColorScheme()->rowCount(QModelIndex()))
        return false;
    m_ctx->getColorScheme()->setCurrentIndex(index);
    emit themeIndexChanged();
    return true;
}

void OnboardingController::restoreTheme()
{
    if (!m_previewActive)
        return;
    if (m_ctx && m_initialTheme >= 0) {
        m_ctx->getColorScheme()->setCurrentIndex(m_initialTheme);
        emit themeIndexChanged();
    }
    m_previewActive = false;
    m_initialTheme = -1;
}

bool OnboardingController::cancel()
{
    if (m_busy)
        return false; // Folder registration cannot be canceled after submission.
    restoreTheme();
    setError({});
    return true;
}

bool OnboardingController::validateFolders(const QVariantList& values, QList<QUrl>* folders)
{
    folders->clear();
    if (!values.isEmpty() && (!m_ctx || !m_ctx->getMediaLibrary())) {
        setError(tr("The media library is unavailable."));
        return false;
    }

    for (const QVariant& value : values) {
        const QUrl url = value.toUrl();
        if (!url.isValid() || !url.isLocalFile()) {
            setError(tr("Choose a local media folder."));
            return false;
        }
        const QFileInfo info(url.toLocalFile());
        if (!info.exists() || !info.isDir() || !info.isReadable()) {
            setError(tr("The media folder does not exist or cannot be read: %1")
                         .arg(url.toDisplayString()));
            return false;
        }
        const QUrl canonical = QUrl::fromLocalFile(info.canonicalFilePath());
        if (!folders->contains(canonical))
            folders->append(canonical);
    }
    return true;
}

bool OnboardingController::folderExists(const QUrl& folder) const
{
    for (int row = 0; row < m_folders.rowCount(); ++row) {
        const QString mrl = m_folders.data(m_folders.index(row, 0),
                                           MLFoldersBaseModel::MRL).toString();
        const QUrl current = QUrl::fromEncoded(mrl.toUtf8());
        if (!current.isLocalFile())
            continue;
        if (QFileInfo(current.toLocalFile()).canonicalFilePath() == folder.toLocalFile())
            return true;
    }
    return false;
}

bool OnboardingController::finish(const QVariantList& folderUrls, bool metadataNetworkAccess)
{
    if (!m_ctx || m_busy || !m_previewActive)
        return false;
    setError({});
    QList<QUrl> folders;
    if (!validateFolders(folderUrls, &folders))
        return false;

    m_metadataNetworkAccess = metadataNetworkAccess;
    m_requestedFolders = folders;

    QList<QUrl> missing;
    for (const QUrl& folder : folders) {
        if (!folderExists(folder))
            missing.append(folder);
    }
    if (missing.isEmpty())
        return commit();

    setBusy(true);
    for (const QUrl& folder : missing)
        m_folders.add(folder);
    return true; // Accepted for asynchronous indexing; completed() is authoritative.
}

void OnboardingController::checkPendingFolders()
{
    if (!m_busy || m_requestedFolders.isEmpty())
        return;
    for (const QUrl& folder : m_requestedFolders) {
        if (!folderExists(folder))
            return;
    }
    setBusy(false);
    commit();
}

bool OnboardingController::skip()
{
    if (!m_ctx || m_busy || !m_previewActive)
        return false;
    if (!needsSetup())
        return cancel(); // Reopened from Settings: keep the existing choices.
    restoreTheme();
    m_metadataNetworkAccess = config_GetInt("metadata-network-access") != 0;
    m_requestedFolders.clear();
    setError({});
    return commit();
}

bool OnboardingController::commit()
{
    if (!m_ctx)
        return false;

    auto* const intf = m_ctx->getIntf();
    auto* const settings = intf->mainSettings;
    const int oldPrivacy = config_GetInt("qt-privacy-ask");
    const int oldMetadata = config_GetInt("metadata-network-access");
    const QVariant oldTheme = settings->value("MainWindow/color-scheme-index");
    const bool hadTheme = settings->contains("MainWindow/color-scheme-index");

    settings->setValue("MainWindow/color-scheme-index", themeIndex());
    settings->sync();
    if (settings->status() != QSettings::NoError) {
        if (hadTheme)
            settings->setValue("MainWindow/color-scheme-index", oldTheme);
        else
            settings->remove("MainWindow/color-scheme-index");
        settings->sync();
        setError(tr("Could not save the theme setting."));
        return false;
    }

    config_PutInt("metadata-network-access", m_metadataNetworkAccess ? 1 : 0);
    config_PutInt("qt-privacy-ask", 0);
    if (config_SaveConfigFile(intf) != 0) {
        config_PutInt("metadata-network-access", oldMetadata);
        config_PutInt("qt-privacy-ask", oldPrivacy);
        if (hadTheme)
            settings->setValue("MainWindow/color-scheme-index", oldTheme);
        else
            settings->remove("MainWindow/color-scheme-index");
        settings->sync();
        setError(tr("Could not save the first-run preferences."));
        return false;
    }

    m_previewActive = false;
    m_initialTheme = -1;
    m_requestedFolders.clear();
    m_completed = true;
    if (m_ctx->getMediaLibrary())
        m_ctx->getMediaLibrary()->reload();
    m_ctx->reloadPrefs();
    emit needsSetupChanged();
    emit completed();
    return true;
}

QVariantList OnboardingController::activeShortcuts() const
{
    QVariantList result;
    if (!m_ctx)
        return result;

    struct Shortcut { const char* key; const char* action; };
    static const Shortcut shortcuts[] = {
        {"key-play-pause", QT_TR_NOOP("Play / Pause")},
        {"key-jump-short", QT_TR_NOOP("Seek backward")},
        {"key-jump+short", QT_TR_NOOP("Seek forward")},
        {"key-prev", QT_TR_NOOP("Previous item")},
        {"key-next", QT_TR_NOOP("Next item")},
        {"key-frame-previous", QT_TR_NOOP("Previous frame")},
        {"key-frame-next", QT_TR_NOOP("Next frame")},
        {"key-subtitle-track", QT_TR_NOOP("Cycle subtitle track")},
        {"key-audio-track", QT_TR_NOOP("Cycle audio track")},
        {"key-toggle-fullscreen", QT_TR_NOOP("Toggle fullscreen")},
        {"key-vol-up", QT_TR_NOOP("Increase volume")},
        {"key-vol-down", QT_TR_NOOP("Decrease volume")},
        {"key-snapshot", QT_TR_NOOP("Take a snapshot")},
        {"key-record", QT_TR_NOOP("Record")},
    };

    for (const Shortcut& shortcut : shortcuts) {
        char* const configured = config_GetPsz(shortcut.key);
        const QString sequence = configured ? QString::fromUtf8(configured) : QString();
        std::free(configured);
        if (!sequence.isEmpty())
            result.append(QVariantMap{{"action", tr(shortcut.action)},
                                      {"sequence", sequence},
                                      {"configKey", QString::fromLatin1(shortcut.key)}});
    }
    return result;
}
