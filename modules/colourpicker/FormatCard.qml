import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property string formatName
    required property string formatValue

    implicitHeight: 64
    color: Colours.tPalette.m3surfaceContainerHighest
    radius: Tokens.rounding.medium

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.small
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.formatName
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }

            StyledText {
                Layout.fillWidth: true
                text: root.formatValue
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }
        }

        IconTextButton {
            icon: copyTimer.running ? "check" : "content_copy"
            text: copyTimer.running ? qsTr("Copied") : qsTr("Copy")
            type: IconTextButton.Tonal
            onClicked: {
                Quickshell.clipboardText = root.formatValue;
                copyTimer.restart();
            }
        }
    }

    Timer {
        id: copyTimer

        interval: 1200
    }
}
