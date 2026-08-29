import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import "components"

PlasmoidItem {
    id: root

    readonly property color claudeColor: "#F97316"
    readonly property color claudeGlow: "#FDBA74"
    readonly property color codexColor: "#7C5CFC"
    readonly property color codexGlow: "#C4B5FD"
    readonly property string helperPath: String(Qt.resolvedUrl("../tools/ai-usage-status")).replace("file://", "")
    property string command: "/usr/bin/env node " + helperPath
    property string claudeText: "—"
    property string codexText: "—"
    property string codexmText: "—"
    property bool codexmAvailable: false
    property int claudeResetCredits: 0
    property int codexResetCredits: 0
    property int codexTotalResetCredits: 1
    property int codexmResetCredits: 0
    property int codexmTotalResetCredits: 1
    property double claudePrimaryReset: 0
    property double claudeSecondaryReset: 0
    property string claudePrimaryLabel: ""
    property string claudeSecondaryLabel: ""
    property double codexPrimaryReset: 0
    property double codexSecondaryReset: 0
    property string codexPrimaryLabel: ""
    property string codexSecondaryLabel: ""
    property double codexmPrimaryReset: 0
    property double codexmSecondaryReset: 0
    property string codexmPrimaryLabel: ""
    property string codexmSecondaryLabel: ""
    property double nowMs: Date.now()
    property string detailText: "Loading AI usage…"
    property string updatedText: "Updating"
    property bool refreshing: false

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? fullRepresentation
        : compactRepresentation
    toolTipMainText: "AI usage"
    toolTipSubText: detailText

    function percentages(value) {
        if (!value || value === "\u2014") return { short: null, weekly: null };
        const found = String(value).match(/\d+/g) || [];
        if (found.length === 0) return { short: null, weekly: null };
        return {
            short: Math.min(100, Number(found[0])),
            weekly: found.length > 1 ? Math.min(100, Number(found[1])) : null
        };
    }

    function compactUsage(value) {
        if (!value || value === "\u2014") return "?";
        const found = String(value).match(/\d+/g) || [];
        return found.length ? found.slice(0, 2).join("/") : "?";
    }

    function resetLabel(value) {
        if (!value)
            return "unknown";
        const ms = typeof value === "number" ? value : new Date(value).getTime();
        if (!ms || isNaN(ms)) return "unknown";
        return new Date(ms).toLocaleString(Qt.locale(), Locale.ShortFormat);
    }

    function countdown(resetAt) {
        if (!resetAt)
            return "—";
        const remaining = Math.max(0, Math.floor((resetAt - nowMs) / 60000));
        const days = Math.floor(remaining / 1440);
        const hours = Math.floor((remaining % 1440) / 60);
        const minutes = remaining % 60;
        return `${days}D ${hours}H ${minutes}M`;
    }

    function applyUsage(raw) {
        try {
            const value = JSON.parse(raw);
            claudeText = value.claude?.short || "—";
            codexText = value.codex?.short || "—";
            codexmText = value.codexm?.short || "—";
            codexmAvailable = value.codexm?.available === true;
            claudeResetCredits = value.claude?.resetCredits || 0;
            codexResetCredits = value.codex?.resetCredits || 0;
            codexTotalResetCredits = value.codex?.totalResetCredits || 1;
            codexmResetCredits = value.codexm?.resetCredits || 0;
            codexmTotalResetCredits = value.codexm?.totalResetCredits || 1;
            claudePrimaryReset = value.claude?.primary?.resetsAt || 0;
            claudeSecondaryReset = value.claude?.secondary?.resetsAt || 0;
            claudePrimaryLabel = value.claude?.primaryLabel || "";
            claudeSecondaryLabel = value.claude?.secondaryLabel || "";
            codexPrimaryReset = value.codex?.primary?.resetsAt || 0;
            codexSecondaryReset = value.codex?.secondary?.resetsAt || 0;
            codexPrimaryLabel = value.codex?.primaryLabel || "";
            codexSecondaryLabel = value.codex?.secondaryLabel || "";
            codexmPrimaryReset = value.codexm?.primary?.resetsAt || 0;
            codexmSecondaryReset = value.codexm?.secondary?.resetsAt || 0;
            codexmPrimaryLabel = value.codexm?.primaryLabel || "";
            codexmSecondaryLabel = value.codexm?.secondaryLabel || "";
            nowMs = Date.now();
            updatedText = Qt.formatTime(new Date(), "h:mm AP");
            const claudeReset = resetLabel(value.claude?.primary?.resetsAt);
            const claudeWeek = resetLabel(value.claude?.secondary?.resetsAt);
            const codexReset = resetLabel(value.codex?.primary?.resetsAt);
            const codexWeek = resetLabel(value.codex?.secondary?.resetsAt);
            const codexmReset = resetLabel(value.codexm?.primary?.resetsAt);
            const codexmWeek = resetLabel(value.codexm?.secondary?.resetsAt);
            const codexmSummary = codexmAvailable ? ` · Codex M ${codexmText} (${codexmResetCredits} resets)` : "";
            const codexmDetails = codexmAvailable
                ? `\nCodex M resets: ${codexmReset} / ${codexmWeek}` : "";
            detailText =
                `Used: Claude ${claudeText} (${claudeResetCredits} resets) · Codex ${codexText} (${codexResetCredits} resets)${codexmSummary}\n` +
                `Claude resets: ${claudeReset} / ${claudeWeek}\n` +
                `Codex resets: ${codexReset} / ${codexWeek}${codexmDetails}`;
        } catch (error) {
            detailText = `Usage refresh failed: ${error}`;
            updatedText = "Unavailable";
        }
    }

    function refresh() {
        updatedText = "Updating";
        refreshing = true;
        refreshIndicatorTimer.restart();
        executable.disconnectSource(root.command);
        executable.connectSource(root.command);
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: [root.command]
        interval: 300000

        onNewData: function(sourceName, data) {
            if (data["exit code"] === 0 && data.stdout)
                root.applyUsage(data.stdout.trim());
            else {
                root.detailText = data.stderr ? data.stderr.trim() : "Usage refresh failed";
                root.updatedText = "Unavailable";
            }
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.nowMs = Date.now()
    }

    Timer {
        id: refreshIndicatorTimer
        interval: 6000
        onTriggered: root.refreshing = false
    }

    component ResetBadge: Item {
        id: badgeItem
        property bool isAvailable: false
        readonly property color purpleColor: "#A855F7"
        readonly property color purpleGlow: "#C084FC"
        readonly property color grayColor: "#64748B"

        implicitWidth: 16
        implicitHeight: 14
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            visible: badgeItem.isAvailable
            anchors.centerIn: badgeCore
            width: badgeCore.width + 6
            height: badgeCore.height + 6
            radius: height / 2
            color: badgeItem.purpleGlow
            opacity: 0.40
        }

        Rectangle {
            id: badgeCore
            anchors.centerIn: parent
            width: 12
            height: 7
            radius: 3.5
            color: badgeItem.isAvailable ? badgeItem.purpleColor : badgeItem.grayColor
            border.width: 1
            border.color: badgeItem.isAvailable ? badgeItem.purpleGlow : Qt.rgba(1, 1, 1, 0.20)
            opacity: badgeItem.isAvailable ? 0.95 : 0.35
        }
    }

    component UsageRing: Item {
        id: ring
        property real value: 0
        property color accent: "white"
        property color glow: "white"
        property color textColor: "#FFFFFF"
        property color labelColor: "#AEB0C0"
        property color countdownColor: glow
        property bool countdownOutlined: false
        property bool hasData: false
        property string label: "5H"
        property double resetAt: 0

        implicitWidth: 62
        implicitHeight: 88

        Canvas {
            id: canvas
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 58
            height: 58
            onPaint: {
                const ctx = getContext("2d");
                const start = -Math.PI / 2;
                const amount = Math.max(0, Math.min(100, ring.value));
                ctx.reset();
                ctx.lineCap = "round";
                ctx.lineWidth = 5;
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.10);
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, 23, 0, Math.PI * 2);
                ctx.stroke();
                if (amount > 0) {
                    ctx.strokeStyle = ring.accent;
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, 23, start,
                            start + Math.PI * 2 * amount / 100);
                    ctx.stroke();
                }
            }
            Connections {
                target: ring
                function onValueChanged() { canvas.requestPaint(); }
                function onAccentChanged() { canvas.requestPaint(); }
            }
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -14
            text: ring.hasData ? Math.round(ring.value) + "%" : "\u2014"
            color: ring.textColor
            font.family: "SF Pro Text"
            font.pixelSize: ring.hasData ? 13 : 16
            font.weight: Font.DemiBold
            opacity: ring.hasData ? 1.0 : 0.45
        }

        Text {
            anchors.top: parent.top
            anchors.topMargin: 59
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.label
            color: ring.labelColor
            font.family: "SF Pro Text"
            font.pixelSize: 10
            font.weight: Font.Medium
            font.letterSpacing: 0.7
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.countdown(ring.resetAt)
            color: ring.resetAt ? ring.countdownColor : "#777989"
            style: ring.countdownOutlined ? Text.Outline : Text.Normal
            styleColor: Qt.rgba(0, 0, 0, 0.96)
            opacity: ring.countdownOutlined ? 1.0 : (ring.resetAt ? 0.90 : 0.65)
            font.family: "SF Pro Text"
            font.pixelSize: ring.countdownOutlined ? 10 : 8
            font.weight: ring.countdownOutlined ? Font.DemiBold : Font.Medium
        }
    }

    component ServiceCard: Rectangle {
        id: service
        property string serviceName: ""
        property url logoSource: ""
        property color accent: "white"
        property color glow: "white"
        property color primaryTextColor: "#FFFFFF"
        property color secondaryTextColor: "#AEB0C0"
        property color countdownTextColor: glow
        property bool countdownTextOutlined: false
        property string usageText: "—"
        property bool showResetBadges: false
        property int resetCredits: 0
        property int maxResetCredits: 1
        property bool singleWeeklyWindow: false
        property string primaryLabel: ""
        property string secondaryLabel: ""
        property double primaryResetAt: 0
        property double secondaryResetAt: 0
        readonly property var usage: root.percentages(usageText)

        radius: 18
        color: mouse.containsMouse ? Qt.rgba(colors.cardBackground.r, colors.cardBackground.g, colors.cardBackground.b, colors.cardHoverOpacity) : "transparent"
        border.width: 0
        Behavior on color { ColorAnimation { duration: 150 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                Layout.minimumHeight: 28
                Layout.maximumHeight: 28
                spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 9
                        color: "transparent"
                        border.width: 0

                        Image {
                        id: logoImage
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: service.logoSource
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                Text {
                    text: service.serviceName
                    color: service.primaryTextColor
                    font.family: "SF Pro Text"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                Row {
                    visible: service.showResetBadges
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: Math.max(1, service.maxResetCredits)
                        ResetBadge {
                            required property int index
                            isAvailable: index < service.resetCredits
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 88
                Layout.minimumHeight: 88
                Layout.maximumHeight: 88
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                UsageRing {
                    Layout.alignment: Qt.AlignTop
                    value: service.usage.short ?? 0
                    hasData: service.usage.short != null
                    accent: service.accent
                    glow: service.glow
                    textColor: service.primaryTextColor
                    labelColor: service.secondaryTextColor
                    countdownColor: service.countdownTextColor
                    countdownOutlined: service.countdownTextOutlined
                    label: service.primaryLabel || (service.singleWeeklyWindow ? "7D" : "5H")
                    resetAt: service.primaryResetAt
                }
                Rectangle {
                    visible: !service.singleWeeklyWindow
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 48
                    color: Qt.rgba(1, 1, 1, 0.10)
                }
                UsageRing {
                    visible: !service.singleWeeklyWindow
                    Layout.alignment: Qt.AlignTop
                    value: service.usage.weekly ?? 0
                    hasData: service.usage.weekly != null
                    accent: service.accent
                    glow: service.glow
                    textColor: service.primaryTextColor
                    labelColor: service.secondaryTextColor
                    countdownColor: service.countdownTextColor
                    countdownOutlined: service.countdownTextOutlined
                    label: service.secondaryLabel || "7D"
                    resetAt: service.secondaryResetAt
                }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.refresh()
        }
    }

    MacOSColors {
        id: colors
        styleMode: 0
        appearance: 2
    }

    fullRepresentation: Item {
        implicitWidth: 620
        implicitHeight: 168
        Layout.minimumWidth: 560
        Layout.minimumHeight: 160

        LiquidGlass {
            id: representationGlass
            anchors.fill: parent
            radius: 100
            roundness: 7.5
            refractThickness: 35
            refractIOR: 1.7
            refractScale: 65
            tint: colors.glassTint
            tintAlpha: 0.10
            chromaStrength: 0.30
            specStrength: 0.70
            blurRadius: 6
            realtimeRefraction: true
            fallbackOpacity: 0.55
            solidMode: false
        }



        RowLayout {
                id: serviceRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 0

                ServiceCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    serviceName: "Claude"
                    logoSource: Qt.resolvedUrl("../images/claude.png")
                    accent: root.claudeColor
                    glow: root.claudeGlow
                    usageText: root.claudeText
                    showResetBadges: false
                    primaryLabel: root.claudePrimaryLabel
                    secondaryLabel: root.claudeSecondaryLabel
                    primaryResetAt: root.claudePrimaryReset
                    secondaryResetAt: root.claudeSecondaryReset
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 116
                    Layout.alignment: Qt.AlignVCenter
                    color: "#18FFFFFF"
                }

                ServiceCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    serviceName: "Codex"
                    logoSource: Qt.resolvedUrl("../images/codex.png")
                    accent: root.codexColor
                    glow: root.codexGlow
                    countdownTextOutlined: true
                    usageText: root.codexText
                    showResetBadges: true
                    resetCredits: root.codexResetCredits
                    maxResetCredits: root.codexTotalResetCredits
                    primaryLabel: root.codexPrimaryLabel
                    secondaryLabel: root.codexSecondaryLabel
                    primaryResetAt: root.codexPrimaryReset
                    secondaryResetAt: root.codexSecondaryReset
                }

                Rectangle {
                    visible: root.codexmAvailable
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 116
                    Layout.alignment: Qt.AlignVCenter
                    color: "#18FFFFFF"
                }

                ServiceCard {
                    visible: root.codexmAvailable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    serviceName: "Codex M"
                    logoSource: Qt.resolvedUrl("../images/codex.png")
                    accent: root.codexColor
                    glow: root.codexGlow
                    countdownTextOutlined: true
                    usageText: root.codexmText
                    showResetBadges: true
                    resetCredits: root.codexmResetCredits
                    maxResetCredits: root.codexmTotalResetCredits
                    primaryLabel: root.codexmPrimaryLabel
                    secondaryLabel: root.codexmSecondaryLabel
                    primaryResetAt: root.codexmPrimaryReset
                    secondaryResetAt: root.codexmSecondaryReset
                }
        }

        Rectangle {
            visible: root.refreshing
            anchors.centerIn: parent
            z: 10
            width: refreshLabel.implicitWidth + 30
            height: 34
            radius: 17
            color: Qt.rgba(0.05, 0.04, 0.12, 0.78)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.22)

            Text {
                id: refreshLabel
                anchors.centerIn: parent
                text: "Refreshing…"
                color: "white"
                font.family: "SF Pro Text"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
    }

    compactRepresentation: Item {
        implicitWidth: compactLabel.implicitWidth + 16
        implicitHeight: 28
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Text {
            id: compactLabel
            anchors.centerIn: parent
            text: `C ${root.compactUsage(root.claudeText)}  ·  X ${root.compactUsage(root.codexText)}`
                + (root.codexmAvailable ? `  ·  M ${root.compactUsage(root.codexmText)}` : "")
            color: Kirigami.Theme.textColor
            font.family: "SF Pro Text"
            font.pixelSize: 11
            font.weight: Font.Medium
        }
    }
}
