local addonName, SN = ...

--[[
    Elemental Convergence markers (WoW Forever only).

    The Windshaper Skyborne racial, Skysight, draws power from an elemental convergence: next to one it gives a bigger
    bonus. Where they are is not in the game's client tables, so SN.ConvergenceData (Data/Convergence.lua) holds the
    positions of every convergence of every zone, taken from the Wowhead page of the object.

    The world map markers are small frames on the map's canvas. The minimap markers are placed from the distance to the
    player in yards, the same way the exploration markers are (see Modules/Exploration.lua), and the minimap is looked at
    every frame, and a look where nothing moved costs only a few comparisons.
]]

local Convergence = {
    running = false,
    worldPins = {},
    minimapPins = {},
}

local WINDSHAPER_RACE_ID = 96      -- "Windshaper Skyborne" in the game's ChrRaces table
local SKYSIGHT_SPELL_ID = 1259686  -- the racial that benefits from a convergence
local ICON = (SN.config.icon:gsub("SuperNovaUI$", "Convergence")) -- Media/Icons/Convergence.tga: a small wind swirl
local WORLD_PIN_SIZE, MINIMAP_PIN_SIZE = 13, 10
local MINIMAP_STEP = 0 -- every frame, so the markers move smoothly with the minimap
local MAP_EVENTS = { "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "PLAYER_LOGIN", "ADDON_LOADED" }

local function L(enUS, ptBR)
    return SN:Loc({ enUS = enUS, ptBR = ptBR })
end

local function Plain(value)
    if type(value) ~= "number" then
        return nil
    end

    if issecretvalue and issecretvalue(value) then
        return nil
    end

    return value
end

function Convergence:IsSupported()
    return SN.ConvergenceData ~= nil
        and C_Map ~= nil and C_Map.GetBestMapForUnit ~= nil and C_Map.GetPlayerMapPosition ~= nil
end

-- A Windshaper Skyborne, or anyone who knows Skysight.
function Convergence:IsWindshaper()
    if UnitRace then
        local _, _, raceID = UnitRace("player")

        if raceID == WINDSHAPER_RACE_ID then
            return true
        end
    end

    local known = IsPlayerSpell and IsPlayerSpell(SKYSIGHT_SPELL_ID)
    return known and true or false
end

function Convergence:GetSetting(key)
    return SN:GetOption(self.name, key)
end

-- Number of points, from the flat list { x1, y1, x2, y2, ... } of a zone.
local function CountPoints(list)
    return list and math.floor(#list / 2) or 0
end

local function NewPin(parent, size, interactive)
    local pin = CreateFrame("Frame", nil, parent)
    pin:SetSize(size, size)
    pin:SetFrameLevel(parent:GetFrameLevel() + 20)
    pin:EnableMouse(interactive and true or false)

    if interactive then
        -- on the world map a marker at the map's own strata is drawn under its art; one step up the map keeps it above
        pin:SetFrameStrata("FULLSCREEN")
    end

    local icon = pin:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    icon:SetTexture(ICON)
    pin.icon = icon

    if interactive then
        pin:SetScript("OnEnter", function(self)
            if not GameTooltip then
                return
            end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L("Elemental Convergence", "Convergência Elemental"), 1, 1, 1)
            GameTooltip:AddLine(L("Use Skysight next to it for the bigger bonus.", "Use a Visão do Céu perto dela para o bônus maior."), 0.6, 0.9, 0.9)
            GameTooltip:Show()
        end)
        pin:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
    end

    pin:Hide()
    return pin
end

local function HidePins(pins, from)
    for index = from or 1, #pins do
        pins[index]:Hide()
    end
end

-- ---- World map ---------------------------------------------------------------------------------------------------

function Convergence:UpdateWorldMap()
    local map = _G.WorldMapFrame

    if not self.running or not map or not self:GetSetting("worldMap") or not map:IsShown() then
        HidePins(self.worldPins)
        return
    end

    local canvas = map.GetCanvas and map:GetCanvas()
    local mapID = map.GetMapID and map:GetMapID()
    local list = canvas and mapID and SN.ConvergenceData[mapID]

    if not list then
        HidePins(self.worldPins)
        return
    end

    local width, height = canvas:GetWidth(), canvas:GetHeight()
    local scale = canvas:GetScale()

    if not scale or scale <= 0 then
        scale = 1
    end

    local count = CountPoints(list)

    for index = 1, count do
        local pin = self.worldPins[index]

        if not pin then
            pin = NewPin(canvas, WORLD_PIN_SIZE, true)
            self.worldPins[index] = pin
        end

        pin:SetScale(1 / scale)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", canvas, "TOPLEFT", list[index * 2 - 1] * width * scale, -list[index * 2] * height * scale)
        pin:Show()
    end

    HidePins(self.worldPins, count + 1)
end

function Convergence:HookWorldMap()
    local map = _G.WorldMapFrame

    if self.hooked or not map or not hooksecurefunc then
        return
    end

    self.hooked = true
    local function Refresh()
        Convergence:UpdateWorldMap()
    end

    map:HookScript("OnShow", Refresh)
    map:HookScript("OnHide", Refresh)

    for _, method in ipairs({ "OnMapChanged", "OnCanvasScaleChanged" }) do
        if type(map[method]) == "function" then
            hooksecurefunc(map, method, Refresh)
        end
    end
end

-- ---- Minimap -----------------------------------------------------------------------------------------------------

-- The zone's size in yards does not change while you are in it: read it once per zone.
local zoneSizes = {}

local function GetZoneSize(mapID)
    local cached = zoneSizes[mapID]

    if cached then
        return cached[1], cached[2]
    end

    if C_Map.GetMapWorldSize then
        local ok, wide, high = pcall(C_Map.GetMapWorldSize, mapID)
        wide, high = ok and Plain(wide), ok and Plain(high)

        if wide and high and wide > 0 then
            zoneSizes[mapID] = { wide, high }
            return wide, high
        end
    end

    return nil, nil
end

local function GetMinimapRadius()
    if C_Minimap and C_Minimap.GetViewRadius then
        local ok, radius = pcall(C_Minimap.GetViewRadius)
        radius = ok and Plain(radius)

        if radius and radius > 0 then
            return radius
        end
    end

    return nil
end

-- Where a point lands on the minimap from its distance to the player (east and north, in yards); a minimap that
-- rotates keeps the direction the player faces at the top. Same maths as the exploration markers.
function Convergence.Project(east, north, rotates, facing)
    if not rotates then
        return east, north
    end

    local sine, cosine = math.sin(facing), math.cos(facing)
    return east * cosine + north * sine, -east * sine + north * cosine
end

function Convergence:UpdateMinimap()
    local minimap = _G.Minimap

    if not self.running or not minimap or not self:GetSetting("minimap") or not minimap:IsVisible() then
        self.last = nil
        HidePins(self.minimapPins)
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    local list = mapID and SN.ConvergenceData[mapID]
    local radius = GetMinimapRadius()

    if not list or not radius then
        self.last = nil
        HidePins(self.minimapPins)
        return
    end

    local okPosition, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    local playerX, playerY = position and Plain(position.x), position and Plain(position.y)
    local yardsWide, yardsHigh = GetZoneSize(mapID)

    if not (okPosition and playerX and playerY and yardsWide and yardsHigh and yardsWide > 0) then
        self.last = nil
        HidePins(self.minimapPins)
        return
    end

    local half = minimap:GetWidth() / 2
    local shape = GetMinimapShape and GetMinimapShape()
    local square = shape == "SQUARE"
    local rotates = GetCVar and GetCVar("rotateMinimap") == "1"
    local facing = rotates and Plain(GetPlayerFacing and GetPlayerFacing()) or 0

    -- nothing moved since the last look: the markers are already where they belong
    local last = self.last

    if last and last.map == mapID and last.x == playerX and last.y == playerY and last.facing == facing and last.radius == radius then
        return
    end

    self.last = { map = mapID, x = playerX, y = playerY, facing = facing, radius = radius }
    local shown = 0

    for index = 1, CountPoints(list) do
        local east = (list[index * 2 - 1] - playerX) * yardsWide
        local north = -(list[index * 2] - playerY) * yardsHigh
        local sx, sy = Convergence.Project(east, north, rotates, facing)
        local offsetX, offsetY = sx / radius * half, sy / radius * half
        local inside

        if square then
            inside = math.abs(offsetX) <= half and math.abs(offsetY) <= half
        else
            inside = offsetX * offsetX + offsetY * offsetY <= half * half
        end

        if inside then
            shown = shown + 1
            local pin = self.minimapPins[shown]

            if not pin then
                pin = NewPin(minimap, MINIMAP_PIN_SIZE, false)
                self.minimapPins[shown] = pin
            end

            pin:ClearAllPoints()
            pin:SetPoint("CENTER", minimap, "CENTER", offsetX, offsetY)
            pin:Show()
        end
    end

    HidePins(self.minimapPins, shown + 1)
end

function Convergence:UpdateTicker()
    local wanted = self.running and self:GetSetting("minimap")

    if not wanted then
        if self.ticker then
            self.ticker:SetScript("OnUpdate", nil)
        end

        self.last = nil
        HidePins(self.minimapPins)
        return
    end

    if not self.ticker then
        self.ticker = CreateFrame("Frame")
    end

    local elapsed = 0
    self.ticker:SetScript("OnUpdate", function(_, step)
        elapsed = elapsed + step

        if elapsed >= MINIMAP_STEP then
            elapsed = 0
            Convergence:UpdateMinimap()
        end
    end)
end

-- ---- Life cycle --------------------------------------------------------------------------------------------------

function Convergence:Refresh()
    self.last = nil
    if self.running then
        self:HookWorldMap()
    end

    self:UpdateTicker()
    self:UpdateWorldMap()
    self:UpdateMinimap()
end

function Convergence:Listen(on)
    if not self.frame then
        self.frame = CreateFrame("Frame")
        self.frame:SetScript("OnEvent", function(_, event)
            -- the world map can be loaded after this addon (it is an on-demand part of the game): hook it when it appears
            if event == "ADDON_LOADED" and Convergence.hooked then
                return
            end

            Convergence:Refresh()
        end)
    end

    for _, event in ipairs(MAP_EVENTS) do
        if on then
            pcall(self.frame.RegisterEvent, self.frame, event)
        else
            pcall(self.frame.UnregisterEvent, self.frame, event)
        end
    end
end

function Convergence:SetEnabled(enabled)
    self.running = enabled and self:IsSupported()
    self:Listen(self.running)
    self:Refresh()
end

function Convergence:Initialize()
    self:SetEnabled(true)
end

function Convergence:OnOptionChanged()
    self:Refresh()
end

-- /snui converge: how many convergences the current zone has.
function Convergence:HandleCommand(rest)
    if not self:IsSupported() then
        SN:Print(L("convergence markers are not available in this game.", "os marcadores de convergência não estão disponíveis neste jogo."))
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    local count = CountPoints(mapID and SN.ConvergenceData[mapID])

    if rest == "debug" then
        local map = _G.WorldMapFrame
        local shownPins = 0

        for _, pin in ipairs(self.worldPins) do
            if pin:IsShown() then
                shownPins = shownPins + 1
            end
        end

        SN:Print(("running=%s hooked=%s worldMapFrame=%s canvas=%s shownMapID=%s playerMapID=%s points=%d worldPinsShown=%d")
            :format(tostring(self.running), tostring(self.hooked), tostring(map ~= nil),
                tostring(map ~= nil and map.GetCanvas ~= nil and map:GetCanvas() ~= nil),
                tostring(map and map.GetMapID and map:GetMapID()), tostring(mapID), count, shownPins))

        local pin, canvas = self.worldPins[1], map and map.GetCanvas and map:GetCanvas()

        if pin and canvas then
            local cx, cy = pin:GetCenter()
            local mx, my = canvas:GetCenter()
            SN:Print(("pin1: visible=%s center=%s,%s size=%s alpha=%s effScale=%s level=%s texture=%s | canvas: center=%s,%s size=%sx%s scale=%s effScale=%s level=%s shown=%s parent=%s")
                :format(tostring(pin:IsVisible()), tostring(cx and math.floor(cx)), tostring(cy and math.floor(cy)),
                    tostring(pin:GetWidth()), tostring(pin:GetEffectiveAlpha()), tostring(pin:GetEffectiveScale()),
                    tostring(pin:GetFrameLevel()), tostring(pin.icon:GetTexture()),
                    tostring(mx and math.floor(mx)), tostring(my and math.floor(my)), tostring(math.floor(canvas:GetWidth())),
                    tostring(math.floor(canvas:GetHeight())), tostring(canvas:GetScale()), tostring(canvas:GetEffectiveScale()),
                    tostring(canvas:GetFrameLevel()), tostring(canvas:IsShown()),
                    tostring(canvas:GetParent() and canvas:GetParent():GetName())))
        end

        return
    end

    local info = C_Map.GetMapInfo and mapID and C_Map.GetMapInfo(mapID)
    local zone = info and info.name or tostring(mapID)

    if count == 0 then
        SN:Print(L("no elemental convergence is known in this zone.", "nenhuma convergência elemental conhecida nesta zona."))
    else
        SN:Print(L("%s: %d elemental convergences marked on the map.", "%s: %d convergências elementais marcadas no mapa."):format(zone, count))
    end
end

Convergence.info = {
    category = "interface",
    kind = "feature",
    order = 2,
    name = { enUS = "Elemental Convergence markers", ptBR = "Marcadores de Convergência Elemental" },
    desc = {
        enUS = "Marks the elemental convergences on the world map and on the minimap, for the Skysight of the Windshaper Skyborne.",
        ptBR = "Marca as convergências elementais no mapa-múndi e no minimapa, para a Visão do Céu dos Celonatos Moldaventos.",
    },
    -- Only a Windshaper Skyborne has a use for it, so it starts off for everyone else.
    isUseful = function(module)
        return module:IsSupported() and module:IsWindshaper()
    end,
    help = { "/snui converge - how many elemental convergences the current zone has" },
    options = {
        { type = "toggle", key = "worldMap", default = true,
            text = { enUS = "Show markers on the world map", ptBR = "Mostrar marcadores no mapa-múndi" },
            desc = { enUS = "A small wind swirl on the zone map for each elemental convergence.", ptBR = "Um pequeno redemoinho no mapa da zona para cada convergência elemental." } },
        { type = "toggle", key = "minimap", default = true,
            text = { enUS = "Show markers on the minimap", ptBR = "Mostrar marcadores no minimapa" },
            desc = { enUS = "The same markers on the minimap, when the convergence is within its range.", ptBR = "Os mesmos marcadores no minimapa, quando a convergência está ao alcance dele." } },
    },
    GetStatus = function(module)
        if not module:IsSupported() then
            return "warning", L("Not available in this game", "Indisponível neste jogo")
        end

        if not module:IsWindshaper() then
            return "warning", L("Meant for Windshaper Skyborne", "Feito para Celonatos Moldaventos")
        end

        return "active"
    end,
}

SN:RegisterModuleDefaults("converge", { enabled = true })
SN:RegisterModule("converge", Convergence)
