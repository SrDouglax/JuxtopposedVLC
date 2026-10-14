/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include "hdr_output.hpp"
#include "maininterface/mainctx.hpp"
#include "qt.hpp"
#include <vlc_configuration.h>
#include <vlc_plugin.h>
#include <cstdlib>
#include <QSet>
HdrOutput::HdrOutput(QObject* parent) : QObject(parent)
{
    QSet<int> nativeValues;
    if (config_FindConfig("pl-output-hint")) {
        int64_t* values = nullptr;
        char** labels = nullptr;
        const ssize_t count = config_GetIntChoices("pl-output-hint", &values, &labels);
        for (ssize_t i = 0; i < count; ++i) { nativeValues.insert(values[i]); free(labels[i]); }
        free(values); free(labels);
    }
    m_available = !nativeValues.isEmpty();
    const QStringList labels = {tr("Auto"), tr("Off"), QStringLiteral("HDR10"), QStringLiteral("HDR10+"), QStringLiteral("Dolby Vision"), QStringLiteral("HLG")};
    // Only output modes actually implemented by the libplacebo module have a value.
    const int values[] = {0, 1, 2, -1, -1, 3};
    for (int i = 0; i < labels.size(); ++i) {
        const bool enabled = nativeValues.contains(values[i]);
        m_choices.append(QVariantMap{{QStringLiteral("label"), labels[i]}, {QStringLiteral("value"), values[i]}, {QStringLiteral("enabled"), enabled},
            {QStringLiteral("reason"), enabled ? QString() : (m_available
                ? tr("This renderer does not expose this output format.")
                : tr("The libplacebo HDR renderer is not installed in this build."))}});
    }
    m_message = m_available ? tr("Uses libplacebo on next playback. HDR requires a compatible display and driver.")
                            : tr("HDR output is unavailable with the installed video renderer.");
}
void HdrOutput::setCtx(MainCtx* ctx) { if (m_ctx != ctx) { m_ctx = ctx; emit changed(); } }
MainCtx* HdrOutput::ctx() const { return m_ctx; }
int HdrOutput::selectedIndex() const
{
    if (!m_available) return -1;
    const int current = config_GetInt("pl-output-hint");
    for (int i = 0; i < m_choices.size(); ++i)
        if (m_choices[i].toMap().value(QStringLiteral("value")).toInt() == current) return i;
    return -1;
}
bool HdrOutput::select(int index)
{
    if (!m_ctx || !m_ctx->getIntf() || index < 0 || index >= m_choices.size()
        || !m_choices[index].toMap().value(QStringLiteral("enabled")).toBool()) return false;
    const int before = config_GetInt("pl-output-hint");
    char* previousOutput = config_GetPsz("vout");
    config_PutInt("pl-output-hint", m_choices[index].toMap().value(QStringLiteral("value")).toInt());
    config_PutPsz("vout", "libplacebo");
    const bool saved = config_SaveConfigFile(m_ctx->getIntf()) == 0;
    if (!saved) {
        config_PutInt("pl-output-hint", before);
        config_PutPsz("vout", previousOutput);
    }
    free(previousOutput);
    m_message = saved ? tr("HDR output saved. Restart playback to use it.") : tr("Could not save HDR output. Your previous setting was kept.");
    emit changed();
    return saved;
}
