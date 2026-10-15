/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include "menus.hpp"
#include "maininterface/mainctx.hpp"
#include "util/color_scheme_model.hpp"
#include "dialogs/dialogs_provider.hpp"
#include "player/player_controller.hpp"
#include "playlist/playlist_controller.hpp"
#include <QCursor>
#include <QApplication>
#include <QPalette>

static void applyMenuStyle(QMenu *menu, MainCtx *ctx)
{
    const auto scheme = ctx ? ctx->getColorScheme()->currentScheme() : ColorSchemeModel::System;
    const bool dark = scheme == ColorSchemeModel::Night
        || (scheme == ColorSchemeModel::System && QApplication::palette().color(QPalette::Window).lightness() < 128);
    const QString background = dark ? "#191919" : "#eeeeee";
    const QString foreground = dark ? "#8f8f8f" : "#494949";
    const QString hover = dark ? "#252525" : "#d6d6d6";
    auto palette = menu->palette();
    palette.setColor(QPalette::WindowText, QColor(foreground));
    palette.setColor(QPalette::Text, QColor(foreground));
    palette.setColor(QPalette::Window, QColor(background));
    palette.setColor(QPalette::Disabled, QPalette::WindowText, QColor(dark ? "#555555" : "#999999"));
    menu->setPalette(palette);
    QFont font(QStringLiteral("Inter")); font.setPixelSize(14); menu->setFont(font);
    menu->setAttribute(Qt::WA_TranslucentBackground);
    menu->setStyleSheet(QStringLiteral(
        "QMenu { background:%1; color:%2; border:0; border-radius:8px; padding:8px; }"
        "QMenu::item { min-height:24px; padding:12px 36px 12px 44px; border-radius:4px; }"
        "QMenu::item:selected { background:%3; }"
        "QMenu::item:disabled { color:%4; }"
        "QMenu::separator { height:1px; background:%3; margin:4px 12px; }"
        "QMenu::icon { margin-left:12px; }"
        "QMenu::indicator { width:16px; height:16px; margin-left:12px; }")
        .arg(background, foreground, hover, dark ? "#555555" : "#999999"));
}

VLCMenu::VLCMenu(qt_intf_t *p_intf) : QMenu()
{
    assert(p_intf);
    if (isWindow()) QVLCDialog::setWindowTransientParent(this, nullptr, p_intf);
    applyMenuStyle(this, p_intf->p_mi);
    if (p_intf->p_mi)
        connect(p_intf->p_mi->getColorScheme(), &ColorSchemeModel::currentChanged, this,
                [this, ctx = p_intf->p_mi]() { applyMenuStyle(this, ctx); });
}

VLCMenu::VLCMenu(const QString &title, qt_intf_t *p_intf) : VLCMenu(p_intf) { setTitle(title); }

VLCMenu::VLCMenu(const QString &title, QWidget *parent) : QMenu(title, parent)
{
    assert(parent);
    setFont(parent->font());
    setPalette(parent->palette());
    setAttribute(Qt::WA_TranslucentBackground);
}

// Keep the player's primary context menu in the order shown by the redesign.
// Submenus retain VLC's native actions and dynamic choices.
QMenu* VLCMenuBar::PopupMenu(qt_intf_t *p_intf, bool show)
{
    auto *menu = new VLCMenu(p_intf);
    const auto icon = [](const char *name) {
        return QIcon(QStringLiteral(":/redesign/icons/%1/default.png").arg(QString::fromLatin1(name)));
    };
    PopupMenuPlaylistEntries(menu, p_intf);
    // The helper ends with a separator; remove it before Hide UI.
    if (!menu->actions().isEmpty() && menu->actions().last()->isSeparator())
        delete menu->actions().last();
    const QStringList icons = {"play", "stop", "previous", "next", "record"};
    const QStringList names = {THEMIM->getPlayingState() == PlayerController::PLAYING_STATE_PLAYING ? qtr("Pause") : qtr("Play"),
                              qtr("Stop"), qtr("Previous Item"), qtr("Next Item"), qtr("Record")};
    for (int i = 0; i < menu->actions().size() && i < icons.size(); ++i) {
        auto *action = menu->actions()[i];
        action->setText(names[i]);
        action->setIcon(icon(qtu(icons[i])));
    }
    menu->addSeparator();
    if (p_intf->p_mi) {
        auto *hide = menu->addAction(icon("ui"), p_intf->p_mi->isMinimalView() ? qtr("Show UI") : qtr("Hide UI"),
                                    menu, [ctx = p_intf->p_mi]() { ctx->setMinimalView(!ctx->isMinimalView()); });
        hide->setCheckable(true);
        hide->setChecked(p_intf->p_mi->isMinimalView());
    }
    menu->addSeparator();
    const auto submenu = [&](const QString &title, const char *name, auto fill) {
        auto *child = new VLCMenu(title, menu);
        fill(p_intf, child);
        auto *action = menu->addMenu(child);
        action->setIcon(icon(name));
        action->setEnabled(!child->isEmpty());
    };
    submenu(qtr("Playback"), "playback", NavigMenu);
    submenu(qtr("Video"), "video", VideoMenu);
    submenu(qtr("Audio"), "audio", AudioMenu);
    submenu(qtr("Subtitle"), "subtitles", [](qt_intf_t *intf, QMenu *child) { SubtitleMenu(intf, child, true); });
    menu->addSeparator();
    submenu(qtr("More Settings"), "settings", ToolsMenu);
    auto *playlist = new VLCMenu(qtr("Playlist"), menu);
    PopupMenuControlEntries(playlist, p_intf);
    menu->addMenu(playlist)->setIcon(icon("playlist"));
    submenu(qtr("Open Media"), "folder", FileMenu);
    menu->addAction(icon("quit"), qtr("Quit VLC"), THEDP, &DialogsProvider::quit);
    if (show) menu->popup(QCursor::pos());
    return menu;
}
