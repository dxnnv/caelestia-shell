pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property color colour
    readonly property var excluded: Config.bar.peripheralBatteryExcluded

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    ColumnLayout {
        id: layout

        spacing: Tokens.spacing.medium / 2

        Repeater {
            model: ScriptModel {
                values: UPower.devices.values.filter(d => d.isPresent && !d.isLaptopBattery && d.type !== UPowerDeviceType.LinePower && !root.excluded.some(e => e === d.model || e === d.nativePath)) // qmllint disable unresolved-type
            }

            MaterialIcon {
                required property UPowerDevice modelData

                animate: true
                text: {
                    switch (modelData.type) {
                    case UPowerDeviceType.Mouse:
                    case UPowerDeviceType.Touchpad:
                        return "mouse";
                    case UPowerDeviceType.Keyboard:
                        return "keyboard";
                    case UPowerDeviceType.Headset:
                    case UPowerDeviceType.Headphones:
                        return "headphones";
                    case UPowerDeviceType.GamingInput:
                        return "sports_esports";
                    case UPowerDeviceType.Pen:
                        return "stylus";
                    case UPowerDeviceType.Speakers:
                    case UPowerDeviceType.OtherAudio:
                        return "speaker";
                    case UPowerDeviceType.Phone:
                        return "smartphone";
                    default:
                        return "settings_remote";
                    }
                }
                color: modelData.percentage > 0.2 ? root.colour : Colours.palette.m3error
                fill: 1
            }
        }
    }
}
