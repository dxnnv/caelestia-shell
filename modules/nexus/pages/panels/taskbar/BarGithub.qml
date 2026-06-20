pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("GitHub")
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
            Layout.fillWidth: true
            first: true
            text: qsTr("Component background")
            subtext: qsTr("Render a solid background behind the GitHub activity widget")
            checked: Config.bar.github.background
            onToggled: GlobalConfig.bar.github.background = checked
        }
    }
}
