pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("GitHub")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Configuration")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: Tr.tr("Component background")
            subtext: Tr.tr("Render a solid background behind the GitHub activity widget")
            checked: Config.bar.github.background
            onToggled: GlobalConfig.bar.github.background = checked
        }
    }
}
