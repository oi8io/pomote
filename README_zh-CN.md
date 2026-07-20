# Pomote

[English](README.md) | [简体中文](README_zh-CN.md)

一个安静、原生的 macOS 菜单栏专注计时器，用于持续专注和自动休息。

Pomote 会在你专注时保持低调：专注阶段隐藏倒计时，专注与休息周期自动循环，并支持视觉提醒、无声系统通知和声音提醒。

## 功能

- 原生 AppKit 界面和菜单栏图标
- 专注与休息自动循环
- 专注阶段不显示倒计时，减少干扰
- 支持直接输入时长和步进调节
- 支持视觉、无声通知和声音提醒
- 支持中文和英文界面
- 设置保存在本地
- 无第三方依赖

## 系统要求

- macOS 13 或更高版本
- Xcode Command Line Tools

## 构建

```bash
chmod +x build-app.sh
./build-app.sh
open dist/Pomote.app
```

生成的应用位于 `dist/Pomote.app`。Pomote 是菜单栏应用，不会显示在 Dock 中。

## 许可证

[MIT](LICENSE)
