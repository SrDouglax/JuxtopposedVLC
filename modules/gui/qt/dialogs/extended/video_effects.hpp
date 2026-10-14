/*****************************************************************************
 * video_effects.hpp: Transactional video effects for the Qt Quick player
 *****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 or later.
 *****************************************************************************/
#ifndef VLC_QT_VIDEO_EFFECTS_HPP_
#define VLC_QT_VIDEO_EFFECTS_HPP_

#include <QObject>
#include <QPointer>
#include <QHash>
#include <QVariant>
#include <QVariantList>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

Q_MOC_INCLUDE("maininterface/mainctx.hpp")
class MainCtx;

class VideoEffects : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(MainCtx* ctx READ ctx WRITE setCtx NOTIFY ctxChanged FINAL)
    Q_PROPERTY(bool available READ available NOTIFY stateChanged FINAL)
    Q_PROPERTY(bool activeVideo READ activeVideo NOTIFY stateChanged FINAL)
    Q_PROPERTY(bool transactionActive READ transactionActive NOTIFY stateChanged FINAL)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorChanged FINAL)
    Q_PROPERTY(int revision READ revision NOTIFY stateChanged FINAL)

public:
    explicit VideoEffects(QObject* parent = nullptr);
    ~VideoEffects() override;
    MainCtx* ctx() const;
    void setCtx(MainCtx* ctx);
    bool available() const;
    bool activeVideo() const;
    bool transactionActive() const { return m_transactionActive; }
    QString lastError() const { return m_lastError; }
    int revision() const { return m_revision; }

    Q_INVOKABLE bool begin();
    Q_INVOKABLE bool cancel();
    Q_INVOKABLE bool save();
    bool prepareConfiguration(QHash<QString, QVariant>& values, QHash<QString, QVariant>& expected);
    Q_INVOKABLE void finalizeConfiguration();
    Q_INVOKABLE bool filterAvailable(const QString& filter) const;
    Q_INVOKABLE bool filterEnabled(const QString& filter) const;
    Q_INVOKABLE bool setFilterEnabled(const QString& filter, bool enabled);
    Q_INVOKABLE QVariantList parameters(const QString& filter) const;
    Q_INVOKABLE QVariantList choices(const QString& name) const;
    Q_INVOKABLE QVariant parameterValue(const QString& name) const;
    Q_INVOKABLE bool setParameter(const QString& name, const QVariant& value);
    Q_INVOKABLE int cropValue(const QString& side) const;
    Q_INVOKABLE bool setCrop(const QString& side, int pixels);
    Q_INVOKABLE bool resetDefaults(const QString& filter);

signals:
    void ctxChanged(MainCtx* ctx);
    void stateChanged();
    void errorChanged();

private:
    bool fail(const QString& reason);
    void clearError();
    void changed();
    bool requirePreview();
    quintptr voutToken() const;
    QString filterChain() const;
    QVariant readValue(const QString& name) const;
    bool writeValue(const QString& name, const QVariant& value);
    static bool validFilter(const QString& filter);
    static QStringList optionNames(const QString& filter);
    static bool validOption(const QString& name);
    static QVariant defaultValue(const QString& name);
    static QVariant getConfig(const QString& name);
    static bool validSide(const QString& side);

    QPointer<MainCtx> m_ctx;
    bool m_transactionActive = false;
    int m_revision = 0;
    QString m_lastError;
    quintptr m_snapshotVout = 0;
    QString m_snapshotChain;
    QString m_snapshotCropString;
    QHash<QString, QVariant> m_snapshotValues;
    QHash<QString, QVariant> m_configSnapshot;
    QHash<QString, int> m_snapshotCrop;
};
#endif
