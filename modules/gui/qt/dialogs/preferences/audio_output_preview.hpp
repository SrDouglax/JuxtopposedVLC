/****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 * SPDX-License-Identifier: GPL-2.0-or-later
 ****************************************************************************/
#ifndef VLC_QT_PREFERENCES_AUDIO_OUTPUT_PREVIEW_HPP
#define VLC_QT_PREFERENCES_AUDIO_OUTPUT_PREVIEW_HPP

#include <QObject>
#include <QPointer>
#include <QByteArray>
#include <QtQml/qqmlregistration.h>

Q_MOC_INCLUDE("maininterface/mainctx.hpp")
class MainCtx;
struct audio_output;
typedef struct audio_output audio_output_t;

class AudioOutputPreview : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(MainCtx* ctx READ ctx WRITE setCtx NOTIFY ctxChanged FINAL)
    Q_PROPERTY(bool active READ active NOTIFY stateChanged FINAL)
    Q_PROPERTY(bool dirty READ dirty NOTIFY stateChanged FINAL)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorChanged FINAL)
public:
    explicit AudioOutputPreview(QObject* parent = nullptr);
    ~AudioOutputPreview() override;
    MainCtx* ctx() const;
    void setCtx(MainCtx* ctx);
    bool active() const { return m_aout != nullptr; }
    bool dirty() const { return m_dirty; }
    QString lastError() const { return m_error; }
    Q_INVOKABLE bool begin();
    Q_INVOKABLE int currentIndex() const;
    Q_INVOKABLE bool preview(int index, const QString& displayedName);
    Q_INVOKABLE bool canCommit();
    Q_INVOKABLE bool commit();
    Q_INVOKABLE bool cancel();
signals:
    void ctxChanged();
    void stateChanged();
    void errorChanged();
private:
    bool sameOutput() const;
    bool fail(const QString& message);
    void clearError();
    void releaseOutput();
    QPointer<MainCtx> m_ctx;
    audio_output_t* m_aout = nullptr;
    QByteArray m_originalDevice;
    bool m_originalIsDefault = true;
    bool m_dirty = false;
    QString m_error;
};

#endif
