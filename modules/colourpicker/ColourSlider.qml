pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    required property real value

    property bool checkered
    property color handleColour: Colours.palette.m3primary
    property alias gradient: colourLayer.gradient

    signal moved(value: real)

    function moveTo(xPosition: real): void {
        const nextValue = (xPosition - track.x) / track.width;
        moved(Math.max(0, Math.min(1, nextValue)));
    }

    implicitHeight: 30

    StyledRect {
        id: track

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: handle.width / 2
        anchors.rightMargin: handle.width / 2

        implicitHeight: 20

        radius: Tokens.rounding.extraSmall
        clip: true
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        layer.enabled: true
        layer.effect: Mask {
            maskSource: trackMask
        }

        Checkerboard {
            anchors.fill: parent
            cellSize: 8
            visible: root.checkered
        }

        Rectangle {
            id: colourLayer

            anchors.fill: parent
        }
    }

    Item {
        id: trackMask

        anchors.fill: track
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: track.radius
        }
    }

    StyledRect {
        id: handle

        x: Math.round(track.x + root.value * track.width - width / 2)
        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: 16
        implicitHeight: 28
        color: "white"
        radius: Tokens.rounding.full
        border.width: 1
        border.color: Colours.palette.m3shadow

        StyledRect {
            anchors.fill: parent
            anchors.margins: 4
            color: root.handleColour
            radius: Tokens.rounding.full
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.moveTo(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.moveTo(mouse.x);
        }
    }
}
