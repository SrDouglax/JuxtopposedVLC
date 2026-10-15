/*
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify it
 * under the GNU General Public License, version 2 or any later version.
 * See the COPYING file for the license and warranty disclaimer.
 */
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "filepicker.hpp"
#include <QFileDialog>
#include "dialogs/dialogs_provider.hpp"
#include "maininterface/mainctx.hpp"

namespace {
struct ShortcutGuard {
    MainCtx* ctx;
    bool previous;
    explicit ShortcutGuard(MainCtx* context)
        : ctx(context), previous(ctx && ctx->getUseGlobalShortcuts()) {
        if (ctx) ctx->setUseGlobalShortcuts(false);
    }
    ~ShortcutGuard() { if (ctx) ctx->setUseGlobalShortcuts(previous); }
};
}

QVariantList FilePicker::chooseFiles(const QString& title)
{
    const ShortcutGuard guard(m_ctx);
    QVariantList result;
    const auto urls = DialogsProvider::getInstance()->showSimpleOpen(title);
    for (const auto& url : urls)
        result.push_back(QUrl::fromEncoded(url.toUtf8()));
    return result;
}

QUrl FilePicker::chooseFolder(const QString& title)
{
    const ShortcutGuard guard(m_ctx);
    return QFileDialog::getExistingDirectoryUrl(nullptr, title, {},
                                                 QFileDialog::ShowDirsOnly, {"file"});
}

QUrl FilePicker::chooseImage(const QString& title)
{
    const ShortcutGuard guard(m_ctx);
    return QFileDialog::getOpenFileUrl(nullptr, title, {},
                                       QStringLiteral("Images (*.png *.jpg *.jpeg *.webp *.bmp)"),
                                       nullptr, QFileDialog::Options(), {"file"});
}

QUrl FilePicker::chooseFile(const QString& title, const QString& filter)
{
    const ShortcutGuard guard(m_ctx);
    return QFileDialog::getOpenFileUrl(nullptr, title, {}, filter, nullptr, QFileDialog::Options(), {"file"});
}

QString FilePicker::chooseSaveFile(const QString& title, const QString& initialFile)
{
    const ShortcutGuard guard(m_ctx);
    return QFileDialog::getSaveFileName(nullptr, title, initialFile);
}
