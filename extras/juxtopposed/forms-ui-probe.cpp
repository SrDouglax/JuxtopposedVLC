// Real VLC forms and library menu probe, on the private display/profile.
#include <QAbstractItemModel>
#include <QCoreApplication>
#include <QQuickWindow>
#include <QQuickItem>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlExpression>
#include <QtQuick/private/qquickwindow_p.h>
#include <QtTest/QTest>
#include <QMimeData>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QDebug>
#include <functional>

void runFormsProbe(QQuickWindow *view, QQuickItem *context)
{
    bool failed = false;
    auto check = [&](bool ok, const char *name) {
        qInfo() << "MINI-PROBE" << name << (ok ? "PASS" : "FAIL"); failed |= !ok;
    };
    auto evaluate = [&](QObject *object, const QString &code) {
        QQmlExpression expression(qmlContext(object), object, code);
        auto value = expression.evaluate();
        if (expression.hasError()) { qWarning() << expression.error(); failed = true; }
        return value;
    };
    auto named = [](QObject *popup, const QString &name) -> QQuickItem* {
        auto content = qobject_cast<QQuickItem*>(popup->property("contentItem").value<QObject*>());
        std::function<QQuickItem*(QQuickItem*)> visit = [&](QQuickItem *item) -> QQuickItem* {
            if (!item) return nullptr;
            if (item->objectName() == name) return item;
            for (auto child : item->childItems()) if (auto found = visit(child)) return found;
            return nullptr;
        };
        return visit(content);
    };
    auto click = [&](QQuickItem *item) {
        if (!item) { check(false, "form-click-target"); return; }
        QQuickWindowPrivate::get(view)->polishItems();
        auto pos = item->mapToScene(QPointF(item->width()/2, item->height()/2)).toPoint();
        check(view->contentItem()->boundingRect().contains(pos), "form-click-in-window");
        QTest::mouseMove(view, pos, 30); QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, pos, 50);
        QTest::qWait(200); QQuickWindowPrivate::get(view)->polishItems();
    };
    auto capture = [&](const QString &name) { view->grabWindow().save(qEnvironmentVariable("MINI_PROBE_IMAGE") + "-" + name + ".png"); };
    auto window = qobject_cast<QWindow*>(evaluate(context, "MainCtx.intfMainWindow").value<QObject*>());
    check(window != nullptr, "forms-native-window");
    if (!window) { QCoreApplication::quit(); return; }
    window->showMaximized(); QTest::qWait(500);
    evaluate(context, "DialogsProvider.openNetDialog()"); QTest::qWait(500);
    auto network = view->contentItem()->findChild<QObject*>("networkStreamDialog");
    check(network && network->property("visible").toBool(), "network-reference-form-opens");
    if (!network) { QCoreApplication::quit(); return; }
    check(network->property("width").toDouble() == 1048 && network->property("height").toDouble() == 632, "network-reference-dimensions");
    capture("network-empty");
    auto urls = named(network, "networkUrls"), title = named(network, "networkPlaylistName");
    check(urls && title, "network-fields-present");
    if (!urls || !title) { QCoreApplication::quit(); return; }
    urls->setProperty("text", "missing-protocol");
    check(!network->property("canSave").toBool(), "network-invalid-url-disabled");
    const QString stream = "http://127.0.0.1:18787/baseline.mkv";
    urls->setProperty("text", stream + "\n" + stream + "?second"); title->setProperty("text", "M3 Streams Probe");
    check(network->property("canSave").toBool(), "network-multiple-urls-enabled");
    capture("network-filled");
    auto model = qobject_cast<QAbstractItemModel*>(evaluate(network, "playlists").value<QObject*>());
    click(named(network, "networkStreamDialogSave"));
    check(!network->property("visible").toBool(), "network-save-closes");
    auto playlistHas = [&](const QString &name, int count, bool customCover) {
        if (!model) return false;
        const auto roles = model->roleNames();
        const auto nameRole = roles.key("name"), countRole = roles.key("count"), coverRole = roles.key("thumbnail");
        for (int i = 0; i < model->rowCount(); ++i) {
            auto index = model->index(i,0);
            if (model->data(index,nameRole).toString() == name)
                return model->data(index,countRole).toInt() == count
                    && (!customCover || model->data(index,coverRole).toString().endsWith("Icon.png"));
        }
        return false;
    };
    for (int i = 0; i < 50 && !playlistHas("M3 Streams Probe",2,false); ++i) QTest::qWait(100);
    check(playlistHas("M3 Streams Probe",2,false), "network-playlist-has-two-real-items");
    QQmlComponent component(qmlEngine(context), QUrl("qrc:/qt/qml/VLC/MediaLibrary/PlaylistCreateDialog.qml"));
    auto playlist = component.createWithInitialProperties({{"playlistModel", QVariant::fromValue(model)}, {"parent", QVariant::fromValue(view->contentItem())}});
    if (!component.errors().isEmpty()) qWarning() << component.errors();
    check(playlist != nullptr, "playlist-reference-form-loads");
    if (playlist) {
        playlist->setParent(view->contentItem()); QMetaObject::invokeMethod(playlist,"open"); QTest::qWait(250);
        capture("playlist-empty");
        auto name = named(playlist,"playlistTitleField"), dropArea = named(playlist,"playlistFilesDrop");
        check(name && dropArea, "playlist-fields-and-drop-present");
        if (name && dropArea) {
            name->setProperty("text", "M3 Cover Probe");
            QMimeData mime; mime.setUrls({QUrl("file:///work/build-m0/fixtures/baseline.mkv")});
            const auto pos = dropArea->mapToScene(QPointF(20,20)).toPoint();
            QDragEnterEvent enter(pos, Qt::CopyAction, &mime, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(view, &enter);
            QDropEvent drop(pos, Qt::CopyAction, &mime, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(view, &drop); QTest::qWait(150);
            check(playlist->property("files").toList().size() == 1, "playlist-drop-adds-real-file");
            playlist->setProperty("cover", QUrl("file:///work/build-m3/reference/export/Icon.png"));
            QTest::qWait(350); QQuickWindowPrivate::get(view)->polishItems();
            check(playlist->property("canSave").toBool(), "playlist-title-file-cover-enable-save");
            capture("playlist-filled"); click(named(playlist,"playlistCreateDialogSave"));
            for (int i = 0; i < 50 && playlist->property("visible").toBool(); ++i) QTest::qWait(100);
            check(!playlist->property("visible").toBool(), "playlist-creation-closes-after-result");
            for (int i = 0; i < 50 && !playlistHas("M3 Cover Probe",1,true); ++i) QTest::qWait(100);
            check(playlistHas("M3 Cover Probe",1,true), "playlist-real-item-and-cover-in-model");
        }
        QMetaObject::invokeMethod(playlist,"close");
    }
    evaluate(context, "DialogsProvider.openNetDialog()"); QTest::qWait(200);
    urls->setProperty("text",stream);
    click(named(network,"networkStreamDialogSave"));
    for (int i = 0; i < 60 && !evaluate(network,"Player.url.toString().startsWith('http:')").toBool(); ++i) QTest::qWait(100);
    check(evaluate(network,"Player.url.toString().startsWith('http:')").toBool(), "network-stream-reaches-native-player");
    qInfo() << "MINI-PROBE FORMS RESULT" << (failed ? "FAIL" : "PASS");
    QCoreApplication::quit();
}
