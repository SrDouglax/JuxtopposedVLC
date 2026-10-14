/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License, version 2 or later.
 *****************************************************************************/
#ifndef SOFTWAREIMAGE_HPP
#define SOFTWAREIMAGE_HPP

#include <QtQuick/private/qquickimage_p.h>
#include <QColor>
#include <QVector4D>

// ImageExt's CPU rounding path. Reuses Image's decoded pixmap, including image
// providers and asynchronous loading, instead of loading a second full image.
class SoftwareImage : public QQuickImage
{
    Q_OBJECT
    Q_PROPERTY(QVector4D radii MEMBER m_radii NOTIFY radiiChanged FINAL)
    Q_PROPERTY(QColor backgroundColor MEMBER m_backgroundColor NOTIFY backgroundColorChanged FINAL)
    // ImageExt exposes this alias. QQuickImage's revision belongs to QtQuick,
    // so publish it without that module's revision in VLC.Widgets as well.
    Q_PROPERTY(QRectF sourceClipRect READ sourceClipRect WRITE setSourceClipRect
               RESET resetSourceClipRect NOTIFY sourceClipRectChanged FINAL)

public:
    explicit SoftwareImage(QQuickItem *parent = nullptr);

protected:
    QSGNode *updatePaintNode(QSGNode *, UpdatePaintNodeData *) override;

signals:
    void radiiChanged();
    void backgroundColorChanged();

private:
    QVector4D m_radii;
    QColor m_backgroundColor = Qt::transparent;
    bool m_roundingNode = false;
};

#endif
