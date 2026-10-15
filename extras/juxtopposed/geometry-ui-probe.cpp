// Verify actual native window persistence across private VLC launches.
#include <QQuickItem>
#include <QWindow>
#include <QQmlExpression>
#include <QQmlContext>
#include <QtTest/QTest>
#include <QCoreApplication>
#include <QDebug>

void runGeometryProbe(QQuickItem *context)
{
    QQmlExpression expression(qmlContext(context), context, "MainCtx.intfMainWindow");
    auto window = qobject_cast<QWindow*>(expression.evaluate().value<QObject*>());
    bool pass = window;
    const int phase = qEnvironmentVariableIntValue("MINI_PROBE_GEOMETRY_PHASE");
    if (window) {
        if (phase == 1) {
            window->showNormal(); QTest::qWait(250);
            window->setGeometry(140, 100, 960, 680); QTest::qWait(400);
        }
        if (phase < 3) {
            QQmlExpression factory(qmlContext(context), context,
                "Qt.createQmlObject('import QtQuick; import VLC.Dialogs; import VLC.MainInterface; ConfigModel { ctx: MainCtx }', this, 'geometrySettings')");
            QObject *settings = factory.evaluate().value<QObject*>();
            bool applied = false;
            if (settings) {
                QQmlExpression update(qmlContext(settings), settings,
                    phase == 1 ? "setValue('qt-remember-window-position',true) && apply()"
                               : "setValue('qt-remember-window-position',false) && apply()");
                applied = update.evaluate().toBool();
                settings->deleteLater();
            }
            pass &= applied;
            qInfo() << "MINI-PROBE GEOMETRY preference" << phase << (applied ? "PASS" : "FAIL");
        }
        qInfo() << "GEOMETRY phase" << phase << window->geometry();
        pass &= window->width() == (phase == 3 ? 600 : 960)
            && window->height() == (phase == 3 ? 420 : 680);
        if (phase < 3) pass &= window->position() == QPoint(140,100);
    }
    qInfo() << "MINI-PROBE GEOMETRY PHASE" << phase << (pass ? "PASS" : "FAIL");
    if (phase == 3) qInfo() << "MINI-PROBE GEOMETRY RESULT" << (pass ? "PASS" : "FAIL");
    QCoreApplication::quit();
}
