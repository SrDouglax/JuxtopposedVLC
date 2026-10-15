// Exercise the real onboarding popup with a disposable profile.
#include <QCoreApplication>
#include <QQuickWindow>
#include <QQuickItem>
#include <QQmlContext>
#include <QQmlExpression>
#include <QtQuick/private/qquickwindow_p.h>
#include <QtTest/QTest>
#include <QDebug>
#include <QPointer>
#include <QColor>
#include <functional>

void runOnboardingProbe(QQuickWindow *view, QQuickItem *context)
{
    bool failed = false;
    auto check = [&](bool ok, const char *name) {
        qInfo() << "MINI-PROBE" << name << (ok ? "PASS" : "FAIL"); failed |= !ok;
    };
    auto evaluate = [&](QObject *object, const QString &code) {
        auto internal = object->objectName() == "onboardingDialog"
            ? object->property("contentItem").value<QObject*>() : nullptr;
        QQmlExpression expression(qmlContext(internal ? internal : object), object, code);
        const auto value = expression.evaluate();
        if (expression.hasError()) { qWarning() << expression.error(); failed = true; }
        return value;
    };
    auto capture = [&](const QString &name) {
        QQuickWindowPrivate::get(view)->polishItems(); QTest::qWait(100);
        view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-" + name + ".png");
    };
    auto window = qobject_cast<QWindow*>(evaluate(context, "MainCtx.intfMainWindow").value<QObject*>());
    check(window != nullptr, "onboarding-native-window");
    if (!window) { QCoreApplication::quit(); return; }
    window->showMaximized(); QTest::qWait(400);
    const auto initialAccent = evaluate(context, "VLCStyle.redesign.accent.toString()").toString();
    evaluate(context, "DialogsProvider.firstRunDialog()"); QTest::qWait(400);
    QPointer<QObject> popup = view->contentItem()->findChild<QObject*>("onboardingDialog");
    check(popup && popup->property("visible").toBool(), "onboarding-opens");
    if (!popup) { QCoreApplication::quit(); return; }
    auto named = [&](const QString &name) {
        std::function<QQuickItem*(QQuickItem*)> visit = [&](QQuickItem *item) -> QQuickItem* {
            if (item->objectName() == name && item->isVisible()) return item;
            for (auto child : item->childItems()) if (auto found = visit(child)) return found;
            return nullptr;
        };
        return visit(view->contentItem());
    };
    auto click = [&](const QString &name) {
        auto item = named(name);
        check(item != nullptr, "onboarding-click-target");
        if (!item) return;
        const auto point = item->mapToScene(QPointF(item->width()/2, item->height()/2)).toPoint();
        QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, point, 50); QTest::qWait(150);
    };
    capture("welcome");
    click("onboardingNextButton");
    check(popup->property("step").toInt() == 1, "onboarding-next-opens-theme");
    click("onboardingTheme_2");
    check(evaluate(popup, "controller.themeIndex === 2").toBool(), "onboarding-dark-theme-selected");
    const int colorCount = evaluate(popup, "VLCStyle.redesign.accentChoices.length").toInt();
    check(colorCount == 9, "onboarding-nine-native-accent-choices");
    for (int i = 0; i < colorCount; ++i) {
        click("onboardingAccent_" + QString::number(i));
        check(popup->property("selectedAccent").value<QColor>().name() == evaluate(popup, QString("VLCStyle.redesign.accentChoices[%1]").arg(i)).toString(), "onboarding-accent-preview-updates");
        capture("theme-" + QString::number(i));
    }
    click("onboardingNextButton");
    check(popup->property("step").toInt() == 2, "onboarding-next-opens-shortcuts");
    check(evaluate(popup, "shortcuts.length").toInt() == 12, "onboarding-six-shortcut-pairs-per-column");
    check(evaluate(popup, "shortcuts[8].action.length > 0 && shortcuts[8].sequence === 'Q' && shortcuts[9].sequence === 'Ctrl+L'").toBool(), "onboarding-queue-and-browser-show-active-ui-shortcuts");
    capture("shortcuts");
    QTest::keyClick(view, Qt::Key_Escape); QTest::qWait(200);
    check(!popup || !popup->property("visible").toBool(), "onboarding-escape-closes");
    check(evaluate(context, "VLCStyle.redesign.accent.toString()").toString() == initialAccent, "onboarding-cancel-restores-accent");
    qInfo() << "MINI-PROBE ONBOARDING RESULT" << (failed ? "FAIL" : "PASS");
    QCoreApplication::quit();
}
