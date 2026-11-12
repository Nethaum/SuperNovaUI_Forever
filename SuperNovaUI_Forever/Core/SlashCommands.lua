local addonName, SN = ...

local HELP_LINES = {
    "commands:",
    "/snui status - show SuperNovaUI status",
    "/snui reload - reload the UI",
}

-- Commands of the Retail-only modules, shown only on Retail.
local RETAIL_HELP_LINES = {
    "/snui reload - reload the UI",
}

-- Commands of the Retail-only modules, shown only on Retail.
local RETAIL_HELP_LINES = {
    "/snui compat - open the compatibility menu (addons that need a fix)",
    "/snui compat status - print the compatibility state in the chat",
    "/snui pgf - show the Premade Groups Filter tweak (Party Fit) state",
    "/snui rematch - show the Rematch fix (NPC names) state",
}

local function SplitCommand(message)
    local command, rest = string.match(message or "", "^(%S*)%s*(.-)$")
    return string.lower(command or ""), rest or ""
end

function SN:ShowHelp()
    for index, line in ipairs(HELP_LINES) do
        self:Print(line)

        if index == 2 and self.isRetail then
            for _, retailLine in ipairs(RETAIL_HELP_LINES) do
                self:Print(retailLine)
            end
        end
    end
end

function SN:ShowStatus()
    self:Print("SuperNovaUI status:")

    if #self.moduleOrder == 0 then
        self:Print("- no modules installed")
        return
    end

    for _, moduleName in ipairs(self.moduleOrder) do
        local settings = self:GetModuleSettings(moduleName)
        local enabled = settings and settings.enabled ~= false
        self:Print(string.format("- %s: %s", moduleName, enabled and "enabled" or "disabled"))
    end
end

function SN:HandleSlashCommand(message)
    local command, rest = SplitCommand(message)
    local module = self:GetModule(command)

    if module and module.HandleCommand then
        module:HandleCommand((SplitCommand(rest)))
    elseif command == "" or command == "help" then
        self:ShowHelp()
    elseif command == "status" then
        self:ShowStatus()
    elseif command == "reload" then
        ReloadUI()
    else
        self:Print("unknown command. Use /snui help.")
    end
end

function SN:RegisterSlashCommands()
    SLASH_SUPERNOVAUI1 = "/snui"
    SLASH_SUPERNOVAUI2 = "/supernova"

    SlashCmdList.SUPERNOVAUI = function(message)
        SN:HandleSlashCommand(message)
    end
end
