# Pomote - macOS 菜单栏番茄钟

[English](README.md) | [简体中文](README_zh-CN.md)

一个安静、原生、开源的 macOS 菜单栏番茄钟（Pomodoro Timer）。

Pomote 是使用 AppKit 构建的轻量 macOS 番茄钟和专注计时器。它会在工作时保持低调：专注倒计时只显示在控制面板中，不占用菜单栏；专注与休息周期自动循环，并支持视觉提醒、无声系统通知和声音提醒。

## 下载

从 [GitHub Releases](https://github.com/oi8io/pomote/releases/latest) 下载最新 DMG，打开后将 Pomote 拖入“应用程序”文件夹。

Pomote 当前使用临时签名，尚未经过 Apple 公证。首次启动时，macOS 可能要求你在“系统设置 > 隐私与安全性”中确认打开。

## 功能

- 原生 AppKit 界面和菜单栏图标
- 番茄钟专注与休息周期自动循环
- 专注倒计时显示在面板中，但不显示在菜单栏
- 支持直接输入时长和步进调节
- 支持视觉、无声通知和声音提醒
- 支持中文和英文界面
- 设置保存在本地
- 无第三方依赖
- 同时支持 Apple 芯片和 Intel Mac

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

创建可分发的 DMG：

```bash
./build-dmg.sh
```

## 许可证

[MIT](LICENSE)
