# iChat

An iMessage-style whisper client for World of Warcraft — TBC Classic Anniversary (Interface 20505).

Replace the default whisper system with a modern messaging UI featuring chat bubbles, conversation threads, emoji, notification sounds, and more.

![Interface: 20505](https://img.shields.io/badge/Interface-20505-blue) ![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-green)

## Features

### Conversation UI
- **iMessage-style chat bubbles** with rounded corners (9-slice pill textures)
- **Conversation list** on the left panel, sorted by most recent activity
- **Unread badges** on conversations with new messages
- **Message previews** in the conversation list
- **Relative timestamps** (now, 5m, 2h, etc.)
- **Resizable window** (350x400 to 700x800) with drag-to-move
- **Minimize to title bar** with the `-` button
- **ESC to close** — registered with the UI special frames system

### Bubble Colors
- **Blue (right-aligned)** — your sent messages
- **Blue (left-aligned, lighter)** — incoming from friends
- **Green (left-aligned)** — incoming from non-friends

### Compose & Quick Reply
- **Compose button** — start a new conversation with any player
- **5 configurable quick reply buttons** — set your own canned responses (afk, brb, etc.)
- **Send via Enter key** or the send button

### Emoji
- **75+ bundled emoji** from Google's Noto Emoji — type `:shortcode:` to use (e.g. `:thumbsup:`, `:fire:`, `:heart:`)
- **Emoji picker button** next to the input box — click to browse and insert emoji
- **`/ichat emoji`** — prints all available emoji with previews to chat
- **Emoji-Core support** (optional) — if the Emoji-Core addon is installed, its emoji and autocomplete work alongside the built-in set

### Notification Sounds
- **3 built-in notification sounds** — Glass, Tritone, Chime
- **LibSharedMedia support** — any sounds registered by other addons (ElvUI, SharedMedia packs, etc.) appear as additional options
- **Taskbar flash** — the Windows taskbar icon flashes on incoming whisper when you're AFK

### Settings Panel
- **Font selection dropdown** — 6 built-in WoW fonts, plus all LibSharedMedia fonts if available
- **Font size slider** (8–16)
- **Background opacity slider** (30%–100%)
- **Message history slider** (50–500 messages per conversation)
- **Open on incoming whisper** toggle
- **Suppress default chat whispers** toggle — hides whispers from the default chat frame while iChat is open
- **Quick reply editor** — configure up to 5 quick reply messages
- **Export conversation** — copy conversation history as plain text
- **Clear history** — per-conversation or all conversations (with confirmation)

### Friend & Block Management
- **Add Friend / Block buttons** in the conversation header
- Button states update automatically based on your friend and ignore lists

### Auto-Fade
- Window fades to 25% opacity after 1.5 seconds when the mouse leaves
- Instantly restores on hover or incoming whisper
- Fade is disabled while the settings panel or emoji picker is open

### LibSharedMedia Integration
- Optional dependency — works without it, enhanced with it
- When [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) is available (bundled with ElvUI, etc.), all registered fonts and sounds appear in iChat's settings dropdowns

## Installation

1. Download and extract to your AddOns folder:
   ```
   World of Warcraft/_anniversary_/Interface/AddOns/iChat/
   ```
2. Ensure the folder structure looks like:
   ```
   iChat/
   ├── iChat.toc
   ├── core.lua
   ├── config.lua
   ├── messages.lua
   ├── emoji.lua
   ├── ui.lua
   ├── bubbles.lua
   ├── settings.lua
   └── media/
       ├── emoji/       (75 .png files)
       ├── sounds/      (glass.ogg, tritone.ogg, chime.ogg)
       └── textures/    (pill.tga, etc.)
   ```
3. Restart WoW or `/reload` if already in-game.

## Usage

| Command | Action |
|---------|--------|
| `/ichat` | Toggle the iChat window |
| `/ichat clear` | Clear the active conversation's history |
| `/ichat scale <n>` | Set window scale (0.5–2.0) |
| `/ichat emoji` | Print all available emoji shortcodes to chat |

### Sending Messages
- Click a conversation on the left, or use the compose button (chat bubble icon) to start a new one
- Type in the input box and press **Enter** to send
- Click the smiley button to open the emoji picker
- Use quick reply buttons for canned responses

### Emoji Shortcodes
Type `:name:` in your message — it renders as an inline icon in the chat bubble.

**Smileys:** `:grin:` `:smile:` `:laughing:` `:joy:` `:wink:` `:heart_eyes:` `:sunglasses:` `:thinking:` `:cry:` `:angry:` `:skull:` `:party:` and more

**Gestures:** `:thumbsup:` `:thumbsdown:` `:wave:` `:pray:` `:muscle:` `:clap:` `:ok_hand:`

**Symbols:** `:heart:` `:fire:` `:star:` `:100:` `:check:` `:x:` `:sparkles:` `:boom:` `:eyes:`

**Objects:** `:swords:` `:shield:` `:trophy:` `:crown:` `:gem:` `:beer:` `:dragon:` `:ghost:` `:rocket:`

## Saved Variables

iChat stores data per-character in `ICHAT_DATA`:
- **Conversation history** — messages, timestamps, read state
- **Settings** — font, font size, opacity, sound, quick replies, toggles

Data persists across sessions. Use `/ichat clear` or the settings panel to manage history.

## Optional Dependencies

| Addon | What it adds |
|-------|-------------|
| [Emoji-Core](https://github.com/KittenBall/Emoji-Core) | Unicode emoji autocomplete in the input box, additional emoji rendering |
| [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) | Extra fonts and sounds from other addons appear in settings |

## Compatibility

- **WoW Version:** TBC Classic Anniversary (Interface 20505)
- **Client Engine:** Modern (uses `C_FriendList`, `C_Timer`, `C_ChatInfo`, `BackdropTemplate`)
- **Conflicts:** If using WIM (WoW Instant Messenger), consider disabling iChat's "Suppress default chat whispers" to avoid double-suppression

## Credits

- **Author:** paradosi (Dreamscythe)
- **Emoji:** [Google Noto Emoji](https://github.com/googlefonts/noto-emoji) (Apache 2.0 License)
- **Emoji Integration:** [Emoji-Core](https://github.com/KittenBall/Emoji-Core) by KittenBall — optional emoji autocomplete and rendering library
