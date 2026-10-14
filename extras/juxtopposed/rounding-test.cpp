// Exercise the real ImageExt QML component with the software scene graph.
#include "softwareimage.hpp"
#include <QGuiApplication>
#include <QQuickView>
#include <QQuickImageProvider>
#include <QQmlContext>
#include <QTimer>
#include <QDebug>
#include <QDir>

class FixtureProvider : public QQuickImageProvider
{
public:
    FixtureProvider() : QQuickImageProvider(Image) {}
    QImage requestImage(const QString &, QSize *size, const QSize &) override
    {
        QImage image(160, 80, QImage::Format_ARGB32_Premultiplied);
        image.fill(QColor("#00ccaa"));
        *size = image.size();
        return image;
    }
};

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    if (argc < 3) return 2;
    const QString root = QString::fromLocal8Bit(argv[1]);
    const QString out = QString::fromLocal8Bit(argv[2]);
    QDir().mkpath(out);
    qmlRegisterType<SoftwareImage>("VLC.Widgets", 1, 0, "SoftwareImage");
    QQuickView view;
    view.engine()->addImageProvider("fixture", new FixtureProvider);
    view.rootContext()->setContextProperty("componentUrl", QUrl::fromLocalFile(
        argc > 3 ? QString::fromLocal8Bit(argv[3])
                 : root + "/modules/gui/qt/widgets/qml/ImageExt.qml"));
    view.setSource(QUrl::fromLocalFile(root + "/extras/juxtopposed/rounding-test.qml"));
    if (view.status() == QQuickView::Error) return 2;
    view.show();
    bool passed = true;
    const auto snapshot = [&](const QString &name) {
        const QImage raw = view.grabWindow();
        raw.save(out + "/" + name + ".png");
        // Assertions use logical coordinates, including at 2x DPI.
        return raw.scaled(view.width(), view.height());
    };
    const QColor background("#36506b"), image("#00ccaa");
    const auto expect = [&](const QImage &shot, int x, int y, QColor color, const char *name) {
        const bool ok = shot.pixelColor(x, y) == color;
        qInfo() << name << (ok ? "PASS" : "FAIL");
        passed &= ok;
    };
    QTimer::singleShot(1200, [&] {
        QImage shot = snapshot("rounded");
        for (const QPoint point : {QPoint(22, 22), QPoint(197, 22),
                                   QPoint(22, 117), QPoint(197, 117)})
            expect(shot, point.x(), point.y(), background, "crop transparent corner");
        expect(shot, 100, 60, image, "crop image center");
        expect(shot, 232, 62, background, "fit transparent corner");
        expect(shot, 300, 90, image, "fit image center");
        expect(shot, 232, 22, background, "fit letterbox");
        expect(shot, 442, 22, background, "mixed rounded corner");
        expect(shot, 617, 22, image, "mixed square corner");
        auto *first = view.rootObject()->property("cropImage").value<QQuickItem *>();
        if (!first) { app.exit(2); return; }
        first->setProperty("backgroundColor", QColor("#eeeeee"));
        QTimer::singleShot(100, &app, [&, first, snapshot, expect] {
            const QImage recolored = snapshot("recolored");
            expect(recolored, 197, 117, background, "texture replacement keeps corners transparent");
            first->setProperty("radius", 0);
            QTimer::singleShot(100, &app, [&, first, snapshot, expect] {
                const QImage plain = snapshot("square");
                expect(plain, 22, 22, image, "radius reset restores square node");
                first->setProperty("source", QUrl());
                QTimer::singleShot(100, &app, [&, first, snapshot, expect] {
                    const QImage cleared = snapshot("cleared");
                    expect(cleared, 100, 60, background, "pooled image clears old pixels");
                    first->setProperty("radius", 20);
                    first->setProperty("source", QUrl("image://fixture/reloaded"));
                    QTimer::singleShot(200, &app, [&, snapshot, expect] {
                        const QImage reused = snapshot("reused");
                        expect(reused, 197, 117, background, "reused image rounds again");
                        expect(reused, 100, 60, image, "reused image reloads");
                        app.exit(passed ? 0 : 1);
                    });
                });
            });
        });
    });
    return app.exec();
}
