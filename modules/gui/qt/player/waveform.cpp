/*****************************************************************************
 * waveform.cpp: Cancellable local audio envelope analysis
 *****************************************************************************/
#include "waveform.hpp"

#include <QCoreApplication>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <algorithm>
#include <cmath>

namespace {
constexpr qint64 maxFileBytes = 1024LL * 1024LL * 1024LL;
constexpr int maxDurationSeconds = 8 * 60;
constexpr qsizetype maxJsonBytes = 64 * 1024;
constexpr int maxCacheEntries = 8;
}

Waveform::Waveform(QObject* parent) : QObject(parent) {}

Waveform::~Waveform()
{
    if (m_process) {
        m_process->kill();
        m_process->waitForFinished(100);
    }
}

void Waveform::setSource(const QUrl& source)
{
    if (m_source == source) return;
    m_source = source;
    emit sourceChanged();
    refresh();
}

void Waveform::setDurationSeconds(int seconds)
{
    if (m_durationSeconds == seconds) return;
    m_durationSeconds = seconds;
    emit durationSecondsChanged();
    refresh();
}

void Waveform::setBins(const QVariantList& bins)
{
    if (m_bins == bins) return;
    m_bins = bins;
    emit binsChanged();
    emit stateChanged();
}

void Waveform::setError(const QString& error)
{
    if (m_lastError == error) return;
    m_lastError = error;
    emit stateChanged();
}

void Waveform::stopCurrent()
{
    ++m_generation;
    if (m_process) {
        m_process->kill();
        m_process = nullptr;
    }
    if (m_busy) {
        m_busy = false;
        emit stateChanged();
    }
}

QString Waveform::helperPath()
{
#ifdef Q_OS_WIN
    return QCoreApplication::applicationDirPath() + "/vlc-waveform.exe";
#else
    return QCoreApplication::applicationDirPath() + "/vlc-waveform";
#endif
}

QVariantList Waveform::parseOutput(const QByteArray& bytes, int expectedSeconds)
{
    if (bytes.size() > maxJsonBytes) return {};
    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(bytes, &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) return {};
    const QJsonObject object = document.object();
    const double duration = object.value("durationUs").toDouble() / 1000000.0;
    if (object.value("version").toInt() != 1 || object.value("decodedFrames").toDouble() <= 0 ||
        object.value("sampleRate").toInt() != 48000 ||
        std::abs(object.value("playbackRate").toDouble() - 16.0) > 0.01 ||
        !std::isfinite(duration) || duration <= 0 ||
        std::abs(duration - expectedSeconds) > std::max(2.0, expectedSeconds * 0.03))
        return {};
    const QJsonArray values = object.value("bins").toArray();
    if (values.size() != 512) return {};
    QVariantList result;
    result.reserve(values.size());
    for (const QJsonValue& value : values) {
        if (!value.isDouble()) return {};
        const double peak = value.toDouble();
        if (!std::isfinite(peak) || peak < 0 || peak > 16) return {};
        result << peak;
    }
    return result;
}

void Waveform::refresh()
{
    stopCurrent();
    setBins({});
    setError({});

    if (!m_source.isLocalFile() || m_durationSeconds <= 0 ||
        m_durationSeconds > maxDurationSeconds) return;
    const QFileInfo file(m_source.toLocalFile());
    if (!file.isFile() || !file.isReadable() || file.size() > maxFileBytes) return;
    const QString path = file.canonicalFilePath();
    if (path.isEmpty()) return;
    const QString key = path + '|' + QString::number(file.size()) + '|' +
                        QString::number(file.lastModified().toMSecsSinceEpoch());
    for (int i = 0; i < m_cache.size(); ++i) {
        if (m_cache[i].key != key) continue;
        const CacheEntry hit = m_cache.takeAt(i);
        m_cache.prepend(hit);
        setBins(hit.bins);
        return;
    }
    const QString program = helperPath();
    if (!QFileInfo::exists(program)) {
        setError(tr("Waveform analyzer is unavailable."));
        return;
    }

    auto* process = new QProcess(this);
    m_process = process;
    const quint64 request = m_generation;
    m_busy = true;
    emit stateChanged();
    process->setProgram(program);
    process->setArguments({path});
    connect(process, &QProcess::errorOccurred, this,
            [this, process, request](QProcess::ProcessError error) {
        if (request != m_generation || error != QProcess::FailedToStart) return;
        m_process = nullptr;
        m_busy = false;
        setError(tr("Waveform analyzer could not start."));
        emit stateChanged();
        process->deleteLater();
    });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, request, key](int exitCode, QProcess::ExitStatus status) {
        process->deleteLater();
        if (request != m_generation) return;
        m_process = nullptr;
        m_busy = false;
        const QVariantList result = status == QProcess::NormalExit && exitCode == 0
            ? parseOutput(process->readAllStandardOutput(), m_durationSeconds) : QVariantList{};
        if (result.size() == 512) {
            m_cache.prepend({key, result});
            while (m_cache.size() > maxCacheEntries) m_cache.removeLast();
            setBins(result);
        } else setError(tr("Waveform analysis did not complete."));
        emit stateChanged();
    });
    process->start();
}
