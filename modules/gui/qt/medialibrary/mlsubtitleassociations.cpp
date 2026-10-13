/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *****************************************************************************/

#if HAVE_CONFIG_H
# include "config.h"
#endif

#include "mlsubtitleassociations.hpp"

#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QHash>
#include <QSet>

#include <utility>

#include <vlc_input_item.h>
#include <vlc_media_library.h>

#include "medialib.hpp"
#include "mlhelper.hpp"
#include "qt.hpp"

namespace {
QString baseName(const QUrl& url)
{
    return QFileInfo(url.toLocalFile()).completeBaseName().toCaseFolded();
}

QUrl fileUrl(const QVariant& value)
{
    QUrl url = value.toUrl();
    if (url.isValid() && url.isLocalFile())
        return QUrl::fromLocalFile(QFileInfo(url.toLocalFile()).absoluteFilePath());
    return {};
}
}

MLSubtitleAssociations::MLSubtitleAssociations(QObject* parent) : QObject(parent) {}

QVariantList MLSubtitleAssociations::destinations() const
{
    QVariantList list;
    for (const auto& destination : m_destinations)
        list.push_back(QVariantMap{{"label", destination.label}, {"url", destination.url}});
    return list;
}

QVariantList MLSubtitleAssociations::sources() const
{
    QVariantList list;
    for (const auto& source : m_sources)
        list.push_back(QVariantMap{{"label", QFileInfo(source.url.toLocalFile()).fileName()},
                                   {"url", source.url}, {"destination", source.destination},
                                   {"issue", source.issue}});
    return list;
}

void MLSubtitleAssociations::setError(const QString& error)
{
    m_error = error;
    emit changed();
}

void MLSubtitleAssociations::cancel()
{
    ++m_revision;
    m_destinations.clear();
    m_sources.clear();
    m_error.clear();
    m_busy = false;
    emit changed();
}

void MLSubtitleAssociations::open(const MLItemId& target)
{
    cancel();
    if (!m_ml || !target.isValid() ||
        (target.type != VLC_ML_PARENT_UNKNOWN && target.type != VLC_ML_PARENT_FOLDER &&
         target.type != VLC_ML_PARENT_PLAYLIST))
    {
        setError(tr("Select a media file, folder, or playlist from the library."));
        return;
    }

    m_busy = true;
    emit changed();
    const quint64 revision = m_revision;
    struct Context { QVector<Destination> destinations; };
    m_ml->runOnMLThread<Context>(this,
        [target](vlc_medialibrary_t* ml, Context& ctx) {
            auto append = [&ctx](const vlc_ml_media_t& media) {
                if (!media.p_files)
                    return;
                for (size_t i = 0; i < media.p_files->i_nb_items; ++i)
                {
                    const auto& file = media.p_files->p_items[i];
                    if (file.i_type != VLC_ML_FILE_TYPE_MAIN || !file.psz_mrl)
                        continue;
                    QUrl url = QUrl::fromEncoded(file.psz_mrl);
                    if (!url.isLocalFile())
                        return;
                    ctx.destinations.push_back({media.i_id, url, QFileInfo(url.toLocalFile()).fileName()});
                    return;
                }
            };
            if (target.type == VLC_ML_PARENT_UNKNOWN)
            {
                ml_unique_ptr<vlc_ml_media_t> media(vlc_ml_get_media(ml, target.id));
                if (media)
                    append(*media);
            }
            else
            {
                vlc_ml_query_params_t query = vlc_ml_query_params_create();
                ml_unique_ptr<vlc_ml_media_list_t> list(vlc_ml_list_media_of(ml, &query, target.type, target.id));
                if (!list)
                    return;
                QSet<int64_t> seen;
                for (size_t i = 0; i < list->i_nb_items; ++i)
                {
                    const auto& media = list->p_items[i];
                    if (!seen.contains(media.i_id))
                    {
                        append(media);
                        seen.insert(media.i_id);
                    }
                }
            }
        },
        [this, revision](quint64, Context& ctx) {
            if (revision != m_revision)
                return;
            m_destinations = std::move(ctx.destinations);
            m_busy = false;
            if (m_destinations.isEmpty())
                m_error = tr("No local media files were found in this destination.");
            match();
        });
}

void MLSubtitleAssociations::openUrl(const QUrl& target)
{
    cancel();
    const QUrl url = fileUrl(target);
    if (url.isEmpty() || !QFileInfo(url.toLocalFile()).isFile())
    {
        setError(tr("Choose an existing local media file."));
        return;
    }
    m_destinations.push_back({0, url, QFileInfo(url.toLocalFile()).fileName()});
    emit changed();
}

void MLSubtitleAssociations::addFiles(const QVariantList& urls)
{
    QSet<QString> seen;
    for (const auto& source : m_sources)
        seen.insert(source.url.toString(QUrl::FullyEncoded));
    for (const auto& value : urls)
    {
        const QUrl url = fileUrl(value);
        if (url.isEmpty() || seen.contains(url.toString(QUrl::FullyEncoded)))
            continue;
        const QFileInfo info(url.toLocalFile());
        if (!info.isFile() || !info.isReadable())
        {
            setError(tr("A selected subtitle file is missing or unreadable: %1").arg(info.fileName()));
            return;
        }
        enum slave_type type;
        const QByteArray path = QFile::encodeName(info.fileName());
        if (!input_item_slave_GetType(path.constData(), &type) || type != SLAVE_TYPE_SPU)
        {
            setError(tr("Unsupported subtitle file: %1").arg(info.fileName()));
            return;
        }
        seen.insert(url.toString(QUrl::FullyEncoded));
        m_sources.push_back({url, -1, {}});
    }
    m_error.clear();
    match();
}

void MLSubtitleAssociations::chooseFiles()
{
    const auto urls = QFileDialog::getOpenFileUrls(nullptr, tr("Choose subtitle files"), {},
                                                  tr("Subtitle files (*.srt *.ass *.ssa *.sub *.vtt *.ttml *.smi);;All files (*)"),
                                                  nullptr, QFileDialog::Options(), {"file"});
    QVariantList values;
    for (const auto& url : urls)
        values.push_back(url);
    addFiles(values);
}

void MLSubtitleAssociations::match()
{
    QHash<QString, QVector<int>> destinationsByName;
    for (int i = 0; i < m_destinations.size(); ++i)
        destinationsByName[baseName(m_destinations[i].url)].push_back(i);

    for (auto& source : m_sources)
    {
        if (source.destination >= 0)
            continue;
        source.issue.clear();
        const auto matches = destinationsByName.value(baseName(source.url));
        if (matches.size() == 1)
            source.destination = matches.front();
        else if (m_destinations.size() == 1)
            source.destination = 0;
        else if (matches.size() > 1)
            source.issue = tr("Several media files have this name. Choose one.");
        else
            source.issue = tr("No exact filename match. Choose a destination.");
    }
    emit changed();
}

void MLSubtitleAssociations::assign(int sourceIndex, int destinationIndex)
{
    if (m_busy || sourceIndex < 0 || sourceIndex >= m_sources.size() ||
        destinationIndex < 0 || destinationIndex >= m_destinations.size())
        return;
    m_sources[sourceIndex].destination = destinationIndex;
    m_sources[sourceIndex].issue.clear();
    m_error.clear();
    emit changed();
}

void MLSubtitleAssociations::save()
{
    if (!m_ml || m_busy || m_destinations.isEmpty() || m_sources.isEmpty())
    {
        setError(tr("Choose a destination and at least one subtitle file."));
        return;
    }
    for (const auto& source : m_sources)
    {
        if (source.destination < 0 || source.destination >= m_destinations.size())
        {
            setError(tr("Choose a destination for every subtitle file."));
            return;
        }
        if (!QFileInfo(source.url.toLocalFile()).isReadable())
        {
            setError(tr("A subtitle file is no longer readable: %1").arg(source.url.fileName()));
            return;
        }
    }

    struct Assignment { int64_t id; QByteArray mediaMrl; QByteArray subtitleMrl; };
    QVector<Assignment> assignments;
    for (const auto& source : m_sources)
    {
        const auto& destination = m_destinations[source.destination];
        assignments.push_back({destination.id,
                               destination.url.toString(QUrl::FullyEncoded).toUtf8(),
                               source.url.toString(QUrl::FullyEncoded).toUtf8()});
    }

    m_busy = true;
    m_error.clear();
    emit changed();
    const quint64 revision = m_revision;
    struct Context { int saved = 0; QString error; };
    m_ml->runOnMLThread<Context>(this,
        [assignments](vlc_medialibrary_t* ml, Context& ctx) {
            for (const auto& assignment : assignments)
            {
                ml_unique_ptr<vlc_ml_media_t> media(assignment.id ?
                    vlc_ml_get_media(ml, assignment.id) :
                    vlc_ml_get_media_by_mrl(ml, assignment.mediaMrl.constData()));
                if (!media && !assignment.id)
                    media.reset(vlc_ml_new_external_media(ml, assignment.mediaMrl.constData()));
                if (!media)
                {
                    ctx.error = QObject::tr("The destination media could not be found in the library.");
                    break;
                }
                bool exists = false;
                if (media->p_files)
                    for (size_t i = 0; i < media->p_files->i_nb_items; ++i)
                    {
                        const auto& file = media->p_files->p_items[i];
                        if (file.i_type == VLC_ML_FILE_TYPE_SUBTITLE && file.psz_mrl &&
                            assignment.subtitleMrl == file.psz_mrl)
                            exists = true;
                    }
                if (exists)
                    continue;
                if (vlc_ml_media_add_external_mrl(ml, media->i_id,
                        assignment.subtitleMrl.constData(), VLC_ML_FILE_TYPE_SUBTITLE) != VLC_SUCCESS)
                {
                    ctx.error = QObject::tr("Could not save subtitle association for %1.")
                                    .arg(QUrl::fromEncoded(assignment.mediaMrl).fileName());
                    break;
                }
                ++ctx.saved;
            }
        },
        [this, revision](quint64, Context& ctx) {
            if (revision != m_revision)
                return;
            m_busy = false;
            m_error = ctx.error;
            if (!m_error.isEmpty() && ctx.saved > 0)
                m_error += tr(" %n earlier association(s) were saved.", nullptr, ctx.saved);
            emit changed();
            if (ctx.error.isEmpty())
                emit saved(ctx.saved);
        });
}
