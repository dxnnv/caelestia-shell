pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config

Singleton {
    function shouldHide(item: SystemTrayItem): bool {
        const hidden = GlobalConfig.bar.tray.hiddenIcons;
        if (!hidden.length)
            return false;

        const text = [item.id, item.title, item.tooltipTitle, item.tooltipDescription].join(" ").toLowerCase();
        return hidden.some(needle => needle.length > 0 && text.includes(needle.toLowerCase()));
    }
}
