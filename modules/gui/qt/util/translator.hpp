/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#pragma once
#include <QTranslator>
#include <QSettings>
#include <QCoreApplication>
#include <QGuiApplication>
#include <vlc_common.h>

class Translator : public QTranslator
{
public:
    explicit Translator(QObject* parent, bool english) : QTranslator(parent), m_english(english) { }

    bool isEmpty() const override { return false; };

    QString translate(const char *context,
                      const char *sourceText,
                      const char *disambiguation = nullptr,
                      int n = -1) const override
    {
        Q_UNUSED(context);
        if (m_english)
            return QString::fromUtf8(n >= 0 && n != 1 && disambiguation ? disambiguation : sourceText);

        const char* text = (n >= 0 && disambiguation != nullptr) ? vlc_ngettext(sourceText, disambiguation, n)
                                                                 : vlc_gettext(sourceText);

        assert(text);
        return QString::fromUtf8(text);
    }
private:
    const bool m_english;
};

inline void installInterfaceTranslator(QObject* application, const QSettings& settings)
{
    const bool english = settings.value("redesign/interface-language").toString() == "en";
    const auto translator = new Translator(application, english);
    const auto installed = QCoreApplication::installTranslator(translator);
    assert(installed);
    if (english) QGuiApplication::setLayoutDirection(Qt::LeftToRight);
}
