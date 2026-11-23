local addonName, SN = ...

--[[
    Elemental Convergence markers (WoW Forever only).

    The Windshaper Skyborne racial, Skysight, draws power from an elemental convergence: next to one it gives a bigger
    bonus. Where they are is not in the game's client tables, so SN.ConvergenceData (Data/Convergence.lua) holds the
    positions of every convergence of every zone, taken from the Wowhead page of the object.

    If the addon "Skyborne Leyline & Convergence Marker" (tr0tsky, MIT) is installed, its list is used instead: it is
    bigger, it keeps growing (it learns from the players' own finds) and it drops bad reports. It offers the list to
    other addons through SLLCM_GetNodes. That addon draws the same markers itself, so this module starts off next to it
    (conflictsWith); the player can still switch it on, and then it draws its markers from that list.

    The world map markers are small frames on the map's canvas. The minimap markers are placed from the distance to the
    player in yards, the same way the exploration markers are (see Modules/Exploration.lua), and the minimap is looked at
    every frame, and a look where nothing moved costs only a few comparisons.
]]

local Convergence = {
    running = false,
    worldPins = {},
    minimapPins = {},
}

local PARTNER_ADDON = "SkyborneLeyLineConvergenceMarker" -- folder of Skyborne Leyline & Convergence Marker
local PARTNER_NAME = "Skyborne Leyline & Convergence Marker"
local WINDSHAPER_RACE_ID = 96      -- "Windshaper Skyborne" in the game's ChrRaces table
local SKYSIGHT_SPELL_ID = 1259686  -- the racial that benefits from a convergence
local NEARBY_SPELL_ID = 1271953    -- "A powerful elemental convergence is nearby..."
local CHARGED_SPELL_ID = 1270893   -- "Charged": Skysight used next to a convergence
local ICON = (SN.config.icon:gsub("SuperNovaUI$", "Convergence")) -- Media/Icons/Convergence.tga: a small wind swirl
local WORLD_PIN_SIZE, MINIMAP_PIN_SIZE = 13, 10
local PIN_LEVEL_ABOVE_PARENT = 20
local MINIMAP_STEP = 0 -- every frame, so the markers move smoothly with the minimap
local MAX_AURAS_SCANNED = 60
local MAP_EVENTS = { "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "PLAYER_LOGIN", "ADDON_LOADED" }

local function L(enUS, ptBR)
    return SN:Loc({ enUS = enUS, ptBR = ptBR })
end

-- A number the game lets addons read (in some situations it hands out "secret" values), else nil.
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

local function IsWindshaperRace()
    if not UnitRace then
        return false
    end

    local _, _, raceID = UnitRace("player")
    return raceID == WINDSHAPER_RACE_ID
end

-- A Windshaper Skyborne, or anyone who knows Skysight.
function Convergence:IsWindshaper()
    if IsWindshaperRace() then
        return true
    end

    local known = IsPlayerSpell and IsPlayerSpell(SKYSIGHT_SPELL_ID)
    return known and true or false
end

function Convergence:GetSetting(key)
    return SN:GetOption(self.name, key)
end

-- The points -----------------------------------------------------------------------------------------------------------

-- The partner's lists as flat lists { x1, y1, x2, y2, ... } per zone; nil when it has none.
local function FlattenNodes(nodes)
    local flat = {}

    for mapID, list in pairs(nodes) do
        local points = {}

        for _, point in ipairs(list) do
            points[#points + 1] = point[1]
            points[#points + 1] = point[2]
        end

        if #points > 0 then
            flat[mapID] = points
        end
    end

    return next(flat) and flat or nil
end

local function ReadPartnerNodes()
    if type(_G.SLLCM_GetNodes) ~= "function" then
        return nil
    end

    local ok, nodes = pcall(_G.SLLCM_GetNodes, "Horde")

    if ok and type(nodes) == "table" then
        return FlattenNodes(nodes)
    end

    return nil
end

-- The partner addon's points when it is there (its list is the more complete). They are read once and kept until the next
-- refresh, because it hands out a new table on every call.
function Convergence:GetPartnerList()
    if self.partner == nil then
        self.partner = ReadPartnerNodes() or false
    end

    return self.partner or nil
end

-- The points of a zone as a flat list { x1, y1, x2, y2, ... }: the partner's when it knows the zone, otherwise our own.
function Convergence:GetPoints(mapID)
    local partner = self:GetPartnerList()
    return partner and partner[mapID] or (mapID and SN.ConvergenceData and SN.ConvergenceData[mapID])
end

-- Number of points, from the flat list { x1, y1, x2, y2, ... } of a zone.
local function CountPoints(list)
    return list and math.floor(#list / 2) or 0
end

local function PointX(list, index)
    return list[index * 2 - 1]
end

local function PointY(list, index)
    return list[index * 2]
end

-- The markers ----------------------------------------------------------------------------------------------------------

local function AddIcon(pin)
    local icon = pin:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    icon:SetTexture(ICON)

    -- the game snaps pictures to the screen's pixel grid; the minimap slides smoothly, so a snapped marker moves in
    -- little jumps next to it. Markers keep their sub-pixel position instead.
    if icon.SetSnapToPixelGrid then
        icon:SetSnapToPixelGrid(false)
    end

    if icon.SetTexelSnappingBias then
        icon:SetTexelSnappingBias(0)
    end

    pin.icon = icon
end

local function ShowPinTooltip(pin)
    if not GameTooltip then
        return
    end

    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L("Elemental Convergence", "Convergência Elemental"), 1, 1, 1)
    GameTooltip:AddLine(L("Use Skysight next to it for the bigger bonus.", "Use a Visão do Céu perto dela para o bônus maior."), 0.6, 0.9, 0.9)

    if Convergence:GetPartnerList() then
        GameTooltip:AddLine(L("Positions: ", "Posições: ") .. PARTNER_NAME, 0.5, 0.5, 0.5)
    end

    GameTooltip:Show()
end

local function HidePinTooltip()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

local function MakeInteractive(pin)
    -- on the world map a marker at the map's own strata is drawn under its art; one step up the map keeps it above
    pin:SetFrameStrata("FULLSCREEN")
    pin:SetScript("OnEnter", ShowPinTooltip)
    pin:SetScript("OnLeave", HidePinTooltip)
end

local function NewPin(parent, size, interactive)
    local pin = CreateFrame("Frame", nil, parent)
    pin:SetSize(size, size)
    pin:SetFrameLevel(parent:GetFrameLevel() + PIN_LEVEL_ABOVE_PARENT)
    pin:EnableMouse(interactive and true or false)
    AddIcon(pin)

    if interactive then
        MakeInteractive(pin)
    end

    pin:Hide()
    return pin
end

-- The pin at this position of the list, made the first time it is needed.
local function PinAt(pins, index, parent, size, interactive)
    if not pins[index] then
        pins[index] = NewPin(parent, size, interactive)
    end

    return pins[index]
end

local function HidePins(pins, from)
    for index = from or 1, #pins do
        pins[index]:Hide()
    end
end

-- World map ------------------------------------------------------------------------------------------------------------

local function CanvasScale(canvas)
    local scale = canvas:GetScale()

    if not scale or scale <= 0 then
        return 1
    end

    return scale
end

function Convergence:UpdateWorldMap()
    local map = _G.WorldMapFrame

    if not (self.running and map and self:GetSetting("worldMap") and map:IsShown()) then
        HidePins(self.worldPins)
        return
    end

    local canvas = map.GetCanvas and map:GetCanvas()
    local mapID = map.GetMapID and map:GetMapID()
    local list = canvas and mapID and self:GetPoints(mapID)

    if not list then
        HidePins(self.worldPins)
        return
    end

    local width, height, scale = canvas:GetWidth(), canvas:GetHeight(), CanvasScale(canvas)
    local count = CountPoints(list)

    for index = 1, count do
        local pin = PinAt(self.worldPins, index, canvas, WORLD_PIN_SIZE, true)

        pin:SetScale(1 / scale)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", canvas, "TOPLEFT", PointX(list, index) * width * scale, -PointY(list, index) * height * scale)
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

-- Minimap --------------------------------------------------------------------------------------------------------------

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

local function PlayerPosition(mapID)
    local ok, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")

    if not ok or not position then
        return nil, nil
    end

    return Plain(position.x), Plain(position.y)
end

local function MinimapRotation()
    local rotates = GetCVar and GetCVar("rotateMinimap") == "1"
    local facing = rotates and Plain(GetPlayerFacing and GetPlayerFacing()) or 0
    return rotates, facing
end

-- Everything needed to place the markers now, or nil when they cannot be placed (no zone points, no radius, no position).
function Convergence:ReadMinimapView(minimap)
    local mapID = C_Map.GetBestMapForUnit("player")
    local list = mapID and self:GetPoints(mapID)
    local radius = GetMinimapRadius()

    if not list or not radius then
        return nil
    end

    local playerX, playerY = PlayerPosition(mapID)
    local yardsWide, yardsHigh = GetZoneSize(mapID)

    if not (playerX and playerY and yardsWide and yardsHigh and yardsWide > 0) then
        return nil
    end

    local rotates, facing = MinimapRotation()

    return {
        map = mapID, list = list, radius = radius, x = playerX, y = playerY, facing = facing, rotates = rotates,
        yardsWide = yardsWide, yardsHigh = yardsHigh,
        half = minimap:GetWidth() / 2, square = GetMinimapShape and GetMinimapShape() == "SQUARE",
    }
end

-- Nothing moved since the last look: the markers are already where they belong.
local function IsSameView(last, view)
    return last ~= nil and last.map == view.map and last.x == view.x and last.y == view.y
        and last.facing == view.facing and last.radius == view.radius
end

local function IsInsideMinimap(offsetX, offsetY, half, square)
    if square then
        return math.abs(offsetX) <= half and math.abs(offsetY) <= half
    end

    return offsetX * offsetX + offsetY * offsetY <= half * half
end

-- Where a point lands on the minimap, in pixels from its centre.
local function MinimapOffset(view, index)
    local east = (PointX(view.list, index) - view.x) * view.yardsWide
    local north = -(PointY(view.list, index) - view.y) * view.yardsHigh
    local screenX, screenY = Convergence.Project(east, north, view.rotates, view.facing)
    return screenX / view.radius * view.half, screenY / view.radius * view.half
end

function Convergence:ClearMinimap()
    self.last = nil
    HidePins(self.minimapPins)
end

function Convergence:PlaceMinimapPins(minimap, view)
    local shown = 0

    for index = 1, CountPoints(view.list) do
        local offsetX, offsetY = MinimapOffset(view, index)

        if IsInsideMinimap(offsetX, offsetY, view.half, view.square) then
            shown = shown + 1
            local pin = PinAt(self.minimapPins, shown, minimap, MINIMAP_PIN_SIZE, false)

            pin:ClearAllPoints()
            pin:SetPoint("CENTER", minimap, "CENTER", offsetX, offsetY)
            pin:Show()
        end
    end

    HidePins(self.minimapPins, shown + 1)
end

function Convergence:UpdateMinimap()
    local minimap = _G.Minimap

    if not (self.running and minimap and self:GetSetting("minimap") and minimap:IsVisible()) then
        self:ClearMinimap()
        return
    end

    local view = self:ReadMinimapView(minimap)

    if not view then
        self:ClearMinimap()
        return
    end

    if IsSameView(self.last, view) then
        return
    end

    self.last = view
    self:PlaceMinimapPins(minimap, view)
end

function Convergence:UpdateTicker()
    if not (self.running and self:GetSetting("minimap")) then
        if self.ticker then
            self.ticker:SetScript("OnUpdate", nil)
        end

        self:ClearMinimap()
        return
    end

    self.ticker = self.ticker or CreateFrame("Frame")

    local elapsed = 0
    self.ticker:SetScript("OnUpdate", function(_, step)
        elapsed = elapsed + step

        if elapsed >= MINIMAP_STEP then
            elapsed = 0
            Convergence:UpdateMinimap()
        end
    end)
end

-- Life cycle -----------------------------------------------------------------------------------------------------------

function Convergence:Refresh()
    self.last = nil
    self.partner = nil -- read the partner addon's list again (it may have learned new points)

    if self.running then
        self:HookWorldMap()
    end

    self:UpdateTicker()
    self:UpdateWorldMap()
    self:UpdateMinimap()
end

local function OnMapEvent(event)
    -- the world map can be loaded after this addon (it is an on-demand part of the game): hook it when it appears
    if event == "ADDON_LOADED" and Convergence.hooked then
        return
    end

    Convergence:Refresh()
end

function Convergence:Listen(on)
    if not self.frame then
        self.frame = CreateFrame("Frame")
        self.frame:SetScript("OnEvent", function(_, event)
            OnMapEvent(event)
        end)
    end

    local register = on and self.frame.RegisterEvent or self.frame.UnregisterEvent

    for _, event in ipairs(MAP_EVENTS) do
        pcall(register, self.frame, event)
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

-- Watching the "convergence nearby" signal -----------------------------------------------------------------------------
-- The game puts an effect on the player while an active convergence is close ("A powerful elemental convergence is
-- nearby...") and "Charged" after Skysight next to one. /snui converge watch prints, whenever one of them comes or goes,
-- how far the nearest known point is: that tells how near a point has to be for the signal, and which points are idle.

local function HasAuraById(spellID)
    for index = 1, MAX_AURAS_SCANNED do
        local name, _, _, _, _, _, _, _, _, id = UnitAura("player", index)

        if not name then
            return false
        end

        if id == spellID then
            return true
        end
    end

    return false
end

local function HasPlayerAura(spellID)
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        return ok and aura ~= nil
    end

    return UnitAura ~= nil and HasAuraById(spellID)
end

local function DistanceInYards(dx, dy)
    return math.sqrt(dx * dx + dy * dy)
end

-- Distance in yards to the nearest known point of the zone the player is in, and that point's coordinates (0 to 100).
function Convergence:GetNearestPoint()
    local mapID = C_Map.GetBestMapForUnit("player")
    local list = mapID and self:GetPoints(mapID)

    if not list then
        return nil
    end

    local playerX, playerY = PlayerPosition(mapID)
    local yardsWide, yardsHigh = GetZoneSize(mapID)

    if not (playerX and playerY and yardsWide) then
        return nil
    end

    local best, bestX, bestY

    for index = 1, CountPoints(list) do
        local x, y = PointX(list, index), PointY(list, index)
        local distance = DistanceInYards((x - playerX) * yardsWide, (y - playerY) * yardsHigh)

        if not best or distance < best then
            best, bestX, bestY = distance, x, y
        end
    end

    return best, bestX * 100, bestY * 100
end

local function ReportSignalChange(label, now, before)
    if now == before then
        return
    end

    local distance, x, y = Convergence:GetNearestPoint()
    local where = distance and ("nearest known point %.0f yards away (%.1f, %.1f)"):format(distance, x, y) or "no known point in this zone"
    SN:Print(("watch: %s %s | %s"):format(label, now and "ON" or "OFF", where))
end

local function CheckSignals(watcher)
    local nearby, charged = HasPlayerAura(NEARBY_SPELL_ID), HasPlayerAura(CHARGED_SPELL_ID)
    ReportSignalChange("convergence nearby", nearby, watcher.nearby)
    ReportSignalChange("charged", charged, watcher.charged)
    watcher.nearby, watcher.charged = nearby, charged
end

function Convergence:Watch(on)
    if not self.watcher then
        self.watcher = CreateFrame("Frame")
        self.watcher.nearby, self.watcher.charged = false, false
        self.watcher:SetScript("OnEvent", CheckSignals)
    end

    if on then
        self.watcher.nearby, self.watcher.charged = HasPlayerAura(NEARBY_SPELL_ID), HasPlayerAura(CHARGED_SPELL_ID)
        pcall(self.watcher.RegisterUnitEvent, self.watcher, "UNIT_AURA", "player")
    else
        pcall(self.watcher.UnregisterEvent, self.watcher, "UNIT_AURA")
    end

    self.watching = on
end

-- The command ----------------------------------------------------------------------------------------------------------

local function PrintWatch(self)
    self:Watch(not self.watching)
    SN:Print(self.watching and "watch: on. Walk around the points; each time the nearby signal comes or goes, the distance is printed. Run it again to stop."
        or "watch: off.")
end

local function CountShownPins(pins)
    local shown = 0

    for _, pin in ipairs(pins) do
        if pin:IsShown() then
            shown = shown + 1
        end
    end

    return shown
end

local function PrintDebugSummary(self, map, mapID, count)
    SN:Print(("running=%s hooked=%s worldMapFrame=%s canvas=%s shownMapID=%s playerMapID=%s points=%d worldPinsShown=%d")
        :format(tostring(self.running), tostring(self.hooked), tostring(map ~= nil),
            tostring(map ~= nil and map.GetCanvas ~= nil and map:GetCanvas() ~= nil),
            tostring(map and map.GetMapID and map:GetMapID()), tostring(mapID), count, CountShownPins(self.worldPins)))
end

local function PrintFirstPin(pin, canvas)
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

local function PrintDebug(self, mapID, count)
    local map = _G.WorldMapFrame
    PrintDebugSummary(self, map, mapID, count)

    local pin, canvas = self.worldPins[1], map and map.GetCanvas and map:GetCanvas()

    if pin and canvas then
        PrintFirstPin(pin, canvas)
    end
end

local function PrintZoneCount(mapID, count)
    local info = C_Map.GetMapInfo and mapID and C_Map.GetMapInfo(mapID)
    local zone = info and info.name or tostring(mapID)

    if count == 0 then
        SN:Print(L("no elemental convergence is known in this zone.", "nenhuma convergência elemental conhecida nesta zona."))
    else
        SN:Print(L("%s: %d elemental convergences marked on the map.", "%s: %d convergências elementais marcadas no mapa."):format(zone, count))
    end
end

-- /snui converge: how many convergences the current zone has; watch and debug are for finding problems.
function Convergence:HandleCommand(rest)
    if not self:IsSupported() then
        SN:Print(L("convergence markers are not available in this game.", "os marcadores de convergência não estão disponíveis neste jogo."))
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    local count = CountPoints(mapID and self:GetPoints(mapID))

    if rest == "watch" then
        PrintWatch(self)
    elseif rest == "debug" then
        PrintDebug(self, mapID, count)
    else
        PrintZoneCount(mapID, count)
    end
end

-- The module -----------------------------------------------------------------------------------------------------------

Convergence.info = {
    category = "interface",
    kind = "feature",
    order = 2,
    name = { enUS = "Elemental Convergence markers", ptBR = "Marcadores de Convergência Elemental" },
    desc = {
        enUS = "Marks the elemental convergences on the world map and on the minimap, for the Skysight of the Windshaper Skyborne. Uses the point list of Skyborne Leyline & Convergence Marker (tr0tsky) when that addon is installed.",
        ptBR = "Marca as convergências elementais no mapa-múndi e no minimapa, para a Visão do Céu dos Celonatos Moldaventos. Usa a lista de pontos do Skyborne Leyline & Convergence Marker (tr0tsky) quando esse addon está instalado.",
    },
    -- Skyborne Leyline & Convergence Marker draws the same markers (and shows which were seen just now): next to it this
    -- module starts off, and if the player switches it on anyway it uses that addon's list of points.
    conflictsWith = { PARTNER_ADDON },
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

        if module:GetPartnerList() then
            return "active", L("Using the point list of " .. PARTNER_NAME, "Usando a lista de pontos do " .. PARTNER_NAME)
        end

        return "active"
    end,
}

SN:RegisterModuleDefaults("converge", { enabled = true })
SN:RegisterModule("converge", Convergence)
