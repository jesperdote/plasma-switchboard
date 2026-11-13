# Switchboard

Hide and show your Plasma panel widgets, one by one or with presets, from a panel popup or
a terminal. A hidden widget is **not removed**: it keeps its place and every setting, so
showing it again is exact and instant (no plasmashell restart).

## How it works

[Panel Colorizer](https://github.com/luisbocanegra/plasma-panel-colorizer) can hide
widgets on its panel (its *Hide widgets* page). Switchboard drives that setting live
through plasmashell's scripting D-Bus API (`org.kde.PlasmaShell.evaluateScript`).

**Requirement:** each panel whose widgets you want to hide needs a Panel Colorizer widget
on it. Panels without one are listed but can't be changed. Panel Colorizer shows hidden
widgets while the panel is in edit mode, which is its own behaviour.

## Panel popup

Click the eye icon: preset buttons on top (the active one is highlighted), **Show all**,
a field to save the current state as a new preset, then every widget grouped by panel
with a switch. The icon changes when anything is hidden.

## Terminal: `widgetctl`

The popup is a view over `package/contents/code/widgetctl` (Python 3, needs `qdbus6`).
Once the widget is installed, link it onto your PATH to use it directly or from shortcuts:

```bash
ln -s ~/.local/share/plasma/plasmoids/com.github.jesperdote.switchboard/contents/code/widgetctl ~/.local/bin/widgetctl

widgetctl list                 # every widget, its name, shown/hidden
widgetctl hide nba-scores claude-usage
widgetctl show nba-scores
widgetctl toggle cpu-ram
widgetctl show-all
widgetctl preset               # list presets; * marks the one in effect
widgetctl preset focus
widgetctl preset save evening  # save what's hidden now
widgetctl preset delete evening
```

Widget names come from the widget's title (`Command Output` widgets are named after their
command); a name used on two panels gets `-top` / `-bottom` added. The numeric widget id
works too.

Presets live in `~/.config/widgetctl/presets.json` (`{"name": {"hidden": [names]}}`),
created on first run with `full`, `focus` and `screen-share`. Edit it freely; names that
aren't on your panels are skipped with a note.

## Install

**From the KDE Store** (once it's listed): right-click the panel → **Add Widgets…** → **Get New Widgets…**
→ **Download New Plasma Widgets** and search for it.

**From a release:** download the `.plasmoid` file from the
[latest release](https://github.com/jesperdote/plasma-switchboard/releases/latest), then

```bash
kpackagetool6 -t Plasma/Applet -i com.github.jesperdote.switchboard.plasmoid      # first install
kpackagetool6 -t Plasma/Applet -u com.github.jesperdote.switchboard.plasmoid      # upgrade
```

**From source:**

```bash
git clone https://github.com/jesperdote/plasma-switchboard.git
kpackagetool6 -t Plasma/Applet -i plasma-switchboard/package
```

Then right-click the panel → **Add Widgets…** and search for it. Needs Plasma 6.

## License

[GPL-3.0-or-later](LICENSE).
