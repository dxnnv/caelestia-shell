pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n

Singleton {
    id: root

    property int temperature: 6000
    readonly property bool active: hyprSunsetProcess.running

    Process {
        id: hyprSunsetProcess
        command: ["hyprsunset", "--temperature", root.temperature.toString()]
        running: false
    }

    function start(temp): void {
        if (temp !== undefined && temp !== null)
            root.temperature = temp;

        hyprSunsetProcess.running = true;
    }

    function stop(): void {
        hyprSunsetProcess.running = false;
    }

    function toggle(temp): void {
        let toggled = "";
        if (hyprSunsetProcess.running) {
            stop();
            toggled = "Disabled";
        } else {
            start(temp);
            toggled = "Enabled";
        }

        Toaster.toast(Tr.tr("Night Light"), Tr.tr(toggled), "dark_mode");
    }

    Component.onDestruction: {
        stop();
    }
}
