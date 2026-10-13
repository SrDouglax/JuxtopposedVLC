/*****************************************************************************
 * waveform.hpp: Local audio envelope request for the Qt Quick player
 *****************************************************************************/
#ifndef VLC_QT_WAVEFORM_HPP_
#define VLC_QT_WAVEFORM_HPP_

#include <QObject>
#include <QPointer>
#include <QProcess>
#include <QUrl>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class Waveform : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged FINAL)
    Q_PROPERTY(int durationSeconds READ durationSeconds WRITE setDurationSeconds NOTIFY durationSecondsChanged FINAL)
    Q_PROPERTY(QVariantList bins READ bins NOTIFY binsChanged FINAL)
    Q_PROPERTY(bool ready READ ready NOTIFY stateChanged FINAL)
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged FINAL)
    Q_PROPERTY(QString lastError READ lastError NOTIFY stateChanged FINAL)

public:
    explicit Waveform(QObject* parent = nullptr);
    ~Waveform() override;

    QUrl source() const { return m_source; }
    void setSource(const QUrl& source);
    int durationSeconds() const { return m_durationSeconds; }
    void setDurationSeconds(int seconds);
    QVariantList bins() const { return m_bins; }
    bool ready() const { return m_bins.size() == 512; }
    bool busy() const { return m_busy; }
    QString lastError() const { return m_lastError; }

signals:
    void sourceChanged();
    void durationSecondsChanged();
    void binsChanged();
    void stateChanged();

private:
    struct CacheEntry { QString key; QVariantList bins; };
    void refresh();
    void stopCurrent();
    void setBins(const QVariantList& bins);
    void setError(const QString& error);
    static QString helperPath();
    static QVariantList parseOutput(const QByteArray& bytes, int expectedSeconds);

    QUrl m_source;
    int m_durationSeconds = 0;
    QVariantList m_bins;
    bool m_busy = false;
    QString m_lastError;
    QPointer<QProcess> m_process;
    QList<CacheEntry> m_cache;
    quint64 m_generation = 0;
};

#endif
