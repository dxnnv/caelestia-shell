pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

    function refresh(): void {
        checkProc.exec(["pgrep", "-x", "hyprsunset"]);
    }

    function start(temp: int): void {
        const args = ["hyprsunset"];
        if (temp)
            args.push("-t", String(temp));
        Quickshell.execDetached(args);
        active = true;
    }

    function stop(): void {
        Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
        active = false;
    }

    function toggle(temp: int): void {
        refresh();
        Qt.callLater(() => {
            if (active)
                stop();
            else
                start(temp);
        });
    }

    Process {
        id: checkProc

        onExited: code => {
            root.active = code === 0;
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
