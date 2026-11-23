local addonName, SN = ...

--[[
    Profession goal: what is saved.

    The goals, the highest level seen of each profession and the recipes the character knows are kept per profession under its
    id ("cooking"), never its translated name, so a change of the game's language loses nothing. This file also creates the
    module table that the other Goal files add to.
]]

local Goals = {
    running = false,
    frame = nil,
}

SN.ProfessionGoal = Goals

local function L(enUS, ptBR)
    return SN:Loc({ enUS = enUS, ptBR = ptBR })
end

local function Clean(text)
    return (tostring(text or ""):gsub("[\r\n]", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

Goals.L, Goals.Clean = L, Clean

function Goals:GetGoals()
    local settings = SN:GetModuleSettings(self.name)

    if not settings then
        return {}
    end

    settings.goals = type(settings.goals) == "table" and settings.goals or {}
    settings.seen = type(settings.seen) == "table" and settings.seen or {}
    return settings.goals
end

function Goals:GetSeen()
    self:GetGoals()
    local settings = SN:GetModuleSettings(self.name)
    return settings and settings.seen or {}
end

function Goals:HasGoal()
    for _, goal in pairs(self:GetGoals()) do
        if type(goal) == "table" and tonumber(goal.level) then
            return true
        end
    end

    return false
end

-- The game's skill line of each profession is the same in every language; the recipe data is named in English. The line
-- of each profession the player has is kept so a profession is matched to its data by line, not by its translated name.
local LINE_TO_ID = {
    [171] = "alchemy", [164] = "blacksmithing", [185] = "cooking", [333] = "enchanting", [202] = "engineering",
    [129] = "firstaid", [165] = "leatherworking", [197] = "tailoring", [356] = "fishing",
}

-- Everything the module saves about a profession (goal, level seen, known recipes) is kept under the profession's id
-- ("cooking"), never its translated name, so a change of the game's language loses nothing. A profession whose line is not
-- known keeps its name as the key, and is moved to its id the moment its line is seen.
local SAVED_PER_PROFESSION = { "goals", "seen", "knownRecipes" }

function Goals:MoveKey(from, to)
    local settings = SN:GetModuleSettings(self.name)

    if not settings or from == to then
        return
    end

    for _, field in ipairs(SAVED_PER_PROFESSION) do
        local saved = settings[field]

        if type(saved) == "table" and saved[from] ~= nil then
            if saved[to] == nil then
                saved[to] = saved[from]
            end

            saved[from] = nil
        end
    end
end

function Goals:RememberLine(name, skillLine)
    local settings = SN:GetModuleSettings(self.name)
    local id = LINE_TO_ID[tonumber(skillLine)]

    if settings and id then
        settings.lines = type(settings.lines) == "table" and settings.lines or {}
        settings.names = type(settings.names) == "table" and settings.names or {}
        settings.lines[name] = id
        settings.names[id] = name
        self:MoveKey(name, id)
    end
end

-- The data id ("cooking") of a profession by the name the player sees; nil when its line was never seen.
function Goals:DataId(profession)
    local settings = SN:GetModuleSettings(self.name)
    return settings and type(settings.lines) == "table" and settings.lines[profession] or nil
end

-- The key everything is saved under: the id when the line is known, else the name.
function Goals:KeyOf(profession)
    profession = Clean(profession)
    return self:DataId(profession) or profession
end

-- The name to show for a saved key, in the language the game is in now.
function Goals:NameOf(key)
    local settings = SN:GetModuleSettings(self.name)
    return settings and type(settings.names) == "table" and settings.names[key] or key
end

-- Vendor prices the player saw: { [itemID] = copper for one }, kept in the saved settings.
function Goals:GetVendorSeen()
    local settings = SN:GetModuleSettings(self.name)

    if not settings then
        return {}
    end

    settings.vendorSeen = type(settings.vendorSeen) == "table" and settings.vendorSeen or {}
    return settings.vendorSeen
end

-- The recipes saved as known for a profession: { [spellId or lowercase name] = true }.
function Goals:GetKnownRecipes(profession)
    local settings = SN:GetModuleSettings(self.name)
    local saved = settings and settings.knownRecipes
    return type(saved) == "table" and saved[self:KeyOf(profession)] or {}
end

-- The recipes the character knows, kept per profession by spell id (a name only where the game gives no id, as in the old
-- window); the profession window is the only place that lists them.
function Goals:RememberKnownRecipes(profession)
    local settings = SN:GetModuleSettings(self.name)

    if not settings then
        return
    end

    local recipes = self:ReadRecipes()

    if #recipes == 0 then
        return
    end

    settings.knownRecipes = type(settings.knownRecipes) == "table" and settings.knownRecipes or {}
    local names = {}

    for _, recipe in ipairs(recipes) do
        if recipe.id then
            names[recipe.id] = true
        else
            names[string.lower(recipe.name)] = true
        end
    end

    settings.knownRecipes[self:KeyOf(profession)] = names
end
