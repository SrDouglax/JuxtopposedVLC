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


#include <QNetworkProxy>
#include <QSslConfiguration>
#include <QSslCertificate>

bool runAssociationsProbe(QQuickWindow *view, QQuickItem *context)
{
    // Trust and route only this disposable process through the local API fixture.
    auto ssl = QSslConfiguration::defaultConfiguration();
    ssl.addCaCertificates(QSslCertificate::fromPath("/work/build-m3/fixtures/api.crt"));
    QSslConfiguration::setDefaultConfiguration(ssl);
    QNetworkProxy::setApplicationProxy(QNetworkProxy(QNetworkProxy::HttpProxy, "127.0.0.1", 18789));
    bool failed = false;
    auto check = [&](bool ok, const char *name) {
        qInfo() << "MINI-PROBE" << name << (ok ? "PASS" : "FAIL"); failed |= !ok;
    };
    auto evaluate = [&](QObject *object, const QString &code) {
        auto internal = object->objectName() == "subtitleAssociationsDialog"
            ? object->property("contentItem").value<QObject*>() : nullptr;
        if (!internal && object->property("pendingSave").isValid())
            internal = object->findChild<QObject*>("openSubtitlesResults");
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
    for (auto child : view->contentItem()->childItems())
        if (qmlContext(child)) { context = child; break; }
    auto window = qobject_cast<QWindow*>(evaluate(context, "MainCtx.intfMainWindow").value<QObject*>());
    if (window) window->showMaximized();
    evaluate(context, "MainCtx.playerView = false"); QTest::qWait(300);
    auto libraryScene = view->contentItem()->findChild<QQuickItem*>("libraryMiniPlayer");
    if (libraryScene && !qEnvironmentVariableIsSet("MINI_PROBE_AUDIT")) {
        auto folders = evaluate(libraryScene, "Qt.createQmlObject('import QtQuick; import VLC.MainInterface; import VLC.MediaLibrary; MLFolderModel { ctx: MainCtx }', g_mainDisplay, 'associationFixtureFolder')").value<QObject*>();
        if (folders) { evaluate(folders, "add('file:///work/build-m0/fixtures')"); QTest::qWait(600); folders->deleteLater(); }
    }
    auto associations = libraryScene ? evaluate(libraryScene,
        "Qt.createQmlObject('import QtQuick; import VLC.MediaLibrary; SubtitleAssociationsDialog {}', g_mainDisplay, 'associationAudit')").value<QObject*>() : nullptr;
    check(associations != nullptr, "subtitle-association-native-loads");
    if (associations) {
        evaluate(associations, "openForUrl('file:///work/build-m3/fixtures/Show.S01E01.mkv')"); QTest::qWait(500);
        evaluate(associations, "addFiles(['file:///work/build-m3/fixtures/Show.S01E01.srt'])"); QTest::qWait(250);
        check(associations->property("readyToSave").toBool(), "subtitle-file-mapping-ready");
        capture("subtitle-computer");
        check(evaluate(associations, "singleFile").toBool(), "subtitle-single-file-uses-selectable-list");
        evaluate(associations, "associations.setSourceSelected(0,false)");
        check(!associations->property("readyToSave").toBool(), "subtitle-no-selection-disables-save");
        evaluate(associations, "saveAssociations()");
        check(!associations->property("error").toString().isEmpty() && associations->property("visible").toBool(), "subtitle-native-save-rejects-empty-selection");
        evaluate(associations, "associations.setSourceSelected(0,true)");
        check(associations->property("readyToSave").toBool(), "subtitle-selection-restores-save");
        evaluate(associations, "selectedOrigin = 1"); capture("subtitle-link");
        evaluate(associations, "reject(); selectedOrigin = 2; openForUrl('file:///work/build-m3/fixtures/Show.S01E01.mkv')");
        QTest::qWait(200);
        auto online = evaluate(associations, "onlinePanel").value<QObject*>();
        check(online != nullptr, "subtitle-online-panel-loaded");
        if (online) {
            evaluate(online, "queryField.text = 'Show.S01E01'; account.apiKey = 'fixture-key'; search()");
            for (int attempt = 0; attempt < 60 && evaluate(online, "service.results.length").toInt() != 2; ++attempt) QTest::qWait(100);
            check(evaluate(online, "service.results.length === 2 && !busy").toBool(), "subtitle-native-https-search-loads-results");
            evaluate(online, "selectedIndex = 0"); capture("subtitle-search");
            auto save = associations->findChild<QQuickItem*>("subtitleSaveButton");
            check(save && save->isEnabled(), "subtitle-online-save-enabled-for-selection");
            if (save) {
                QTest::mouseClick(view, Qt::LeftButton, Qt::NoModifier, save->mapToScene(QPointF(save->width()/2,save->height()/2)).toPoint(), 50);
                QTest::qWait(100);
                check(evaluate(online, "account.visible && account.z > 100 && account.downloadRequired && !account.credentialsReady").toBool(), "subtitle-save-opens-account-above-dialog");
                capture("subtitle-account");
                evaluate(online, "account.username = 'fixture-user'; account.password = 'fixture-password'; account.accept()");
                check(evaluate(online, "busy").toBool(), "subtitle-online-save-starts-native-download");
                auto target = associations->findChild<QQuickItem*>("subtitleTargetPicker");
                check(target && !target->isEnabled(), "subtitle-target-locked-during-download");
                for (int attempt = 0; attempt < 80 && associations->property("visible").toBool(); ++attempt) QTest::qWait(100);
                check(!associations->property("visible").toBool() && associations->property("error").toString().isEmpty(), "subtitle-online-save-waits-for-file-and-native-association");
                check(evaluate(online, "account.apiKey.length === 0 && account.password.length === 0").toBool(), "subtitle-online-close-clears-session-credentials");
            }
        }
        evaluate(associations, "reject(); selectedOrigin = 0; audioTracks = true; openForUrl('file:///work/build-m3/fixtures/Show.S01E01.mkv')");
        QTest::qWait(400);
        evaluate(associations, "addFiles(['file:///work/build-m3/fixtures/music.mp3'])");
        check(associations->property("readyToSave").toBool(), "audio-file-mapping-ready"); capture("audio-association");
        evaluate(associations, "saveAssociations()"); QTest::qWait(1200);
        qInfo() << "AUDIT association error" << associations->property("error");
        check(!associations->property("visible").toBool(), "audio-association-saved-in-native-library");
        evaluate(associations, "audioTracks = false; openForUrl('file:///work/build-m3/fixtures/Show.S01E01.mkv')");
        QTest::qWait(300);
        const int folder = evaluate(associations,
            "associations.targets.findIndex(target => target.kind === 'Folder')").toInt();
        check(folder >= 0, "subtitle-indexed-folder-target-available");
        if (folder >= 0) {
            evaluate(associations, QString("associations.selectTarget(%1)").arg(folder));
            QTest::qWait(400);
            evaluate(associations, "addFiles(['file:///work/build-m0/fixtures/baseline.srt'])");
            check(!associations->property("singleFile").toBool()
                  && associations->property("readyToSave").toBool(), "subtitle-folder-matching-uses-native-destinations");
            capture("subtitle-folder");
        }
        evaluate(associations, "reject()");
        associations->deleteLater();
    }
    evaluate(context, "MainPlaylistController.append(['file:///work/build-m3/fixtures/Show.S01E01.mkv'], true); MainCtx.playerView = true"); QTest::qWait(1500);
    check(evaluate(context, "Player.audioTracks.count >= 2").toBool(), "saved-external-audio-track-loads-in-player");
    return !failed;
}
