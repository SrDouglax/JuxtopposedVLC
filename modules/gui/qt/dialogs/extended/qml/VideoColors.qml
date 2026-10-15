/* Copyright (C) 2026 VLC authors and VideoLAN. GPL version 2 or later. */
import QtQuick
import QtQuick.Layouts
import VLC.Player
import VLC.Style

ColumnLayout {
    id: root
    required property var effects
    spacing: VLCStyle.dp(20, VLCStyle.scale)
    function parameter(filter, key) {
        return effects.parameters(filter).find(p => p.id === key) || {id: key, type: "color", name: ""}
    }
    function enabled(filter) { effects.revision; return effects.filterEnabled(filter) }
    function toggle(filter, value) { if (effects.begin()) effects.setFilterEnabled(filter, value) }
    component ColorField: PanelField {
        id: colorField
        required property string filter
        required property string key
        controlWidth: VLCStyle.dp(200, VLCStyle.scale)
        controlHeight: VLCStyle.dp(32, VLCStyle.scale)
        RowLayout {
            anchors.fill: parent
            spacing: VLCStyle.dp(8, VLCStyle.scale)
            VideoOption {
                Layout.fillWidth: true
                effects: root.effects
                showLabel: false
                option: root.parameter(colorField.filter, colorField.key)
            }
            PanelToggle {
                checked: root.enabled(colorField.filter)
                enabled: root.effects.activeVideo && root.effects.filterAvailable(colorField.filter)
                onClicked: root.toggle(colorField.filter, checked)
            }
        }
    }
    component FilterToggle: PanelField {
        id: filterField
        required property string filter
        controlWidth: VLCStyle.dp(64, VLCStyle.scale)
        PanelToggle {
            anchors.right: parent.right
            checked: root.enabled(filterField.filter)
            enabled: root.effects.activeVideo && root.effects.filterAvailable(filterField.filter)
            onClicked: root.toggle(filterField.filter, checked)
        }
    }
    ColorField {
        Layout.fillWidth: true
        filter: "extract"
        key: "extract-component"
        label: qsTr("Color Extraction")
    }
    Rectangle { Layout.fillWidth: true; height: 1; color: VLCStyle.redesign.separator }
    ColorField {
        Layout.fillWidth: true
        filter: "colorthres"
        key: "colorthres-color"
        label: qsTr("Color Threshold")
    }
    Repeater {
        model: [{key: "colorthres-saturationthres", title: qsTr("Saturation")},
                {key: "colorthres-similaritythres", title: qsTr("Similarity")}]
        ValueSlider {
            required property var modelData
            Layout.fillWidth: true
            label: modelData.title
            property var parameter: root.parameter("colorthres", modelData.key)
            from: parameter.minimum ?? 0
            to: parameter.maximum ?? 255
            showValue: false
            enabled: root.effects.activeVideo && root.enabled("colorthres")
            modelValue: { root.effects.revision; return Number(root.effects.parameterValue(modelData.key)) || 0 }
            onEdited: value => root.effects.setParameter(modelData.key, Math.round(value))
        }
    }
    Rectangle { Layout.fillWidth: true; height: 1; color: VLCStyle.redesign.separator }
    FilterToggle { Layout.fillWidth: true; filter: "invert"; label: qsTr("Negate Colors") }
    FilterToggle { Layout.fillWidth: true; filter: "posterize"; label: qsTr("Posterize") }
    Rectangle { Layout.fillWidth: true; height: 1; color: VLCStyle.redesign.separator }
    FilterToggle { Layout.fillWidth: true; filter: "gradient"; label: qsTr("Gradient") }
    VideoOption {
        Layout.fillWidth: true
        effects: root.effects
        option: root.parameter("gradient", "gradient-mode")
        enabled: root.effects.activeVideo && root.enabled("gradient")
    }
    Repeater {
        model: [{key: "gradient-color", title: qsTr("Color")}, {key: "gradient-cartoon", title: qsTr("Cartoon")}]
        PanelField {
            required property var modelData
            Layout.fillWidth: true
            label: modelData.title
            controlWidth: VLCStyle.dp(64, VLCStyle.scale)
            PanelToggle {
                anchors.right: parent.right
                enabled: root.effects.activeVideo && root.enabled("gradient")
                checked: { root.effects.revision; return Boolean(root.effects.parameterValue(modelData.key)) }
                onClicked: root.effects.setParameter(modelData.key, checked)
            }
        }
    }
    ValueSlider {
        Layout.fillWidth: true
        label: qsTr("Sepia Intensity")
        property var parameter: root.parameter("sepia", "sepia-intensity")
        from: parameter.minimum ?? 0
        to: parameter.maximum ?? 255
        showValue: false
        enabled: root.effects.activeVideo && root.effects.filterAvailable("sepia")
        modelValue: { root.effects.revision; return Number(root.effects.parameterValue("sepia-intensity")) || 0 }
        onEdited: value => {
            if (root.effects.begin() && root.effects.setParameter("sepia-intensity", Math.round(value)))
                root.effects.setFilterEnabled("sepia", value !== 0)
        }
    }
}
