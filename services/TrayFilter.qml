pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config

Singleton {
    function shouldHide(item: SystemTrayItem): bool {
        const text = [item.id, item.title, item.tooltipTitle, item.tooltipDescription, item.icon].map(v => String(v ?? "")).join(" ").toLowerCase();
        const hiddenItems = GlobalConfig.bar.tray.hiddenItems ?? [];

        for (const hidden of hiddenItems) {
            const needle = String(hidden ?? "").toLowerCase();
            if (needle !== "" && text.includes(needle))
                return true;
        }

        return false;
    }
}
