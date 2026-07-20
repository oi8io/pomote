# Pomote - Pomodoro Timer for macOS

[English](README.md) | [简体中文](README_zh-CN.md)

A quiet, native, open-source Pomodoro timer for the macOS menu bar.

Pomote is a lightweight macOS Pomodoro timer and focus timer built with AppKit. It stays out of the way while you work: the focus countdown remains inside the control panel and off the menu bar, focus and break cycles continue automatically, and reminders can be visual, silent notifications, or sound.

## Download

Download the latest DMG from [GitHub Releases](https://github.com/oi8io/pomote/releases/latest), open it, and drag Pomote into Applications.

Pomote is currently ad-hoc signed and not notarized. On first launch, macOS may ask you to confirm opening the app in System Settings > Privacy & Security.

## Features

- Native AppKit UI with a menu bar icon
- Automatic Pomodoro focus/break cycles
- Focus countdown stays visible in the panel but hidden from the menu bar
- Direct duration input and steppers
- Visual, silent notification, and sound reminders
- Chinese and English interface
- Local settings persistence
- No third-party dependencies
- Universal binary for Apple Silicon and Intel Macs

## Requirements

- macOS 13 or later
- Xcode Command Line Tools

## Build

```bash
chmod +x build-app.sh
./build-app.sh
open dist/Pomote.app
```

The generated app is written to `dist/Pomote.app`. Pomote runs as a menu bar app and does not appear in the Dock.

To create a distributable DMG:

```bash
./build-dmg.sh
```

## License

[MIT](LICENSE)
