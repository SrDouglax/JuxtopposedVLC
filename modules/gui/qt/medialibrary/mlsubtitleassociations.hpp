/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *****************************************************************************/
#pragma once

#include <QObject>
#include <QPointer>
#include <QUrl>
#include <QVariantList>
#include <QVector>

#include "mlqmltypes.hpp"

Q_MOC_INCLUDE("medialibrary/medialib.hpp")

class MediaLib;

class MLSubtitleAssociations : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MediaLib* ml READ ml WRITE setMl)
    Q_PROPERTY(QVariantList destinations READ destinations NOTIFY changed)
    Q_PROPERTY(QVariantList sources READ sources NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)

public:
    explicit MLSubtitleAssociations(QObject* parent = nullptr);

    MediaLib* ml() const;
    void setMl(MediaLib* ml);
    QVariantList destinations() const;
    QVariantList sources() const;
    QString error() const { return m_error; }
    bool busy() const { return m_busy; }

    Q_INVOKABLE void open(const MLItemId& target);
    Q_INVOKABLE void openUrl(const QUrl& target);
    Q_INVOKABLE void addFiles(const QVariantList& urls);
    Q_INVOKABLE void chooseFiles();
    Q_INVOKABLE void assign(int sourceIndex, int destinationIndex);
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void save();

signals:
    void changed();
    void saved(int count);

private:
    struct Destination {
        int64_t id = 0;
        QUrl url;
        QString label;
    };
    struct Source {
        QUrl url;
        int destination = -1;
        QString issue;
    };

    void setError(const QString& error);
    void match();
    QPointer<MediaLib> m_ml;
    QVector<Destination> m_destinations;
    QVector<Source> m_sources;
    QString m_error;
    bool m_busy = false;
    quint64 m_revision = 0;
};
