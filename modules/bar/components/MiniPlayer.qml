pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

StyledRect {
    id: root

    required property var popouts

    readonly property MprisPlayer player: Players.active

    readonly property int maxLen: root.Config.bar.miniPlayer.maxTitleLength
    readonly property string rawTitle: player?.trackTitle || qsTr("Now Playing")
    readonly property string trackTitle: rawTitle.length > maxLen ? rawTitle.substring(0, maxLen) + "…" : rawTitle
    readonly property bool isPlaying: player?.isPlaying ?? false

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: contentLayout.implicitHeight + Tokens.padding.medium * 2

    color: Config.bar.miniPlayer.background ? Colours.tPalette.m3surfaceContainer : Qt.alpha(Colours.tPalette.m3surfaceContainer, 0)
    radius: Tokens.rounding.full

    ServiceRef {
        service: root.Config.bar.miniPlayer.showVisualiser ? Audio.cava : null
    }

    GridLayout {
        id: contentLayout

        anchors.centerIn: parent
        columns: 1
        rows: 2
        rowSpacing: Tokens.spacing.small
        columnSpacing: Tokens.spacing.small

        Item {
            id: textContainer

            Layout.alignment: Qt.AlignCenter
            Layout.row: 0
            Layout.column: 0

            implicitWidth: titleText.implicitHeight
            implicitHeight: titleText.implicitWidth

            StyledText {
                id: titleText

                anchors.centerIn: parent
                text: root.trackTitle
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
                animate: true

                rotation: 90
            }
        }

        Item {
            id: equalizerContainer

            Layout.alignment: Qt.AlignCenter
            Layout.row: 1
            Layout.column: 0

            visible: Config.bar.miniPlayer.showVisualiser
            implicitWidth: 20
            implicitHeight: visible ? 23 : 0

            Item {
                anchors.centerIn: parent
                width: 23
                height: 20

                rotation: 90

                Repeater {
                    model: 5

                    Rectangle {
                        id: barItem

                        required property int index

                        readonly property real cavaVal: ((Audio.cava?.values.length ?? 0) > index * 2) ? Audio.cava.values[index * 2] : 0
                        readonly property real rawHeight: root.isPlaying ? Math.max(3, Math.min(18, 3 + cavaVal * 15)) : 3

                        property real animHeight: 3

                        x: index * 5
                        width: 3
                        height: Math.round(animHeight)
                        y: Math.round((20 - height) / 2)
                        radius: 1.5
                        color: Colours.palette.m3primary

                        Binding {
                            target: barItem
                            property: "animHeight"
                            value: barItem.rawHeight
                        }

                        Behavior on animHeight {
                            NumberAnimation {
                                duration: 50
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }
        }
    }
}
