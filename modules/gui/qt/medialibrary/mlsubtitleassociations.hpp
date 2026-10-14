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
class QNetworkAccessManager;
class QNetworkReply;

class MLSubtitleAssociations : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MediaLib* ml READ ml WRITE setMl)
    Q_PROPERTY(QVariantList destinations READ destinations NOTIFY changed)
    Q_PROPERTY(QVariantList sources READ sources NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QVariantList targets READ targets NOTIFY targetsChanged)
    Q_PROPERTY(int selectedTarget READ selectedTarget NOTIFY targetsChanged)

public:
    explicit MLSubtitleAssociations(QObject* parent = nullptr);

    MediaLib* ml() const;
    void setMl(MediaLib* ml);
    QVariantList destinations() const;
    QVariantList sources() const;
    QString error() const { return m_error; }
    bool busy() const { return m_busy; }
    QVariantList targets() const;
    int selectedTarget() const { return m_selectedTarget; }

    Q_INVOKABLE void open(const MLItemId& target);
    Q_INVOKABLE void openUrl(const QUrl& target);
    Q_INVOKABLE void addFiles(const QVariantList& urls);
    Q_INVOKABLE void chooseFiles();
    Q_INVOKABLE void addLink(const QUrl& url);
    Q_INVOKABLE void addLinkWithName(const QUrl& url, const QString& filename);
    Q_INVOKABLE void selectTarget(int index);
    Q_INVOKABLE void assign(int sourceIndex, int destinationIndex);
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void save();

signals:
    void changed();
    void saved(int count);
    void targetsChanged();

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
        QString label;
    };
    struct Target {
        MLItemId id;
        QUrl url;
        QString label;
    };

    void setError(const QString& error);
    void match();
    void loadTarget(const MLItemId& target);
    void loadUrlTarget(const QUrl& target);
    void refreshTargets(const Target& initial);
    QPointer<MediaLib> m_ml;
    QVector<Destination> m_destinations;
    QVector<Source> m_sources;
    QVector<Target> m_targets;
    int m_selectedTarget = 0;
    quint64 m_targetRevision = 0;
    QNetworkAccessManager* m_network = nullptr;
    QNetworkReply* m_download = nullptr;
    QString m_error;
    bool m_busy = false;
    bool m_saving = false;
    quint64 m_revision = 0;
};
