# iChat

## [1.2.1](https://github.com/paradosi/iChat/tree/1.2.1) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.2.0...1.2.1)

### New Features
- **Delivery status indicators**: Sent messages now show ✓ (delivered) or ✗ Failed (red) beneath the bubble
  - Triggered by `CHAT_MSG_WHISPER_INFORM` for delivery confirmation
  - Detects "No player named X" system messages to mark failures
- **`/ichat export`**: Slash command to export current conversation to a copyable text frame
- **`/ichat version`**: Shows current version and storage mode (account-wide vs per-character)

### Improvements
- Version string now reads from TOC metadata at load time (no more hardcoded string to maintain)
- Updated help text with all available commands

## [1.2.0](https://github.com/paradosi/iChat/tree/1.2.0) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.1.4...1.2.0)

### New Features
- **Account-wide shared conversations**: New toggle in Settings > Behavior
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
- **Consistency**: Export conversation frame uses custom scroll (removed `UIPanelScrollFrameTemplate` — only Blizzard template in the addon)
- Version bump across all TOC files

## [1.1.3](https://github.com/paradosi/iChat/tree/1.1.3) (2026-02-15)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.1.2...1.1.3)

- Fix version string mismatch (core.lua now matches TOC)
- Reduce friend list polling from 30s to 60s (less overhead)
- Future-proof InitDB with deep copy for nested table defaults

## [1.1.2](https://github.com/paradosi/iChat/tree/1.1.2) (2026-02-14)
[Full Changelog](https://github.com/paradosi/iChat/compare/1.1.1...1.1.2) [Previous Releases](https://github.com/paradosi/iChat/releases)

- Bump version to 1.1.2
- Add button size slider and update shield icons
    - Add buttonSize setting (24-64px) with slider in Settings > Behavior
    - ResizeButton() scales badge and font proportionally
    - Replace shield icons with new gold-trimmed designs (blue/red with "i")
    - Source PNGs saved to media/art/
