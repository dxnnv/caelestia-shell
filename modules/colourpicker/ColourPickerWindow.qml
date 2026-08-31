pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.colourpicker as ColourPicker

Singleton {
    id: root

    function create(parent: Item): void {
        windowComponent.createObject(parent ?? dummy);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: windowComponent

        FloatingWindow {
            id: window

            property bool screenPicking

            function finishScreenPick(): void {
                screenPicking = false;
                Qt.callLater(content.focusInput);
            }

            function openScreenPicker(): void {
                const opened = ColourPicker.ScreenColourPicker.open(colour => {
                    content.setFromRgba(colour.r, colour.g, colour.b, 1);
                    window.finishScreenPick();
                }, () => window.finishScreenPick(), () => {
                    window.finishScreenPick();
                    Toaster.toast(qsTr("Colour picker"), qsTr("Unable to capture a colour from the screen"), "colorize", Toast.Error);
                });

                if (!opened)
                    finishScreenPick();
            }

            function startScreenPick(): void {
                if (screenPicking)
                    return;

                screenPicking = true;
                openDelay.restart();
            }

            implicitWidth: 850
            implicitHeight: 800
            minimumSize.width: 560
            minimumSize.height: 630
            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false
            title: qsTr("Colour picker")

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            onVisibleChanged: {
                if (!visible && !screenPicking)
                    destroy();
            }

            Content {
                id: content

                anchors.fill: parent
                onScreenPickRequested: window.startScreenPick()
            }

            Timer {
                id: openDelay

                interval: 50
                onTriggered: window.openScreenPicker()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
