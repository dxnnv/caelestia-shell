import QtQuick
import Caelestia.Config
import qs.components

MaterialIcon {
    id: root

    required property bool active

    animate: true
    text: "touch_app"
    color: '#ffe100'
    fill: 1

    SequentialAnimation on opacity {
        running: root.active
        alwaysRunToEnd: true
        loops: Animation.Infinite

        Anim {
            from: 1
            to: 0.35
            duration: Tokens.anim.durations.large
            easing: Tokens.anim.standardAccel
        }
        Anim {
            from: 0.35
            to: 1
            duration: Tokens.anim.durations.large
            easing: Tokens.anim.standardDecel
        }
    }
}
