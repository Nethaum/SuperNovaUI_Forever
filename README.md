# SuperNovaUI Forever

SuperNovaUI for World of Warcraft: Forever (Interface 16001). It is a separate addon from the Retail one
(`SuperNovaUI`), with its own saved variables, so the two never share state.

Status: structure only. The core (bootstrap, database, console, `/snui` commands) and an empty `forever` module are in
place; there are no features and no fixes for other addons yet.

## Install

Copy both folders to `World of Warcraft/_forever_/Interface/AddOns/`:

- `SuperNovaUI_Forever/` - the addon.
- `!SuperNovaUI_Forever_Compat/` - loads first; will restore API functions the game lacks (empty for now).

## Commands

- `/snui status` - show the modules and whether they are enabled.
- `/snui reload` - reload the UI.

## Layout

- `SuperNovaUI_Forever/Core/` - bootstrap, database, console, slash commands.
- `SuperNovaUI_Forever/Modules/Forever/` - the WoW Forever module (empty).
- Each `.toc` exists twice (plain and `_Camelot`) because the client picks one by suffix; keep them identical.

Build the zip with `python build/package.py` (writes `dist/SuperNovaUI-Forever-<version>.zip`).

The Retail addon lives in its own repository folder: `SuperNovaUI`. MIT license.
