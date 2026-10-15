/*
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify it
 * under the GNU General Public License, version 2 or any later version.
 * See the COPYING file for the license and warranty disclaimer.
 */
/* Native file selection for QML, using the existing VLC dialogs. */
#pragma once

#include <QObject>
#include <QUrl>
#include <QVariantList>

class MainCtx;
Q_MOC_INCLUDE("maininterface/mainctx.hpp")

class FilePicker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MainCtx* ctx READ ctx WRITE setCtx)
public:
    explicit FilePicker(QObject* parent = nullptr) : QObject(parent) {}
    MainCtx* ctx() const { return m_ctx; }
    void setCtx(MainCtx* ctx) { m_ctx = ctx; }
    Q_INVOKABLE QVariantList chooseFiles(const QString& title = {});
    Q_INVOKABLE QUrl chooseImage(const QString& title = {});
    Q_INVOKABLE QUrl chooseFile(const QString& title, const QString& filter = {});
    Q_INVOKABLE QString chooseSaveFile(const QString& title, const QString& initialFile = {});
    Q_INVOKABLE QUrl chooseFolder(const QString& title = {});
private:
    MainCtx* m_ctx = nullptr;
};
