pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Mini player")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Configuration")
        }

        ToggleRow {
            first: true
            text: qsTr("Background")
            subtext: qsTr("Render a solid background behind the mini player widget")
            checked: Config.bar.miniPlayer.background
            onToggled: GlobalConfig.bar.miniPlayer.background = checked
        }

        ToggleRow {
            text: qsTr("Show visualiser")
            subtext: qsTr("Display animated frequency visualiser bars")
            checked: Config.bar.miniPlayer.showVisualiser
            onToggled: GlobalConfig.bar.miniPlayer.showVisualiser = checked
        }

        StepperRow {
            label: qsTr("Max title length")
            subtext: qsTr("Cut off character count for track title")
            value: Config.bar.miniPlayer.maxTitleLength
            from: 5
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.bar.miniPlayer.maxTitleLength = v
        }

        ToggleRow {
            text: qsTr("Auto-hide")
            subtext: qsTr("Hide the widget when there is no media source available")
            checked: Config.bar.miniPlayer.autoHide
            onToggled: GlobalConfig.bar.miniPlayer.autoHide = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Horizontal volume slider")
            subtext: qsTr("Place a horizontal volume slider below the playback controls in the popout")
            checked: Config.bar.miniPlayer.horizontalVolume
            onToggled: GlobalConfig.bar.miniPlayer.horizontalVolume = checked
        }
    }
}
