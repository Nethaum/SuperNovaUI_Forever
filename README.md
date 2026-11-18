# SuperNovaUI Forever

SuperNovaUI for World of Warcraft: Forever (Interface 16001). It is a separate addon from the Retail one
(`SuperNovaUI`), with its own saved variables, so the two never share state.

Status: the options panel (`/snui`: modules by category, enable or disable all, profile export and import) and one
feature, **Macro by cooldown**. There are no fixes for other addons yet.

**Macro by cooldown** keeps one macro in step with a spell's cooldown: one text while the spell is ready, another while it
recharges, and it switches back by itself. Set it up in Tools > Macro by cooldown (spell, macro name, the two texts); the
**Fill with the druid example** button writes the racial "Sky Vision" while ready, and Cat Form plus Dash while it is on
cooldown. A macro can only change outside combat, so a change during a fight is applied when the fight ends. It does nothing
until a spell and both texts are set. For combat use, the page explains the two-fixed-macros alternative. The code is the same file as in the Retail addon (`Modules/CooldownMacro.lua`).

## Install

Copy both folders to `World of Warcraft/_forever_/Interface/AddOns/`:

- `SuperNovaUI_Forever/` - the addon.
- `!SuperNovaUI_Forever_Compat/` - loads first; will restore API functions the game lacks (empty for now).

## Commands

- `/snui` - open the options panel.
- `/snui status` - show the modules and whether they are enabled.
- `/snui macro` - show the state of the macro by cooldown.
- `/snui reload` - reload the UI.

## Layout

- `SuperNovaUI_Forever/Core/` - bootstrap, database, console, slash commands.
- `SuperNovaUI_Forever/Modules/Forever/` - the WoW Forever page (no fixes yet).
- `SuperNovaUI_Forever/Modules/CooldownMacro.lua` - Macro by cooldown (shared with Retail).
- Each `.toc` exists twice (plain and `_Camelot`) because the client picks one by suffix; keep them identical.

Build the zip with `python build/package.py` (writes `dist/SuperNovaUI-Forever-<version>.zip`).

The Retail addon lives in its own repository folder: `SuperNovaUI`. MIT license.
