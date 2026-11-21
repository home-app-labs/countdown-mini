# Countdown Mini

Desktop widgets that count down the days to your events.

Add an event, give it a date, a colour and an icon, and put it on the desktop. The widget shows the days left and a bar that drains as the day comes closer.

**[Download the installer](https://github.com/home-app-labs/countdown-mini/releases/latest/download/Countdown-Mini.pkg)** · [Website](https://homeapplabs.com/countdown-mini/) · macOS 14 or later · free

## What it does

- **One widget, three sizes.** Small shows one event, medium two side by side, large three. With one or two events the large widget gives each of them more room.
- **Each widget has its own events.** Right-click a widget → **Edit Widget** and pick Event 1, 2 and 3. Places you leave empty take the next events from your list.
- **Click to edit.** A click on a widget opens the app on its first event.
- **Days your way.** Count every day or only working days (Monday to Friday), with or without today.
- **A bar of the time left.** It is drawn on a scale you choose (7, 30 or 90 days, or a year), so 19 days looks different from 7.
- **The last day.** Less than 24 hours before a timed event the widget becomes a ticking timer. On the day it says "Today", afterwards "N days ago".
- **Backgrounds.** 20 gradients, two colours of your own, or a picture from your Mac.
- **Icons.** 70 symbols, or any emoji.
- **Explicit saving.** Edits reach the widgets when you press **Save** (⌘S). Switching between events in the app never changes a widget.

## Install

1. Download [Countdown-Mini.pkg](https://github.com/home-app-labs/countdown-mini/releases/latest/download/Countdown-Mini.pkg) and open it.
2. The app is not signed with a paid Apple developer certificate, so macOS blocks the installer the first time. Open **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
3. Follow the installer. It copies Countdown Mini to your Applications folder and opens it.

There is a step by step guide with pictures on the [website](https://homeapplabs.com/install/).
Prefer to move the app yourself? Take `Countdown-Mini.zip` from the [latest release](https://github.com/home-app-labs/countdown-mini/releases/latest).

## Add the widget

Right-click the desktop → **Edit Widgets** → search for **Countdown Mini** → pick a size and drag it onto the desktop. Open the app once first, so macOS knows about the widget.

## Good to know

- A widget remembers its events by name. After you rename an event the widget stays with it, but **Edit Widget** still shows the old name in its list.
- When an event is deleted, widgets that showed it say "Event deleted" until you pick another.
- While a window is in front, macOS fades desktop widgets. That is the system's doing and applies to every widget.

## Build from source

You need Xcode 15 or later.

    git clone https://github.com/home-app-labs/countdown-mini.git
    cd countdown-mini
    ./build.sh --install --run

`./build.sh` builds `build/Countdown Mini.app`, `--install` copies it to `/Applications`, `--run` opens it. Run the tests with `swift test`.

Unlike the other Home App Labs apps this one is built from an Xcode project: a widget with settings needs Xcode's App Intents build step, which a plain Swift package does not run. `Package.swift` is there for the tests.

Keep one copy of the app on the Mac. With a second copy (for example in `build/`) macOS mixes the two up and stops updating the widget, so `--install` removes the build copy.

## Layout

| Path | What is there |
| --- | --- |
| `App/CountdownMiniApp.swift` | The window: the list of events, the editor, saving |
| `Widget/CountdownMiniWidget.swift` | The widget: its settings, timeline and sizes |
| `Shared/CountdownEvent.swift` | The event, counting days, the file on disk. Used by the app and the widget |
| `Shared/CountdownCard.swift` | Everything a widget draws |
| `Config` | Info.plist additions and the widget's entitlements |
| `Tests` | Unit tests for counting, the bar, and matching widgets to events |
| `scripts` | Icon drawing and the release script |

## Where your data lives

| What | Where |
| --- | --- |
| Events | `~/Library/Application Support/Countdown Mini/events.json` |
| Background pictures | `~/Library/Application Support/Countdown Mini/images/`, scaled-down copies |

The app writes the file and asks the widget to reload. The widget is sandboxed, as macOS requires, and may only read that one folder (`Config/Widget.entitlements`). Nothing leaves your Mac: the app does not use the network.

## Why the widget chooses events by name

The usual way to offer a list in a widget's settings is an "app entity". With ad hoc signing macOS does not register it and the widget receives nothing, so the settings are plain names instead. To survive renames the app keeps each event's earlier names (`aliases` in the file).

## Releasing

1. Put the new version number into `VERSION` and describe the changes in `release-notes/<version>.md`.
2. Commit.
3. Run `./scripts/release.sh --publish`. It builds a universal app, the installer and the zip, tags the commit and creates the GitHub release with the files attached.

The download links above always point at the latest release.

## Made with AI

Countdown Mini is built by [Home App Labs](https://homeapplabs.com): one person with an idea, and an AI coding assistant doing the typing. Every line is here to read. Fork it and make it yours.

## License

[MIT](LICENSE)
