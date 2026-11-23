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
- `Modules/CooldownMacro.lua` and `Modules/Exploration.lua` are copied from the Retail repository too (see its `docs/ARCHITECTURE.md`, which also explains how modules that are useless or conflict start off): do not edit them here.
- `Data/Exploration.lua` is generated for this client (1.60.1) by the Retail repository's `tools/gen-exploration.py`.
- `Modules/Forever/Convergence.lua` (Elemental Convergence markers) exists only here. Its positions, `Data/Convergence.lua`, were copied from the Wowhead page of the object (616992) because the client tables do not hold them; it starts on only for a Windshaper Skyborne (race 96, or anyone who knows Skysight). When the addon Skyborne Leyline & Convergence Marker (folder `SkyborneLeyLineConvergenceMarker`, an optional dependency in the toc) is installed, the module reads its list through the public `SLLCM_GetNodes("Horde")` (kept until the next refresh) and falls back to our own for zones it lacks; it also declares it in `conflictsWith`, so it starts off next to it.
