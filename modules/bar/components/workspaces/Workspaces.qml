pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

StyledClippingRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property var currentMonitor: GlobalConfig.bar.workspaces.perMonitorWorkspaces ? (screen ? Hypr.monitorFor(screen) : null) : Hypr.focusedMonitor
    readonly property string activeSpecial: currentMonitor?.lastIpcObject?.specialWorkspace?.name ?? ""
    readonly property bool onSpecial: activeSpecial !== "" && Hypr.workspaces.values.some(ws => ws.name === activeSpecial && (!GlobalConfig.bar.workspaces.perMonitorWorkspaces || ws.monitor?.name === currentMonitor?.name))
    readonly property int activeWsId: currentMonitor?.activeWorkspace?.id ?? 1

    function monitorSelector(monitor: var): string {
        return monitor?.name ?? monitor?.lastIpcObject?.name ?? "";
    }

    function switchOrSwapWorkspace(ws: int): void {
        const targetMonitor = (screen ? Hypr.monitorFor(screen) : null) ?? currentMonitor ?? Hypr.focusedMonitor;
        const target = monitorSelector(targetMonitor);
        if (!targetMonitor || !target) {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = ${ws} })` : `workspace ${ws}`);
            return;
        }

        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ monitor = "${target}" })` : `focusmonitor ${target}`);

        if (targetMonitor.activeWorkspace?.id === ws) {
            Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.workspace.toggle_special("special")' : "togglespecialworkspace special");
            return;
        }

        const sourceMonitor = Hypr.monitors.values.find(m => m.activeWorkspace?.id === ws);
        if (sourceMonitor) {
            const source = monitorSelector(sourceMonitor);
            if (source && source !== target)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.swap_monitors({ monitor1 = "${target}", monitor2 = "${source}" })` : `swapactiveworkspaces ${target} ${source}`);
            return;
        }

        const existingWs = Hypr.workspaces.values.find(w => w.id === ws);
        if (existingWs && monitorSelector(existingWs.monitor) !== target)
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.move({ workspace = ${ws}, monitor = "${target}" })` : `moveworkspacetomonitor ${ws} ${target}`);

        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = ${ws} })` : `workspace ${ws}`);
    }

    readonly property var occupied: {
        const occ = {};
        for (const ws of Hypr.workspaces.values)
            occ[ws.id] = ws.lastIpcObject.windows > 0;
        return occ;
    }
    readonly property int groupOffset: Math.floor((activeWsId - 1) / Config.bar.workspaces.shown) * Config.bar.workspaces.shown

    property real blur: onSpecial ? 1 : 0

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.small

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        Loader {
            asynchronous: true
            active: Config.bar.workspaces.occupiedBg

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall

            sourceComponent: OccupiedBg {
                workspaces: workspaces
                occupied: root.occupied
                groupOffset: root.groupOffset
            }
        }

        ColumnLayout {
            id: layout

            anchors.centerIn: parent
            spacing: Math.floor(Tokens.spacing.extraSmall)

            Repeater {
                id: workspaces

                model: Config.bar.workspaces.shown

                Workspace {
                    activeWsId: root.activeWsId
                    occupied: root.occupied
                    groupOffset: root.groupOffset
                }
            }
        }

        Loader {
            asynchronous: true
            anchors.horizontalCenter: parent.horizontalCenter
            active: Config.bar.workspaces.activeIndicator

            sourceComponent: ActiveIndicator {
                activeWsId: root.activeWsId
                workspaces: workspaces
                mask: layout
                fullscreen: root.fullscreen
            }
        }

        MouseArea {
            anchors.fill: layout
            onClicked: event => {
                const ws = (layout.childAt(event.x, event.y) as Workspace)?.ws;
                if (ws)
                    root.switchOrSwapWorkspace(ws);
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: specialWs

        asynchronous: true

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall

        active: opacity > 0

        scale: root.onSpecial ? 1 : 0.5
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: SpecialWorkspaces {
            screen: root.screen
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
