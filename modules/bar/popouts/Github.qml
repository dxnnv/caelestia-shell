pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.bar.components

Item {
    id: root

    required property var popouts

    implicitWidth: layout.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 3

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.medium

        StyledText {
            text: GithubStore.username.length > 0 ? `@${GithubStore.username}` : "GitHub"
            font.weight: 600
        }

        StyledText {
            text: GithubStore.lastError.length > 0 ? `Error: ${GithubStore.lastError}` : `Last 7 days: ${GithubStore.total} commits`
            color: GithubStore.lastError.length > 0 ? Colours.palette.m3error : Colours.palette.m3secondary
        }

        StyledRect {
            Layout.topMargin: Tokens.spacing.medium
            implicitWidth: ctaRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: ctaRow.implicitHeight + Tokens.padding.medium * 2
            color: Colours.palette.m3primaryContainer
            radius: Tokens.rounding.medium

            StateLayer {
                color: Colours.palette.m3onPrimaryContainer
                radius: parent.radius
                onClicked: {
                    root.popouts.hasCurrent = false;
                    Qt.openUrlExternally("https://github.com/" + GithubStore.username);
                }
            }

            RowLayout {
                id: ctaRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.leftMargin: Tokens.padding.small
                    text: "Open profile"
                    color: Colours.palette.m3onPrimaryContainer
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onPrimaryContainer
                    font: Tokens.font.icon.large
                }
            }
        }
    }
}
