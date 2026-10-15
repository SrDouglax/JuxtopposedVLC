/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include <vlc_common.h>
#include <vlc_interface.h>
#include <vlc_intf_strings.h>
#include "qt.hpp"
#include "dialogs_provider.hpp"
#include "preferences/preferences.hpp"
#include "extended/extended.hpp"
#include "maininterface/mainctx.hpp"
#include <QFileDialog>
#include <QInputDialog>

QString DialogsProvider::getSaveFileName( QWidget *parent,
                                          const QString &caption,
                                          const QUrl &dir,
                                          const QString &filter,
                                          QString *selectedFilter )
{
    const QStringList schemes = QStringList(QStringLiteral("file"));
    return QFileDialog::getSaveFileUrl( parent, caption, dir, filter, selectedFilter, QFileDialog::Options(), schemes).toLocalFile();
}

QVariant DialogsProvider::getTextDialog(QWidget *parent,
                                        const QString &title,
                                        const QString &label,
                                        const QString &placeholder,
                                        bool *ok)
{
    bool _ok = false;
    QString ret = QInputDialog::getText(parent,
                                        title,
                                        label,
                                        QLineEdit::Normal,
                                        placeholder,
                                        ok ? ok : &_ok);

    if (!ok)
    {
        // When this function is called from the QML side, instead of setting `ok` parameter
        // a QVariantMap with key `ok` and `text` is returned instead

        QVariantMap map;
        map["text"] = ret;
        map["ok"] = _ok;
        return map;
    }
    else
    {
        return ret;
    }
}

QStringList DialogsProvider::showSimpleOpen( const QString& help,
                                             int filters,
                                             const QUrl& path )
{
    QString fileTypes = "";
    if( filters & EXT_FILTER_MEDIA ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_MEDIA );
    }
    if( filters & EXT_FILTER_VIDEO ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_VIDEO );
    }
    if( filters & EXT_FILTER_AUDIO ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_AUDIO );
    }
    if( filters & EXT_FILTER_PLAYLIST ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_PLAYLIST );
    }
    if( filters & EXT_FILTER_SUBTITLE ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_SUBTITLE );
    }
    ADD_EXT_FILTER( fileTypes, EXTENSIONS_ALL );
    fileTypes.replace( ";*", " *");
    fileTypes.chop(2); //remove trailing ";;"

    QList<QUrl> urls = QFileDialog::getOpenFileUrls( NULL,
        help.isEmpty() ? qfut(I_OP_SEL_FILES ) : help,
        path.isEmpty() ? p_intf->p_mi->getDialogFilePath() : path,
        fileTypes );

    if( !urls.isEmpty() )
        p_intf->p_mi->setDialogFilePath(urls.last());

    QStringList res;
    foreach( const QUrl &url, urls )
        res << url.toEncoded();

    return res;
}

void DialogsProvider::nativePrefsDialog()
{
    if (Q_LIKELY(!m_prefsDialog))
    {
        m_prefsDialog = new PrefsDialog( nullptr, p_intf );
        m_prefsDialog->setAttribute(Qt::WA_DeleteOnClose);
        m_prefsDialog->installEventFilter(this);
        m_prefsDialog->open();
    }
    else
    {
        m_prefsDialog->reject();
    }
}

void DialogsProvider::playerMenuDialog(QObject* source, int page) { emit playerMenuRequested(source, page); }
bool DialogsProvider::playerMenuVisible() const { return m_redesignDialogs.contains("playerMenu"); }
void DialogsProvider::sleepTimerDialog() { emit sleepTimerRequested(); }
void DialogsProvider::audioVisualizationDialog() { emit audioVisualizationRequested(); }
void DialogsProvider::hdrOutputDialog() { emit hdrOutputRequested(); }

void DialogsProvider::prefsDialog() { emit preferencesRequested(); }
void DialogsProvider::firstRunDialog() { emit setupRequested(); }

void DialogsProvider::nativeEffectsDialog(int page)
{
    if (!m_extendedDialog) {
        m_extendedDialog = std::make_unique<ExtendedDialog>(p_intf);
        m_extendedDialog->installEventFilter(this);
    }
    m_extendedDialog->showTab(qBound(0, page, 2));
}

void DialogsProvider::setRedesignDialogVisible(const QString& name, bool visible)
{
    if (name != "prefsDialog" && name != "firstRunDialog" && name != "extendedDialog" && name != "playerMenu")
        return;
    const bool previous = m_redesignDialogs.contains(name);
    if (visible) m_redesignDialogs.insert(name);
    else m_redesignDialogs.remove(name);
    if (previous == visible) return;
    if (name == "prefsDialog") emit prefsDialogVisibleChanged();
    else if (name == "firstRunDialog") emit firstRunDialogVisibleChanged();
    else if (name == "playerMenu") emit playerMenuVisibleChanged();
    else emit extendedDialogVisibleChanged();
}
