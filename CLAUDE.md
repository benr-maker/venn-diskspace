# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**venn_diskspace** is a Tauri v2 desktop app that visualizes disk usage as an interactive circle-packing diagram using D3.js v7. The Rust backend scans the filesystem; the HTML/JS frontend renders it in a native webview.

## Prerequisites

- Rust (stable) via `rustup`
- Node.js 20+
- On Linux: `libwebkit2gtk-4.1-dev`, `libappindicator3-dev`, `librsvg2-dev`, `patchelf`

## Common Commands

```bash
make setup              # Install npm deps + macOS universal Rust targets
make dev                # Dev mode with hot-reload (npm run tauri dev)
make build              # Release build for current platform
make build-mac-universal  # macOS universal binary (arm64 + x86_64)
make clean              # Remove src-tauri/target and node_modules
```

Direct equivalents if make is unavailable:
```bash
npm run tauri dev
npm run tauri build
npm run tauri build -- --target universal-apple-darwin
```

## Architecture

```
src/                        # Frontend (served as static files by Tauri webview)
├── index.html              # Full UI: D3.js circle-pack + Tauri IPC calls
└── d3.v7.min.js            # D3.js bundled locally

src-tauri/                  # Rust backend
├── src/
│   ├── main.rs             # Tauri app entry; registers scan_directory command
│   └── scanner.rs          # Filesystem scanner (port of original Python logic)
├── icons/                  # App icons: .icns (macOS), .ico (Windows), PNGs (Linux)
├── Cargo.toml
├── build.rs
└── tauri.conf.json         # Window config, bundle targets, icon list
```

**IPC:** The frontend calls `window.__TAURI__.core.invoke("scan_directory", { path })` (enabled by `withGlobalTauri: true` in `tauri.conf.json`). The command returns a `DirNode` tree directly, or rejects the Promise with an error string.

**Scanner (`scanner.rs`):** Mirrors the Python original — recursive walk, depth-capped at 20, skips cross-filesystem directories (Unix only via `st_dev`), gracefully handles `PermissionDenied`.

**Data shape:** `{ name, size, files, children[], skipped? }` — identical to the previous Flask version.

## CI / Releases

`.github/workflows/build.yml` runs on version tags (`v*`) across three runners:
- `macos-latest` → universal binary (`--target universal-apple-darwin`)
- `ubuntu-22.04` → Linux x86_64
- `windows-latest` → Windows x86_64

Push a tag to trigger a draft GitHub Release with all three installers attached.

## Icons

All icon files live in `src-tauri/icons/`. The source is `icon.icns` (from `MyIcon.icns`). The `.ico` and PNG variants were generated from it. To regenerate after changing the icon, replace `icon.icns` and re-run the extraction commands, or use `npm run tauri icon <source.png>` with a 1024×1024 PNG.
