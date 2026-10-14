/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#ifndef VLC_QT_HDR_OUTPUT_HPP
#define VLC_QT_HDR_OUTPUT_HPP
#include <QObject>
#include <QPointer>
#include <QVariantList>
class MainCtx;
Q_MOC_INCLUDE("maininterface/mainctx.hpp")
class HdrOutput : public QObject {
    Q_OBJECT
    Q_PROPERTY(MainCtx* ctx READ ctx WRITE setCtx NOTIFY changed)
    Q_PROPERTY(QVariantList choices READ choices CONSTANT)
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(int selectedIndex READ selectedIndex NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
public:
    explicit HdrOutput(QObject* parent = nullptr);
    MainCtx* ctx() const;
    void setCtx(MainCtx* ctx);
    QVariantList choices() const { return m_choices; }
    bool available() const { return m_available; }
    int selectedIndex() const;
    QString message() const { return m_message; }
    Q_INVOKABLE bool select(int index);
signals:
    void changed();
private:
    QPointer<MainCtx> m_ctx;
    QVariantList m_choices;
    bool m_available = false;
    QString m_message;
};
#endif
