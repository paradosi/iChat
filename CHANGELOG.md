# iChat Changelog

## [1.4.2](https://github.com/paradosi/iChat/tree/1.4.2) (2026-02-24)

### Added

**Battle.net Integration**
- Full BNet (RealID) whisper support — send and receive whispers to/from Battle.net friends
- Smart display format: `BattleTag (CharacterName)` with BattleTag in Blizzard's cyan-blue and character name in class color
- Mixed conversation list — BNet and regular whispers appear together, sorted by activity
- Cross-game messaging — message friends playing Diablo 3, Hearthstone, Overwatch, StarCraft, etc.
- Game info display — header shows what game they're playing (e.g., "WoW: CharName (L60 Warrior)" or "Diablo 3")
- BNet chat filter — suppress BNet whispers from default chat frame (respects "Suppress whispers" setting)
- New modules: `bnet.lua` (BNet messaging & friend info), `playerinfo.lua` (class/race caching system)

**Titan Panel Integration**
- Native Titan Panel plugin with proper layout integration
- Left-click: toggle iChat window
- Right-click: shows Titan Panel context menu with "Toggle iChat Window" and "Settings..." options
- Bar display: unread count (e.g., `3`, `99+`) or empty when no unread messages
- Tooltip: shows unread count and usage hints
- Proper horizontal padding (no icon overlap)
- New module: `titanpanel.lua` (added to all three TOC files)

**Class-Colored Names**
- Player info caching system scans friend list, guild roster, and visible units
- Class colors persist even when players are offline or in different zones
- Works for both regular whispers and BNet WoW characters
- Toggle in Settings → Display → "Show class-colored names in conversation header"

### Fixed
- **Window fade behavior** — no longer fades while typing or actively using the window; only fades when mouse leaves AND input is not focused
- **Input focus clearing** — clicking outside the window now clears focus immediately (not after 1.5s fade delay)
- **Titan Panel duplicate registration** — removed conflicting LibDataBroker registration

### Changed
- **BNet visual language** — BNet conversations use Blizzard's signature cyan-blue color (RGB 0, 184, 255) throughout: conversation list names, header names, and chat bubbles
- **Compose button** — 43% larger (28×28 → 40×40) and 50% brighter for better visibility
- **Emoji button** — 33% larger (24×24 → 32×32) and 50% brighter for better visibility
- **Portrait system removed** — 3D portraits and race icons removed in favor of clean class-colored text
- Setting renamed: "Show 3D portrait" → "Show class-colored names in conversation header"

### Technical Notes
- BNet conversations stored as `BNet:12345` (where 12345 is bnetIDAccount)
- Player info cache stored in `SavedVariables` for persistence across sessions
- Titan Panel integration uses native API (not LDB auto-discovery) for proper layout participation
- Friend list and guild roster scanned on login and during `FRIENDLIST_UPDATE`/`GUILD_ROSTER_UPDATE` events

## [1.4.1](https://github.com/paradosi/iChat/tree/1.4.1) (2026-02-23)

### Changed
- **True head-and-shoulders portrait** — `SetCamera(1)` now applied after `SetUnit()` (deferred one frame via `C_Timer.After` so the model geometry is ready). This is the same portrait zoom WoW uses for character frames. Portrait frame is 46×50px with a slight vertical offset to crop cleanly within the 36px header.

## [1.4.0](https://github.com/paradosi/iChat/tree/1.4.0) (2026-02-23)

### Changed
- **Portrait logic extracted to `portraits.lua`** — `FindUnitByName`, `ns.CreatePortraitFrame`, and `ns.UpdatePortrait` now live in a dedicated module. `ui.lua` calls the library; no behavior change.

## [1.3.9](https://github.com/paradosi/iChat/tree/1.3.9) (2026-02-23)

### Fixed
- **Portrait missing on self-whisper** — `FindUnitByName` now checks `"player"` first, so whispering yourself correctly shows your own 3D portrait.

## [1.3.8](https://github.com/paradosi/iChat/tree/1.3.8) (2026-02-23)

### Added
- **3D portrait in conversation header** — when the selected conversation partner is your current target, focus, or party/raid member, their 3D character model appears in the header next to their name. Updates automatically when you switch conversations.
- **Portrait on/off toggle** — Settings → Display → "Show 3D portrait in conversation header" checkbox.

### Changed
- **Brighter floating button icon** — resting brightness raised from 100% → 150% (hover 130% → 200%). The button is now clearly visible without hovering.

## [1.3.7](https://github.com/paradosi/iChat/tree/1.3.7) (2026-02-23)

### Fixed
- **Addon list icon still white** — v1.3.6 used `minimap_icon.png` as source, which has a white opaque background baked in. Switched to `app_logo.png` (the actual addon icon) as source, scaled to 64×64 via ffmpeg. Icon now renders correctly in the addon list.

## [1.3.6](https://github.com/paradosi/iChat/tree/1.3.6) (2026-02-23)

### Fixed
- **Addon list icon white background** — replaced sips-converted TGA (which lost alpha) with a properly hand-crafted uncompressed BGRA TGA. Icon now shows correctly with transparency.

## [1.3.5](https://github.com/paradosi/iChat/tree/1.3.5) (2026-02-23)

### Fixed
- **Addon list icon missing** — added `icon.tga` (64×64 RGBA). WoW requires TGA/BLP for `## IconTexture`; the existing `icon.png` was silently ignored.

## [1.3.4](https://github.com/paradosi/iChat/tree/1.3.4) (2026-02-23)

### Fixed
- **Combat focus steal** — input box no longer auto-focuses when a DM arrives while the player is in combat (dungeon/raid). Uses `InCombatLockdown()` to detect combat state. Rotation keybinds will no longer accidentally type into the chat input.

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
