pragma Singleton

import QtQuick

QtObject {
    id: root

    function readlink(path: string): var {
        return new Promise(resolve => {
            const proc = Qt.createQmlObject("import Quickshell; import Quickshell.Io; Process {}", root);
            const out = Qt.createQmlObject("import Quickshell.Io; StdioCollector {}", proc);
            proc.command = ["bash", "-lc", "readlink -f -- \"$1\" 2>/dev/null || :", "readlink", path];
            proc.stdout = out;
            out.streamFinished.connect(() => {
                const text = out.text.trim();
                out.destroy();
                proc.destroy();
                resolve(text);
            });
            proc.running = true;
        });
    }

    function exists(path: string): var {
        return new Promise(resolve => {
            const proc = Qt.createQmlObject("import Quickshell; import Quickshell.Io; Process {}", root);
            const out = Qt.createQmlObject("import Quickshell.Io; StdioCollector {}", proc);
            proc.command = ["bash", "-lc", "[ -e \"$1\" ] && echo yes || echo no", "exists", path];
            proc.stdout = out;
            out.streamFinished.connect(() => {
                const exists = out.text.trim() === "yes";
                out.destroy();
                proc.destroy();
                resolve(exists);
            });
            proc.running = true;
        });
    }
}
