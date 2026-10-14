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
#include <thread>
#include <chrono>
#include <functional>

static QQuickWindow *view;
static QQuickItem *mini, *video;
static bool failed = false;
static void check(bool ok, const char *name) {
    qInfo() << "MINI-PROBE" << name << (ok ? "PASS" : "FAIL");
    failed |= !ok;
}
static void drag(QPoint start, QPoint delta, const char *name) {
    auto before = mini->position();
    QTest::mouseMove(view, start, 100);
    QTest::qWait(250); // show the actual hover controls before pressing
    QTest::mousePress(view, Qt::LeftButton, Qt::NoModifier, start, 50);
    for (int i = 1; i <= 10; ++i)
        QTest::mouseMove(view, start + delta * i / 10, 30);
    QTest::mouseRelease(view, Qt::LeftButton, Qt::NoModifier, start + delta, 50);
    QTest::qWait(150);
    qInfo() << "MINI-PROBE" << name << before << mini->position();
    check((mini->position() - before - QPointF(delta)).manhattanLength() < 5, name);
}
static void panels() {
    view->showMaximized(); QTest::qWait(600);
    QQmlExpression expression(qmlContext(mini), mini, "MainCtx.playerView = true; MainCtx.pinVideoControls = true");
    expression.evaluate();
    if(expression.hasError())qWarning()<<expression.error();
    QTest::qWait(1000);
    QQuickWindowPrivate::get(view)->polishItems();
    view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE")+"-player.png");
    auto find = [](const char *description) -> QQuickItem* {
        std::function<QQuickItem*(QQuickItem*)> visit = [&](QQuickItem *item)->QQuickItem* {
            if (item->isVisible() && item->property("description").toString() == description) return item;
            for(auto child:item->childItems()) if(auto found=visit(child))return found;
            return nullptr;
        };
        return visit(view->contentItem());
    };
    auto click = [](QQuickItem *item) {
        QQuickWindowPrivate::get(view)->polishItems();
        const auto p = item->mapToScene(QPointF(item->width()/2, item->height()/2)).toPoint();
        QTest::mouseMove(view, p, 100);
        QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, p, 100);
        QTest::qWait(250);
        QQuickWindowPrivate::get(view)->polishItems();
        QTest::qWait(50);
    };
    const char *descriptions[] = {"Player settings", "Languages and tracks", "Play Queue"};
    const char *names[] = {"playerSettingsMenu", "tracksMenu", "playerNavigationMenu"};
    for (int size = 0; size < 2; ++size) {
        if (size) { view->showNormal(); QTest::qWait(600); view->resize(720,540); QTest::qWait(600); check(view->size()==QSize(720,540),"small-window-size"); QQuickWindowPrivate::get(view)->polishItems(); QTest::qWait(100); }
        for (int i = 0; i < 3; ++i) {
            auto button = find(descriptions[i]);
            check(button != nullptr, descriptions[i]);
            if (!button) continue;
            auto viewport = button->property("popupViewport").value<QObject*>();
            qInfo()<<"MINI-PROBE viewport"<<descriptions[i]<<(viewport?viewport->property("width"):QVariant())<<(viewport?viewport->property("height"):QVariant());
            click(button);
            auto popup = button->findChild<QObject*>(names[i]);
            if (!popup) popup = view->contentItem()->findChild<QObject*>(names[i]);
            check(popup && popup->property("visible").toBool(), "panel-opens");
            check(button->property("checked").toBool(), "icon-active");
            if (popup) {
                auto parent = qobject_cast<QQuickItem*>(popup->property("parent").value<QObject*>());
                if (parent) {
                    auto origin = parent->mapToScene(QPointF(popup->property("x").toDouble(),popup->property("y").toDouble()));
                    auto width=popup->property("width").toDouble(), height=popup->property("height").toDouble();
                    qInfo() << "MINI-PROBE panel" << names[i] << origin << QSizeF(width,height) << view->size()<<"barTop"<<button->property("panelTop");
                    auto content=qobject_cast<QQuickItem*>(popup->property("contentItem").value<QObject*>());
                    if(content){auto actual=content->mapToScene(QPointF());check(actual.y()+content->height()<=button->property("panelTop").toDouble()-7,"rendered-content-above-bar");}
                    check(origin.x()>=0 && origin.y()>=0 && origin.x()+width<=view->width()+1 && origin.y()+height<=button->property("panelTop").toDouble()-7, "panel-in-bounds-above-entire-bar");
                    check(qAbs(view->width()-origin.x()-width-20)<3, "panel-right-aligned");
                }
                view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE")+QString("-%1-%2.png").arg(i).arg(size));
                if(i==2) {
                    for (auto label : {QString("Bookmarks"),QString("Chapters")}) {
                        auto content = qobject_cast<QQuickItem*>(popup->property("contentItem").value<QObject*>());
                        std::function<QQuickItem*(QQuickItem*)> visit = [&](QQuickItem *item)->QQuickItem* {
                            if(item->property("text").toString()==label && item->property("checked").isValid())return item;
                            for(auto child:item->childItems())if(auto found=visit(child))return found;
                            return nullptr;
                        };
                        if(auto tab=visit(content))click(tab);
                        check(popup->property("currentTab").toInt()==(label=="Bookmarks"?1:2), "navigation-tab");
                    }
                }
            }
            click(button);
            check(!button->property("checked").toBool(), "second-click-closes-icon");
            check(popup && !popup->property("visible").toBool(), "second-click-closes-popup");
            click(button);
            QTest::keyClick(view, Qt::Key_Escape);QTest::qWait(200);
            check(!button->property("checked").toBool(), "escape-clears-icon");
            click(button);
            QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, QPoint(200,200),100);QTest::qWait(200);
            check(!button->property("checked").toBool(), "outside-clears-icon");
        }
    }
    qInfo() << "MINI-PROBE PANELS RESULT" << (failed?"FAIL":"PASS");
    QMetaObject::invokeMethod(QCoreApplication::instance(), "quit", Qt::QueuedConnection);
}
static void run() {
    if (qEnvironmentVariableIsSet("MINI_PROBE_PANELS")) { panels(); return; }
    qInfo() << "MINI-PROBE platform" << QGuiApplication::platformName();
    auto evaluate = [](const QString &code) {
        QQmlExpression expression(qmlContext(mini), mini, code);
        auto result = expression.evaluate();
        if (expression.hasError()) qWarning() << expression.error();
        return result;
    };
    evaluate("MainPlaylistController.pause()");
    QTest::qWait(300);
    auto state = evaluate("Player.playingState");
    auto point = [](QQuickItem *item, qreal x, qreal y) {
        return item->mapToScene(QPointF(x, y)).toPoint();
    };
    // Moving away from the lower edge leaves room for every subsequent drag.
    auto title = mini->findChild<QQuickItem *>("miniPlayerTitleDrag");
    if (title) drag(point(title, 20, 12), QPoint(200, -280), "title");
    else {
        // The baseline title already has a known explicit grip, but no objectName.
        drag(point(video, 24, video->height() + 6 + 14 + 24 + 12), QPoint(200, -280), "title-baseline");
    }
    drag(point(video, 24, 24), QPoint(100, 50), "video-corner-hover");
    drag(point(video, video->width()/2, video->height()/2), QPoint(100, 50), "video-play-button");
    drag(point(video, video->width()/2 + 55, video->height()/2), QPoint(100, 50), "video-next-button");
    check(evaluate("Player.playingState") == state, "drag-does-not-toggle-playback");
    auto queue = mini->findChild<QQuickItem *>("miniPlayerQueueToggle");
    if (queue) {
        QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, point(queue, queue->width()/2, queue->height()/2), 100);
        QTest::qWait(300);
        check(mini->property("queueExpanded").toBool(), "queue-opens");
        QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, point(queue, queue->width()/2, queue->height()/2), 100);
        QTest::qWait(150);
        check(!mini->property("queueExpanded").toBool(), "queue-closes");
    }
    QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, point(video, video->width()/2, video->height()/2), 100);
    QTest::qWait(300);
    check(evaluate("Player.playingState") != state, "play-button-click");
    evaluate("MainPlaylistController.pause()");
    qInfo() << "MINI-PROBE RESULT" << (failed ? "FAIL" : "PASS");
    view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE"));
    QMetaObject::invokeMethod(QCoreApplication::instance(), "quit", Qt::QueuedConnection);
}
static void startup() {
    if (!qEnvironmentVariableIsSet("MINI_PROBE_IMAGE")) return;
    std::thread([] {
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    QMetaObject::invokeMethod(QCoreApplication::instance(), [] {
    auto timer = new QTimer;
    timer->setInterval(500);
    QObject::connect(timer, &QTimer::timeout, [timer] {
        static int attempts = 0;
        for (auto window : QGuiApplication::allWindows()) {
            auto candidate = qobject_cast<QQuickWindow *>(window);
            if (!candidate) continue;
            for (auto child : candidate->contentItem()->childItems()) {
                if (!qmlContext(child)) continue;
                QQmlExpression back(qmlContext(child), child, "MainCtx.playerView = false");
                back.evaluate();
                break;
            }
            auto item = candidate->contentItem()->findChild<QQuickItem *>("libraryMiniPlayer");
            if (!item) continue;
            QQmlExpression expression(qmlContext(item), item, "MainCtx.playerView = false");
            expression.evaluate();
            auto v = item->findChild<QQuickItem *>("miniPlayerVideo");
            if (v && item->isVisible() && v->isVisible() && ++attempts > 6) {
                view = candidate; mini = item; video = v;
                timer->stop();
                QTimer::singleShot(1000, run);
                return;
            }
        }
        if (++attempts > 100) {
            qWarning() << "MINI-PROBE no visible miniplayer";
            timer->stop(); QCoreApplication::quit();
        }
    });
    timer->start();
    }, Qt::QueuedConnection);
    }).detach();
}
Q_COREAPP_STARTUP_FUNCTION(startup)
