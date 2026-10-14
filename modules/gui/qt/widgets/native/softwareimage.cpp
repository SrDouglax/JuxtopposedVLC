/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License, version 2 or later.
 *****************************************************************************/
#include "softwareimage.hpp"

#include <QtQuick/private/qquickimage_p_p.h>
#include <QQuickWindow>
#include <QSGImageNode>
#include <QSGRendererInterface>
#include <QPainter>
#include <QPainterPath>
#include <cmath>

SoftwareImage::SoftwareImage(QQuickItem *parent) : QQuickImage(parent)
{
    connect(this, &SoftwareImage::radiiChanged, this, &QQuickItem::update);
    connect(this, &SoftwareImage::backgroundColorChanged, this, &QQuickItem::update);
}

QSGNode *SoftwareImage::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *data)
{
    const bool rounded = window()
        && window()->rendererInterface()->graphicsApi() == QSGRendererInterface::Software
        && !m_radii.isNull()
        && (fillMode() == Stretch || fillMode() == PreserveAspectFit
            || fillMode() == PreserveAspectCrop || fillMode() == Pad);

    // The base Image and this path use different scene graph node types.
    if (rounded != m_roundingNode) {
        delete oldNode;
        oldNode = nullptr;
        m_roundingNode = rounded;
    }
    if (!rounded)
        return QQuickImage::updatePaintNode(oldNode, data);

    const auto *imageData = static_cast<QQuickImagePrivate *>(QQuickItemPrivate::get(this));
    const QImage source = imageData->pix.image();
    if (source.isNull() || width() <= 0 || height() <= 0) {
        delete oldNode;
        return nullptr;
    }

    const qreal dpr = window()->effectiveDevicePixelRatio();
    const QSize size(std::ceil(width() * dpr), std::ceil(height() * dpr));
    QImage output(size, QImage::Format_ARGB32_Premultiplied);
    output.setDevicePixelRatio(dpr);
    output.fill(Qt::transparent);

    // QQuickImage's boundingRect can include the uncropped painted size.
    // The rounded crop must follow the item's viewport on all four sides.
    const QRectF viewport(0, 0, width(), height());
    QRectF target = viewport;
    QRectF sample = source.rect();
    if (fillMode() == PreserveAspectFit || fillMode() == Pad) {
        target.setSize(QSizeF(paintedWidth(), paintedHeight()));
        target.moveCenter(viewport.center());
    } else if (fillMode() == PreserveAspectCrop) {
        const qreal scale = qMax(width() / source.width(), height() / source.height());
        sample.setSize(QSizeF(width() / scale, height() / scale));
        sample.moveCenter(QRectF(source.rect()).center());
    }

    const qreal limit = qMin(target.width(), target.height()) / 2;
    const qreal tl = qBound(qreal(0), qreal(m_radii.x()), limit);
    const qreal tr = qBound(qreal(0), qreal(m_radii.y()), limit);
    const qreal br = qBound(qreal(0), qreal(m_radii.z()), limit);
    const qreal bl = qBound(qreal(0), qreal(m_radii.w()), limit);
    const qreal left = target.left(), top = target.top();
    const qreal right = target.right(), bottom = target.bottom();
    QPainterPath path;
    path.moveTo(left + tl, top);
    path.lineTo(right - tr, top);
    if (tr > 0) path.arcTo(right - 2 * tr, top, 2 * tr, 2 * tr, 90, -90);
    else path.lineTo(right, top);
    path.lineTo(right, bottom - br);
    if (br > 0) path.arcTo(right - 2 * br, bottom - 2 * br, 2 * br, 2 * br, 0, -90);
    else path.lineTo(right, bottom);
    path.lineTo(left + bl, bottom);
    if (bl > 0) path.arcTo(left, bottom - 2 * bl, 2 * bl, 2 * bl, 270, -90);
    else path.lineTo(left, bottom);
    path.lineTo(left, top + tl);
    if (tl > 0) path.arcTo(left, top, 2 * tl, 2 * tl, 180, -90);
    else path.lineTo(left, top);
    path.closeSubpath();

    QImage mask(size, QImage::Format_ARGB32_Premultiplied);
    mask.setDevicePixelRatio(dpr);
    mask.fill(Qt::transparent);
    {
        QPainter painter(&mask);
        painter.setRenderHint(QPainter::Antialiasing, antialiasing());
        painter.fillPath(path, Qt::white);
    }
    {
        QPainter painter(&output);
        painter.setRenderHint(QPainter::SmoothPixmapTransform, smooth());
        painter.fillRect(target, m_backgroundColor);
        painter.drawImage(target, source, sample);
        painter.setCompositionMode(QPainter::CompositionMode_DestinationIn);
        painter.drawImage(QPointF(0, 0), mask);
    }

    auto *node = static_cast<QSGImageNode *>(oldNode);
    if (!node) node = window()->createImageNode();
    // setTexture may inspect or release the previous texture. Keep it alive
    // during replacement, and transfer ownership explicitly to avoid freeing
    // it twice when a palette change repaints an existing node.
    QSGTexture *previous = node->texture();
    node->setOwnsTexture(false);
    node->setTexture(window()->createTextureFromImage(output));
    delete previous;
    node->setOwnsTexture(true);
    node->setFiltering(smooth() ? QSGTexture::Linear : QSGTexture::Nearest);
    node->setRect(viewport);
    return node;
}
