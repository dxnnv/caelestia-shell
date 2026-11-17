pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Row {
    id: root

    readonly property var reasonLabels: ({
            GPG: Tr.tr("OpenPGP/SSH"),
            U2F: Tr.tr("FIDO2/U2F"),
            MAC: Tr.tr("HMAC")
        })
    readonly property var uniqueReasons: [...new Set(YubiKey.reasons)]

    spacing: Tokens.spacing.small

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        text: "touch_app"
        color: Colours.palette.m3tertiary
        fill: 1
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.extraSmall

        StyledText {
            text: Tr.tr("Touch your YubiKey")
            font: Tokens.font.body.medium
        }

        Repeater {
            model: root.uniqueReasons

            StyledText {
                required property string modelData

                readonly property int count: YubiKey.reasons.filter(reason => reason === modelData).length

                text: (root.reasonLabels[modelData] ?? modelData) + (count > 1 ? ` (${count})` : "")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }
        }
    }
}
