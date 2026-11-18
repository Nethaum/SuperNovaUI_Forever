local addonName, SN = ...

--[[
    The only Core file that differs from the Retail addon. Everything else in Core/ and Panel/ is shared: it is edited in
    the SuperNovaUI repository and copied here by tools/sync-shared.py.
]]

SN.config = {
    title = "SuperNovaUI Forever",
    family = "SuperNovaUI",       -- profiles exported by one addon can be imported by the other
    flavor = "forever",
    database = "SuperNovaUIForeverDB",
    characterDatabase = "SuperNovaUIForeverCharDB",
    compartmentFunction = nil,
    slashCommands = { "/snui", "/supernova" },
    icon = "Interface\\AddOns\\SuperNovaUI_Forever\\Media\\Icons\\SuperNovaUI",
    panelName = "SuperNovaUIForeverPanel",
    welcomeName = "SuperNovaUIForeverWelcome",
}

local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
SN.version = (getMetadata and getMetadata(addonName, "Version")) or "?"
