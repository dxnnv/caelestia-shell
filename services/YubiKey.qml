pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var reasons: []
    readonly property bool waiting: reasons.length > 0
    readonly property string socketPath: Quickshell.env("XDG_RUNTIME_DIR") + "/yubikey-touch-detector.socket"

    function update(event: string): void {
        const match = event.trim().match(/^(GPG|U2F|MAC)_([01])$/);
        if (!match)
            return;

        const reason = match[1];
        const next = reasons.slice();
        const index = next.indexOf(reason);

        if (match[2] === "1")
            next.push(reason);
        else if (match[2] === "0" && index >= 0)
            next.splice(index, 1);

        reasons = next;
    }

    Process {
        id: listener

        running: true
        command: ["bash", "-c", `
            socket="$1"
            while [[ ! -S "$socket" ]]; do sleep 1; done
            while IFS= read -r -N 5 event; do
                printf '%s\n' "$event"
            done < <(socat -u "UNIX-CONNECT:$socket" STDOUT)
        `, "yubikey-touch-listener", root.socketPath]

        stdout: SplitParser {
            onRead: data => root.update(data)
        }

        onExited: { // qmllint disable signal-handler-parameters
            root.reasons = [];
            reconnect.start();
        }
    }

    Timer {
        id: reconnect

        interval: 1000
        onTriggered: listener.running = true
    }
}
