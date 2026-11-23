local addonName, SN = ...

--[[
    The cheapest way to a goal: what each step costs and what to buy.

    From the player's current skill to the goal, every craft is the recipe with the lowest price per expected skill point.
    A craft gives `ups` points while it is orange or yellow; between yellow and grey the chance falls off to nothing
    ((grey - skill) / (grey - yellow)), the same rule the recipe data is made for. A recipe that is learned from an item
    (a recipe book) can be used when the player knows it, or when its item has a price: that price is spread over the
    points the recipe can still give and paid once, the first time it is chosen.

    Where a price comes from, in this order, the lowest one winning:
      1. the Auction House, through an addon that keeps its prices: Auctionator (Auctionator.API.v1), then TradeSkillMaster;
      2. a vendor: the gold price a vendor was seen asking at a merchant window the player opened (kept in the module's
         saved settings), or VoidGPS's vendor list when that addon is installed.
    There is no other guess. The recipe data holds no buy price for a reason: such a price says nothing about who sells the
    item (nobody sells most clam meat), so an item without a price from those sources has an UNKNOWN price. A recipe with
    an unknown price is only chosen when no recipe with a known price can give points, and the plan says it is incomplete.

    Not counted: what the player already owns, training costs, and the sale of what is crafted.
]]

local Plan = {}
SN.GoalPlan = Plan

local CALLER = "SuperNovaUI"
local MAX_CRAFTS = 20000
local COPPER_PER_SILVER, COPPER_PER_GOLD = 100, 10000

-- Prices -----------------------------------------------------------------------------------------------------------

-- The result of a price function when it is a usable price (a positive number), else nil. A failing addon is never fatal.
local function UsablePrice(priceFunction, ...)
    local ok, price = pcall(priceFunction, ...)

    if ok and type(price) == "number" and price > 0 then
        return price
    end

    return nil
end

local function AuctionatorPrice(itemID)
    local api = Auctionator and Auctionator.API and Auctionator.API.v1

    if api and api.GetAuctionPriceByItemID then
        return UsablePrice(api.GetAuctionPriceByItemID, CALLER, itemID)
    end

    return nil
end

local function TradeSkillMasterPrice(itemID)
    if TSM_API and TSM_API.GetCustomPriceValue then
        return UsablePrice(TSM_API.GetCustomPriceValue, "DBMarket", "i:" .. itemID)
    end

    return nil
end

-- copper, "auction"; nil when no addon has one.
local function AuctionPrice(itemID)
    return AuctionatorPrice(itemID) or TradeSkillMasterPrice(itemID)
end

local function SeenVendorPrice(itemID)
    local seen = Plan.GetSeen and Plan.GetSeen() or {}
    local price = seen[itemID]

    if type(price) == "number" and price > 0 then
        return price
    end

    return nil
end

-- A vendor sells for plain gold when no extra currency is asked and its stock is not limited.
local function SellsForPlainGold(vendor)
    return not vendor.cost and not vendor.limited
end

local function VoidGpsPrice(itemID)
    local goods = _G.VoidGPS and _G.VoidGPS.Goods

    if not (goods and goods.Get) then
        return nil
    end

    local ok, entry = pcall(function()
        return goods:Get(itemID)
    end)

    if not (ok and type(entry) == "table" and (entry.buy or 0) > 0) then
        return nil
    end

    for _, vendor in ipairs(entry.vendors or {}) do
        if SellsForPlainGold(vendor) then
            return entry.buy / (entry.qty or 1)
        end
    end

    return nil
end

-- copper for one unit; nil when no vendor is known to sell it.
local function VendorPrice(itemID)
    return SeenVendorPrice(itemID) or VoidGpsPrice(itemID)
end

-- The cheapest known price of one unit and where it comes from ("auction" or "vendor"); nil, nil when unknown.
function Plan.PriceOf(itemID)
    local auction, vendor = AuctionPrice(itemID), VendorPrice(itemID)

    if auction and (not vendor or auction <= vendor) then
        return auction, "auction"
    end

    if vendor then
        return vendor, "vendor"
    end

    return nil, nil
end

function Plan.HasAuctionPrices()
    return (Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID) ~= nil
        or (TSM_API and TSM_API.GetCustomPriceValue) ~= nil
end

-- The cheapest of the items that can fill one slot of a recipe: itemID, price, source. Nothing when none has a price.
local function SlotPrice(ids)
    local bestID, bestPrice, bestSource

    for _, itemID in ipairs(ids) do
        local price, source = Plan.PriceOf(itemID)

        if price and (not bestPrice or price < bestPrice) then
            bestID, bestPrice, bestSource = itemID, price, source
        end
    end

    return bestID, bestPrice, bestSource
end

-- Recipes ---------------------------------------------------------------------------------------------------------

-- Reagents of a recipe as slots { count = n, ids = { ... } } from the compact rows { n, id, id, ... }.
local function Slots(recipe)
    local slots = {}

    for _, mat in ipairs(recipe.mats or {}) do
        local ids = {}

        for index = 2, #mat do
            table.insert(ids, mat[index])
        end

        table.insert(slots, { count = mat[1], ids = ids })
    end

    return slots
end

-- Points one craft is expected to give at this skill (0 when the recipe is not usable yet, or is grey).
local function ExpectedPoints(recipe, skill)
    if skill < (recipe.min or 0) then
        return 0
    end

    local ups = recipe.ups or 1
    local yellow, grey = recipe.yellow or recipe.min, recipe.grey

    if not grey or skill < yellow then
        return grey and ups or 0
    end

    if skill >= grey then
        return 0
    end

    return ups * (grey - skill) / math.max(1, grey - yellow)
end

-- Cost of one craft of a recipe: copper, the list of reagents { itemID, count, price, source } and the item ids with no
-- price. The cost is nil when any reagent has no price.
local function CraftCost(recipe)
    local total, parts, missing = 0, {}, {}

    for _, slot in ipairs(Slots(recipe)) do
        local itemID, price, source = SlotPrice(slot.ids)

        if price then
            total = total + price * slot.count
            table.insert(parts, { itemID = itemID, count = slot.count, price = price, source = source })
        else
            table.insert(missing, slot.ids[1])
        end
    end

    if #missing > 0 then
        return nil, parts, missing
    end

    return total, parts, missing
end

-- Candidates ----------------------------------------------------------------------------------------------------------

-- Can this recipe be considered for a goal at all?
local function IsUsableForGoal(recipe, goal)
    return type(recipe) == "table" and type(recipe.min) == "number" and recipe.grey ~= nil and recipe.min < goal
end

-- What a recipe that is learned from a book needs: nothing more when known, the book's price when it can be bought, and
-- nothing at all (nil) when it cannot be learned. Returns the fields to add to the candidate, or nil.
local function BookRequirement(recipe, known)
    if not recipe.book or (known and known(recipe)) then
        return { bookOwned = true }
    end

    if type(recipe.book) ~= "number" then
        return nil
    end

    local price = Plan.PriceOf(recipe.book)

    if not price then
        return nil -- a recipe that cannot be learned: no known price for its book
    end

    return { bookOwned = false, bookPrice = price, bookItem = recipe.book }
end

local function BuildCandidate(recipe, known)
    local book = BookRequirement(recipe, known)

    if not book then
        return nil
    end

    local cost, parts, missing = CraftCost(recipe)
    book.recipe, book.cost, book.parts, book.missing = recipe, cost, parts, missing
    return book
end

local function BuildCandidates(entry, goal, known)
    local candidates = {}

    for _, recipe in ipairs(entry.recipes) do
        if IsUsableForGoal(recipe, goal) then
            local candidate = BuildCandidate(recipe, known)

            if candidate then
                table.insert(candidates, candidate)
            end
        end
    end

    return candidates
end

-- Choosing the next craft ---------------------------------------------------------------------------------------------

-- Copper per expected point, with the recipe book's price spread over the points the recipe can still give; nil when a
-- reagent has no price.
local function PriceScore(candidate, points, current, goal)
    if not candidate.cost then
        return nil
    end

    local score = candidate.cost / points

    if not candidate.bookOwned then
        local span = math.max(1, math.min(goal, candidate.recipe.grey) - current)
        score = score + candidate.bookPrice / span
    end

    return score
end

-- The candidate with the lowest price per point. A candidate with an unknown price is chosen only when no priced one can
-- give points (then the one with the fewest missing reagents per point).
local function PickBest(candidates, current, goal)
    local floorSkill = math.floor(current)
    local best, bestScore, bestIsPriced

    for _, candidate in ipairs(candidates) do
        local points = ExpectedPoints(candidate.recipe, floorSkill)

        if points > 0 then
            local score = PriceScore(candidate, points, current, goal)

            if score then
                if not bestIsPriced or score < bestScore then
                    best, bestScore, bestIsPriced = candidate, score, true
                end
            elseif not bestIsPriced then
                local unknownScore = #candidate.missing / points

                if not best or unknownScore < bestScore then
                    best, bestScore = candidate, unknownScore
                end
            end
        end
    end

    return best
end

-- Recording a craft ---------------------------------------------------------------------------------------------------

local function BuyBookOnce(plan, candidate)
    if candidate.bookOwned then
        return
    end

    candidate.bookOwned = true
    plan.total = plan.total + candidate.bookPrice
    table.insert(plan.books, { recipe = candidate.recipe, itemID = candidate.bookItem, price = candidate.bookPrice })
end

-- The step the craft belongs to: the last one when it uses the same recipe, else a new one.
local function StepFor(plan, recipe, skill)
    local last = plan.steps[#plan.steps]

    if last and last.recipe == recipe then
        return last
    end

    local step = { from = skill, recipe = recipe, crafts = 0, cost = 0, partial = false }
    table.insert(plan.steps, step)
    return step
end

local function AddCost(plan, step, candidate)
    if candidate.cost then
        step.cost = step.cost + candidate.cost
        plan.total = plan.total + candidate.cost
    else
        step.partial, plan.partial = true, true
    end
end

local function AddShopping(plan, candidate)
    for _, part in ipairs(candidate.parts) do
        plan.shopping[part.itemID] = (plan.shopping[part.itemID] or 0) + part.count
        plan.usesAuction = plan.usesAuction or part.source == "auction"
        plan.usesVendor = plan.usesVendor or part.source == "vendor"
    end

    for _, itemID in ipairs(candidate.missing) do
        plan.unpriced[itemID] = true
        plan.shopping[itemID] = (plan.shopping[itemID] or 0) + 1
    end
end

local function RecordCraft(plan, candidate, skillBefore, skillAfter)
    BuyBookOnce(plan, candidate)

    local step = StepFor(plan, candidate.recipe, math.floor(skillBefore))
    step.crafts = step.crafts + 1
    step.to = math.min(plan.goal, math.floor(skillAfter))

    AddCost(plan, step, candidate)
    AddShopping(plan, candidate)
end

-- The plan ---------------------------------------------------------------------------------------------------------

local function NewPlan(skill, goal)
    return {
        start = skill, goal = goal, crafts = 0, steps = {}, total = 0, partial = false,
        shopping = {}, unpriced = {}, books = {},
    }
end

--[[
    Plan.Build(entry, skill, goal, known) -> plan or nil

    entry = a profession of SN.RecipeData, skill = the player's skill now, goal = the target skill,
    known = function(recipe) -> true when the player already knows the recipe (no book to buy).

    plan = {
        start, goal, crafts (total),
        steps = { { from, to, recipe (row), crafts, cost (copper or nil), partial } },
        total (copper of everything that has a price: crafts and books), partial (something has no price),
        shopping = { [itemID] = count }, unpriced = { [itemID] = true }, books = { { recipe, itemID, price } },
        stuck = skill where no recipe can give points (nil when the goal was reached),
        usesAuction (a price came from the Auction House), usesVendor
    }
]]
function Plan.Build(entry, skill, goal, known)
    if type(entry) ~= "table" or type(entry.recipes) ~= "table" or not tonumber(skill) or not tonumber(goal) or skill >= goal then
        return nil
    end

    local candidates = BuildCandidates(entry, goal, known)
    local plan = NewPlan(skill, goal)
    local current, crafts = skill, 0

    while current < goal and crafts < MAX_CRAFTS do
        local best = PickBest(candidates, current, goal)

        if not best then
            plan.stuck = math.floor(current)
            break
        end

        local skillBefore = current
        current = current + ExpectedPoints(best.recipe, math.floor(current))
        crafts = crafts + 1
        RecordCraft(plan, best, skillBefore, current)
    end

    plan.crafts = crafts
    plan.partial = plan.partial or next(plan.unpriced) ~= nil
    return plan
end

-- Text ------------------------------------------------------------------------------------------------------------

function Plan.Money(copper)
    copper = math.floor((copper or 0) + 0.5)
    local gold = math.floor(copper / COPPER_PER_GOLD)
    local silver = math.floor(copper / COPPER_PER_SILVER) % 100
    local rest = copper % 100

    if gold > 0 then
        return string.format("%dg %ds", gold, silver)
    elseif silver > 0 then
        return string.format("%ds %dc", silver, rest)
    end

    return string.format("%dc", rest)
end

local function ItemNameFromGame(itemID)
    if C_Item and C_Item.GetItemNameByID then
        local ok, name = pcall(C_Item.GetItemNameByID, itemID)

        if ok and type(name) == "string" then
            return name
        end
    end

    if GetItemInfo then
        local ok, name = pcall(GetItemInfo, itemID)

        if ok and type(name) == "string" then
            return name
        end
    end

    return nil
end

-- An item's name in the player's language when the game has it, else the English one of the data.
function Plan.ItemName(itemID)
    return ItemNameFromGame(itemID) or (SN.RecipeData and SN.RecipeData.items and SN.RecipeData.items[itemID]) or ("item " .. itemID)
end
