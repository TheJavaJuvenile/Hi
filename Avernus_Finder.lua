task.wait(10)

--==[ Settings ]==--
local maxLevel = _G.MaxAvernusLevel or 1000
local logFolder = "AvernusLogs"
if not isfolder(logFolder) then makefolder(logFolder) end
local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
local logFile = logFolder .. "/Avernus_Log_" .. timestamp .. ".txt"

--==[ Helper Functions ]==--
local function findSeasonData()
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" and rawget(obj, "Season") then
            local season = obj.Season
            if type(season) == "table" and season.Seed then
                return season
            end
        end
    end
    return nil
end

local function GetRarity(name)
    if name == "Avernus" then return "Secret"
    elseif name == "Hellcat" then return "Legendary"
    else return "Common" end
end

local function buildPool(pool)
    local weighted = {}
    for _, entry in ipairs(pool) do
        for _ = 1, math.floor(entry.Chance * 100) do
            table.insert(weighted, entry.Item)
        end
    end
    return weighted
end

local function pickItem(weighted, rng)
    local index = rng:NextInteger(1, #weighted)
    local item = weighted[index]

    local shinyRoll = rng:NextNumber() < 0.05
    local mythicRoll = rng:NextNumber() < 0.01
    local shiny = shinyRoll
    local mythic = mythicRoll
    local variant = mythic and shiny and "Mythic Shiny" or mythic and "Mythic" or shiny and "Shiny" or "Normal"

    return {
        Name = item.Name,
        Type = item.Type,
        Rarity = GetRarity(item.Name),
        Variant = variant
    }
end

--==[ GUI Display ]==--
local function displayInGui(results)
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    ScreenGui.Name = "AvernusGUI"

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.Size = UDim2.new(0, 400, 0, 300)
    Frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    Frame.Draggable = true
    Frame.Active = true
    Frame.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Text = "🎯 Avernus Finder Results"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18

    local Scroller = Instance.new("ScrollingFrame", Frame)
    Scroller.Position = UDim2.new(0, 0, 0, 30)
    Scroller.Size = UDim2.new(1, 0, 1, -30)
    Scroller.CanvasSize = UDim2.new(0, 0, 0, #results * 30)
    Scroller.ScrollBarThickness = 6
    Scroller.BackgroundTransparency = 1

    for i, text in ipairs(results) do
        local Label = Instance.new("TextLabel", Scroller)
        Label.Size = UDim2.new(1, -10, 0, 30)
        Label.Position = UDim2.new(0, 5, 0, (i - 1) * 30)
        Label.Text = text
        Label.TextColor3 = Color3.new(1, 1, 1)
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 16
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left
    end
end

--==[ Simulated Pet Pool ]==--
local pool = {
    { Chance = 0.05, Item = { Type = "Pet", Name = "Avernus" } },
    { Chance = 20, Item = { Type = "Pet", Name = "Hellcat" } },
    { Chance = 30, Item = { Type = "Pet", Name = "Firefly" } },
    { Chance = 49.95, Item = { Type = "Potion", Name = "Bubbles" } },
}

--==[ Finder Logic ]==--
local function findAvernus(seed, startCost, startIndex, pool)
    local weightedPool = buildPool(pool)
    local results = {}
    local username = game.Players.LocalPlayer.Name

    for level = startIndex + 1, maxLevel do
        local rng = Random.new(seed + level)
        local free = pickItem(weightedPool, rng)
        local premium = pickItem(weightedPool, rng)

        local function handleRoll(roll, rewardType)
            if roll.Name == "Avernus" then
                local resultText = string.format("🎯 %s FOUND at Level %d [%s] | Variant: %s", roll.Name, level, rewardType, roll.Variant)
                table.insert(results, resultText)

                if level < 50 then
                    local log = string.format("User: %s | Level: %d | Type: %s | Rarity: %s\n", username, level, rewardType, roll.Variant)
                    appendfile(logFile, log)
                end
            end
        end

        handleRoll(free, "Free")
        handleRoll(premium, "Premium")
    end

    if #results == 0 then
        table.insert(results, "❌ Avernus not found within the range.")
    end

    displayInGui(results)
end

--==[ Run Script ]==--
local season = findSeasonData()
if season then
    findAvernus(season.Seed, season.LastCost, season.LastCostIndex, pool)
else
    warn("❌ Season data not found.")
end
