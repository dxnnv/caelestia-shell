pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.components.controls
import qs.modules.bar.components

ColumnLayout {
    id: root

    required property var popouts

    width: 300
    spacing: Tokens.spacing.small

    StyledText {
        Layout.topMargin: Tokens.padding.medium
        Layout.leftMargin: Tokens.padding.small
        text: Tr.tr("GitHub")
        font: Tokens.font.title.builders.small.weight(500).build()
    }

    StyledRect {
        Layout.fillWidth: true
        implicitWidth: cardLayout.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: cardLayout.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        ColumnLayout {
            id: cardLayout

            width: parent.width - Tokens.padding.medium * 2
            x: Tokens.padding.medium
            y: Tokens.padding.medium
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "person"
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: GithubStore.username.length > 0 ? `@${GithubStore.username}` : Tr.tr("Not authenticated")
                    color: Colours.palette.m3onSurface
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small
                visible: GithubStore.available

                MaterialIcon {
                    text: "history"
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Last 7 days")
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    text: Tr.tr("%1 commits").arg(GithubStore.total)
                    font.weight: 600
                    color: Colours.palette.m3onSurface
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small
                visible: !GithubStore.available

                MaterialIcon {
                    text: "error"
                    color: Colours.palette.m3error
                }

                StyledText {
                    Layout.fillWidth: true
                    text: GithubStore.lastError
                    color: Colours.palette.m3error
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    IconTextButton {
        Layout.fillWidth: true
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer
        verticalPadding: Tokens.padding.small
        text: Tr.tr("Open profile")
        icon: "open_in_new"

        onClicked: {
            root.popouts.hasCurrent = false;
            Qt.openUrlExternally("https://github.com/" + GithubStore.username);
        }
    }
}
