// Native contexts and remaining M3 surfaces; private test profile only.
#include <algorithm>
#include <functional>
#include <QPointer>
#include <QProcess>
#include <QApplication>
#include <QMenu>
#include <QInputDialog>
#include <QTimer>
#include <QQuickWindow>
#include <QQuickItem>
#include <QQmlContext>
#include <QQmlExpression>
#include <QtQuick/private/qquickwindow_p.h>
#include <QtTest/QTest>
#include <QDebug>

bool runAssociationsProbe(QQuickWindow*, QQuickItem*);

void runAuditProbe(QQuickWindow *view, QQuickItem *context)
{
    bool failed = false;
    auto check = [&](bool ok, const char *name) {
        qInfo() << "MINI-PROBE" << name << (ok ? "PASS" : "FAIL"); failed |= !ok;
    };
    auto evaluate = [&](QObject *object, const QString &code) {
        auto internal = object->objectName() == "sourceLibraryPane"
            ? object->property("listView").value<QObject*>() : nullptr;
        QQmlExpression expression(qmlContext(internal ? internal : object), object, code);
        auto result = expression.evaluate();
        if (expression.hasError()) { qWarning() << expression.error(); failed = true; }
        return result;
    };
    auto capture = [&](const QString &name) {
        QTest::mouseMove(view, QPoint(16,16), 30);
        QQuickWindowPrivate::get(view)->polishItems(); QTest::qWait(150);
        view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-" + name + ".png");
    };
    // Only the window's root survives navigation. Both the library display and
    // its miniplayer may be unloaded when playerView changes.
    for (auto child : view->contentItem()->childItems())
        if (qmlContext(child)) { context = child; break; }
    check(context != nullptr, "audit-persistent-display-context");
    if (!context) { QCoreApplication::quit(); return; }
    auto window = qobject_cast<QWindow*>(evaluate(context, "MainCtx.intfMainWindow").value<QObject*>());
    check(window != nullptr, "audit-native-window");
    if (!window) { QCoreApplication::quit(); return; }
    qInfo() << "AUDIT native volume" << evaluate(context, "Player.volume");
    check(qAbs(evaluate(context, "Player.volume").toFloat() - .5f) < .01f, "native-pulse-startup-volume-50-percent");
    check(evaluate(context, "/^[0-9]{2,}:[0-9]{2}:[0-9]{2}$/.test(VLCStyle.redesign.formatTime(Player.time))").toBool(), "player-times-use-reference-hours-minutes-seconds");
    window->showMaximized(); QTest::qWait(500);
    evaluate(context, "MainCtx.playerView = true; MainCtx.pinVideoControls = true"); QTest::qWait(400);
    evaluate(context, "DialogsProvider.setPopupMenu()"); QTest::qWait(250);
    auto menu = qobject_cast<QMenu*>(QApplication::activePopupWidget());
    check(menu && menu->isVisible(), "player-context-native-opens");
    if (menu) {
        QStringList names;
        for (auto action : menu->actions()) if (!action->isSeparator()) names << action->text().remove('&');
        const QStringList expected = {"Play", "Stop", "Previous Item", "Next Item", "Record", "Hide UI", "Playback", "Video", "Audio", "Subtitle", "More Settings", "Playlist", "Open Media", "Quit VLC"};
        if (!names.isEmpty() && names[0] == "Pause") names[0] = "Play";
        check(names == expected, "player-context-reference-action-order");
        menu->grab().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-player-context.png");
        QTest::keyClick(menu, Qt::Key_Escape); QTest::qWait(150);
    }
    evaluate(context, "MainCtx.playerView = false"); QTest::qWait(500);
    auto libraryScene = view->contentItem()->findChild<QQuickItem*>("libraryMiniPlayer");
    check(libraryScene != nullptr, "library-context-scene-present");
    QPointer<QObject> libraryContext = libraryScene ? evaluate(libraryScene,
        "Qt.createQmlObject('import QtQuick; import VLC.MainInterface; import VLC.MediaLibrary; Item { id: probe; property bool playlistCreated: false; MLFolderModel { id: folders; ctx: MainCtx } MLVideoModel { id: videos; ml: MediaLib } MLPlaylistListModel { id: playlists; ml: MediaLib; onCreationFinished: success => probe.playlistCreated = success } function createPlaylist() { playlists.create(\"M3 Source Playlist\", [\"file:///work/build-m0/fixtures/baseline.mkv\", \"file:///work/build-m3/fixtures/music.mp3\"]) } function playPlaylist() { playlists.getData([playlists.index(0,0)], data => MediaLib.addAndPlay(data[0].id)) } function playlistCount() { return playlists.count } function prepare(url) { folders.add(url) } function mediaCount() { return videos.count } MLContextMenu { id: libraryMenu; model: videos; showPlayAsAudioAction: true } function showMenu() { libraryMenu.popup([videos.index(0,0)], Qt.point(800,400)) } }', g_mainDisplay, 'libraryContextAudit')").value<QObject*>() : nullptr;
    check(libraryContext != nullptr, "library-context-native-model-loads");
    if (libraryContext) {
        evaluate(libraryContext, "prepare('file:///work/build-m0/fixtures')");
        int count = 0;
        for (int attempt = 0; attempt < 30 && !count; ++attempt) {
            count = evaluate(libraryContext, "mediaCount()").toInt(); QTest::qWait(100);
        }
        check(count > 0, "library-context-has-indexed-fixture");
        if (count) evaluate(libraryContext, "showMenu()");
        QTest::qWait(500); capture("library-context");
        const auto popups = view->contentItem()->findChildren<QObject*>("libraryContextMenu");
        const bool visible = std::any_of(popups.begin(), popups.end(), [](QObject *popup) { return popup->property("visible").toBool(); });
        check(visible, "library-context-real-media-opens");
        QTest::keyClick(view, Qt::Key_Escape);
        evaluate(libraryContext, "createPlaylist()");
        for (int attempt = 0; attempt < 30 && !libraryContext->property("playlistCreated").toBool(); ++attempt) QTest::qWait(100);
        int playlists = 0;
        for (int attempt = 0; attempt < 30 && !playlists; ++attempt) {
            playlists = evaluate(libraryContext, "playlistCount()").toInt(); QTest::qWait(100);
        }
        check(libraryContext->property("playlistCreated").toBool() && playlists > 0, "customization-source-playlist-created");
        if (playlists > 0) {
            evaluate(libraryContext, "playPlaylist()"); QTest::qWait(1000);
            check(evaluate(context, "Player.playlistName === 'M3 Source Playlist'").toBool(), "customization-source-playlist-name-reaches-native-player");
        }
        if (libraryContext) libraryContext->deleteLater();
    }
    evaluate(context, "MainPlaylistController.pause()");
    evaluate(context, "DialogsProvider.showToolbarEditorDialog()"); QTest::qWait(500);
    QPointer<QObject> editor = view->contentItem()->findChild<QObject*>("toolbarEditorDialog");
    if (!editor) editor = view->contentItem()->findChild<QObject*>("toolbarEditorPanel");
    check(editor != nullptr, "customization-native-opens");
    check(window->isActive(), "customization-native-window-active");
    auto catalog = view->contentItem()->findChild<QQuickItem*>("toolbarEditorControlCatalog");
    check(catalog != nullptr, "customization-catalog-present");
    if (catalog) {
        check(evaluate(catalog, "catalog.length === 31").toBool(), "customization-reference-31-controls");
        check(evaluate(catalog, "Math.floor(width / cellWidth) === 9").toBool(), "customization-nine-columns");
        check(evaluate(catalog,
            "catalog.map(entry => entry.text).join('|') === 'Spacer|Divider|Playback Speed|Forward 10s|Backward 10s|Forward 15s|Backward 15s|Stop|Repeat|Shuffle|Record|Snapshot|Picture in Picture|HDR|Zoom|Right Sidebar|Quit VLC|VLC Settings|Go Home|Thumbnail|File Name|Artist Name|Folder Name|Playlist Name|Properties|Replay|Chapters|Favorite|Bookmark|Bookmarks|Playlists'").toBool(), "customization-reference-control-order");
        const auto failures = evaluate(catalog, "catalog.map(entry => { const component = Qt.createComponent('qrc:///qt/qml/VLC/PlayerControls/' + entry.file); if (component.status !== Component.Ready) return entry.file + ': ' + component.errorString(); const instance = component.createObject(this, {visible:false}); const ready = !!instance; if(instance) instance.destroy(); return ready ? '' : entry.file }).filter(value => value.length).join(' | ')").toString();
        if (!failures.isEmpty()) qWarning() << "CUSTOMIZATION failures" << failures;
        check(failures.isEmpty(), "customization-all-native-controls-instantiate");
    }
    int visibleDropViews = 0;
    QQuickItem *leftDropView = nullptr;
    std::function<void(QQuickItem*)> inspectDropViews = [&](QQuickItem *item) {
        if (item->objectName() == "toolbarEditorDropView" && item->isVisible()
            && item->width() > 0 && item->property("count").toInt() > 0) {
            ++visibleDropViews;
            if (evaluate(item, "model === MainCtx.controlbarProfileModel.currentModel.getModel(0).left").toBool())
                leftDropView = item;
        }
        for (auto child : item->childItems()) inspectDropViews(child);
    };
    inspectDropViews(view->contentItem());
    check(visibleDropViews >= 2, "customization-live-player-controls-visible");
    capture("customization");
    auto nativeDrag = [&](QQuickItem *source, const QPoint &destination) {
        if (!source) return false;
        const QPoint start = source->mapToScene(QPointF(source->width()/2, source->height()/2)).toPoint();
        const QPoint globalStart = window->mapToGlobal(start);
        const QPoint globalEnd = window->mapToGlobal(destination);
        QStringList args{"mousemove", QString::number(globalStart.x()), QString::number(globalStart.y()),
                         "mousedown", "1", "sleep", "0.1"};
        for (int step = 1; step <= 16; ++step) {
            const QPoint position = globalStart + (globalEnd-globalStart)*step/16;
            args << "mousemove" << QString::number(position.x()) << QString::number(position.y()) << "sleep" << "0.035";
        }
        args << "mouseup" << "1";
        QProcess pointer; pointer.start("xdotool", args);
        for (int attempt = 0; attempt < 150 && pointer.state() != QProcess::NotRunning; ++attempt) QTest::qWait(20);
        QTest::qWait(250);
        return pointer.state() == QProcess::NotRunning && pointer.exitCode() == 0;
    };
    int originalControls = leftDropView ? leftDropView->property("count").toInt() : 0;
    if (catalog && leftDropView) {
        auto source = qobject_cast<QQuickItem*>(evaluate(catalog, "itemAtIndex(5)").value<QObject*>());
        check(source != nullptr, "customization-drag-source-present");
        if (source) {
            const QPoint destination = leftDropView->mapToScene(QPointF(leftDropView->width()-12, leftDropView->height()/2)).toPoint();
            check(nativeDrag(source, destination), "customization-native-pointer-drag-delivered");
            check(leftDropView->property("count").toInt() == originalControls + 1, "customization-real-drag-adds-15-second-control");
            check(evaluate(context, "MainCtx.controlbarProfileModel.currentModel.dirty").toBool(), "customization-drag-marks-profile-dirty");
            capture("customization-drag");
        }
    }
    QQuickItem *centerDropView = nullptr;
    std::function<void(QQuickItem*)> findCenter = [&](QQuickItem *item) {
        if (item->objectName() == "toolbarEditorDropView" && item->isVisible() && item->width() > 0
            && evaluate(item, "model === MainCtx.controlbarProfileModel.currentModel.getModel(0).center").toBool())
            centerDropView = item;
        for (auto child : item->childItems()) findCenter(child);
    };
    findCenter(view->contentItem());
    if (centerDropView && leftDropView && leftDropView->property("count").toInt() == originalControls + 1) {
        auto play = qobject_cast<QQuickItem*>(evaluate(leftDropView, "itemAtIndex(1)").value<QObject*>());
        nativeDrag(play, centerDropView->mapToScene(QPointF(centerDropView->width()/2, centerDropView->height()/2)).toPoint());
        check(centerDropView->property("count").toInt() == 1 && leftDropView->property("count").toInt() == originalControls,
              "customization-real-drag-moves-play-to-center");
        capture("customization-center");
        if (qEnvironmentVariableIsSet("MINI_PROBE_CUSTOMIZATION_ONLY")) {
            for (int repeat = 0; repeat < 4; ++repeat) {
                auto moved = qobject_cast<QQuickItem*>(evaluate(centerDropView, "itemAtIndex(0)").value<QObject*>());
                const int id = moved ? moved->property("controlId").toInt() : -1;
                nativeDrag(moved, leftDropView->mapToScene(QPointF(leftDropView->width()-2,leftDropView->height()/2)).toPoint());
                check(centerDropView->property("count").toInt() == 0, "customization-repeated-transfer-to-left");
                moved = qobject_cast<QQuickItem*>(evaluate(leftDropView, QString("Array.from({length:count}, (_,i) => itemAtIndex(i)).find(item => item.controlId === %1)").arg(id)).value<QObject*>());
                nativeDrag(moved, centerDropView->mapToScene(QPointF(centerDropView->width()/2,centerDropView->height()/2)).toPoint());
                check(centerDropView->property("count").toInt() == 1, "customization-repeated-transfer-to-center");
            }
        }
        auto added = qobject_cast<QQuickItem*>(evaluate(leftDropView, "Array.from({length:count}, (_,i) => itemAtIndex(i)).find(item => item.controlId === 53)").value<QObject*>());
        nativeDrag(added, catalog->mapToScene(QPointF(catalog->width()/2, catalog->height()/2)).toPoint());
        check(leftDropView->property("count").toInt() == originalControls - 1, "customization-real-drag-removes-control");
        auto next = qobject_cast<QQuickItem*>(evaluate(leftDropView, "Array.from({length:count}, (_,i) => itemAtIndex(i)).find(item => item.controlId === 4)").value<QObject*>());
        nativeDrag(next, leftDropView->mapToScene(QPointF(8, leftDropView->height()/2)).toPoint());
        check(evaluate(leftDropView, "itemAtIndex(0).controlId === 4").toBool(), "customization-real-drag-reorders-control");
    } else check(false, "customization-center-drop-zone-present");
    QQuickItem *headerCenter = nullptr;
    QQuickItem *headerLeft = nullptr;
    std::function<void(QQuickItem*)> findHeader = [&](QQuickItem *item) {
        if (item->objectName() == "toolbarEditorDropView" && item->isVisible() && item->width() > 0) {
            if (evaluate(item, "model === MainCtx.controlbarProfileModel.currentModel.getModel(3).center").toBool()) headerCenter = item;
            if (evaluate(item, "model === MainCtx.controlbarProfileModel.currentModel.getModel(3).left").toBool()) headerLeft = item;
        }
        for (auto child : item->childItems()) findHeader(child);
    };
    findHeader(view->contentItem());
    check(headerCenter && headerLeft && headerCenter->property("count").toInt() == 1 && headerLeft->property("count").toInt() == 2,
          "customization-migrates-existing-profile-with-header-controls");
    if (headerCenter && headerLeft && leftDropView) {
        auto title = qobject_cast<QQuickItem*>(evaluate(headerCenter, "itemAtIndex(0)").value<QObject*>());
        check(title && qAbs(title->mapToScene(QPointF(title->width()/2,0)).x() - view->width()/2) < 2,
              "customization-header-title-centered-in-window");
        const auto destination = [&] { return leftDropView->mapToScene(QPointF(leftDropView->width()-2, leftDropView->height()/2)).toPoint(); };
        nativeDrag(title, destination());
        check(headerCenter->property("count").toInt() == 0, "customization-moves-title-from-header-to-bottom");
        for (int attempt = 0; attempt < 2 && headerLeft->property("count").toInt(); ++attempt) {
            auto control = qobject_cast<QQuickItem*>(evaluate(headerLeft, "itemAtIndex(0)").value<QObject*>());
            nativeDrag(control, destination());
        }
        check(headerLeft->property("count").toInt() == 0, "customization-moves-navigation-metadata-out-of-header");
        capture("customization-header-moved");
    }
    // Exercise X11's real key path; the composited QQuickWindow is offscreen.
    QProcess keyboard;
    keyboard.start("xdotool", {"key", "--clearmodifiers", "Escape"});
    check(keyboard.waitForFinished(2000) && keyboard.exitCode() == 0,
          "customization-native-escape-delivered");
    for (int attempt = 0; attempt < 40 && editor; ++attempt) QTest::qWait(25);
    check(!editor, "customization-close-animation-completes");
    qInfo() << "CANCEL original" << originalControls << evaluate(context,
        "JSON.stringify({selected:MainCtx.controlbarProfileModel.selectedProfile, error:MainCtx.controlbarProfileModel.lastError, video:MainCtx.controlbarProfileModel.currentModel.getModel(0).left.count, audio:MainCtx.controlbarProfileModel.currentModel.getModel(1).left.count})");
    check(evaluate(context, QString("MainCtx.controlbarProfileModel.currentModel.getModel(0).left.count === %1").arg(originalControls)).toBool(), "customization-escape-restores-original-controls");
    check(evaluate(context, "MainCtx.controlbarProfileModel.currentModel.getModel(3).left.count === 2 && MainCtx.controlbarProfileModel.currentModel.getModel(3).center.count === 1").toBool(), "customization-cancel-restores-header-layout");
    const int profileCount = evaluate(context, "MainCtx.controlbarProfileModel.count").toInt();
    const int selectedProfile = evaluate(context, "MainCtx.controlbarProfileModel.selectedProfile").toInt();
    QPointer<QObject> profiles = evaluate(context,
        "Qt.createQmlObject('import QtQuick; import VLC.Dialogs; ProfilesMenu {}', this, 'profilesAudit')").value<QObject*>();
    check(profiles != nullptr, "profiles-menu-native-loads");
    auto createProfile = [&](const QString &name) {
        if (!profiles) return;
        profiles->setProperty("parent", QVariant::fromValue(view->contentItem()));
        evaluate(profiles, "open()"); QTest::qWait(150);
        QTimer::singleShot(200, [name] {
            for (auto widget : QApplication::topLevelWidgets()) {
                if (auto prompt = qobject_cast<QInputDialog*>(widget); prompt && prompt->isVisible()) {
                    prompt->setTextValue(name); prompt->accept(); return;
                }
            }
        });
        evaluate(profiles, "createNewProfile()"); QTest::qWait(400);
    };
    createProfile("M3 Draft Profile");
    editor = view->contentItem()->findChild<QObject*>("toolbarEditorDialog");
    check(editor && evaluate(context, QString("MainCtx.controlbarProfileModel.count === %1 && MainCtx.controlbarProfileModel.currentModel.name === 'M3 Draft Profile'").arg(profileCount + 1)).toBool(),
          "profiles-new-action-creates-selected-draft");
    keyboard.start("xdotool", {"key", "--clearmodifiers", "Escape"}); keyboard.waitForFinished(2000);
    for (int attempt = 0; attempt < 40 && editor; ++attempt) QTest::qWait(25);
    check(!editor && evaluate(context, QString("MainCtx.controlbarProfileModel.count === %1").arg(profileCount)).toBool(),
          "profiles-cancel-discards-new-draft");
    createProfile("M3 Saved Profile");
    editor = view->contentItem()->findChild<QObject*>("toolbarEditorDialog");
    auto saveProfile = view->contentItem()->findChild<QObject*>("toolbarEditorSave");
    check(saveProfile && saveProfile->property("enabled").toBool(), "profiles-new-draft-can-save-without-changing-controls");
    catalog = view->contentItem()->findChild<QQuickItem*>("toolbarEditorControlCatalog");
    QQuickItem *rightDropView = nullptr;
    std::function<void(QQuickItem*)> findRight = [&](QQuickItem *item) {
        if (item->objectName() == "toolbarEditorDropView" && item->isVisible() && item->width() > 0
            && evaluate(item, "model === MainCtx.controlbarProfileModel.currentModel.getModel(0).right").toBool())
            rightDropView = item;
        for (auto child : item->childItems()) findRight(child);
    };
    findRight(view->contentItem());
    if (catalog && rightDropView) {
        auto sidebar = qobject_cast<QQuickItem*>(evaluate(catalog, "itemAtIndex(15)").value<QObject*>());
        nativeDrag(sidebar, rightDropView->mapToScene(QPointF(rightDropView->width()-12, rightDropView->height()/2)).toPoint());
        capture("customization-sidebar");
        check(evaluate(rightDropView, "Array.from({length:count}, (_,i) => itemAtIndex(i)?.controlId).includes(62)").toBool(),
              "customization-sidebar-is-distinct-from-queue");
    } else check(false, "customization-sidebar-drop-zone-present");
    if (editor) evaluate(editor, "const header = MainCtx.controlbarProfileModel.currentModel.getModel(3); while (header.left.count) header.left.remove(0); while (header.center.count) header.center.remove(0); header.right.insert(0,{id:43}); saveEditor()");
    for (int attempt = 0; attempt < 40 && editor; ++attempt) QTest::qWait(25);
    evaluate(context, "MainCtx.controlbarProfileModel.reload()");
    check(!editor && evaluate(context, QString("MainCtx.controlbarProfileModel.count === %1 && MainCtx.controlbarProfileModel.currentModel.name === 'M3 Saved Profile'").arg(profileCount + 1)).toBool(),
          "profiles-save-survives-model-reload");
    check(evaluate(context, "const header = MainCtx.controlbarProfileModel.currentModel.getModel(3); header.left.count === 0 && header.center.count === 0 && header.right.count === 1").toBool(),
          "profiles-intentionally-empty-header-sections-survive-reload");
    QTest::qWait(300);
    QQuickItem *headerSettings = nullptr;
    std::function<void(QQuickItem*)> findHeaderSettings = [&](QQuickItem *item) {
        if (item->isVisible() && item->property("description").toString() == "Player settings"
            && item->property("opensBelow").toBool()) headerSettings = item;
        for (auto child : item->childItems()) findHeaderSettings(child);
    };
    findHeaderSettings(view->contentItem());
    check(headerSettings != nullptr, "customized-header-renders-native-settings-button");
    if (headerSettings) {
        const auto point = headerSettings->mapToScene(QPointF(headerSettings->width()/2,headerSettings->height()/2)).toPoint();
        QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, point, 50); QTest::qWait(300);
        check(evaluate(headerSettings, "checked && activePopup && activePopup.contentItem.mapToItem(popupViewport,0,0).y >= panelBottom").toBool(),
              "customized-header-popup-opens-below-header");
        capture("customization-header-popup");
        QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, point, 50); QTest::qWait(200);
        check(!headerSettings->property("checked").toBool(), "customized-header-popup-second-click-closes");
    }
    QQuickItem *sidebarButton = nullptr;
    std::function<void(QQuickItem*)> findSidebar = [&](QQuickItem *item) {
        if (item->objectName() == "sourceSidebarButton" && item->isVisible()
            && item->mapToScene(QPointF()).y() > view->height()/2) sidebarButton = item;
        for (auto child : item->childItems()) findSidebar(child);
    };
    findSidebar(view->contentItem());
    check(sidebarButton && sidebarButton->isVisible(), "customization-saved-sidebar-button-is-live");
    if (sidebarButton) {
        const auto position = window->mapToGlobal(sidebarButton->mapToScene(QPointF(sidebarButton->width()/2,sidebarButton->height()/2)).toPoint());
        QProcess pointer;
        pointer.start("xdotool", {"mousemove", QString::number(position.x()), QString::number(position.y()), "click", "1"});
        for (int attempt = 0; attempt < 100 && pointer.state() != QProcess::NotRunning; ++attempt) QTest::qWait(20);
        QTest::qWait(500);
        auto videoSource = view->contentItem()->findChild<QQuickItem*>("sourceLibraryPane");
        check(videoSource && videoSource->isVisible() && videoSource->property("hasSource").toBool()
              && qAbs(videoSource->mapToScene(QPointF()).x()) < 1,
              "customization-sidebar-opens-video-source-on-left");
        capture("video-library");
        evaluate(context, "MainCtx.playqueuePanel.visible = false");
    }
    evaluate(context, QString("if (MainCtx.controlbarProfileModel.count > %1 && MainCtx.controlbarProfileModel.currentModel.name === 'M3 Saved Profile') MainCtx.controlbarProfileModel.deleteSelectedProfile(); MainCtx.controlbarProfileModel.setSelectedProfile(%2); MainCtx.controlbarProfileModel.save()").arg(profileCount).arg(selectedProfile));
    if (profiles) profiles->deleteLater();
    if (qEnvironmentVariableIsSet("MINI_PROBE_CUSTOMIZATION_ONLY")) {
        qInfo() << "MINI-PROBE AUDIT RESULT" << (failed ? "FAIL" : "PASS");
        QCoreApplication::quit(); return;
    }
    failed |= !runAssociationsProbe(view, context);
    auto musicSource = evaluate(context,
        "Qt.createQmlObject('import QtQuick; import VLC.MainInterface; import VLC.MediaLibrary; Item { MLPlaylistListModel { id: playlists; ml: MediaLib } function playSource() { playlists.getData([playlists.index(0,0)], data => MediaLib.addAndPlay(data[0].id)) } }', this, 'musicSourceAudit')").value<QObject*>();
    check(musicSource != nullptr, "music-source-native-model-loads");
    QTest::qWait(400);
    if (musicSource) evaluate(musicSource, "playSource()");
    QTest::qWait(1000);
    evaluate(context, "MainPlaylistController.next(); MainCtx.playerView = true");
    QTest::qWait(1200);
    check(evaluate(context, "Player.playlistName === 'M3 Source Playlist' && Player.playlistId.length > 0").toBool(), "music-source-playlist-id-reaches-player");
    QObject *waveform = nullptr;
    for (int attempt = 0; attempt < 350 && !waveform; ++attempt) {
        for (auto candidate : view->contentItem()->findChildren<QObject*>("waveformAnalysis"))
            if (candidate->property("ready").toBool()) { waveform = candidate; break; }
        if (!waveform) QTest::qWait(100);
    }
    if (!waveform) for (auto candidate : view->contentItem()->findChildren<QObject*>("waveformAnalysis"))
        qWarning() << "WAVEFORM" << candidate->property("source") << candidate->property("durationSeconds") << candidate->property("lastError");
    check(waveform != nullptr, "music-waveform-uses-analyzed-audio-bins");
    capture("music");
    check(evaluate(context, "Player.hasInput && !Player.hasVideoOutput").toBool(), "music-uses-real-audio-input");
    evaluate(context, "MainCtx.playqueuePanel.visible = true"); QTest::qWait(400);
    auto sourcePane = view->contentItem()->findChild<QQuickItem*>("sourceLibraryPane");
    check(sourcePane && sourcePane->isVisible() && qAbs(sourcePane->mapToScene(QPointF()).x()) < 1,
          "music-library-anchored-to-left-edge");
    check(sourcePane && qAbs(sourcePane->width() - 426) < 1, "music-library-reference-width");
    check(sourcePane && sourcePane->property("hasSource").toBool(), "music-library-uses-origin-playlist");
    check(sourcePane && sourcePane->property("sourceName").toString() == "M3 Source Playlist", "music-library-shows-source-name");
    auto sourceTracks = view->contentItem()->findChild<QQuickItem*>("musicSourceTracks");
    for (int attempt = 0; attempt < 30 && sourceTracks && sourceTracks->property("count").toInt() != 2; ++attempt)
        QTest::qWait(100);
    check(sourceTracks && sourceTracks->property("count").toInt() == 2,
          "music-library-shows-two-source-items-instead-of-entire-queue");
    capture("music-library");
    auto clickSource = [&](const QString &name) {
        auto item = sourcePane ? sourcePane->findChild<QQuickItem*>(name) : nullptr;
        check(item && item->isVisible() && item->isEnabled(), "source-pane-click-target");
        if (!item) return;
        QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, item->mapToScene(QPointF(item->width()/2,item->height()/2)).toPoint(), 50);
        QTest::qWait(250);
    };
    if (sourcePane) {
        clickSource("sourceBackButton");
        check(sourcePane->property("browsingSources").toBool(), "source-pane-back-opens-playlist-level");
        clickSource("sourceForwardButton");
        check(!sourcePane->property("browsingSources").toBool(), "source-pane-forward-restores-source");
        clickSource("sourceViewModeButton");
        check(sourcePane->property("gridMode").toBool(), "source-pane-grid-mode-works");
        capture("music-library-grid");
        clickSource("sourceViewModeButton");
        clickSource("sourceSortButton");
        auto sortMenu = qobject_cast<QMenu*>(QApplication::activePopupWidget());
        check(sortMenu && sortMenu->isVisible(), "source-pane-native-sort-menu-opens");
        if (sortMenu) for (auto action : sortMenu->actions()) if (action->text().contains("Duration")) { action->trigger(); sortMenu->close(); break; }
        check(evaluate(sourcePane, "sourceModel.sortCriteria === 'duration'").toBool(), "source-pane-sort-applies-native-duration-order");
        clickSource("sourceContextButton");
        auto sourceMenu = qobject_cast<QMenu*>(QApplication::activePopupWidget());
        check(sourceMenu && sourceMenu->isVisible() && sourceMenu->actions().size() >= 4, "source-pane-native-playlist-actions-open");
        if (sourceMenu) { QTest::keyClick(sourceMenu, Qt::Key_Escape); QTest::qWait(150); }
        evaluate(sourcePane, "sourceModel.getData([sourceModel.index(0,0)], data => MediaLib.playFromPlaylist(data[0].id, sourceModel.parentId))");
        QTest::qWait(1000);
        check(evaluate(context, "Player.playlistName === 'M3 Source Playlist' && Player.playlistId.length > 0").toBool(), "source-pane-playing-item-preserves-origin-metadata");
    }
    evaluate(context, "MainCtx.playqueuePanel.visible = false");
    qInfo() << "MINI-PROBE AUDIT RESULT" << (failed ? "FAIL" : "PASS");
    if (musicSource) musicSource->deleteLater();
    QCoreApplication::quit();
}
