# CLAUDE.md — iChat

> **Last Updated:** 2026-04-02
> **Global rules at ~/.claude/CLAUDE.md apply automatically.** This file adds project-specific context only.

## Project Overview

| Field | Value |
|-------|-------|
| Name | iChat |
| GitLab URL | `http://10.10.10.218/jim/iChat` |
| GitHub Mirror | `github.com/paradosi/iChat` (push mirror from GitLab) |
| Stack | Lua, WoW API, Ace3 (AceAddon, AceDB, AceConfig, AceEvent, AceGUI, AceTimer) |
| Deployed At | CurseForge, Wago, WoWInterface |
| Obsidian Page | `[[iChat]]` |
| Status | Active |
| Clients | Retail, Classic Era, TBC Anniversary |
| Author | paradosi (paradosi@dreamscythe) |
| Version | 1.4.8 |

iMessage-style whisper client for World of Warcraft. Replaces the default whisper system with chat bubbles, conversation threads, emoji, notification sounds, and more.

## Project-Specific Context

- No AI attribution anywhere — code is authored by paradosi, full stop
- Test with BugGrabber + BugSack in-game for runtime Lua errors
- Run Luacheck on all `.lua` files before committing
- Uses `.pkgmeta` for CurseForge/Wago packaging
- GitHub Actions workflow handles releases (`.github/workflows/release.yml`)

## Related Obsidian Pages

- `[[iChat]]`
- `[[WoW-Addons]]`
