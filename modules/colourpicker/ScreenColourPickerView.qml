pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia

MouseArea {
    id: root

    required property ShellScreen screen

    property bool sampling
    property bool captureReady

    signal picked(colour: color)
    signal cancelled
    signal failed

    function sample(x: real, y: real): void {
        if (sampling || !captureReady)
            return;

        sampling = true;
        if (typeof CUtils.sampleColour !== "function") {
            failed();
            return;
        }

        CUtils.sampleColour(screencopy, Qt.point(x, y), colour => picked(colour), () => failed());
    }

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: captureReady && !sampling ? Qt.CrossCursor : Qt.BusyCursor
    focus: true

    onClicked: event => sample(event.x, event.y)
    Keys.onEscapePressed: cancelled()

    // Keep the capture view renderable for grabToImage(), but hide the
    // Loader so the captured frame is never painted into the picker window.
    Loader {
        id: screencopy

        asynchronous: true
        anchors.fill: parent
        visible: false

        sourceComponent: ScreencopyView {
            captureSource: root.screen
            paintCursor: false

            onHasContentChanged: root.captureReady = hasContent
            onStopped: root.failed()
        }
    }

    Timer {
        interval: 5000
        running: !root.captureReady
        onTriggered: root.failed()
    }
}
