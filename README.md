# RoboGUI
A lightweight, native Windows Explorer context menu extension for high-speed, multi-threaded file transfers via Robocopy.

## Overview

This utility integrates seamlessly into the Windows Explorer right-click menu, offering a high-performance alternative to default file copy operations. By leveraging multi-threading (`/MT:32`) and unbuffered I/O (`/J`), it optimizes throughput for large transfers while maintaining a minimal footprint with zero external dependencies.

## Features

* **Context Menu Integration:** Adds a **"Paste (Robocopy)"** option to both empty space (background) and direct item/drive right-click menus.
* **High-Performance Transfers:** Utilizes optimized `robocopy` parameters like `/MT` and `/J` and for maximum read/write efficiency.
* **Intelligent Handling:** Automatically detects same-directory paste actions to perform standard duplication, routing inter-directory transfers through Robocopy.
* **Real-Time Metrics:** Displays live progress tracking alongside rounded MB/s speed metrics.
* **Transparent Execution:** Pure PowerShell implementation with local user registry (`HKCU`) deployment and no background services.

## Installation

1. Clone or download this repository and place `Robo.ps1` in your target local directory.
2. Open PowerShell and execute the installer switch:
   ```powershell
   .\Robo.ps1 -Install
(This registers the context menu handlers, deploys the local helper script, and restarts Windows Explorer).

## Uninstallation
To completely remove the context menu integration and clean up associated local files, run:
```powershell
.\Robo.ps1 -Remove
```
## Maintenance & Support
Status: This repository is provided as-is as a completed, standalone utility. Active maintenance, feature updates, and issue tracking are not provided. Users are free to fork, adapt, or modify the source code for their own requirements.

## License
Distributed under the MIT License. See LICENSE for more information.
