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
#include <QProcess>
#include <thread>
#include <chrono>
#include <functional>

void runFormsProbe(QQuickWindow*, QQuickItem*);
void runSettingsProbe(QQuickWindow*, QQuickItem*);
bool runAssociationsProbe(QQuickWindow*, QQuickItem*);
void runAuditProbe(QQuickWindow*, QQuickItem*);
void runOnboardingProbe(QQuickWindow*, QQuickItem*);
static QQuickWindow *view;
static QWindow *interfaceWindow;
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
    QQmlExpression nativeWindow(qmlContext(mini), mini, "MainCtx.intfMainWindow");
    interfaceWindow = qobject_cast<QWindow*>(nativeWindow.evaluate().value<QObject*>());
    check(interfaceWindow != nullptr, "native-interface-window");
    if (!interfaceWindow) { QCoreApplication::quit(); return; }
    interfaceWindow->showMaximized(); QTest::qWait(600);
    QQmlExpression expression(qmlContext(mini), mini, "MainCtx.playerView = true; MainCtx.pinVideoControls = true; MainPlaylistController.play()");
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
        const auto p = item->mapToScene(QPointF(item->width()/2, item->height()/2)).toPoint();
        QTest::mouseMove(view, p, 100);
        QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, p, 100);
        QTest::qWait(250);
        QQuickWindowPrivate::get(view)->polishItems();
        QTest::qWait(50);
    };
    auto evaluate = [](QObject *object, const QString &code) {
        QQmlExpression expression(qmlContext(object), object, code);
        auto result = expression.evaluate();
        if (expression.hasError()) { qWarning() << expression.error(); failed = true; }
        return result;
    };
    auto named = [](QObject *popup, const QString &name)->QQuickItem* {
        auto content = qobject_cast<QQuickItem*>(popup->property("contentItem").value<QObject*>());
        std::function<QQuickItem*(QQuickItem*)> visit = [&](QQuickItem *item)->QQuickItem* {
            if (!item) return nullptr;
            if (item->objectName() == name && item->isVisible()) return item;
            for (auto child : item->childItems()) if (auto found = visit(child)) return found;
            return nullptr;
        };
        return visit(content);
    };
    const char *descriptions[] = {"Player settings", "Languages and tracks", "Play Queue", "Audio effects"};
    const char *names[] = {"playerSettingsMenu", "tracksMenu", "playerNavigationMenu", "playerSettingsMenu"};
    for (int size = 0; size < 2; ++size) {
        if (size) { interfaceWindow->showNormal(); QTest::qWait(600); interfaceWindow->resize(720,540); QTest::qWait(600); check(view->size()==QSize(720,540),"small-window-size"); QQuickWindowPrivate::get(view)->polishItems(); QTest::qWait(100); }
        for (int i = 0; i < 4; ++i) {
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
                if (i == 3) {
                    check(popup->property("currentTab").toInt() == 2, "effects-opens-audio-tab");
                    auto eq = named(popup, "playerEqualizer");
                    check(eq && eq->property("expanded").toBool(), "effects-equalizer-expanded");
                    auto heading = named(popup, "playerAudioEffectsHeading");
                    if (heading) {
                        auto parent = qobject_cast<QQuickItem*>(popup->property("parent").value<QObject*>());
                        const auto top = parent->mapToScene(QPointF(popup->property("x").toDouble(), popup->property("y").toDouble())).y();
                        const auto y = heading->mapToScene(QPointF()).y();
                        check(y >= top + 48 && y <= top + 80, "effects-scroll-reveals-filters");
                    } else check(false, "effects-heading-present");
                    auto settings = find("Player settings");
                    check(settings && !settings->property("checked").toBool(), "effects-only-source-icon-active");
                }
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
                if (i == 0) {
                    for (int tabIndex = 0; tabIndex < 4; ++tabIndex) {
                        auto tab = named(popup, QString("panelTab%1").arg(tabIndex));
                        check(tab != nullptr, "settings-tab-present");
                        if (!tab) continue;
                        click(tab);
                        check(popup->property("currentTab").toInt() == tabIndex && tab->property("checked").toBool(), "settings-tab-active");
                        view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE")+QString("-settings-%1-%2.png").arg(tabIndex).arg(size));
                        if (size) continue;
                        if (tabIndex == 0) {
                            auto speed = named(popup, "playerSpeedRange");
                            check(speed != nullptr, "speed-control-present");
                            if (speed) {
                                QMetaObject::invokeMethod(speed, "edited", Q_ARG(double, 1.25));
                                QTest::qWait(150);
                                check(qAbs(evaluate(popup, "Player.rate").toDouble()-1.25)<0.01, "speed-updates-core");
                                QMetaObject::invokeMethod(speed, "edited", Q_ARG(double, 1.0));
                            }
                            auto stats = named(popup, "playerShowStatistics");
                            if (stats) { click(stats); check(evaluate(popup,"PlayerPanelState.showStatistics").toBool(), "statistics-toggle"); click(stats); }
                            check(evaluate(popup,"PlayerPanelState.statistics.decodedVideo > 0").toBool(), "statistics-from-core");
                            check(evaluate(popup,"PlayerPanelState.timelineAvailable && PlayerPanelState.cueAt(1).length > 0").toBool(), "timeline-from-srt");
                        } else if (tabIndex == 1) {
                            auto zoom = named(popup, "playerZoom");
                            check(zoom && qAbs(zoom->width()-218)<2, "choice-field-width");
                            if (zoom) {
                                click(zoom);
                                auto choices = zoom->property("popup").value<QObject*>();
                                check(choices && choices->property("visible").toBool(), "choice-dropdown-opens");
                                auto list = choices ? choices->property("contentItem").value<QObject*>() : nullptr;
                                check(list && list->property("count").toInt() > 0, "choice-dropdown-has-native-rows");
                                QTest::keyClick(view, Qt::Key_Escape); QTest::qWait(100);
                                check(popup->property("visible").toBool(), "choice-escape-keeps-settings-open");
                            }
                            auto flip = named(popup, "playerFlip-hflip");
                            auto reset = named(popup, "playerFlip-");
                            check(flip && reset && flip->isEnabled(), "flip-controls-available");
                            if (flip && reset) {
                                click(flip);
                                check(evaluate(popup,"videoEffects.filterEnabled('transform') && videoEffects.parameterValue('transform-type') === 'hflip'").toBool(), "flip-updates-core");
                                click(reset);
                                check(!evaluate(popup,"videoEffects.filterEnabled('transform')").toBool(), "flip-reset");
                            }
                        } else {
                            const auto name = tabIndex == 2 ? "playerAudioDelay" : "playerSubtitleDelay";
                            auto delay = named(popup, name);
                            check(delay != nullptr, "delay-control-present");
                            if (delay) {
                                auto fill = delay->findChild<QQuickItem*>("panelRangeFill");
                                check(fill && fill->width() < 1, "delay-zero-has-no-fill");
                                QMetaObject::invokeMethod(delay, "edited", Q_ARG(double, 0.5)); QTest::qWait(150);
                                check(evaluate(popup,tabIndex==2?"Player.audioDelayMS === 500":"Player.subtitleDelayMS === 500").toBool(), "delay-updates-core");
                                check(fill && qAbs(fill->x()-fill->parentItem()->width()/2) < 1 && fill->width() > 0, "positive-delay-fills-from-zero");
                                QMetaObject::invokeMethod(delay, "edited", Q_ARG(double, -4.0)); QTest::qWait(150);
                                check(evaluate(popup,tabIndex==2?"Player.audioDelayMS === -4000":"Player.subtitleDelayMS === -4000").toBool(), "negative-delay-updates-core");
                                check(fill && qAbs(fill->x()+fill->width()-fill->parentItem()->width()/2) < 1 && fill->width() > 0, "negative-delay-fills-to-zero");
                                view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE")+QString("-delay-negative-%1.png").arg(tabIndex));
                                QMetaObject::invokeMethod(delay, "edited", Q_ARG(double, 0.0));
                            }
                            if (tabIndex == 3) {
                                evaluate(popup, "for (let i=0; i<Player.subtitleTracks.count; ++i) Player.subtitleTracks.setData(Player.subtitleTracks.index(i,0),false,Qt.CheckStateRole)");
                                QTest::qWait(150);
                                auto choice = named(popup, "playerSubtitleTrackChoice");
                                check(choice && choice->property("currentIndex").toInt()==-1 && choice->property("displayText").toString()=="None", "disabled-tracks-show-none");
                                evaluate(popup, "Player.subtitleTracks.setData(Player.subtitleTracks.index(0,0),true,Qt.CheckStateRole)");
                            }
                        }
                    }
                }
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
                if (i == 1 && size == 0) {
                    popup->setProperty("currentTab", 0); QTest::qWait(150);
                    auto edit = named(popup, "playerSubtitleTools");
                    check(edit != nullptr, "subtitle-tools-accessible");
                    if (edit) {
                        click(edit);
                        check(popup->property("visiblePanel").toBool() && button->property("checked").toBool(), "subtitle-tools-active-icon");
                        click(button);
                        check(!popup->property("visiblePanel").toBool() && !button->property("checked").toBool(), "subtitle-tools-toggle-closes");
                        click(button);
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
    auto queue = find("Play Queue");
    QProcess::execute("xdotool", {"key", "--clearmodifiers", "q"}); QTest::qWait(200);
    check(queue && queue->property("checked").toBool(), "queue-keyboard-shortcut-opens-native-panel");
    QProcess::execute("xdotool", {"key", "--clearmodifiers", "q"}); QTest::qWait(200);
    check(queue && !queue->property("checked").toBool(), "queue-keyboard-shortcut-closes-native-panel");
    if (queue) {
        QQmlExpression removeQueue(qmlContext(queue), queue,
            "Qt.callLater(() => MainCtx.controlbarProfileModel.currentModel.getModel(0).right.clear())");
        removeQueue.evaluate(); QTest::qWait(300);
        QProcess::execute("xdotool", {"key", "--clearmodifiers", "q"}); QTest::qWait(200);
        auto fallback = view->contentItem()->findChild<QObject*>("shortcutQueueMenu");
        check(fallback && fallback->property("visible").toBool(), "queue-shortcut-works-with-button-removed");
        if (fallback) {
            QQmlExpression bounds(qmlContext(fallback), fallback, "y + height <= controlBar.y - 8 && x >= 0");
            check(bounds.evaluate().toBool(), "queue-shortcut-fallback-stays-above-entire-footer");
            QProcess::execute("xdotool", {"key", "--clearmodifiers", "q"}); QTest::qWait(200);
            check(!fallback->property("visible").toBool(), "queue-shortcut-fallback-second-key-closes");
            QQmlExpression restore(qmlContext(fallback), fallback, "MainCtx.controlbarProfileModel.reload()");
            restore.evaluate(); QTest::qWait(200);
        }
    }
    qInfo() << "MINI-PROBE PANELS RESULT" << (failed?"FAIL":"PASS");
    QMetaObject::invokeMethod(QCoreApplication::instance(), "quit", Qt::QueuedConnection);
}
void runGeometryProbe(QQuickItem *context);
static void run() {
    if (qEnvironmentVariableIsSet("MINI_PROBE_GEOMETRY_PHASE")) { runGeometryProbe(mini); return; }
    if (qEnvironmentVariableIsSet("MINI_PROBE_AUDIT")) { runAuditProbe(view, mini); return; }
    if (qEnvironmentVariableIsSet("MINI_PROBE_FORMS")) { runFormsProbe(view, mini); return; }
    if (qEnvironmentVariableIsSet("MINI_PROBE_ASSOCIATIONS")) {
        const bool ok = runAssociationsProbe(view, mini);
        qInfo() << "MINI-PROBE ASSOCIATIONS RESULT" << (ok ? "PASS" : "FAIL");
        QCoreApplication::quit(); return;
    }
    if (qEnvironmentVariableIsSet("MINI_PROBE_ONBOARDING")) { runOnboardingProbe(view, mini); return; }
    if (qEnvironmentVariableIsSet("MINI_PROBE_SETTINGS")) { runSettingsProbe(view, mini); return; }
    if (qEnvironmentVariableIsSet("MINI_PROBE_PANELS")) { panels(); return; }
    qInfo() << "MINI-PROBE platform" << QGuiApplication::platformName();
    auto evaluate = [](const QString &code) {
        QQmlExpression expression(qmlContext(mini), mini, code);
        auto result = expression.evaluate();
        if (expression.hasError()) qWarning() << expression.error();
        return result;
    };
    interfaceWindow = qobject_cast<QWindow*>(evaluate("MainCtx.intfMainWindow").value<QObject*>());
    check(interfaceWindow != nullptr, "mini-native-window");
    if (!interfaceWindow) { QCoreApplication::quit(); return; }
    interfaceWindow->showMaximized();
    QTest::qWait(600);
    QQuickWindowPrivate::get(view)->polishItems();
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
