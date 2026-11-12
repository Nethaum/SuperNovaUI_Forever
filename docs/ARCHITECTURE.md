# Architecture

Same shape as the Retail addon, kept small:

- The addon namespace table (`local addonName, SN = ...`) is the public project table.
- Modules register with `SN:RegisterModule(name, module)` and `SN:RegisterModuleDefaults(name, defaults)`.
- The bootstrap initializes the database, registers `/snui`, then initializes modules in registration order.
- Account options live in `SuperNovaUIForeverDB`, character options in `SuperNovaUIForeverCharDB` (different from the Retail
  addon's variables on purpose).
- One module owns one feature; add each new file to both `.toc` files.
