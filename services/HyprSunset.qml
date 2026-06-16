pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia

Singleton {
    id: root

    readonly property alias temperature: props.temperature
    readonly property alias active: props.active
    readonly property var sunsetCmd: ["hyprctl", "hyprsunset"]
    property bool serviceEnabled: false
    property bool serviceChecked: false
    property bool available: false
    property string pendingAction: ""

    function nightLightToast(message: string): void {
        Toaster.toast(qsTr("Night Light"), qsTr(message), "dark_mode");
    }

    function start(temp): void {
        if (temp !== undefined && temp !== null)
            props.temperature = temp;

        runAction("start");
    }

    function stop(): void {
        runAction("stop");
    }

    function toggle(temp): void {
        if (props.active)
            stop();
        else
            start(temp);
    }

    function runAction(action: string): void {
        if (!root.serviceChecked) {
            root.pendingAction = action;
            refresh();
            return;
        }

        if (!root.serviceEnabled) {
            nightLightToast("Enable hyprsunset.service to control night light");
            return;
        }

        if (!root.available) {
            root.pendingAction = action;
            startServiceProc.running = true;
            return;
        }

        actionProc.command = root.sunsetCmd.concat((action === "start" ? ["temperature", props.temperature.toString()] : ["identity"]));
        root.pendingAction = action;
        actionProc.running = true;
    }

    function refresh(): void {
        if (!serviceEnabledProc.running)
            serviceEnabledProc.running = true;
    }

    Component.onCompleted: refresh()

    PersistentProperties {
        id: props

        property int temperature: 6000
        property bool active: false

        reloadableId: "hyprSunset"
    }

    Process {
        id: serviceEnabledProc

        command: ["systemctl", "--user", "is-enabled", "--quiet", "hyprsunset.service"]
        onExited: code => { // qmllint disable signal-handler-parameters
            root.serviceChecked = true;
            root.serviceEnabled = code === 0;
            if (root.serviceEnabled) {
                socketCheckProc.running = true;
            } else {
                root.available = false;
                if (root.pendingAction) {
                    root.pendingAction = "";
                    root.nightLightToast("Enable hyprsunset.service to control night light");
                }
            }
        }
    }

    Process {
        id: socketCheckProc

        command: root.sunsetCmd.concat(["temperature"])
        onExited: code => { // qmllint disable signal-handler-parameters
            root.available = code === 0;

            if (root.available && root.pendingAction)
                root.runAction(root.pendingAction);
            else if (!root.available && root.pendingAction) {
                root.pendingAction = "";
                root.nightLightToast("Unable to connect to hyprsunset");
            }
        }
    }

    Process {
        id: startServiceProc

        command: ["systemctl", "--user", "start", "hyprsunset.service"]
        onExited: code => { // qmllint disable signal-handler-parameters
            if (code === 0) {
                socketRetryTimer.start();
            } else {
                root.pendingAction = "";
                root.nightLightToast("Unable to start hyprsunset.service");
            }
        }
    }

    Process {
        id: actionProc

        onExited: code => { // qmllint disable signal-handler-parameters
            const action = root.pendingAction;
            root.pendingAction = "";

            if (code !== 0) {
                root.available = false;
                root.nightLightToast("Unable to control hyprsunset");
                return;
            }

            props.active = action === "start";
            root.nightLightToast(props.active ? "Enabled" : "Disabled");
        }
    }

    Timer {
        id: socketRetryTimer

        interval: 500
        onTriggered: socketCheckProc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
