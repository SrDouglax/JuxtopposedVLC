/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import VLC.Style

ColumnLayout {
    id: root
    required property var effects
    spacing: VLCStyle.dp(20, VLCStyle.scale)
    readonly property var fields: [
        {filter: "adjust", key: "hue", title: qsTr("Hue")},
        {filter: "adjust", key: "brightness", title: qsTr("Brightness")},
        {filter: "adjust", key: "contrast", title: qsTr("Contrast")},
        {filter: "adjust", key: "saturation", title: qsTr("Saturation")},
        {filter: "adjust", key: "gamma", title: qsTr("Gamma")},
        {filter: "sharpen", key: "sharpen-sigma", title: qsTr("Sharpen Sigma")},
        {filter: "gradfun", key: "gradfun-radius", title: qsTr("Banding Removal Radius")},
        {filter: "grain", key: "grain-variance", title: qsTr("Film Grain Variance")}
    ]
    Repeater {
        model: root.fields
        ValueSlider {
            required property var modelData
            Layout.fillWidth: true
            objectName: "videoEssential_" + modelData.key
            property var parameter: root.effects.parameters(modelData.filter).find(p => p.id === modelData.key) || {}
            label: modelData.title
            from: parameter.minimum ?? 0
            to: parameter.maximum ?? 1
            showValue: false
            modelValue: { root.effects.revision; return Number(root.effects.parameterValue(modelData.key)) || 0 }
            enabled: root.effects.activeVideo && root.effects.filterAvailable(modelData.filter)
            onEdited: number => {
                const value = parameter.type === "integer" ? Math.round(number) : number
                if (root.effects.begin() && root.effects.setParameter(modelData.key, value))
                    root.effects.setFilterEnabled(modelData.filter, true)
            }
        }
    }
}
