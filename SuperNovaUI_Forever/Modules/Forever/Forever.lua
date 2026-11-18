local addonName, SN = ...

--[[
    WoW Forever module. Structure only for now: a page that says so. Fixes for the game's own API differences and for
    other addons will be added here as modules, one file per feature, and listed in both .toc files.
]]

local ForeverModule = {}

ForeverModule.info = {
    category = "compat",
    kind = "core",
    order = 1,
    name = { enUS = "WoW Forever", ptBR = "WoW Forever" },
    desc = {
        enUS = "No fixes are needed yet. Fixes for the game and for other addons will show up here as modules you can turn on or off.",
        ptBR = "Ainda não há correções. As correções do jogo e de outros addons vão aparecer aqui como módulos que você pode ligar ou desligar.",
    },
}

function ForeverModule:Initialize()
end

SN:RegisterModule("forever", ForeverModule)
