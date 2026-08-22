pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit 0.1
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

StyledWindow {
    id: root

    Tokens.screen: screen.name

    required property PolkitAgent agent

    property AuthFlow agentFlow: agent.flow // qmllint disable unresolved-type
    property bool isActive: agent.isActive && agentFlow != null
    property bool waitingForPrompt: false

    readonly property real centerScale: Math.max(0.8, Math.min(1, root.height / 1440))
    readonly property int centerWidth: root.screen ? Tokens.sizes.lock.centerWidth * centerScale : 0
    readonly property int passwordMaxWidth: centerWidth * 0.8

    readonly property bool authFailed: agentFlow?.failed ?? false
    readonly property var polkitIdentity: isActive ? agentFlow.selectedIdentity : null //qmllint disable unresolved-type
    readonly property string inputPrompt: isActive && agentFlow.inputPrompt ? agentFlow.inputPrompt : "Enter your password"
    readonly property string displayedInputPrompt: waitingForPrompt ? "Authenticating..." : inputPrompt
    readonly property bool responseVisible: isActive && agentFlow.responseVisible
    readonly property string rawMessage: isActive ? agentFlow.message : ""

    readonly property var splitMessage: {
        let msg = rawMessage.trim();
        let cmd = "";

        let pkexecMatch = msg.match(/Authentication is needed to run `(.+?)' as the super user/);
        if (pkexecMatch) {
            cmd = pkexecMatch[1];
            msg = "Escalation required to execute:";
        } else if (msg.includes('\n')) {
            let parts = msg.split('\n').filter(s => s.trim().length > 0);
            if (parts.length > 1) {
                cmd = parts.pop().trim();
                msg = parts.join('\n').trim();
            }
        } else if (msg.includes(': ')) {
            let lastColonIdx = msg.lastIndexOf(': ');
            cmd = msg.substring(lastColonIdx + 2).trim();
            msg = msg.substring(0, lastColonIdx + 1).trim();
        } else {
            let backtickMatch = msg.match(/`(.+?)`/);
            if (backtickMatch) {
                cmd = backtickMatch[1];
                msg = msg.replace(backtickMatch[0], "").replace(/\s+/g, " ").trim();
            }
        }

        return {
            message: msg,
            command: cmd
        };
    }
    readonly property string mainMessage: splitMessage.message
    readonly property string commandText: splitMessage.command

    property string buffer: ""
    readonly property list<int> shapeQueue: {
        const shapes = [MaterialShape.Slanted, MaterialShape.Arch, MaterialShape.Fan, MaterialShape.Arrow, MaterialShape.SemiCircle, MaterialShape.Triangle, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Sunny, MaterialShape.VerySunny, MaterialShape.Cookie4Sided, MaterialShape.Ghostish, MaterialShape.SoftBurst];
        for (let i = shapes.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [shapes[i], shapes[j]] = [shapes[j], shapes[i]];
        }
        return shapes;
    }

    function submitInput(): void {
        if (!isActive || waitingForPrompt || !responseInput.text.length)
            return;

        const response = responseInput.text;
        responseInput.text = "";
        waitingForPrompt = true;

        agentFlow.submit(response);
    }

    function cancelInput(): void {
        waitingForPrompt = false;
        responseInput.text = "";

        if (isActive)
            agentFlow.cancelAuthenticationRequest();
    }

    name: "polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    visible: isActive || closeAnim.running

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    onIsActiveChanged: {
        if (isActive) {
            closeAnim.stop();
            openAnim.start();
        } else {
            waitingForPrompt = false;
            openAnim.stop();
            closeAnim.start();
        }
    }

    ParallelAnimation {
        id: openAnim

        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: dialogContainer
                    property: "opacity"
                    to: 1
                    duration: root.Tokens.anim.durations.small
                }
                Anim {
                    target: dialogContainer
                    property: "scale"
                    to: 1
                    type: Anim.Emphasized
                    duration: 400
                }
            }
            // Delegate size expansion to Behaviors so they constantly evaluate layout recalculations
            PropertyAction {
                target: dialogContainer
                property: "isExpanded"
                value: true
            }
            ParallelAnimation {
                Anim {
                    target: lockIcon
                    property: "scale"
                    to: 0
                    type: Anim.Emphasized
                    duration: 400
                }
                Anim {
                    type: Anim.DefaultEffects
                    target: lockIcon
                    property: "opacity"
                    to: 0
                    duration: 250
                }
                Anim {
                    type: Anim.DefaultEffects
                    target: dialogContent
                    property: "opacity"
                    to: 1
                    duration: 500
                }
                Anim {
                    target: dialogContent
                    property: "scale"
                    to: 1
                    type: Anim.Emphasized
                    duration: 500
                }
                Anim {
                    target: dialogBg
                    property: "radius"
                    to: root.Tokens.rounding.large
                    duration: 500
                }
            }
        }
    }

    TextMetrics {
        id: nonAnimPlaceholder

        text: root.displayedInputPrompt
        font: Tokens.font.body.builders.medium.scale(root.centerScale).width(110).build()
    }

    SequentialAnimation {
        id: failureShake

        PropertyAction {
            target: dialogContainer
            property: "failureOffset"
            value: 0
        }
        NumberAnimation {
            target: dialogContainer
            property: "failureOffset"
            to: -12
            duration: 45
        }
        NumberAnimation {
            target: dialogContainer
            property: "failureOffset"
            to: 12
            duration: 80
        }
        NumberAnimation {
            target: dialogContainer
            property: "failureOffset"
            to: -8
            duration: 65
        }
        NumberAnimation {
            target: dialogContainer
            property: "failureOffset"
            to: 0
            duration: 55
        }
    }

    SequentialAnimation {
        id: closeAnim

        ParallelAnimation {
            // Trigger collapse logic via the Behavior state
            PropertyAction {
                target: dialogContainer
                property: "isExpanded"
                value: false
            }
            Anim {
                target: dialogBg
                property: "radius"
                to: dialogContainer.initialRadius
            }
            Anim {
                target: dialogContent
                property: "scale"
                to: 0
            }
            Anim {
                target: dialogContent
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
            }
            Anim {
                target: lockIcon
                property: "opacity"
                to: 1
                type: Anim.StandardLarge
            }
            Anim {
                target: lockIcon
                property: "scale"
                to: 1
                type: Anim.StandardLarge
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: Tokens.anim.durations.small
                }
                Anim {
                    target: dialogContainer
                    property: "opacity"
                    to: 0
                    type: Anim.Standard
                }
                PropertyAction {
                    target: dialogContainer
                    property: "scale"
                    value: 0
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
    }

    Item {
        id: dialogContainer

        property bool isExpanded: false
        property real failureOffset: 0

        readonly property int iconSize: lockIcon.implicitHeight + (root.screen ? Tokens.padding.large * 4 : 0)
        readonly property int initialRadius: root.screen ? iconSize / 4 * Tokens.rounding.scale : 0

        property int targetWidth: Math.max(420, root.passwordMaxWidth + Tokens.padding.extraLarge * 2)
        property int targetHeight: dialogContent.implicitHeight + (Tokens.padding.large * 2)

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: failureOffset
        implicitWidth: isExpanded ? targetWidth : iconSize
        implicitHeight: isExpanded ? targetHeight : iconSize
        scale: 0

        // This prevents the snapshotting issue by persistently interpolating dynamically updating bindings
        Behavior on implicitWidth {
            Anim {
                type: Anim.Emphasized
                duration: 500
            }
        }
        Behavior on implicitHeight {
            Anim {
                type: Anim.Emphasized
                duration: 500
            }
        }

        StyledRect {
            id: dialogBg

            anchors.fill: parent
            radius: dialogContainer.initialRadius
            color: Colours.layer(Colours.palette.m3surface, 0)

            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
            }
        }

        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "shield_person"
            fill: 1
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.Medium).build()
            color: Colours.palette.m3secondary
        }

        ColumnLayout {
            id: dialogContent

            width: dialogContainer.targetWidth - Tokens.padding.large * 2
            anchors.centerIn: parent

            opacity: 0
            scale: 0
            spacing: Tokens.spacing.large

            // Title Container
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: titleLayout.implicitHeight + Tokens.padding.large * 2
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Tokens.rounding.large

                ColumnLayout {
                    id: titleLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: "Authentication Required"
                        font: Tokens.font.title.builders.large.weight(Font.Medium).build()
                        color: Colours.palette.m3onSurface
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Message and Command
            Column {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    width: parent.width
                    text: root.mainMessage
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledRect {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.commandText.length > 0
                    width: Math.min(commandLabel.implicitWidth + Tokens.padding.large * 2, parent.width)
                    implicitHeight: commandLabel.implicitHeight + Tokens.padding.small * 2
                    color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
                    radius: Tokens.rounding.small

                    StyledText {
                        id: commandLabel

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        anchors.leftMargin: Tokens.padding.large
                        anchors.rightMargin: Tokens.padding.large
                        text: root.commandText
                        font: Tokens.font.mono.medium
                        color: Colours.palette.m3onSurface
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAnywhere
                    }
                }

                StyledText {
                    width: parent.width
                    text: root.agentFlow?.supplementaryMessage ?? ""
                    font: Tokens.font.body.small
                    color: root.agentFlow?.supplementaryIsError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    visible: text.length > 0
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    width: parent.width
                    visible: root.polkitIdentity !== null && root.polkitIdentity.string !== Quickshell.env("USER")
                    text: root.polkitIdentity ? `Authenticating as: ${root.polkitIdentity.string}` : ""
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            StyledRect {
                id: passwordRect

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: {
                    const emptyW = nonAnimPlaceholder.width + iconWrapper.implicitWidth + enterButton.implicitWidth + passwordInputLayout.spacing * 2 + Tokens.padding.medium * 2;
                    return root.buffer.length > 0 ? root.passwordMaxWidth : Math.min(root.passwordMaxWidth, emptyW);
                }
                implicitHeight: passwordInputLayout.implicitHeight + Tokens.padding.small
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Tokens.rounding.full

                border.width: root.authFailed ? 2 : 0
                border.color: root.authFailed ? '#ff5c5c' : "transparent"

                Behavior on implicitWidth {
                    Anim {}
                }

                Behavior on border.color {
                    CAnim {}
                }

                Connections {
                    function onIsActiveChanged() {
                        if (root.agent.isActive) {
                            responseInput.text = "";
                            root.waitingForPrompt = false;
                            responseInput.forceActiveFocus();
                        }
                    }

                    target: root.agent
                }

                Connections {
                    function onAuthenticationFailed() {
                        failureShake.restart();
                    }

                    function onIsResponseRequiredChanged() {
                        if (root.agentFlow && root.agentFlow.isResponseRequired) {
                            root.waitingForPrompt = false;
                            responseInput.forceActiveFocus();
                        }
                    }

                    target: root.agentFlow
                }

                TextInput {
                    id: responseInput

                    anchors.fill: parent
                    opacity: 0
                    focus: true
                    cursorVisible: false
                    echoMode: root.responseVisible ? TextInput.Normal : TextInput.Password
                    inputMethodHints: root.responseVisible ? Qt.ImhNone : Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData

                    enabled: root.isActive && !root.waitingForPrompt

                    onTextChanged: {
                        root.buffer = text;
                        charList.bindImWidth();

                        if (!text.length)
                            placeholder.animate = true;
                    }

                    onAccepted: root.submitInput()

                    Keys.onEscapePressed: event => {
                        root.cancelInput();
                        event.accepted = true;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: responseInput.forceActiveFocus()
                }

                RowLayout {
                    id: passwordInputLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraSmall
                    spacing: Tokens.spacing.medium

                    Item {
                        id: iconWrapper

                        Layout.fillHeight: true
                        implicitWidth: height

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "lock"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.builders.medium.scale(root.centerScale).build()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        StyledText {
                            id: placeholder

                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 1
                            text: nonAnimPlaceholder.text
                            animate: true
                            color: Colours.palette.m3outline
                            font: nonAnimPlaceholder.font
                            opacity: root.buffer ? 0 : 1

                            Behavior on opacity {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            width: parent.width
                            visible: root.responseVisible && root.buffer.length > 0
                            text: root.buffer
                            elide: Text.ElideRight
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                        }

                        ListView {
                            id: charList

                            readonly property int fullWidth: {
                                let w = (count - 1) * spacing;
                                for (let i = 0; i < count; i++)
                                    w += ((itemAtIndex(i) as CharItem)?.nonAnimWidthScale ?? 1) * implicitHeight;
                                return w + implicitHeight;
                            }

                            function bindImWidth(): void {
                                imWidthBehavior.enabled = false;
                                implicitWidth = Qt.binding(() => fullWidth);
                                imWidthBehavior.enabled = true;
                            }

                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: implicitWidth > parent.width ? -(implicitWidth - parent.width) / 2 : 0

                            implicitWidth: fullWidth
                            implicitHeight: Tokens.font.body.medium.pointSize

                            orientation: Qt.Horizontal
                            spacing: Tokens.spacing.extraSmall
                            interactive: false
                            visible: !root.responseVisible

                            model: ScriptModel {
                                values: root.buffer.split("")
                            }

                            delegate: CharItem {}

                            Behavior on implicitWidth {
                                id: imWidthBehavior

                                Anim {}
                            }
                        }
                    }

                    Item {
                        id: enterButton

                        implicitWidth: implicitHeight
                        implicitHeight: {
                            const h = enterIcon.implicitHeight + Tokens.padding.extraSmall * 2;
                            return h % 2 === 0 ? h : h + 1;
                        }

                        MaterialShape {
                            anchors.fill: parent
                            color: root.buffer ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                            shape: root.buffer ? MaterialShape.Arrow : MaterialShape.Circle
                            scale: !root.buffer ? 1 : enterMouse.pressed ? 0.6 : enterMouse.containsMouse ? 0.8 : 0.7
                            rotation: 90

                            Behavior on scale {
                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }
                            Behavior on color {
                                CAnim {}
                            }

                            MouseArea {
                                id: enterMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !root.waitingForPrompt
                                cursorShape: root.buffer && !root.waitingForPrompt ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    root.submitInput();
                                }
                            }
                        }

                        MaterialIcon {
                            id: enterIcon

                            anchors.centerIn: parent
                            text: "arrow_forward"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.builders.medium.scale(root.centerScale * 1.2).build()
                            opacity: root.buffer ? 0 : 1

                            Behavior on opacity {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component CharItem: Item {
        id: char

        required property int index
        property real nonAnimWidthScale: 1

        implicitHeight: charList.implicitHeight

        ListView.onRemove: {
            initAnim.stop();
            removeAnim.start();
        }

        MaterialShape {
            id: charShape

            anchors.centerIn: parent
            implicitSize: charList.implicitHeight * 1.5
            shape: root.shapeQueue[char.index % root.shapeQueue.length] ?? MaterialShape.Circle
            color: Colours.palette.m3onSurface

            Behavior on color {
                CAnim {}
            }

            SequentialAnimation {
                id: initAnim

                running: true

                ParallelAnimation {
                    Anim {
                        target: charShape
                        property: "opacity"
                        from: 0
                        to: 1
                        type: Anim.DefaultEffects
                    }
                    Anim {
                        target: charShape
                        property: "scale"
                        from: 0
                        to: 1
                        type: Anim.FastSpatial
                    }
                    Anim {
                        target: char
                        property: "implicitWidth"
                        from: charList.implicitHeight
                        to: charList.implicitHeight * 1.3
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        target: char
                        property: "nonAnimWidthScale"
                        value: 1.5
                    }
                }
                PauseAnimation {
                    duration: 180 * Tokens.anim.durations.scale
                }
                PropertyAction {
                    target: charShape
                    property: "shape"
                    value: MaterialShape.Circle
                }
                ParallelAnimation {
                    Anim {
                        target: charShape
                        property: "scale"
                        to: 2 / 3
                        type: Anim.FastSpatial
                    }
                    Anim {
                        target: char
                        property: "implicitWidth"
                        to: charList.implicitHeight
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        target: char
                        property: "nonAnimWidthScale"
                        value: 1
                    }
                }
            }

            SequentialAnimation {
                id: removeAnim

                PropertyAction {
                    target: char
                    property: "ListView.delayRemove"
                    value: true
                }
                ParallelAnimation {
                    Anim {
                        type: Anim.DefaultEffects
                        target: charShape
                        property: "opacity"
                        to: 0
                    }
                    Anim {
                        target: charShape
                        property: "scale"
                        to: 0.5
                    }
                }
                PropertyAction {
                    target: char
                    property: "ListView.delayRemove"
                    value: false
                }
            }
        }
    }
}
