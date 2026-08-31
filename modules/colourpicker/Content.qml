pragma ComponentBehavior: Bound

import "ColourUtils.js" as ColourUtils
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services

StyledRect {
    id: root

    property real hue
    property real saturation
    property real value
    property real alpha: 1
    property bool inputError

    readonly property color selectedColour: Qt.hsva(hue, saturation, value, alpha)
    readonly property string hexText: ColourUtils.toHex(selectedColour)
    readonly property string rgbText: ColourUtils.toRgb(selectedColour)
    readonly property string hslText: ColourUtils.toHsl(selectedColour, hue)
    readonly property string cmykText: ColourUtils.toCmyk(selectedColour)
    readonly property string oklchText: ColourUtils.toOklch(selectedColour)

    signal screenPickRequested

    function focusInput(): void {
        colourInput.forceActiveFocus();
    }

    function syncInput(): void {
        colourInput.text = hexText;
        colourInput.selectAll();
    }

    function setFromRgba(red: real, green: real, blue: real, nextAlpha: real): void {
        const colour = Qt.rgba(red, green, blue, nextAlpha);
        if (colour.hsvHue >= 0)
            hue = colour.hsvHue;
        saturation = colour.hsvSaturation;
        value = colour.hsvValue;
        alpha = colour.a;
        inputError = false;
        Qt.callLater(syncInput);
    }

    function applyInput(): void {
        const parsed = ColourUtils.parseColour(colourInput.text);
        if (!parsed.valid) {
            inputError = true;
            return;
        }

        setFromRgba(parsed.red, parsed.green, parsed.blue, parsed.alpha);
    }

    function isCompleteHex(input: string): bool {
        return /^#?[0-9a-fA-F]{6}$/.test(input.trim());
    }

    function updateHsv(nextHue: real, nextSaturation: real, nextValue: real): void {
        hue = nextHue;
        saturation = nextSaturation;
        value = nextValue;
        inputError = false;
        Qt.callLater(syncInput);
    }

    color: Colours.tPalette.m3surfaceContainerLow
    radius: Tokens.rounding.large
    clip: true

    anchors.fill: parent

    Component.onCompleted: {
        const initial = Colours.palette.m3primary;
        setFromRgba(initial.r, initial.g, initial.b, 1);
        Qt.callLater(root.focusInput);
    }

    Item {
        id: swatch

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: 168

        layer.enabled: true
        layer.effect: Mask {
            maskSource: swatchMask
        }

        Checkerboard {
            anchors.fill: parent
        }

        StyledRect {
            anchors.fill: parent
            color: root.selectedColour
        }
    }

    Item {
        id: swatchMask

        anchors.fill: swatch
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            topLeftRadius: root.radius
            topRightRadius: root.radius
        }
    }

    Elevation {
        z: 1
        anchors.fill: colourInput
        radius: colourInput.bg.radius
        level: 3
    }

    SearchBar {
        id: colourInput

        z: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: swatch.bottom
        anchors.leftMargin: Tokens.padding.extraLarge
        anchors.rightMargin: Tokens.padding.extraLarge
        implicitHeight: 56

        placeholderText: qsTr("HEX, RGB, HSL, CMYK, or OKLCH")
        font: Tokens.font.body.large
        rightPadding: colourInput.clearIcon.width + colourInput.clearIcon.anchors.rightMargin + screenPickerButton.width + screenPickerButton.anchors.rightMargin + Tokens.spacing.medium

        bg.color: Colours.tPalette.m3surfaceContainerHigh
        bg.radius: Tokens.rounding.extraLarge
        bg.border.width: root.inputError ? 2 : 0
        bg.border.color: root.inputError ? Colours.palette.m3error : Colours.palette.m3primary

        onTextEdited: {
            root.inputError = false;
            if (root.isCompleteHex(text))
                root.applyInput();
        }
        onAccepted: root.applyInput()
        onEditingFinished: {
            if (text)
                root.applyInput();
            else
                root.syncInput();
        }

        IconButton {
            id: screenPickerButton

            z: 3
            anchors.right: colourInput.clearIcon.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Tokens.spacing.extraSmall

            icon: "colorize"
            type: IconButton.Text
            radius: Tokens.rounding.full
            radiusMorph: false
            onClicked: root.screenPickRequested()
        }
    }

    StyledText {
        id: inputErrorText

        z: 2
        anchors.top: colourInput.bottom
        anchors.left: colourInput.left
        anchors.right: colourInput.right
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.leftMargin: Tokens.padding.large
        visible: root.inputError
        text: qsTr("Enter a valid HEX, RGB(A), HSL(A), CMYK, or OKLCH colour")
        color: Colours.palette.m3error
        font: Tokens.font.label.small
    }

    VerticalFadeFlickable {
        id: flickable

        anchors.top: colourInput.bottom
        anchors.left: colourInput.left
        anchors.right: colourInput.right
        anchors.bottom: parent.bottom
        anchors.topMargin: Tokens.spacing.medium + (root.inputError ? inputErrorText.implicitHeight + Tokens.spacing.extraSmall : 0)
        anchors.bottomMargin: Tokens.padding.large
        contentWidth: width
        contentHeight: contentContainer.implicitHeight
        clip: true
        fadeAmount: 0.03

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: flickable
        }

        StyledRect {
            id: contentContainer

            width: flickable.width
            implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.extraLarge
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            ColumnLayout {
                id: layout

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.minimumWidth: 160
                        Layout.preferredWidth: 220
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Colour picker")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.large
                        }

                        StyledText {
                            Layout.fillWidth: true
                            Layout.topMargin: Tokens.spacing.small
                            text: root.hexText
                            font: Tokens.font.title.large
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.rgbText
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }
                    }

                    ColourField {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 280
                        hue: root.hue
                        saturation: root.saturation
                        value: root.value
                        selectedColour: root.selectedColour
                        onPicked: (nextSaturation, nextValue) => root.updateHsv(root.hue, nextSaturation, nextValue)
                    }
                }

                ColourSlider {
                    Layout.fillWidth: true
                    value: root.hue
                    handleColour: Qt.hsva(root.hue, 1, 1, 1)
                    onMoved: nextHue => root.updateHsv(nextHue, root.saturation, root.value)

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: "#FF0000"
                        }

                        GradientStop {
                            position: 0.1667
                            color: "#FFFF00"
                        }

                        GradientStop {
                            position: 0.3333
                            color: "#00FF00"
                        }

                        GradientStop {
                            position: 0.5
                            color: "#00FFFF"
                        }

                        GradientStop {
                            position: 0.6667
                            color: "#0000FF"
                        }

                        GradientStop {
                            position: 0.8333
                            color: "#FF00FF"
                        }

                        GradientStop {
                            position: 1
                            color: "#FF0000"
                        }
                    }
                }

                ColourSlider {
                    Layout.fillWidth: true
                    value: root.alpha
                    checkered: true
                    handleColour: root.selectedColour
                    onMoved: nextAlpha => {
                        root.alpha = nextAlpha;
                        root.inputError = false;
                        Qt.callLater(root.syncInput);
                    }

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: Qt.alpha(root.selectedColour, 0)
                        }

                        GradientStop {
                            position: 1
                            color: Qt.alpha(root.selectedColour, 1)
                        }
                    }
                }

                GridLayout {
                    id: formats

                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Tokens.spacing.medium
                    rowSpacing: Tokens.spacing.small

                    FormatCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (formats.width - formats.columnSpacing) / 2
                        formatName: qsTr("HEX")
                        formatValue: root.hexText
                    }

                    FormatCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (formats.width - formats.columnSpacing) / 2
                        formatName: root.alpha < 0.9995 ? qsTr("RGBA") : qsTr("RGB")
                        formatValue: root.rgbText
                    }

                    FormatCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (formats.width - formats.columnSpacing) / 2
                        formatName: root.alpha < 0.9995 ? qsTr("HSLA") : qsTr("HSL")
                        formatValue: root.hslText
                    }

                    FormatCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (formats.width - formats.columnSpacing) / 2
                        formatName: qsTr("CMYK")
                        formatValue: root.cmykText
                    }

                    FormatCard {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        formatName: qsTr("OKLCH")
                        formatValue: root.oklchText
                    }
                }
            }
        }
    }
}
