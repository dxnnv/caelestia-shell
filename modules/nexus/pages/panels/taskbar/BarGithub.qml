pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property bool tokenInputEdited: false

    property Process readTokenProc: Process {
        id: readTokenProc

        command: ["secret-tool", "lookup", "service", "caelestia-shell", "account", "github"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.tokenInputEdited)
                    tokenInput.text = text.trim();
            }
        }
    }

    function saveToken(token) {
        if (!token) {
            Quickshell.execDetached(["secret-tool", "clear", "service", "caelestia-shell", "account", "github"]);
        } else {
            Quickshell.execDetached(["bash", "-c", "secret-tool store --label=\"Caelestia GitHub Token\" service caelestia-shell account github <<< \"$1\"", "--", token]);
        }
    }

    title: qsTr("GitHub")
    isSubPage: true

    Component.onCompleted: readTokenProc.running = true

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

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: contentRow.implicitHeight + Tokens.padding.medium * 2

            ConnectedRect {
                id: bg

                anchors.fill: parent
                last: true
            }

            RowLayout {
                id: contentRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                Column {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: qsTr("Personal Access Token")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: qsTr("Used to fetch your contribution graph (read:user)")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                        elide: Text.ElideRight
                    }
                }

                StyledTextField {
                    id: tokenInput

                    Layout.preferredWidth: 200
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "ghp_..."
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    onTextEdited: root.tokenInputEdited = true
                    onAccepted: root.saveToken(text)
                }

                IconButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    icon: "save"
                    onClicked: root.saveToken(tokenInput.text)
                }

                IconButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    icon: "close"
                    onClicked: {
                        tokenInput.text = "";
                        root.saveToken("");
                    }
                }
            }
        }
    }
}
