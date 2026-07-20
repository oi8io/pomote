# Pomote

A quiet, native macOS menu bar focus timer for uninterrupted work and automatic breaks.

Pomote stays out of the way while you focus: focus sessions hide the countdown, cycles continue automatically, and reminders can be visual, silent notifications, or sound.

一个安静、原生的 macOS 菜单栏专注计时器。专注阶段隐藏倒计时，专注与休息自动循环，并支持视觉、无声通知和声音提醒。

## Features

- Native AppKit UI with a menu bar icon
- Automatic focus/break cycles
- Distraction-free focus state without a visible countdown
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
