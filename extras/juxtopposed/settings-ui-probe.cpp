// Native VLC UI regression probe. Loaded only by player-ui-test.sh.
#include <QCoreApplication>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QQuickItem>
#include <QtQuick/private/qquickwindow_p.h>
#include <QQmlContext>
#include <QQmlExpression>
#include <QTimer>
#include <QtTest/QTest>
#include <QDebug>
#include <QMap>
#include <thread>
#include <chrono>
#include <functional>

void runSettingsProbe(QQuickWindow *view, QQuickItem *mini) {
    bool failed = false;
    auto check = [&](bool ok, const char *name) { qInfo() << "MINI-PROBE" << name << (ok ? "PASS" : "FAIL"); failed |= !ok; };
    QQmlExpression expression(qmlContext(mini), mini, "MainCtx.intfMainWindow");
    auto interfaceWindow = qobject_cast<QWindow*>(expression.evaluate().value<QObject*>());
    if (!interfaceWindow) { check(false, "settings-native-window"); QCoreApplication::quit(); return; }
    interfaceWindow->showMaximized(); QTest::qWait(600);
    QQmlExpression open(qmlContext(mini), mini, "DialogsProvider.prefsDialog()");
    open.evaluate(); QTest::qWait(500);
    auto popup = view->contentItem()->findChild<QObject*>("redesignSettingsDialog");
    check(popup && popup->property("visible").toBool(), "settings-opens");
    if (!popup) { QCoreApplication::quit(); return; }
    auto content = qobject_cast<QQuickItem*>(popup->property("contentItem").value<QObject*>());
    auto named = [&](const QString &name) -> QQuickItem* {
        std::function<QQuickItem*(QQuickItem*)> visit = [&](QQuickItem *item) -> QQuickItem* {
            if (item->objectName() == name && item->isVisible()) return item;
            for (auto child : item->childItems()) if (auto found = visit(child)) return found;
            return nullptr;
        };
        return visit(content);
    };
    auto click = [&](QQuickItem *item) {
        if (!item) { check(false, "settings-click-target"); return; }
        // Reach clipped fields through their real scroll viewport. Clicking an
        // offscreen item's scene position would instead dismiss the popup.
        for (auto ancestor = item->parentItem(); ancestor; ancestor = ancestor->parentItem()) {
            if (!ancestor->property("contentY").isValid()) continue;
            const auto bounds = item->mapRectToItem(ancestor, item->boundingRect());
            double y = ancestor->property("contentY").toDouble();
            if (bounds.top() < 0) y += bounds.top();
            else if (bounds.bottom() > ancestor->height()) y += bounds.bottom() - ancestor->height();
            ancestor->setProperty("contentY", qBound(0.0, y, qMax(0.0, ancestor->property("contentHeight").toDouble() - ancestor->height())));
            QQuickWindowPrivate::get(view)->polishItems();
        }
        const auto pos = item->mapToScene(QPointF(item->width()/2, item->height()/2)).toPoint();
        QTest::mouseMove(view, pos, 30); QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, pos, 50);
        QTest::qWait(200); QQuickWindowPrivate::get(view)->polishItems();
    };
    const QStringList categories = {"general", "interface", "privacy", "controls", "playback", "video", "audio", "subtitles", "library", "network", "performance", "recording", "extensions"};
    for (const auto &category : categories) {
        click(named("settingsCategory_" + category));
        check(popup->property("selectedCategory").toString() == category, "settings-category-selected");
        QTest::qWait(150); QQuickWindowPrivate::get(view)->polishItems();
        view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-" + category + ".png");
        auto scroll = named("settingsContent");
        if (scroll && scroll->property("contentHeight").toDouble() > scroll->height()) {
            scroll->setProperty("contentY", scroll->property("contentHeight").toDouble() - scroll->height());
            QTest::qWait(150); QQuickWindowPrivate::get(view)->polishItems();
            view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-" + category + "-bottom.png");
        }
        auto advanced = named("settingsAdvancedOptions");
        if ((category == "general" || category == "performance") && advanced && advanced->isEnabled()) {
            click(advanced);
            view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-" + category + "-advanced.png");
            if (scroll) {
                scroll->setProperty("contentY", qMax(0.0, scroll->property("contentHeight").toDouble() - scroll->height()));
                QTest::qWait(150); QQuickWindowPrivate::get(view)->polishItems();
                view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-" + category + "-advanced-bottom.png");
            }
        }
    }
    click(named("settingsCategory_video"));
    const QMap<QString, QPair<double,double>> pictureRanges = {
        {"hue", {-180,180}}, {"brightness", {0,2}}, {"contrast", {0,2}},
        {"saturation", {0,3}}, {"gamma", {.01,10}}
    };
    for (auto it = pictureRanges.cbegin(); it != pictureRanges.cend(); ++it) {
        auto slider = named("settingsPicture-" + it.key());
        check(slider && slider->isEnabled()
            && qAbs(slider->property("from").toDouble() - it.value().first) < .001
            && qAbs(slider->property("to").toDouble() - it.value().second) < .001,
            "picture-sliders-use-native-adjust-ranges");
    }
    click(named("settingsCategory_privacy"));
    auto exclusion = named("settingInput_qt-history-exclude");
    auto clearHistory = named("privacyHistoryActions");
    check(exclusion && clearHistory && exclusion->mapToScene(QPointF()).y() < clearHistory->mapToScene(QPointF()).y(), "privacy-exclusion-precedes-clear-history");
    click(named("settingsCategory_playback"));
    QQmlExpression seekInitial(qmlContext(popup), popup, "config.valueFor('input-fast-seek')");
    const bool fastSeek = seekInitial.evaluate().toBool();
    click(named("settingToggle_input-fast-seek"));
    check(seekInitial.evaluate().toBool() != fastSeek, "precise-seeking-toggle-updates-native-fast-seek");
    click(named("settingToggle_input-fast-seek"));
    check(seekInitial.evaluate().toBool() == fastSeek, "precise-seeking-toggle-restores-native-value");
    click(named("settingsCategory_subtitles"));
    QQmlExpression shadowInitial(qmlContext(popup), popup, "config.valueFor('freetype-shadow-opacity')");
    const int shadowOpacity = shadowInitial.evaluate().toInt();
    click(named("settingToggle_freetype-shadow-opacity"));
    check((shadowInitial.evaluate().toInt() > 0) != (shadowOpacity > 0), "shadow-toggle-updates-native-opacity");
    click(named("settingToggle_freetype-shadow-opacity"));
    check(shadowInitial.evaluate().toInt() == shadowOpacity, "shadow-toggle-restores-opacity");
    click(named("settingsCategory_network"));
    check(named("settingInput_http-proxy") && named("settingInput_http-proxy-pwd"), "network-preserves-proxy-controls");
    click(named("settingsCategory_audio"));
    QQmlExpression normalizer(qmlContext(popup), popup,
        "inlineEffects.audioBridge.begin() && inlineEffects.audioBridge.setFilterEnabled('normvol',true) && inlineEffects.audioBridge.filterEnabled('normvol') && inlineEffects.audioBridge.setParameter('norm-max-level',1.25) && Math.abs(inlineEffects.audioBridge.parameterValue('norm-max-level')-1.25)<0.001");
    check(normalizer.evaluate().toBool(), "normalizer-native-filter-and-target");
    QQmlExpression rollback(qmlContext(popup), popup, "inlineEffects.audioBridge.cancel() && !inlineEffects.audioBridge.filterEnabled('normvol')");
    check(rollback.evaluate().toBool(), "normalizer-cancel-restores-filter-chain");
    QQmlExpression beginAudio(qmlContext(popup), popup, "inlineEffects.beginForCurrentCategory()"); beginAudio.evaluate();
    auto loudness = named("settingsLoudness");
    check(loudness != nullptr, "night-mode-control-loaded");
    if (loudness) {
        QQmlExpression prepare(qmlContext(popup), popup,
            "inlineEffects.audioBridge.setParameter('compressor-threshold',-10) && inlineEffects.audioBridge.setFilterEnabled('compressor',true)");
        check(prepare.evaluate().toBool(), "night-mode-previous-compressor-prepared");
        QQmlExpression enable(qmlContext(loudness), loudness, "setNightMode(true) && nightEnabled");
        check(enable.evaluate().toBool(), "night-mode-applies-complete-native-preset");
        click(named("settingsCategory_video"));
        click(named("settingsCategory_audio"));
        loudness = named("settingsLoudness");
        check(loudness != nullptr, "night-mode-control-reloads-after-category-change");
        QQmlExpression disable(qmlContext(loudness), loudness,
            "setNightMode(false) && !nightEnabled && effects.filterEnabled('compressor') && Math.abs(effects.parameterValue('compressor-threshold')+10)<0.001");
        check(disable.evaluate().toBool(), "night-mode-restores-previous-compressor");
        QQmlExpression cancel(qmlContext(popup), popup, "inlineEffects.audioBridge.cancel()");
        check(cancel.evaluate().toBool(), "night-mode-transaction-cancels");
        beginAudio.evaluate();
    }
    QQmlExpression options(qmlContext(popup), popup, "config.hasOption('qt-remember-window-position') && config.hasOption('qt-reverse-wheel') && config.hasOption('qt-double-click-action') && config.hasOption('qt-history-exclude') && config.hasOption('freetype-absolute-size')");
    check(options.evaluate().toBool(), "new-settings-have-native-options");
    QQmlExpression wheel(qmlContext(popup), popup,
        "Qt.createQmlObject('import QtQuick; import VLC.Util; WheelToVLCConverter { property int lastStep: 0; onWheelUpDown: (steps, modifiers) => lastStep = steps }', root, 'wheelProbe')");
    auto converter = wheel.evaluate().value<QObject*>();
    check(converter != nullptr, "native-wheel-converter-loads");
    if (converter) {
        auto setReverse = [&](bool value) {
            QQmlExpression config(qmlContext(popup), popup, value ? "config.setValue('qt-reverse-wheel', true) && config.apply()" : "config.setValue('qt-reverse-wheel', false) && config.apply()");
            check(config.evaluate().toBool(), "reverse-setting-applies");
            QQmlExpression event(qmlContext(converter), converter, "customWheelEvent(Qt.point(0,0), Qt.point(0,120))");
            event.evaluate();
            if (event.hasError()) { qWarning() << event.error(); failed = true; }
            check(converter->property("lastStep").toInt() == (value ? -1 : 1), value ? "wheel-reversed" : "wheel-normal");
        };
        setReverse(false); setReverse(true); setReverse(false);
        converter->deleteLater();
    }
    click(named("settingsCategory_subtitles"));
    QQmlExpression pixel(qmlContext(popup), popup, "config.setValue('freetype-absolute-size',32)");
    check(pixel.evaluate().toBool(), "subtitle-pixels-stage-native-value");
    QTest::qWait(200); QQuickWindowPrivate::get(view)->polishItems();
    view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-subtitle-pixels.png");
    QQmlExpression relative(qmlContext(popup), popup, "config.setValue('freetype-absolute-size',0)");
    relative.evaluate();
    click(named("settingsCategory_general"));
    QQmlExpression light(qmlContext(popup), popup, "appearance.chooseTheme(1)");
    light.evaluate(); QTest::qWait(300); QQuickWindowPrivate::get(view)->polishItems();
    view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-light.png");
    QTest::keyClick(view, Qt::Key_Escape); QTest::qWait(250);
    check(!popup->property("visible").toBool(), "settings-escape-cancels");
    open.evaluate(); QTest::qWait(250);
    QQmlExpression staged(qmlContext(popup), popup, "config.setValue('volume-step', 7)");
    check(staged.evaluate().toBool(), "settings-value-staged");
    click(named("settingsClose"));
    check(!popup->property("visible").toBool(), "settings-close-saves");
    open.evaluate(); QTest::qWait(250);
    QQmlExpression saved(qmlContext(popup), popup, "config.valueFor('volume-step')");
    check(saved.evaluate().toInt() == 7, "settings-close-value-persists");
    QTest::keyClick(view, Qt::Key_Escape);
    qInfo() << "MINI-PROBE SETTINGS RESULT" << (failed ? "FAIL" : "PASS");
    QCoreApplication::quit();
}
