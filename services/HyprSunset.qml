pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.I18n
import qs.utils

Singleton {
    id: root

    readonly property alias temperature: props.temperature
    readonly property alias active: props.active
    property var actionQueue: Promise.resolve()

    function reportFailure(code: int): void {
        const message = code === 3 ? Tr.tr("Unable to connect to HyprSunset") : Tr.tr("Unable to control HyprSunset");
        Toaster.toast(Tr.tr("Night Light"), message, "brightness_alert");
    }

    function enqueue(action): void {
        actionQueue = actionQueue.then(action, action);
    }

    function stop(): void {
        enqueue(() => setActive(false));
    }

    function toggle(temp): void {
        enqueue(() => readIdentity(true, temp));
    }

    function readIdentity(forToggle: bool, temp): var {
        return ProcessUtil.run(["hyprctl", "hyprsunset", "identity", "get"]).then(result => {
            const reply = result.stdout.trim();

            if (result.code !== 0 || (reply !== "true" && reply !== "false")) {
                if (forToggle)
                    reportFailure(result.code);
                return;
            }

            props.active = reply === "false";
            if (forToggle)
                return setActive(!props.active, temp);
        });
    }

    function setActive(enable: bool, temp): var {
        const kelvin = temp ?? props.temperature;
        const args = enable ? ["temperature", String(kelvin)] : ["identity", "true"];

        return ProcessUtil.run(["hyprctl", "hyprsunset"].concat(args)).then(result => {
            if (result.code !== 0 || result.stdout.trim() !== "ok") {
                reportFailure(result.code);
                return;
            }

            let message, icon;
            if (enable) {
                props.temperature = kelvin;
                message = Tr.tr("Enabled");
                icon = "nightlight";
            } else {
                message = Tr.tr("Disabled");
                icon = "light";
            }

            props.active = enable;
            Toaster.toast(Tr.tr("Night Light"), message, icon);
        });
    }

    Component.onCompleted: enqueue(() => readIdentity(false))

    PersistentProperties {
        id: props

        property int temperature: 5000
        property bool active: false

        reloadableId: "hyprSunset"
    }
}
