pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    property int cellSize: 10

    clip: true

    Grid {
        id: cells

        columns: Math.max(1, Math.ceil(root.width / root.cellSize))

        Repeater {
            model: cells.columns * Math.max(1, Math.ceil(root.height / root.cellSize))

            Rectangle {
                required property int index

                width: root.cellSize
                height: root.cellSize
                color: (Math.floor(index / cells.columns) + index % cells.columns) % 2 === 0 ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3outlineVariant
            }
        }
    }
}
