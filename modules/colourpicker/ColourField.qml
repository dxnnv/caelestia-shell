pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property real hue
    required property real saturation
    required property real value
    required property color selectedColour

    signal picked(saturation: real, value: real)

    implicitWidth: 360
    implicitHeight: 220
    radius: Tokens.rounding.extraLarge

    Item {
        anchors.fill: parent

        layer.enabled: true
        layer.effect: Mask {
            maskSource: fieldMask
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.hsva(root.hue, 1, 1, 1)
        }

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "white"
                }

                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
        }

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    position: 0
                    color: "transparent"
                }

                GradientStop {
                    position: 1
                    color: "black"
                }
            }
        }
    }

    Item {
        id: fieldMask

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: root.radius
        }
    }

    MouseArea {
        function pick(mouse: MouseEvent): void {
            root.picked(Math.max(0, Math.min(1, mouse.x / width)), 1 - Math.max(0, Math.min(1, mouse.y / height)));
        }

        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.CrossCursor

        onPressed: mouse => pick(mouse)
        onPositionChanged: mouse => {
            if (pressed)
                pick(mouse);
        }
    }

    StyledRect {
        x: Math.round(root.saturation * (root.width - width))
        y: Math.round((1 - root.value) * (root.height - height))
        implicitWidth: 24
        implicitHeight: implicitWidth
        color: "transparent"
        radius: Tokens.rounding.full
        border.width: 3
        border.color: "white"

        StyledRect {
            anchors.fill: parent
            anchors.margins: 4
            color: Qt.alpha(root.selectedColour, 1)
            radius: Tokens.rounding.full
            border.width: 1
            border.color: Colours.palette.m3shadow
        }
    }
}
