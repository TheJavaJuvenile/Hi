task.spawn(function()
    task.wait(10)

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UIS = game:GetService("UserInputService")
    local MAX_LEVEL_CHECK = _G.MaxAvernusLevel or 1000

    -- GUI Creation
    local function createGui()
        local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
        screenGui.Name = "AvernusResultGUI"
        screenGui.ResetOnSpawn = false

        local frame = Instance.new("Frame", screenGui)
        frame.Size = UDim2.new(0, 400, 0, 200)
        frame.Position = UDim2.new(0.5, -200, 0.4, 0)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true

        -- Drag fallback
        local dragging, dragStart, startPos
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundTransparency = 1
        title.Text = "🎯 Avernus Finder Result"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 22

        local info = Instance.new("TextLabel", frame)
        info.Name = "Info"
        info.Size = UDim2.new(1, -20, 1, -50)
        info.Position = UDim2.new(0, 10, 0, 45)
        info.BackgroundTransparency = 1
        info.TextColor3 = Color3.fromRGB(200, 200, 200)
        info.Font = Enum.Font.Gotham
        info.TextSize = 18
        info.TextWrapped = true
        info.TextYAlignment = Enum.TextYAlignment.Top
        info.Text = "Searching..."

        return info
    end

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

    local pool = {
        { Chance = 0.05, Item = { Type = "Pet", Name = "Avernus" } },
        { Chance = 20, Item = { Type = "Pet", Name = "Hellcat" } },
        { Chance = 30, Item = { Type = "Pet", Name = "Firefly" } },
        { Chance = 49.95, Item = { Type = "Potion", Name = "Bubbles" } },
    }

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
        local item = weighted[rng:NextInteger(1, #weighted)]
        local clone = table.clone(item)

        local shiny = rng:NextInteger(1, 50) == 1
        local mythic = rng:NextInteger(1, 200) == 1

        if shiny and mythic then
            clone.Rarity = "Mythic Shiny"
        elseif mythic then
            clone.Rarity = "Mythic"
        elseif shiny then
            clone.Rarity = "Shiny"
        else
            clone.Rarity = GetRarity(clone.Name)
        end

        return clone
    end

    local function findAvernus(seed, startCost, startIndex, pool, guiInfoLabel)
        local weightedPool = buildPool(pool)
        local foundVariants = {}

        for level = startIndex + 1, MAX_LEVEL_CHECK do
            local rng = Random.new(seed + level)
            local free = pickItem(weightedPool, rng)
            local premium = pickItem(weightedPool, rng)

            if free.Name == "Avernus" then
                table.insert(foundVariants, {
                    Level = level,
                    Type = "Free",
                    Rarity = free.Rarity
                })
            end

            if premium.Name == "Avernus" then
                table.insert(foundVariants, {
                    Level = level,
                    Type = "Premium",
                    Rarity = premium.Rarity
                })
            end

            if #foundVariants > 0 then break end
        end

        if #foundVariants == 0 then
            guiInfoLabel.Text = "❌ Avernus not found within " .. MAX_LEVEL_CHECK .. " levels."
        else
            local summary = "👤 Username: " .. (LocalPlayer and LocalPlayer.Name or "N/A") .. "\n"
            for _, v in pairs(foundVariants) do
                summary = summary .. string.format("🎯 Found Avernus at Level %d [%s] - %s\n", v.Level, v.Type, v.Rarity)
            end
            guiInfoLabel.Text = summary
        end
    end

    local label = createGui()
    local season = findSeasonData()
    if season then
        findAvernus(season.Seed, season.LastCost, season.LastCostIndex, pool, label)
    else
        label.Text = "❌ Could not find Season data."
    end
end)
