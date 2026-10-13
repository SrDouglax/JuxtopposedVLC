import QtQuick
import QtQuick.Controls.Basic as Controls

import VLC.MainInterface
import VLC.Style

Controls.Popup {
    id: root
    focus: true
    property bool previousGlobalShortcuts: true
    onOpened: {
        previousGlobalShortcuts = MainCtx.useGlobalShortcuts
        MainCtx.useGlobalShortcuts = false
    }
    onClosed: MainCtx.useGlobalShortcuts = previousGlobalShortcuts
    objectName: "sleepTimerMenu"
    required property var timerController
    property int selectedAction: 0

    width: 300
    height: timerController.active ? 190 : 293
    padding: 16
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside

    function formatRemaining(seconds) {
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)
        const rest = seconds % 60
        const two = value => value < 10 ? "0" + value : String(value)
        return hours > 0 ? hours + ":" + two(minutes) + ":" + two(rest)
                         : two(minutes) + ":" + two(rest)
    }

    background: Rectangle {
        color: "#1b1b1b"
        radius: 11
        border.color: "#303030"
    }

    contentItem: Column {
        spacing: 12

        Text {
            text: qsTr("Sleep timer")
            color: "#eaeaea"
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        Text {
            visible: root.timerController.active
            text: qsTr("Remaining: %1").arg(root.formatRemaining(root.timerController.remainingSeconds))
            color: "#c6c6c6"
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: 16
        }

        Text {
            visible: !root.timerController.active
            text: qsTr("After")
            color: "#969696"
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: 14
        }

        Row {
            visible: !root.timerController.active
            spacing: 8
            Controls.SpinBox {
                id: durationInput
                palette.text: "#eaeaea"
                palette.base: "#101010"
                palette.button: "#202020"
                palette.buttonText: "#969696"
                objectName: "sleepTimerMinutes"
                from: 1
                to: 720
                value: 30
                editable: true
                width: 110
                Accessible.name: qsTr("Minutes until sleep timer")
                background: Rectangle {
                    color: "#101010"
                    border.color: "#383838"
                    radius: 6
                }
                contentItem: TextInput {
                    z: 2
                    text: durationInput.textFromValue(durationInput.value, durationInput.locale)
                    font.family: VLCStyle.redesign.fontFamily
                    font.pixelSize: 15
                    color: "#eaeaea"
                    selectionColor: VLCStyle.redesign.accent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    readOnly: !durationInput.editable
                    validator: durationInput.validator
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }
            }
            Text {
                height: durationInput.height
                text: qsTr("minutes")
                color: "#969696"
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
            }
        }

        Row {
            visible: !root.timerController.active
            width: parent.width
            spacing: 8
            Repeater {
                model: [qsTr("Stop playback"), qsTr("Pause playback")]
                delegate: Controls.Button {
                    required property int index
                    required property string modelData
                    objectName: index === 0 ? "sleepTimerStopAction" : "sleepTimerPauseAction"
                    width: (root.width - root.leftPadding - root.rightPadding - 8) / 2
                    height: 34
                    text: modelData
                    Accessible.name: text
                    onClicked: root.selectedAction = index
                    background: Rectangle {
                        color: root.selectedAction === index ? "#343434" : "#121212"
                        border.color: root.selectedAction === index ? VLCStyle.redesign.accent : "#383838"
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#c6c6c6"
                        font.family: VLCStyle.redesign.fontFamily
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.timerController.error !== ""
            text: root.timerController.error
            color: "#e57373"
            wrapMode: Text.WordWrap
            font.family: VLCStyle.redesign.fontFamily
            font.pixelSize: 13
        }

        Controls.Button {
            objectName: root.timerController.active ? "cancelSleepTimer" : "startSleepTimer"
            width: parent.width
            height: 34
            text: root.timerController.active ? qsTr("Cancel timer") : qsTr("Start timer")
            Accessible.name: text
            onClicked: {
                if (root.timerController.active)
                    root.timerController.cancel()
                else
                    root.timerController.start(durationInput.value * 60, root.selectedAction)
            }
            background: Rectangle {
                radius: 6
                color: VLCStyle.redesign.accent
            }
            contentItem: Text {
                text: parent.text
                color: "#161616"
                font.family: VLCStyle.redesign.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
