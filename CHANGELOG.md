# iChat Changelog

## [1.3.3](https://github.com/paradosi/iChat/tree/1.3.3) (2026-02-22)

### Added
- **Invite to Group** button in conversation header (next to Add Friend / Block)
- **Invite to Group** option in right-click context menu
- Both call `InviteUnit()` on the active/selected conversation target

## [1.3.2](https://github.com/paradosi/iChat/tree/1.3.2) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.3.1...1.3.2)

### Bug Fixes
- Fix delivery status indicators showing boxes — replaced Unicode ✓/✗ with "Sent"/"Failed" text (WoW fonts lack Unicode support)

## [1.3.1](https://github.com/paradosi/iChat/tree/1.3.1) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.3.0...1.3.1)

### Bug Fixes
- Fix ElvUI skin crash on login — ElvUI color tables can be `{r=,g=,b=}` or `{[1],[2],[3]}` format
- Wrap ElvUI integration in pcall so failures print a warning instead of crashing iChat

## [1.3.0](https://github.com/paradosi/iChat/tree/1.3.0) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.2.4...1.3.0)

### New Features
- **Typing indicator**: Animated "typing..." in the conversation header when you're typing in the input box. Auto-clears after 2 seconds of inactivity. Toggle in Settings → Behavior.
- **Online/offline toast notifications**: Popup at top of screen when a friend you've chatted with comes online or goes offline. Class-colored names, click to open conversation. Auto-fades, queues multiple toasts. Toggle in Settings → Behavior.
- **Guild/party awareness**: Conversation header shows relationship tags — guild rank (green), party role with icon (blue), raid membership (orange). Updates on roster changes.
- **ElvUI theme integration**: Auto-detects ElvUI and matches backdrop, border, and accent colors. Only overrides font if you haven't explicitly chosen one. Toggle in Settings → Behavior.
- **WeakAuras integration**: 5 custom events for WeakAuras triggers:
  - `ICHAT_WHISPER_RECEIVED` (sender, text)
  - `ICHAT_WHISPER_SENT` (target, text)
  - `ICHAT_FRIEND_ONLINE` / `ICHAT_FRIEND_OFFLINE` (name)
  - `ICHAT_UNREAD_CHANGED` (total)

### New Files
- `typing.lua` — Typing indicator system
- `notifications.lua` — Online/offline toast notifications
- `social.lua` — Guild/party/raid relationship detection
- `elvui.lua` — ElvUI theme integration
- `weakauras.lua` — WeakAuras event bridge

## [1.2.4](https://github.com/paradosi/iChat/tree/1.2.4) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.2.3...1.2.4)

- Show version number in the main window title bar (reads from TOC metadata)

## [1.2.3](https://github.com/paradosi/iChat/tree/1.2.3) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.2.2...1.2.3)

### Improvements
- Settings font size slider now updates all text smoothly in-place (no more panel flash/rebuild)
- Tracks all FontStrings and EditBoxes for live resizing

## [1.2.2](https://github.com/paradosi/iChat/tree/1.2.2) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.2.1...1.2.2)

### New Features
- **Settings panel font size slider** (8–14px) — adjust the settings UI text size
- All settings elements (labels, checkboxes, sliders, dropdowns, buttons, edit boxes) respect the setting

## [1.2.1](https://github.com/paradosi/iChat/tree/1.2.1) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.2.0...1.2.1)

### New Features
- **Delivery status indicators**: Sent messages show "Sent" (gray) or "Failed" (red) beneath the bubble
  - Delivery confirmed via `CHAT_MSG_WHISPER_INFORM`
  - Failure detected via "No player named X" system messages
- **`/ichat export`**: Slash command to export current conversation to a copyable text frame
- **`/ichat version`**: Shows current version and storage mode (account-wide vs per-character)

### Improvements
- Version string now reads from TOC metadata at load time (no more hardcoded string)
- Updated `/ichat help` with all available commands

## [1.2.0](https://github.com/paradosi/iChat/tree/1.2.0) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.1.4...1.2.0)

### New Features
- **Account-wide shared conversations**: New toggle in Settings → Behavior
  - "Share conversations across characters" — off by default
  - When enabled, all characters on the account share one conversation history
  - Intelligently migrates existing per-character data when toggling on
  - Merges conversations, contact notes, pins, and muted contacts

### Technical
- Dual SavedVariables: `ICHAT_ACCOUNT` (account-wide) + `ICHAT_DATA` (per-character)
- `ns.SetSharedAccount()` handles live switching with full UI refresh

## [1.1.4](https://github.com/paradosi/iChat/tree/1.1.4) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.1.3...1.1.4)

### Improvements
- **Performance**: `AddBubble` tracks cumulative Y offset instead of recalculating by iterating all existing bubbles
- **Consistency**: Export conversation frame uses custom scroll (removed last Blizzard template dependency)
- Version bump across all TOC files

## [1.1.3](https://github.com/paradosi/iChat/tree/1.1.3) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.1.2...1.1.3)

- Fix version string mismatch (core.lua now matches TOC)
- Reduce friend list polling from 30s to 60s (less overhead)
- Future-proof InitDB with deep copy for nested table defaults

## [1.1.2](https://github.com/paradosi/iChat/tree/1.1.2) (2026-02-14)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.1.1...1.1.2) [Previous Releases](https://github.com/paradosi/iChat/releases)

- Add button size slider (24–64px) in Settings → Behavior
- ResizeButton() scales badge and font proportionally
- Replace shield icons with new gold-trimmed designs (blue Alliance / red Horde with "i")
- Source PNGs saved to media/art/
