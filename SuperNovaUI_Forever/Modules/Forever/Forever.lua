local addonName, SN = ...

--[[
    WoW Forever module. Structure only for now: it registers, shows up in /snui status and does nothing else.
    Fixes for the game's own API differences and for other addons will be added here, one file per feature,
    and listed in SuperNovaUI_Camelot.toc.
]]

local ForeverModule = {}

function ForeverModule:Initialize()
end

SN:RegisterModuleDefaults("forever", { enabled = true })
SN:RegisterModule("forever", ForeverModule)
