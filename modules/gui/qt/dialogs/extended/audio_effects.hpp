/*****************************************************************************
 * audio_effects.hpp: Live audio effects for the Qt Quick player
 *****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *****************************************************************************/
#ifndef VLC_QT_AUDIO_EFFECTS_HPP_
#define VLC_QT_AUDIO_EFFECTS_HPP_

#include <QObject>
#include <QPointer>
#include <QHash>
#include <QVariant>
#include <QVariantList>
#include <QStringList>
#include <QtGlobal>
#include <QtQml/qqmlregistration.h>

Q_MOC_INCLUDE("maininterface/mainctx.hpp")
class MainCtx;

class AudioEffects : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(MainCtx* ctx READ ctx WRITE setCtx NOTIFY ctxChanged FINAL)
    Q_PROPERTY(bool available READ available NOTIFY stateChanged FINAL)
    Q_PROPERTY(bool activeAudio READ activeAudio NOTIFY stateChanged FINAL)
    Q_PROPERTY(bool transactionActive READ transactionActive NOTIFY stateChanged FINAL)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorChanged FINAL)
    Q_PROPERTY(QVariantList presets READ presets CONSTANT FINAL)
    Q_PROPERTY(QVariantList frequencies READ frequencies NOTIFY stateChanged FINAL)
    Q_PROPERTY(QVariantList bands READ bands NOTIFY stateChanged FINAL)
    Q_PROPERTY(double preamp READ preamp NOTIFY stateChanged FINAL)
    Q_PROPERTY(bool twoPass READ twoPass NOTIFY stateChanged FINAL)
    Q_PROPERTY(QString preset READ preset NOTIFY stateChanged FINAL)

public:
    explicit AudioEffects(QObject* parent = nullptr);
    ~AudioEffects() override;

    MainCtx* ctx() const;
    void setCtx(MainCtx* ctx);
    bool available() const;
    bool activeAudio() const;
    bool transactionActive() const { return m_transactionActive; }
    QString lastError() const { return m_lastError; }
    QVariantList presets() const;
    QVariantList frequencies() const;
    QVariantList bands() const;
    double preamp() const;
    bool twoPass() const;
    QString preset() const;

    Q_INVOKABLE bool begin();
    Q_INVOKABLE bool cancel();
    Q_INVOKABLE bool save();
    Q_INVOKABLE bool filterAvailable(const QString& filter) const;
    Q_INVOKABLE bool filterEnabled(const QString& filter) const;
    Q_INVOKABLE bool setFilterEnabled(const QString& filter, bool enabled);
    Q_INVOKABLE QVariantList parameters(const QString& filter) const;
    Q_INVOKABLE QVariant parameterValue(const QString& name) const;
    Q_INVOKABLE bool setParameter(const QString& name, double value);
    Q_INVOKABLE bool setPreset(const QString& name);
    Q_INVOKABLE bool setBand(int index, double value);
    Q_INVOKABLE bool setPreamp(double value);
    Q_INVOKABLE bool setTwoPass(bool enabled);
    Q_INVOKABLE bool resetDefaults(const QString& filter);

signals:
    void ctxChanged(MainCtx* ctx);
    void stateChanged();
    void errorChanged();

private:
    bool requirePreview();
    bool fail(const QString& reason);
    void clearError();
    QString chain() const;
    QVariant readValue(const QString& name) const;
    bool writeValue(const QString& name, const QVariant& value);
    static QStringList optionNames(const QString& filter);
    static bool validFilter(const QString& filter);
    static QVariant defaultValue(const QString& name);
    static bool validOption(const QString& name);
    quintptr aoutToken() const;

    QPointer<MainCtx> m_ctx;
    bool m_transactionActive = false;
    QString m_lastError;
    QString m_snapshotChain;
    quintptr m_snapshotAout = 0;
    QHash<QString, QVariant> m_snapshotValues;
};

#endif
