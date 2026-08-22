pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.bar.components

StyledRect {
    id: root

    required property var popouts
    readonly property int refreshInterval: 1800

    function setUnavailable(message: string) {
        const error = (message || "").replace(/bearer\s+[A-Za-z0-9_\-.]+/gi, "bearer [redacted]").replace(/ghp_\w+/gi, "[redacted token]");
        GithubStore.lastError = error;
        GithubStore.available = false;
        console.error(lc, error);
    }

    function buildDays(weeks, today) {
        const counts = {};
        for (const week of weeks) {
            for (const day of week.contributionDays)
                counts[day.date] = day.contributionCount;
        }

        const days = [];
        const cursor = new Date(today);
        cursor.setDate(cursor.getDate() - 6);
        for (let i = 0; i < 7; ++i) {
            const date = Qt.formatDate(cursor, "yyyy-MM-dd");
            days.push({
                date,
                count: counts[date] ?? 0
            });
            cursor.setDate(cursor.getDate() + 1);
        }

        const palette = ["#161b22", "#0e4429", "#006d32", "#26a641", "#39d353"];
        const max = Math.max(1, ...days.map(day => day.count));
        for (const day of days) {
            const level = day.count === 0 ? 0 : Math.min(4, 1 + Math.floor(day.count * 4 / max));
            day.color = palette[level];
        }
        return days;
    }

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: cells.implicitHeight + (Config.bar.github.background ? Tokens.padding.medium : Tokens.padding.small) * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.github.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Column {
        id: cells

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Repeater {
            model: GithubStore.days

            delegate: Rectangle {
                required property var modelData

                width: 12
                height: 12
                radius: 2
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)
                color: modelData.color
            }
        }

        /* Uncomment for total count beside the widget
        StyledText {
            id: text
            verticalAlignment: StyledText.AlignVCenter
            text: GithubStore.total
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: Colours.palette.m3secondary
        }
        */
    }

    // Could do something with this in the future, nothing currently though to keep things decluttered
    // var counts GithubStore.lastError.length ? `GitHub: ${GithubStore.lastError}` : GithubStore.days.map(d => `${d.date}: ${d.count}`).join("\n")

    Process {
        id: proc

        command: ["bash", "-lc", `
        set -Eeuo pipefail
        : "\${GITHUB_TOKEN:?Missing GITHUB_TOKEN}"

        payload="$(LOGIN="\${GITHUB_USERNAME-}" python - <<'PY'
import json
import os
from datetime import date, timedelta

today = date.today()
variables = {
    "from": f"{today - timedelta(days=6)}T00:00:00Z",
    "to": f"{today}T23:59:59Z"
}

login = os.environ["LOGIN"]
if login:
    query = "query($from: DateTime!, $to: DateTime!, $login: String!) { user(login: $login) { ...Activity } }"
    variables["login"] = login
else:
    query = "query($from: DateTime!, $to: DateTime!) { user: viewer { ...Activity } }"

query += """
fragment Activity on User {
  login
  contributionsCollection(from: $from, to: $to) {
    contributionCalendar { weeks { contributionDays { date contributionCount } } }
  }
}
"""
print(json.dumps({"query": query, "variables": variables}))
PY
        )"

        tmp="$(mktemp)"
        trap 'rm -f -- "$tmp"' EXIT
        code="$(curl -sS -o "$tmp" -w "%{http_code}" \
                 -H "Authorization: bearer $GITHUB_TOKEN" \
                 -H "Content-Type: application/json" \
                 -X POST https://api.github.com/graphql \
                 --data "$payload")"
        case "$code" in
          2??) cat "$tmp" ;;
          *)   echo "HTTP $code: $(head -c 200 "$tmp")" >&2; exit 22 ;;
        esac
    `]

        stdout: StdioCollector {
            id: out
        }

        stderr: StdioCollector {
            id: err
        }

        onExited: code => {
            if (code !== 0) {
                root.setUnavailable(err.text || `fetch failed with exit code: ${code}`);
                return;
            }

            const raw = out.text.trim();
            try {
                const obj = JSON.parse(raw);
                if (obj.errors) {
                    root.setUnavailable(obj.errors.map(e => e.message).join("; "));
                    return;
                }

                const user = obj?.data?.user;
                const weeks = user?.contributionsCollection?.contributionCalendar?.weeks;
                if (!user?.login || !Array.isArray(weeks)) {
                    root.setUnavailable("GitHub response is missing user or contribution calendar");
                    return;
                }

                const days = root.buildDays(weeks, new Date());
                GithubStore.days = days;
                GithubStore.total = days.reduce((sum, day) => sum + day.count, 0);
                GithubStore.username = user.login;
                GithubStore.lastError = "";
                GithubStore.available = true;
            } catch (e) {
                root.setUnavailable("parse error: " + e + " | first 200B: " + raw.slice(0, 200));
            }
        }
    }

    Timer {
        interval: root.refreshInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.exec(proc.command)
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.modules.bar.github"
        defaultLogLevel: LoggingCategory.Info
    }
}
