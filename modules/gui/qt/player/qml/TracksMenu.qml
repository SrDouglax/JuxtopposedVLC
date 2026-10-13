/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.Dialogs
import VLC.MainInterface
import VLC.Player
import VLC.Style

T.Popup {
    id: root
    objectName: "tracksMenu"

    property int currentTab: 0
    property bool previousGlobalShortcuts: true
    readonly property var trackTabs: [
        { title: qsTr("Video"), icon: "qrc:///redesign/track-video.png", activeIcon: "qrc:///redesign/track-video-active.png", tab: 2 },
        { title: qsTr("Audio"), icon: "qrc:///redesign/track-audio.png", activeIcon: "qrc:///redesign/track-audio-active.png", tab: 1 },
        { title: qsTr("Subtitles"), icon: "qrc:///redesign/track-subtitles.png", activeIcon: "qrc:///redesign/track-subtitles-active.png", tab: 0 }
    ]

    function ensureVisible(item) {
        const top = item.mapToItem(scroll, 0, 0).y
        if (top < 0)
            scroll.contentY = Math.max(0, scroll.contentY + top)
        else if (top + item.height > scroll.height)
            scroll.contentY = Math.min(Math.max(0, scroll.contentHeight - scroll.height),
                                       scroll.contentY + top + item.height - scroll.height)
    }

    width: Math.min(VLCStyle.dp(400, VLCStyle.scale), parent ? parent.width : VLCStyle.dp(400, VLCStyle.scale))
    height: Math.min(VLCStyle.dp(500, VLCStyle.scale), parent ? Math.max(0, parent.height - VLCStyle.dp(48, VLCStyle.scale)) : VLCStyle.dp(500, VLCStyle.scale))
    padding: 0
    focus: true
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside

    onOpened: {
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
        tabs.itemAt(currentTab === 3 ? 0 : 2 - currentTab).forceActiveFocus()
    }
    onClosed: MainCtx.useGlobalShortcuts = previousGlobalShortcuts

    background: Rectangle {
        color: VLCStyle.redesign.windowBackground
        radius: VLCStyle.dp(6, VLCStyle.scale)
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                id: tabs
                model: root.trackTabs
                delegate: T.Button {
                    objectName: "tracksTab" + modelData.tab
                    Layout.fillWidth: true
                    implicitHeight: VLCStyle.dp(58, VLCStyle.scale)
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: modelData.title
                    onClicked: root.currentTab = modelData.tab
                    background: Rectangle {
                        color: parent.hovered ? "#151515" : "transparent"
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - VLCStyle.dp(24, VLCStyle.scale)
                            height: VLCStyle.dp(2, VLCStyle.scale)
                            color: root.currentTab === modelData.tab ? VLCStyle.redesign.accent : "transparent"
                        }
                    }
                    contentItem: RowLayout {
                        spacing: VLCStyle.dp(8, VLCStyle.scale)
                        Item { Layout.fillWidth: true }
                        Image {
                            source: root.currentTab === modelData.tab ? modelData.activeIcon : modelData.icon
                            visible: root.width >= VLCStyle.dp(320, VLCStyle.scale)
                            sourceSize.width: VLCStyle.dp(24, VLCStyle.scale)
                            sourceSize.height: VLCStyle.dp(24, VLCStyle.scale)
                            Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)
                        }
                        Text {
                            text: modelData.title
                            color: root.currentTab === modelData.tab ? VLCStyle.redesign.accent : VLCStyle.redesign.textMuted
                            font.family: VLCStyle.redesign.fontFamily
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: VLCStyle.dp(1, VLCStyle.scale)
            color: VLCStyle.redesign.separator
        }

        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
            clip: true
            contentHeight: page.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: page
                width: scroll.width
                spacing: VLCStyle.dp(12, VLCStyle.scale)

                ColumnLayout {
                    visible: root.currentTab === 0
                    Layout.fillWidth: true
                    spacing: VLCStyle.dp(8, VLCStyle.scale)

                    SectionTitle { text: qsTr("Embedded tracks") }
                    TrackRow {
                        objectName: "subtitleOffButton"
                        Layout.fillWidth: true
                        text: qsTr("Off")
                        checked: {
                            for (let i = 0; i < subtitleRows.count; ++i) {
                                const row = subtitleRows.itemAt(i)
                                if (row && row.checked)
                                    return false
                            }
                            return true
                        }
                        onClicked: {
                            for (let i = 0; i < subtitleRows.count; ++i) {
                                const row = subtitleRows.itemAt(i)
                                if (row && row.checked)
                                    row.disable()
                            }
                        }
                    }
                    EmptyLabel {
                        visible: Player.subtitleTracks.count === 0
                        text: qsTr("No subtitle tracks in this media")
                    }
                    Repeater {
                        id: subtitleRows
                        model: Player.subtitleTracks
                        delegate: TrackChoice {
                            objectName: "subtitleTrack" + index
                            Layout.fillWidth: true
                            allowOff: true
                        }
                    }
                    SectionDivider { }
                    PanelButton {
                        objectName: "addSubtitleButton"
                        Layout.fillWidth: true
                        text: qsTr("Add subtitle file…")
                        onClicked: DialogsProvider.loadSubtitlesFile()
                    }
                    DelayControl {
                        objectName: "subtitleDelayControl"
                        Layout.fillWidth: true
                        title: qsTr("Subtitle delay")
                        value: Player.subtitleDelayMS
                        onRequested: (ms) => Player.subtitleDelayMS = ms
                    }
                }

                ColumnLayout {
                    visible: root.currentTab === 1
                    Layout.fillWidth: true
                    spacing: VLCStyle.dp(8, VLCStyle.scale)

                    SectionTitle { text: qsTr("Embedded tracks") }
                    TrackRow {
                        objectName: "audioOffButton"
                        Layout.fillWidth: true
                        text: qsTr("None")
                        checked: {
                            for (let i = 0; i < audioRows.count; ++i) {
                                const row = audioRows.itemAt(i)
                                if (row && row.checked)
                                    return false
                            }
                            return true
                        }
                        onClicked: {
                            for (let i = 0; i < audioRows.count; ++i) {
                                const row = audioRows.itemAt(i)
                                if (row && row.checked)
                                    row.disable()
                            }
                        }
                    }
                    EmptyLabel {
                        visible: Player.audioTracks.count === 0
                        text: qsTr("No audio tracks in this media")
                    }
                    Repeater {
                        id: audioRows
                        model: Player.audioTracks
                        delegate: TrackChoice {
                            objectName: "audioTrack" + index
                            Layout.fillWidth: true
                            allowOff: true
                        }
                    }
                    SectionDivider { }
                    SectionTitle { text: qsTr("Output device") }
                    EmptyLabel {
                        visible: outputRows.count === 0
                        text: qsTr("No output device available")
                    }
                    Repeater {
                        id: outputRows
                        model: Player.audioDevices
                        delegate: TrackChoice {
                            objectName: "outputDevice" + index
                            Layout.fillWidth: true
                        }
                    }
                    SectionDivider { }
                    DelayControl {
                        objectName: "audioDelayControl"
                        Layout.fillWidth: true
                        title: qsTr("Audio delay")
                        value: Player.audioDelayMS
                        onRequested: (ms) => Player.audioDelayMS = ms
                    }
                }

                ColumnLayout {
                    visible: root.currentTab === 2
                    Layout.fillWidth: true
                    spacing: VLCStyle.dp(8, VLCStyle.scale)

                    SectionTitle { text: qsTr("Embedded tracks") }
                    EmptyLabel {
                        visible: Player.videoTracks.count === 0
                        text: qsTr("No video tracks in this media")
                    }
                    Repeater {
                        model: Player.videoTracks
                        delegate: TrackChoice {
                            objectName: "videoTrack" + index
                            Layout.fillWidth: true
                        }
                    }
                }

                ColumnLayout {
                    visible: root.currentTab === 3
                    Layout.fillWidth: true
                    spacing: VLCStyle.dp(8, VLCStyle.scale)

                    SectionTitle { text: qsTr("Playback speed") }
                    EmptyLabel { text: qsTr("Current: %1×").arg(Number(Player.rate).toFixed(2)) }
                    Flow {
                        Layout.fillWidth: true
                        spacing: VLCStyle.dp(6, VLCStyle.scale)
                        Repeater {
                            model: [0.5, 0.75, 1, 1.25, 1.5, 2]
                            delegate: PanelButton {
                                objectName: "speed" + modelData
                                text: modelData + "×"
                                enabled: Player.ratechangable
                                checked: Math.abs(Player.rate - modelData) < 0.01
                                onClicked: Player.rate = modelData
                            }
                        }
                    }
                    EmptyLabel {
                        visible: !Player.ratechangable
                        text: qsTr("Speed cannot be changed for this media")
                    }
                    SectionTitle { text: qsTr("Chapters") }
                    EmptyLabel {
                        visible: Player.chapters.count === 0
                        text: qsTr("No chapters in this media")
                    }
                    Repeater {
                        model: Player.chapters
                        delegate: PanelButton {
                            objectName: "chapter" + index
                            Layout.fillWidth: true
                            text: model.display
                            checked: model.checked
                            onClicked: Player.chapters.selectChapter(index)
                        }
                    }
                    SectionTitle { text: qsTr("Bookmarks") }
                    PanelButton {
                        objectName: "manageBookmarksButton"
                        Layout.fillWidth: true
                        text: qsTr("Manage bookmarks…")
                        enabled: MainCtx.mediaLibraryAvailable
                        onClicked: DialogsProvider.bookmarksDialog()
                    }
                    EmptyLabel {
                        visible: !MainCtx.mediaLibraryAvailable
                        text: qsTr("Bookmarks require the media library")
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: VLCStyle.dp(1, VLCStyle.scale)
            color: VLCStyle.redesign.separator
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(8, VLCStyle.scale)
            spacing: VLCStyle.dp(8, VLCStyle.scale)

            FooterButton {
                objectName: "playbackFooterButton"
                text: qsTr("Playback")
                selected: root.currentTab === 3
                onClicked: root.currentTab = 3
            }
            Item { Layout.fillWidth: true }
            FooterButton {
                objectName: "showPreferencesButton"
                text: qsTr("Show Preferences")
                onClicked: DialogsProvider.prefsDialog()
            }
        }
    }

    component FooterButton: T.Button {
        implicitWidth: implicitContentWidth
        property bool selected: false
        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
        focusPolicy: Qt.StrongFocus
        background: Rectangle {
            color: parent.hovered || parent.activeFocus ? "#151515" : "transparent"
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }
        contentItem: Text {
            text: parent.text
            color: parent.selected ? VLCStyle.redesign.accent : VLCStyle.redesign.textMuted
            verticalAlignment: Text.AlignVCenter
            leftPadding: VLCStyle.dp(8, VLCStyle.scale)
            rightPadding: VLCStyle.dp(8, VLCStyle.scale)
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
        }
    }

    component PanelButton: T.Button {
        implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
        implicitWidth: VLCStyle.dp(62, VLCStyle.scale)
        focusPolicy: Qt.StrongFocus
        onActiveFocusChanged: if (activeFocus) root.ensureVisible(this)
        background: Rectangle {
            color: parent.checked ? VLCStyle.redesign.accentBackground
                 : parent.hovered || parent.activeFocus ? VLCStyle.redesign.controlHoverBackground : "transparent"
            border.width: VLCStyle.dp(1, VLCStyle.scale)
            border.color: parent.activeFocus ? VLCStyle.redesign.focusColor : VLCStyle.redesign.border
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }
        contentItem: Text {
            text: parent.text
            color: parent.checked ? VLCStyle.redesign.accent : VLCStyle.redesign.textPrimary
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        }
    }

    component SectionTitle: Text {
        color: "#6B6B6B"
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
    }

    component SectionDivider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: VLCStyle.dp(1, VLCStyle.scale)
        color: VLCStyle.redesign.separator
    }

    component EmptyLabel: Text {
        Layout.fillWidth: true
        color: VLCStyle.redesign.textMuted
        wrapMode: Text.WordWrap
        font.family: VLCStyle.redesign.fontFamily
        font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
    }

    component TrackRow: T.Button {
        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)
        focusPolicy: Qt.StrongFocus
        onActiveFocusChanged: if (activeFocus) root.ensureVisible(this)
        background: Rectangle {
            color: parent.hovered || parent.activeFocus ? "#151515" : "transparent"
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }
        contentItem: Item {
            Image {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:///redesign/track-check-active.png"
                visible: parent.parent.checked
                width: VLCStyle.dp(24, VLCStyle.scale)
                height: width
            }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(40, VLCStyle.scale)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.text
                color: VLCStyle.redesign.textSecondary
                elide: Text.ElideRight
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            }
        }
    }

    component TrackChoice: TrackRow {
        property bool allowOff: false
        function disable() { model.checked = false }

        text: model.display
        checked: model.checked
        onClicked: model.checked = allowOff ? !model.checked : true
    }

    component DelayControl: ColumnLayout {
        property string title
        property int value
        signal requested(int ms)
        spacing: VLCStyle.dp(4, VLCStyle.scale)

        Text {
            text: title
            color: VLCStyle.redesign.textPrimary
            Layout.fillWidth: true
            font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
        }
        Flow {
            Layout.fillWidth: true
            spacing: VLCStyle.dp(4, VLCStyle.scale)
            PanelButton {
                text: "−50"
                onClicked: requested(Math.max(-10000, value - 50))
            }
            Text {
                text: value + " ms"
                color: VLCStyle.redesign.textMuted
                width: VLCStyle.dp(64, VLCStyle.scale)
                height: VLCStyle.dp(34, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
            }
            PanelButton {
                text: "+50"
                onClicked: requested(Math.min(10000, value + 50))
            }
            PanelButton {
                text: qsTr("Reset")
                onClicked: requested(0)
            }
        }
    }
}
