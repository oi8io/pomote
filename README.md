# Pomote

[English](README.md) | [简体中文](README_zh-CN.md)

A quiet, native macOS menu bar focus timer for uninterrupted work and automatic breaks.

Pomote stays out of the way while you focus: the focus countdown stays inside the control panel and off the menu bar, cycles continue automatically, and reminders can be visual, silent notifications, or sound.

## Features

- Native AppKit UI with a menu bar icon
- Automatic focus/break cycles
- Focus countdown stays visible in the panel but hidden from the menu bar
- Direct duration input and steppers
- Visual, silent notification, and sound reminders
- Chinese and English interface
- Local settings persistence
- No third-party dependencies

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

## License

[MIT](LICENSE)
