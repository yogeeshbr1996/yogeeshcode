# YogeeshCode VS Code Extension

YogeeshCode integrates directly into your development workflow.
Forked from [OpenCode / sst/opencode](https://github.com/sst/opencode) - not built by, affiliated with, or endorsed by the OpenCode team.

## Prerequisites

This extension requires the YogeeshCode CLI (`yogeeshcode`) to be installed on your system. Legacy `opencode` CLI also works as fallback.

## Features

- **Quick Launch**: Use `Cmd+Esc` (Mac) or `Ctrl+Esc` (Windows/Linux) to open YogeeshCode in a split terminal view, or focus an existing terminal session if one is already running.
- **New Session**: Use `Cmd+Shift+Esc` (Mac) or `Ctrl+Shift+Esc` (Windows/Linux) to start a new YogeeshCode terminal session, even if one is already open. You can also click the YogeeshCode button in the UI.
- **Context Awareness**: Automatically share your current selection or tab with YogeeshCode.
- **File Reference Shortcuts**: Use `Cmd+Option+K` (Mac) or `Alt+Ctrl+K` (Linux/Windows) to insert file references. For example, `@File#L37-42`.

## Support

Forked from sst/opencode (MIT). If you encounter issues with YogeeshCode rebrand, please create an issue at https://github.com/yogeshext/opencode/issues.

## Development

1. `code sdks/vscode` - Open the `sdks/vscode` directory in VS Code. **Do not open from repo root.**
2. `bun install` - Run inside the `sdks/vscode` directory.
3. Press `F5` to start debugging - This launches a new VS Code window with the extension loaded.

#### Making Changes

`tsc` and `esbuild` watchers run automatically during debugging (visible in the Terminal tab). Changes to the extension are automatically rebuilt in the background.

To test your changes:

1. In the debug VS Code window, press `Cmd+Shift+P`
2. Search for `Developer: Reload Window`
3. Reload to see your changes without restarting the debug session
