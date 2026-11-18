# Architecture

`Core/` (except `Config.lua`) and `Panel/` are copied from the Retail repository by its `tools/sync-shared.py`: do not edit them here.
Run the tests from the Retail repository: `python tests/run_tests.py <this addon folder>`.

Same shape as the Retail addon, kept small:

- The addon namespace table (`local addonName, SN = ...`) is the public project table.
- Modules register with `SN:RegisterModule(name, module)` and `SN:RegisterModuleDefaults(name, defaults)`.
- The bootstrap initializes the database, registers `/snui`, then initializes modules in registration order.
- Account options live in `SuperNovaUIForeverDB`, character options in `SuperNovaUIForeverCharDB` (different from the Retail
  addon's variables on purpose).
- One module owns one feature; add each new file to both `.toc` files.
- `Modules/CooldownMacro.lua` is copied from the Retail repository too (see its `docs/ARCHITECTURE.md`): do not edit it here.
