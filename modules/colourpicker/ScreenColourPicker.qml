pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components.containers
import qs.services

Singleton {
    id: root

    property bool picking
    property var pickedCallback
    property var cancelledCallback
    property var failedCallback

    function open(onPicked: var, onCancelled: var, onFailed: var): bool {
        if (picking)
            return false;

        pickedCallback = onPicked;
        cancelledCallback = onCancelled;
        failedCallback = onFailed;
        picking = true;
        return true;
    }

    function reset(): void {
        picking = false;
        pickedCallback = null;
        cancelledCallback = null;
        failedCallback = null;
    }

    function finish(callback: var): void {
        if (!picking)
            return;

        reset();
        if (callback)
            Qt.callLater(callback);
    }

    function accept(colour: color): void {
        if (!picking)
            return;

        const callback = pickedCallback;
        reset();
        if (callback)
            Qt.callLater(() => callback(colour));
    }

    function cancel(): void {
        finish(cancelledCallback);
    }

    function fail(): void {
        finish(failedCallback);
    }

    LazyLoader {
        activeAsync: root.picking

        Variants {
            model: Screens.screens

            StyledWindow {
                id: window

                required property ShellScreen modelData

                screen: modelData
                name: "screen-colour-picker"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                ScreenColourPickerView {
                    anchors.fill: parent
                    screen: window.modelData
                    onPicked: colour => root.accept(colour)
                    onCancelled: root.cancel()
                    onFailed: root.fail()
                }
            }
        }
    }
}
