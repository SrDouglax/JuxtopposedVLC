/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include "mainui.hpp"
#include "dialogs/dialogs_provider.hpp"
#include "dialogs/dialogs/dialogmodel.hpp"
#include "dialogs/preferences/config_model.hpp"
#include "dialogs/preferences/audio_output_preview.hpp"
#include "dialogs/preferences/shortcuts_model.hpp"
#include "dialogs/firstrun/onboarding.hpp"
#include "dialogs/extended/audio_effects.hpp"
#include "dialogs/extended/video_effects.hpp"
#include "player/sleep_timer.hpp"
#include "player/hdr_output.hpp"

void MainUI::registerDialogTypes()
{
    {
        const char* uri = "VLC.Dialogs";
        const int versionMajor = 1;
        const int versionMinor = 0;

        // @uri VLC.Dialogs
        qmlRegisterType<VLCDialog>( uri, versionMajor, versionMinor, "VLCDialog" );
        assert(VLCDialogModel::getInstance<false>());
        qmlRegisterSingletonInstance<VLCDialogModel>(uri, versionMajor, versionMinor, "VLCDialogModel", VLCDialogModel::getInstance<false>());
        qmlRegisterUncreatableType<DialogId>( uri, versionMajor, versionMinor, "dialogId", "");
        assert(DialogsProvider::getInstance());
        qmlRegisterSingletonInstance<DialogsProvider>(uri, versionMajor, versionMinor, "DialogsProvider", DialogsProvider::getInstance());
        assert(DialogErrorModel::getInstance<false>());
        qmlRegisterSingletonInstance<DialogErrorModel>(uri, versionMajor, versionMinor, "DialogErrorModel", DialogErrorModel::getInstance<false>());

        qmlRegisterType<AudioOutputPreview>(uri, versionMajor, versionMinor, "AudioOutputPreview");
        qmlRegisterType<ConfigModel>(uri, versionMajor, versionMinor, "ConfigModel");
        qmlRegisterType<OnboardingController>(uri, versionMajor, versionMinor, "OnboardingController");
        qmlRegisterType<AudioEffects>(uri, versionMajor, versionMinor, "AudioEffects");
        qmlRegisterType<SleepTimerController>(uri, versionMajor, versionMinor, "SleepTimerController");
        qmlRegisterType<ShortcutsModel>(uri, versionMajor, versionMinor, "ShortcutsModel");
        qmlRegisterType<VideoEffects>(uri, versionMajor, versionMinor, "VideoEffects");
        qmlRegisterType<HdrOutput>(uri, versionMajor, versionMinor, "HdrOutput");
        qmlRegisterModule(uri, versionMajor, versionMinor);
        qmlProtectModule(uri, versionMajor);
    }

}
