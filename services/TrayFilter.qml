pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config

Singleton {
    function shouldHide(item: SystemTrayItem): bool {
        const text = [item.id, item.title, item.tooltipTitle, item.tooltipDescription].map(v => String(v ?? "")).join(" ").toLowerCase();
        const hiddenIcons = GlobalConfig.bar.tray.hiddenIcons ?? [];

        for (const hidden of hiddenIcons) {
            const needle = String(hidden ?? "").toLowerCase();
            if (needle !== "" && text.includes(needle))
                return true;
        }

        return false;
    }
}
