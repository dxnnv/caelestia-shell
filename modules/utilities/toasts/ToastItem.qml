import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property Toast modelData

    // Bare names remain Material icons for compatibility.
    // Prefix an icon theme name with "theme:" (for example, "theme:dialog-warning-symbolic").
    // "material:" is accepted as an explicit form for material icons as well.
    readonly property bool usesThemeIcon: modelData.icon.startsWith("theme:")
    readonly property string iconName: modelData.icon.startsWith("theme:") || modelData.icon.startsWith("material:") ? modelData.icon.slice(modelData.icon.indexOf(":") + 1) : modelData.icon
    readonly property color iconColour: {
        if (modelData.type === Toast.Success)
            return Colours.palette.m3onSuccess;
        if (modelData.type === Toast.Warning)
            return Colours.palette.m3onSecondaryContainer;
        if (modelData.type === Toast.Error)
            return Colours.palette.m3onError;
        return Colours.palette.m3onSurfaceVariant;
    }

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight + Tokens.padding.large

    radius: Tokens.rounding.large
    color: {
        if (root.modelData.type === Toast.Success)
            return Colours.palette.m3successContainer;
        if (root.modelData.type === Toast.Warning)
            return Colours.palette.m3secondary;
        if (root.modelData.type === Toast.Error)
            return Colours.palette.m3errorContainer;
        return Colours.palette.m3surface;
    }

    border.width: 1
    border.color: {
        let colour = Colours.palette.m3outlineVariant;
        if (root.modelData.type === Toast.Success)
            colour = Colours.palette.m3success;
        if (root.modelData.type === Toast.Warning)
            colour = Colours.palette.m3secondaryContainer;
        if (root.modelData.type === Toast.Error)
            colour = Colours.palette.m3error;
        return Qt.alpha(colour, 0.3);
    }

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 3
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        StyledRect {
            radius: Tokens.rounding.large
            color: {
                if (root.modelData.type === Toast.Success)
                    return Colours.palette.m3success;
                if (root.modelData.type === Toast.Warning)
                    return Colours.palette.m3secondaryContainer;
                if (root.modelData.type === Toast.Error)
                    return Colours.palette.m3error;
                return Colours.palette.m3surfaceContainerHigh;
            }

            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.large

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: root.iconName
                color: root.iconColour
                fontStyle: Tokens.font.icon.builders.large.scale(1.2).build()
                visible: !root.usesThemeIcon
            }

            ColouredIcon {
                anchors.centerIn: parent
                implicitSize: icon.implicitHeight
                source: root.usesThemeIcon ? Quickshell.iconPath(root.iconName, "image-missing") : ""
                colour: root.iconColour
                layer.enabled: root.iconName.endsWith("-symbolic")
                visible: root.usesThemeIcon
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: title

                Layout.fillWidth: true
                text: root.modelData.title
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.m3onSuccessContainer;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.m3onSecondary;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.m3onErrorContainer;
                    return Colours.palette.m3onSurface;
                }
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: root.modelData.message
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.m3onSuccessContainer;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.m3onSecondary;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.m3onErrorContainer;
                    return Colours.palette.m3onSurface;
                }
                opacity: 0.8
                elide: Text.ElideRight
            }
        }
    }

    Behavior on border.color {
        CAnim {}
    }
}
