// Switchboard: hide and show panel widgets, and switch presets.
// All the work is done by ../code/widgetctl (also usable from a terminal); this is the view.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    readonly property string ctl: "python3 '" + decodeURIComponent(Qt.resolvedUrl("../code/widgetctl").toString().replace("file://", "")) + "'"
    property var info: ({ panels: [], widgets: [], presets: [], preset: null })
    property string error: ""
    property bool busy: false
    readonly property int hiddenCount: info.widgets.filter(w => w.hidden).length

    Plasmoid.icon: hiddenCount > 0 ? "view-hidden" : "visibility"
    toolTipMainText: "Switchboard"
    toolTipSubText: hiddenCount > 0
        ? hiddenCount + " widget" + (hiddenCount > 1 ? "s" : "") + " hidden" + (info.preset ? " · preset: " + info.preset : "")
        : "All widgets shown"

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: (source, data) => {
            const cb = callbacks[source]
            delete callbacks[source]
            disconnectSource(source)
            if (cb)
                cb(data["stdout"], data["stderr"], data["exit code"])
        }
        function run(cmd, cb) {
            callbacks[cmd] = cb
            connectSource(cmd)
        }
    }

    function refresh() {
        exec.run(ctl + " list --json", (out, err, code) => {
            busy = false
            if (code !== 0) {
                error = (err || "widgetctl failed").trim()
                return
            }
            try {
                info = JSON.parse(out)
                error = ""
            } catch (e) {
                error = "Could not read widgetctl output"
            }
        })
    }

    // Names are slugs ([a-z0-9-]) from widgetctl itself; strip anything else anyway.
    function safe(s) { return String(s).replace(/[^A-Za-z0-9_-]/g, "") }

    function act(args) {
        busy = true
        exec.run(ctl + " " + args, (out, err, code) => {
            if (code !== 0)
                error = (err || "widgetctl failed").trim()
            refresh()
        })
    }

    Component.onCompleted: refresh()
    onExpandedChanged: if (expanded) refresh()

    Timer {
        // Keeps the panel icon right when presets are switched from a terminal or shortcut.
        interval: 60000; running: true; repeat: true
        onTriggered: if (!root.busy) root.refresh()
    }

    fullRepresentation: PlasmaExtras.Representation {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredHeight: Kirigami.Units.gridUnit * 30
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12

        header: PlasmaExtras.PlasmoidHeading {
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading {
                        level: 3
                        text: "Presets"
                        Layout.fillWidth: true
                    }
                    PC3.ToolButton {
                        icon.name: "visibility"
                        text: "Show all"
                        enabled: root.hiddenCount > 0 && !root.busy
                        onClicked: root.act("show-all")
                    }
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: root.info.presets
                        PC3.Button {
                            required property string modelData
                            text: modelData
                            checkable: true
                            checked: root.info.preset === modelData
                            enabled: !root.busy
                            onClicked: root.act("preset " + root.safe(modelData))
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    PC3.TextField {
                        id: presetName
                        Layout.fillWidth: true
                        placeholderText: "Save current as preset…"
                        onAccepted: saveBtn.clicked()
                    }
                    PC3.ToolButton {
                        id: saveBtn
                        icon.name: "document-save"
                        enabled: root.safe(presetName.text).length > 0 && !root.busy
                        onClicked: {
                            root.act("preset save " + root.safe(presetName.text))
                            presetName.text = ""
                        }
                        PC3.ToolTip.text: "Save which widgets are hidden right now"
                        PC3.ToolTip.visible: hovered
                    }
                }
            }
        }

        PC3.ScrollView {
            id: scroll
            anchors.fill: parent

            ColumnLayout {
                width: scroll.availableWidth
                spacing: 0

                Repeater {
                    model: root.info.panels
                    ColumnLayout {
                        id: panelBlock
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 0

                        Kirigami.ListSectionHeader {
                            Layout.fillWidth: true
                            label: panelBlock.modelData.location.charAt(0).toUpperCase()
                                   + panelBlock.modelData.location.slice(1) + " panel"
                                   + (panelBlock.modelData.controllable ? "" : " (needs Panel Colorizer)")
                        }
                        Repeater {
                            model: root.info.widgets.filter(w => w.panel === panelBlock.modelData.id)
                            PC3.ItemDelegate {
                                id: row
                                required property var modelData
                                Layout.fillWidth: true
                                enabled: panelBlock.modelData.controllable && !root.busy
                                onClicked: root.act((modelData.hidden ? "show " : "hide ") + root.safe(modelData.name))
                                contentItem: RowLayout {
                                    spacing: Kirigami.Units.smallSpacing
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        PC3.Label {
                                            Layout.fillWidth: true
                                            text: row.modelData.title || row.modelData.name
                                            elide: Text.ElideRight
                                            opacity: row.modelData.hidden ? 0.55 : 1
                                        }
                                        PC3.Label {
                                            Layout.fillWidth: true
                                            text: row.modelData.name
                                            font: Kirigami.Theme.smallFont
                                            opacity: 0.6
                                            elide: Text.ElideRight
                                        }
                                    }
                                    PC3.Switch {
                                        checked: !row.modelData.hidden
                                        enabled: row.enabled
                                        onClicked: root.act((checked ? "show " : "hide ") + root.safe(row.modelData.name))
                                    }
                                }
                            }
                        }
                    }
                }

                PlasmaExtras.PlaceholderMessage {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.gridUnit
                    visible: root.error !== "" || root.info.widgets.length === 0
                    iconName: root.error ? "dialog-error" : "visibility"
                    text: root.error ? "Something went wrong" : "Loading…"
                    explanation: root.error
                }
            }
        }
    }
}
