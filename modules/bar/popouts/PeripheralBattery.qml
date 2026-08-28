pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Column {
    id: root

    readonly property var excluded: Config.bar.peripheralBatteryExcluded

    spacing: Tokens.spacing.small

    Repeater {
        model: ScriptModel {
            values: UPower.devices.values.filter(d => !d.isLaptopBattery && d.type !== UPowerDeviceType.LinePower && d.isPresent && !root.excluded.some(e => e === d.model || e === d.nativePath))
        }

        Row {
            id: peripheralRow

            required property UPowerDevice modelData

            spacing: Tokens.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.getBatteryIcon(peripheralRow.modelData.percentage)
                color: Colours.palette.m3onSurface
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: (peripheralRow.modelData.model || "Device") + ": " + Math.round(peripheralRow.modelData.percentage * 100) + "%"
            }
        }
    }
}
