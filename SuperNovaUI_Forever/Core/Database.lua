local addonName, SN = ...

local DEFAULT_DATABASE = {
    debug = false,
    modules = {},
}

local DEFAULT_CHARACTER_DATABASE = {
    modules = {},
}

local function CopyDefaults(defaults, target)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end

            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function SN:InitializeDatabase()
    SuperNovaUIForeverDB = SuperNovaUIForeverDB or {}
    SuperNovaUIForeverCharDB = SuperNovaUIForeverCharDB or {}

    CopyDefaults(DEFAULT_DATABASE, SuperNovaUIForeverDB)
    CopyDefaults(DEFAULT_CHARACTER_DATABASE, SuperNovaUIForeverCharDB)

    self.db = SuperNovaUIForeverDB
    self.charDB = SuperNovaUIForeverCharDB
end

-- Modules register their own defaults here before InitializeDatabase runs.
function SN:RegisterModuleDefaults(moduleName, accountDefaults, characterDefaults)
    DEFAULT_DATABASE.modules[moduleName] = accountDefaults or { enabled = true }
    DEFAULT_CHARACTER_DATABASE.modules[moduleName] = characterDefaults or {}
end

function SN:GetModuleSettings(moduleName)
    if not self.db or not self.db.modules then
        return nil
    end

    return self.db.modules[moduleName]
end

function SN:GetCharacterModuleSettings(moduleName)
    if not self.charDB or not self.charDB.modules then
        return nil
    end

    return self.charDB.modules[moduleName]
end
