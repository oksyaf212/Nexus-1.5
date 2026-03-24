--[[
    ============================================================================
    NEXUS Lite — Mobile Optimized Hub
    Platform: Delta Executor (Android)
    Fitur: ESP, Aimbot, Speed, Fly, NoClip, Infinite Jump, Auto Farm, Blink Attack
    Teknologi: Maid, Config Load/Save, Touch Slider, Drawing API
    ============================================================================
]]

-- ============================================================================
-- [1] SERVICES & GLOBALS
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================================
-- [2] MAID PATTERN (Cleanup)
-- ============================================================================
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({_jobs = {}}, Maid)
end

function Maid:Add(job)
    table.insert(self._jobs, job)
    return job
end

function Maid:Destroy()
    for _, job in ipairs(self._jobs) do
        if typeof(job) == "RBXScriptConnection" then
            pcall(function() job:Disconnect() end)
        elseif type(job) == "function" then
            pcall(job)
        elseif typeof(job) == "Instance" then
            pcall(function() job:Destroy() end)
        end
    end
    self._jobs = {}
end

local Core = Maid.new()
getgenv().NexusLite = Core -- untuk akses global jika perlu

-- ============================================================================
-- [3] CONFIGURATION
-- ============================================================================
local CONFIG_FILE = "nexus_lite_config.json"

local Config = {
    ESP = {
        Enabled = false,
        ShowBox = true,
        ShowName = true,
        ShowHealth = true,
        ShowDistance = true,
        ShowSnapLine = false,
        ShowHeadDot = false,
        ShowChams = false,
        TeamColor = Color3.fromRGB(30, 220, 80),
        EnemyColor = Color3.fromRGB(255, 50, 50),
    },
    Aimbot = {
        Enabled = false,
        FOVRadius = 200,
        Smoothness = 0.35,
        WallCheck = true,
        TeamCheck = true,
    },
    Movement = {
        Speed = false,
        SpeedValue = 60,
        NoClip = false,
        InfJump = false,
        Fly = false,
        FlySpeed = 50,
    },
    Teleport = {
        AutoMonster = false,
        AutoEnemy = false,
        Radius = 500,
    },
    RPG = {
        AutoFarm = false,
        BlinkAttack = false,
        BlinkRadius = 400,
        BlinkInterval = 1.5,
    },
    Visual = {
        Crosshair = false,
        CrossStyle = "Cross", -- Dot, Cross, Circle
        FPSPing = true,
        Radar = false,
        RadarRadius = 80,
    },
    UI = {
        Theme = "Blue",
        Opacity = 0.9,
        Position = "TopLeft", -- TopLeft, TopRight, BottomLeft, BottomRight
        TextSize = 11,
    },
}

-- Theme colors
local Themes = {
    Blue  = { primary = Color3.fromRGB(40, 100, 255), bg = Color3.fromRGB(14, 14, 20), topbar = Color3.fromRGB(20, 20, 30) },
    Red   = { primary = Color3.fromRGB(220, 40, 40),  bg = Color3.fromRGB(18, 10, 10), topbar = Color3.fromRGB(28, 12, 12) },
    Green = { primary = Color3.fromRGB(30, 200, 80),  bg = Color3.fromRGB(10, 18, 12), topbar = Color3.fromRGB(12, 26, 16) },
    Purple= { primary = Color3.fromRGB(150, 50, 255), bg = Color3.fromRGB(14, 10, 20), topbar = Color3.fromRGB(20, 12, 30) },
}
local CurrentTheme = Themes[Config.UI.Theme] or Themes.Blue

-- Save/Load Config
local function SaveConfig()
    pcall(function()
        local data = {
            ESP = Config.ESP,
            Aimbot = Config.Aimbot,
            Movement = Config.Movement,
            Teleport = Config.Teleport,
            RPG = Config.RPG,
            Visual = Config.Visual,
            UI = Config.UI,
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function LoadConfig()
    pcall(function()
        if not isfile(CONFIG_FILE) then return end
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if not data then return end
        -- Merge data (simple assignment)
        for k, v in pairs(data) do
            if Config[k] then
                for k2, v2 in pairs(v) do
                    Config[k][k2] = v2
                end
            end
        end
        -- Apply loaded theme
        CurrentTheme = Themes[Config.UI.Theme] or Themes.Blue
    end)
end
LoadConfig()

-- ============================================================================
-- [4] UTILITIES
-- ============================================================================
local function Notify(msg, isOn, isError)
    pcall(function()
        StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("SendNotification", {
            Title = isError and "⚠️ Error" or (isOn and "✅ ON" or "❌ OFF"),
            Text = msg,
            Duration = 2,
        })
    end)
end

local function ShowConfirm(msg, onYes, onNo)
    pcall(function()
        local sg = Instance.new("ScreenGui", CoreGui)
        sg.Name = "NexusConfirm"
        sg.ResetOnSpawn = false
        local frame = Instance.new("Frame", sg)
        frame.Size = UDim2.new(0, 240, 0, 90)
        frame.Position = UDim2.new(0.5, -120, 0.5, -45)
        frame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        Instance.new("UIStroke", frame).Color = CurrentTheme.primary
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -10, 0, 40)
        label.Position = UDim2.new(0, 5, 0, 8)
        label.BackgroundTransparency = 1
        label.Text = msg
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextWrapped = true
        local yes = Instance.new("TextButton", frame)
        yes.Size = UDim2.new(0, 100, 0, 28)
        yes.Position = UDim2.new(0, 10, 1, -36)
        yes.BackgroundColor3 = Color3.fromRGB(30, 120, 30)
        yes.Text = "✅ Ya"
        yes.TextColor3 = Color3.fromRGB(255, 255, 255)
        yes.Font = Enum.Font.GothamBold
        yes.TextSize = 12
        Instance.new("UICorner", yes).CornerRadius = UDim.new(0, 6)
        local no = Instance.new("TextButton", frame)
        no.Size = UDim2.new(0, 100, 0, 28)
        no.Position = UDim2.new(1, -110, 1, -36)
        no.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
        no.Text = "❌ Tidak"
        no.TextColor3 = Color3.fromRGB(255, 255, 255)
        no.Font = Enum.Font.GothamBold
        no.TextSize = 12
        Instance.new("UICorner", no).CornerRadius = UDim.new(0, 6)
        yes.MouseButton1Click:Connect(function()
            sg:Destroy()
            pcall(onYes)
        end)
        no.MouseButton1Click:Connect(function()
            sg:Destroy()
            if onNo then pcall(onNo) end
        end)
        Core:Add(sg)
    end)
end

-- Helper: Get relation
local function GetRelation(player)
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
        return "Team"
    end
    return "Enemy"
end

-- Helper: Get nearest monster
local function GetNearestMonster(radius)
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local nearest, minDist = nil, radius or math.huge
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local isPlayer = false
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Character == obj then isPlayer = true; break end
            end
            if not isPlayer then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest
end

-- Helper: Get nearest enemy player
local function GetNearestEnemy()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local nearest, minDist = nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == LocalPlayer then continue end
        if GetRelation(pl) == "Team" then continue end
        local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
        local hum = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local dist = (hrp.Position - myHRP.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = pl
            end
        end
    end
    return nearest
end

-- ============================================================================
-- [5] DRAWING (FPS, Ping, Crosshair)
-- ============================================================================
local fpsDraw = Drawing.new("Text")
fpsDraw.Size = 13
fpsDraw.Center = true
fpsDraw.Outline = true
fpsDraw.Visible = true
fpsDraw.ZIndex = 11
Core:Add(function() pcall(function() fpsDraw:Remove() end) end)

local fpsCounter = 0
local fpsTimer = 0
local fpsValue = 0
local pingValue = 0

Core:Add(RunService.RenderStepped:Connect(function(dt)
    -- FPS
    fpsCounter = fpsCounter + 1
    fpsTimer = fpsTimer + dt
    if fpsTimer >= 0.5 then
        fpsValue = math.floor(fpsCounter / fpsTimer)
        fpsCounter = 0
        fpsTimer = 0
    end
    -- Ping
    pcall(function() pingValue = math.floor(LocalPlayer.NetworkPing * 1000) end)

    if Config.Visual.FPSPing then
        local fpsColor = fpsValue >= 50 and Color3.fromRGB(80, 255, 80) or
                        (fpsValue >= 30 and Color3.fromRGB(255, 220, 50) or Color3.fromRGB(255, 60, 60))
        local pingColor = pingValue <= 80 and Color3.fromRGB(80, 255, 80) or
                          (pingValue <= 150 and Color3.fromRGB(255, 220, 50) or Color3.fromRGB(255, 60, 60))
        local worstColor = (fpsValue < 30 or pingValue > 150) and Color3.fromRGB(255, 60, 60) or
                           (fpsValue < 50 or pingValue > 80) and Color3.fromRGB(255, 220, 50) or
                           Color3.fromRGB(80, 255, 80)
        fpsDraw.Color = worstColor
        fpsDraw.Position = Vector2.new(Camera.ViewportSize.X / 2, 14)
        fpsDraw.Text = string.format("FPS: %d  |  Ping: %dms", fpsValue, pingValue)
        fpsDraw.Visible = true
    else
        fpsDraw.Visible = false
    end
end))

-- Crosshair
local crosshairObjects = {}
local function UpdateCrosshair()
    for _, obj in ipairs(crosshairObjects) do pcall(function() obj:Remove() end) end
    crosshairObjects = {}
    if not Config.Visual.Crosshair then return end
    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2
    local style = Config.Visual.CrossStyle
    local color = CurrentTheme.primary
    local size = 10
    local thickness = 1.5
    if style == "Dot" then
        local dot = Drawing.new("Circle")
        dot.Position = Vector2.new(cx, cy)
        dot.Radius = thickness + 1
        dot.Filled = true
        dot.Color = color
        dot.Visible = true
        dot.ZIndex = 10
        table.insert(crosshairObjects, dot)
    elseif style == "Cross" then
        local h = Drawing.new("Line")
        h.From = Vector2.new(cx - size, cy)
        h.To = Vector2.new(cx + size, cy)
        h.Thickness = thickness
        h.Color = color
        h.Visible = true
        h.ZIndex = 10
        table.insert(crosshairObjects, h)
        local v = Drawing.new("Line")
        v.From = Vector2.new(cx, cy - size)
        v.To = Vector2.new(cx, cy + size)
        v.Thickness = thickness
        v.Color = color
        v.Visible = true
        v.ZIndex = 10
        table.insert(crosshairObjects, v)
    elseif style == "Circle" then
        local circ = Drawing.new("Circle")
        circ.Position = Vector2.new(cx, cy)
        circ.Radius = size
        circ.Filled = false
        circ.Thickness = thickness
        circ.NumSides = 32
        circ.Color = color
        circ.Visible = true
        circ.ZIndex = 10
        table.insert(crosshairObjects, circ)
    end
end
Core:Add(UpdateCrosshair)

-- ============================================================================
-- [6] ESP MODULE
-- ============================================================================
local ESPCache = {}
local chamsCache = {}

local function ApplyChams(player, on)
    if not Config.ESP.ShowChams then return end
    local char = player.Character
    if not char then return end
    local col = GetRelation(player) == "Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor
    if on then
        chamsCache[player] = chamsCache[player] or {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                chamsCache[player][part] = part.Color
                part.Color = col
                part.Material = Enum.Material.Neon
            end
        end
    else
        if chamsCache[player] then
            for part, origColor in pairs(chamsCache[player]) do
                pcall(function() part.Color = origColor; part.Material = Enum.Material.SmoothPlastic end)
            end
            chamsCache[player] = nil
        end
    end
end

local function CreateESP(player)
    if player == LocalPlayer or ESPCache[player] then return end
    local c = {
        Highlight = Instance.new("Highlight"),
        BoxT = Drawing.new("Line"), BoxB = Drawing.new("Line"),
        BoxL = Drawing.new("Line"), BoxR = Drawing.new("Line"),
        NameText = Drawing.new("Text"),
        DistText = Drawing.new("Text"),
        HealthBg = Drawing.new("Line"), HealthFg = Drawing.new("Line"),
        SnapLine = Drawing.new("Line"),
        HeadDot = Drawing.new("Circle"),
        Bones = {},
    }
    c.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    c.Highlight.FillTransparency = 0.6
    c.Highlight.OutlineTransparency = 0.2
    c.Highlight.Parent = CoreGui
    local function updateColors()
        local col = GetRelation(player) == "Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor
        c.Highlight.FillColor = col
        c.Highlight.OutlineColor = col
        for _, obj in ipairs({c.BoxT, c.BoxB, c.BoxL, c.BoxR, c.NameText, c.DistText, c.SnapLine, c.HeadDot}) do
            pcall(function() obj.Color = col end)
        end
        for _, b in ipairs(c.Bones) do pcall(function() b.Color = col end) end
    end
    updateColors()
    c.updateColor = updateColors

    -- Skeleton bones
    local boneDefs = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"LowerTorso", "LeftUpperLeg"}, {"LowerTorso", "RightUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"}, {"RightUpperLeg", "RightLowerLeg"},
        {"UpperTorso", "LeftUpperArm"}, {"UpperTorso", "RightUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"}, {"RightUpperArm", "RightLowerArm"},
    }
    for i = 1, #boneDefs do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Visible = false
        line.ZIndex = 3
        c.Bones[i] = line
    end

    -- Connect to character added
    c.CharacterAdded = player.CharacterAdded:Connect(function(char)
        c.Highlight.Adornee = char
        if Config.ESP.ShowChams then ApplyChams(player, true) end
    end)
    if player.Character then
        c.Highlight.Adornee = player.Character
        if Config.ESP.ShowChams then ApplyChams(player, true) end
    end

    ESPCache[player] = c
end

local function RemoveESP(player)
    local c = ESPCache[player]
    if not c then return end
    ApplyChams(player, false)
    if c.CharacterAdded then c.CharacterAdded:Disconnect() end
    pcall(function() c.Highlight:Destroy() end)
    for _, obj in ipairs({c.BoxT, c.BoxB, c.BoxL, c.BoxR, c.NameText, c.DistText, c.SnapLine, c.HeadDot}) do
        pcall(function() obj:Remove() end)
    end
    for _, b in ipairs(c.Bones) do pcall(function() b:Remove() end) end
    ESPCache[player] = nil
end

-- Create ESP for existing players
for _, pl in ipairs(Players:GetPlayers()) do CreateESP(pl) end
Core:Add(Players.PlayerAdded:Connect(CreateESP))
Core:Add(Players.PlayerRemoving:Connect(RemoveESP))

local function UpdateESP()
    if not Config.ESP.Enabled then
        for pl, c in pairs(ESPCache) do
            c.Highlight.Enabled = false
            for _, obj in ipairs({c.BoxT, c.BoxB, c.BoxL, c.BoxR, c.NameText, c.DistText, c.SnapLine, c.HeadDot}) do
                obj.Visible = false
            end
            for _, b in ipairs(c.Bones) do b.Visible = false end
        end
        return
    end

    local vp = Camera.ViewportSize
    for pl, c in pairs(ESPCache) do
        local char = pl.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hum and hrp and hum.Health > 0) then
            c.Highlight.Enabled = false
            for _, obj in ipairs({c.BoxT, c.BoxB, c.BoxL, c.BoxR, c.NameText, c.DistText, c.SnapLine, c.HeadDot}) do
                obj.Visible = false
            end
            for _, b in ipairs(c.Bones) do b.Visible = false end
            continue
        end

        c.Highlight.Enabled = true
        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        if dist > 1500 then
            -- Too far, hide overlay lines
            for _, obj in ipairs({c.BoxT, c.BoxB, c.BoxL, c.BoxR, c.NameText, c.DistText, c.SnapLine, c.HeadDot}) do
                obj.Visible = false
            end
            for _, b in ipairs(c.Bones) do b.Visible = false end
            continue
        end

        -- Update color if relation changed
        c.updateColor()

        -- Get screen positions
        local topV, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3.2, 0))
        local botV = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.2, 0))
        if not onScreen then
            -- hide lines
            for _, obj in ipairs({c.BoxT, c.BoxB, c.BoxL, c.BoxR, c.NameText, c.DistText, c.SnapLine, c.HeadDot}) do
                obj.Visible = false
            end
            for _, b in ipairs(c.Bones) do b.Visible = false end
            continue
        end

        local cx = topV.X
        local cyTop = topV.Y
        local cyBot = botV.Y
        local height = cyBot - cyTop
        local width = height * 0.5
        local left = cx - width/2
        local right = cx + width/2

        -- Box
        if Config.ESP.ShowBox then
            c.BoxT.From = Vector2.new(left, cyTop)
            c.BoxT.To = Vector2.new(right, cyTop)
            c.BoxT.Visible = true
            c.BoxB.From = Vector2.new(left, cyBot)
            c.BoxB.To = Vector2.new(right, cyBot)
            c.BoxB.Visible = true
            c.BoxL.From = Vector2.new(left, cyTop)
            c.BoxL.To = Vector2.new(left, cyBot)
            c.BoxL.Visible = true
            c.BoxR.From = Vector2.new(right, cyTop)
            c.BoxR.To = Vector2.new(right, cyBot)
            c.BoxR.Visible = true
        else
            c.BoxT.Visible = false; c.BoxB.Visible = false
            c.BoxL.Visible = false; c.BoxR.Visible = false
        end

        -- Name
        if Config.ESP.ShowName then
            c.NameText.Text = pl.Name
            c.NameText.Position = Vector2.new(cx, cyTop - 15)
            c.NameText.Size = Config.UI.TextSize
            c.NameText.Center = true
            c.NameText.Outline = true
            c.NameText.Visible = true
        else
            c.NameText.Visible = false
        end

        -- Distance
        if Config.ESP.ShowDistance then
            c.DistText.Text = string.format("[%.0fm]", dist)
            c.DistText.Position = Vector2.new(cx, cyBot + 8)
            c.DistText.Size = Config.UI.TextSize - 1
            c.DistText.Center = true
            c.DistText.Outline = true
            c.DistText.Visible = true
        else
            c.DistText.Visible = false
        end

        -- Health bar
        if Config.ESP.ShowHealth then
            local hp = hum.Health / math.max(hum.MaxHealth, 1)
            local barX = left - 6
            c.HealthBg.From = Vector2.new(barX, cyTop)
            c.HealthBg.To = Vector2.new(barX, cyBot)
            c.HealthBg.Thickness = 3
            c.HealthBg.Color = Color3.new(0, 0, 0)
            c.HealthBg.Visible = true
            c.HealthFg.From = Vector2.new(barX, cyBot)
            c.HealthFg.To = Vector2.new(barX, cyBot - height * hp)
            c.HealthFg.Thickness = 3
            c.HealthFg.Color = Color3.new(1 - hp, hp, 0)
            c.HealthFg.Visible = true
        else
            c.HealthBg.Visible = false
            c.HealthFg.Visible = false
        end

        -- Snap line
        if Config.ESP.ShowSnapLine then
            c.SnapLine.From = Vector2.new(vp.X/2, vp.Y)
            c.SnapLine.To = Vector2.new(cx, cyBot)
            c.SnapLine.Thickness = 1
            c.SnapLine.Visible = true
        else
            c.SnapLine.Visible = false
        end

        -- Head dot
        if Config.ESP.ShowHeadDot then
            local headPos = char:FindFirstChild("Head")
            if headPos then
                local headV, headOn = Camera:WorldToViewportPoint(headPos.Position)
                if headOn then
                    c.HeadDot.Position = Vector2.new(headV.X, headV.Y)
                    c.HeadDot.Radius = 3
                    c.HeadDot.Filled = true
                    c.HeadDot.Visible = true
                else
                    c.HeadDot.Visible = false
                end
            else
                c.HeadDot.Visible = false
            end
        else
            c.HeadDot.Visible = false
        end

        -- Skeleton (simplified)
        if Config.ESP.ShowSkeleton then
            for i, def in ipairs(boneDefs) do
                local p1 = char:FindFirstChild(def[1])
                local p2 = char:FindFirstChild(def[2])
                if p1 and p2 then
                    local v1, on1 = Camera:WorldToViewportPoint(p1.Position)
                    local v2, on2 = Camera:WorldToViewportPoint(p2.Position)
                    if on1 and on2 then
                        c.Bones[i].From = Vector2.new(v1.X, v1.Y)
                        c.Bones[i].To = Vector2.new(v2.X, v2.Y)
                        c.Bones[i].Visible = true
                    else
                        c.Bones[i].Visible = false
                    end
                else
                    c.Bones[i].Visible = false
                end
            end
        else
            for _, b in ipairs(c.Bones) do b.Visible = false end
        end
    end
end

-- ============================================================================
-- [7] AIMBOT MODULE
-- ============================================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Visible = false
Core:Add(function() pcall(function() FOVCircle:Remove() end) end)

local lastCamCF = nil
local function UpdateAimbot()
    if not Config.Aimbot.Enabled then
        FOVCircle.Visible = false
        return
    end
    FOVCircle.Radius = Config.Aimbot.FOVRadius
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Color = CurrentTheme.primary
    FOVCircle.Visible = true

    local bestTarget, bestScore = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and GetRelation(pl) == "Team" then continue end
        local head = pl.Character and pl.Character:FindFirstChild("Head")
        local hum = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
        if not (head and hum and hum.Health > 0) then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local screenDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if screenDist > Config.Aimbot.FOVRadius then continue end
        -- Simple wall check
        if Config.Aimbot.WallCheck then
            local ray = RaycastParams.new()
            ray.FilterDescendantsInstances = {LocalPlayer.Character, pl.Character}
            local result = workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, ray)
            if result then continue end
        end
        if screenDist < bestScore then
            bestScore = screenDist
            bestTarget = pl
        end
    end
    if bestTarget then
        local head = bestTarget.Character and bestTarget.Character:FindFirstChild("Head")
        if head then
            local targetCF = CFrame.lookAt(Camera.CFrame.Position, head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, Config.Aimbot.Smoothness)
        end
    end
end

-- ============================================================================
-- [8] MOVEMENT MODS
-- ============================================================================
-- Speed
local speedConn
local function SetSpeed(on)
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    if on then
        speedConn = RunService.Heartbeat:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= Config.Movement.SpeedValue then
                hum.WalkSpeed = Config.Movement.SpeedValue
            end
        end)
    else
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
    end
end

-- NoClip
local noclipConn
local function SetNoClip(on)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then root.CanCollide = false end
                local torso = char:FindFirstChild("Torso")
                if torso then torso.CanCollide = false end
            end
        end)
    else
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.CanCollide = true end
            local torso = char:FindFirstChild("Torso")
            if torso then torso.CanCollide = true end
        end
    end
end

-- Infinite Jump
local infJumpConn
local function SetInfJump(on)
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    if on then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

-- Fly (mobile-friendly using MoveDirection)
local flyBV, flyConn
local flyUp, flyDown = false, false
local function SetFly(on)
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if on then
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart")
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(10000, 10000, 10000)
        flyBV.Parent = hrp
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
        flyConn = RunService.RenderStepped:Connect(function()
            if not Config.Movement.Fly then
                SetFly(false)
                return
            end
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp or not flyBV then return
            end
            local moveDir = Vector3.new()
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0 then
                moveDir = hum.MoveDirection
            else
                -- Fallback keyboard
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + hrp.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - hrp.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + hrp.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - hrp.CFrame.RightVector end
            end
            if flyUp then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if flyDown then moveDir = moveDir - Vector3.new(0, 1, 0) end
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * Config.Movement.FlySpeed
            end
            flyBV.Velocity = moveDir
        end)
    else
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- Fly controls
local function SetFlyUp(on) flyUp = on end
local function SetFlyDown(on) flyDown = on end

-- ============================================================================
-- [9] TELEPORT SYSTEM
-- ============================================================================
local teleportHistory = {}
local maxHistory = 5

local function SaveTeleportPosition()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        table.insert(teleportHistory, 1, hrp.CFrame)
        if #teleportHistory > maxHistory then table.remove(teleportHistory) end
    end
end

local function TeleportBack()
    if #teleportHistory == 0 then Notify("No history", false, true) return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = table.remove(teleportHistory, 1)
        Notify("Teleported back", true)
    end
end

local function TeleportToPlayer(name)
    local target
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Name:lower():find(name:lower()) and pl ~= LocalPlayer then
            target = pl; break
        end
    end
    if not target then Notify("Player not found", false, true) return end
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not (tHRP and hrp) then Notify("Character not loaded", false, true) return end
    SaveTeleportPosition()
    hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, -4)
    Notify("Teleported to " .. target.Name, true)
end

-- Auto teleport to monster
local autoMonsterConn
local function SetAutoMonster(on)
    if autoMonsterConn then autoMonsterConn:Disconnect(); autoMonsterConn = nil end
    if on then
        local lastTime = 0
        autoMonsterConn = RunService.Heartbeat:Connect(function(dt)
            if not Config.Teleport.AutoMonster then return end
            lastTime = lastTime + dt
            if lastTime < 0.2 then return end
            lastTime = 0
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local monster = GetNearestMonster(Config.Teleport.Radius)
            if monster then
                local mHRP = monster:FindFirstChild("HumanoidRootPart")
                if mHRP then
                    SaveTeleportPosition()
                    hrp.CFrame = mHRP.CFrame * CFrame.new(0, 0, -2.5)
                end
            end
        end)
    end
end

-- Auto teleport to enemy (behind)
local autoEnemyConn
local function SetAutoEnemy(on)
    if autoEnemyConn then autoEnemyConn:Disconnect(); autoEnemyConn = nil end
    if on then
        local lastTime = 0
        autoEnemyConn = RunService.Heartbeat:Connect(function(dt)
            if not Config.Teleport.AutoEnemy then return end
            lastTime = lastTime + dt
            if lastTime < 0.2 then return end
            lastTime = 0
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local enemy = GetNearestEnemy()
            if enemy then
                local eHRP = enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart")
                if eHRP then
                    SaveTeleportPosition()
                    hrp.CFrame = eHRP.CFrame * CFrame.new(0, 0, 2.5) -- behind
                end
            end
        end)
    end
end

-- ============================================================================
-- [10] RPG FEATURES
-- ============================================================================
-- Auto Farm
local autoFarmConn
local function SetAutoFarm(on)
    if autoFarmConn then autoFarmConn:Disconnect(); autoFarmConn = nil end
    if on then
        local lastTime = 0
        autoFarmConn = RunService.Heartbeat:Connect(function(dt)
            if not Config.RPG.AutoFarm then return end
            lastTime = lastTime + dt
            if lastTime < 0.3 then return end
            lastTime = 0
            local monster = GetNearestMonster(Config.Teleport.Radius)
            if monster then
                local mHRP = monster:FindFirstChild("HumanoidRootPart")
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if mHRP and hrp then
                    hrp.CFrame = mHRP.CFrame * CFrame.new(0, 0, -2.5)
                    task.wait(0.1)
                    pcall(function() mouse1click() end)
                end
            end
        end)
    end
end

-- Blink Attack
local blinkConn, blinkActive = nil, false
local blinkOrigin = nil
local blinkTimer = 0
local function SetBlinkAttack(on)
    if blinkConn then blinkConn:Disconnect(); blinkConn = nil end
    if on then
        blinkTimer = 0
        blinkConn = RunService.Heartbeat:Connect(function(dt)
            if not Config.RPG.BlinkAttack then return end
            blinkTimer = blinkTimer + dt
            if blinkTimer < Config.RPG.BlinkInterval then return end
            blinkTimer = 0
            if blinkActive then return end
            blinkActive = true
            task.spawn(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then blinkActive = false; return end
                local target = GetNearestMonster(Config.RPG.BlinkRadius)
                if not target then blinkActive = false; return end
                local tHRP = target:FindFirstChild("HumanoidRootPart")
                if not tHRP then blinkActive = false; return end
                blinkOrigin = hrp.CFrame
                hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, -3)
                task.wait(0.1)
                pcall(function() mouse1click() end)
                task.wait(0.3)
                if blinkOrigin then
                    hrp.CFrame = blinkOrigin
                    task.wait(0.1)
                    pcall(function() mouse1click() end)
                    blinkOrigin = nil
                end
                blinkActive = false
            end)
        end)
    else
        if blinkOrigin then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = blinkOrigin end
            blinkOrigin = nil
        end
        blinkActive = false
    end
end

-- ============================================================================
-- [11] UI BUILDER (Floating Menu)
-- ============================================================================
local ScreenGui, Wrapper, MainFrame, Content, TabBar, Tabs = nil, nil, nil, nil, nil, {}
local minimized = false
local dragData = { dragging = false, start = nil, startPos = nil }

local function ApplyTheme()
    CurrentTheme = Themes[Config.UI.Theme] or Themes.Blue
    if Wrapper then
        pcall(function()
            local stroke = Wrapper:FindFirstChild("UIStroke")
            if stroke then stroke.Color = CurrentTheme.primary end
            MainFrame.BackgroundColor3 = CurrentTheme.bg
            MainFrame.BackgroundTransparency = 1 - Config.UI.Opacity
            local topbar = MainFrame:FindFirstChild("TopBar")
            if topbar then topbar.BackgroundColor3 = CurrentTheme.topbar end
            if TabBar then TabBar.ScrollBarImageColor3 = CurrentTheme.primary end
            for _, tab in ipairs(Tabs) do
                if tab.button then
                    tab.button.BackgroundColor3 = (tab.active and CurrentTheme.primary) or Color3.fromRGB(28, 28, 40)
                end
            end
        end)
    end
end

local function BuildUI()
    -- Create ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NexusLiteUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    Core:Add(ScreenGui)

    -- Position presets
    local positions = {
        TopLeft = UDim2.new(0.02, 0, 0.06, 0),
        TopRight = UDim2.new(0.98, -265, 0.06, 0),
        BottomLeft = UDim2.new(0.02, 0, 0.94, -455),
        BottomRight = UDim2.new(0.98, -265, 0.94, -455),
    }
    local startPos = positions[Config.UI.Position] or positions.TopLeft

    -- Wrapper (for dragging)
    Wrapper = Instance.new("Frame", ScreenGui)
    Wrapper.Size = UDim2.new(0, 265, 0, 455)
    Wrapper.Position = startPos
    Wrapper.BackgroundTransparency = 1
    Wrapper.Name = "Wrapper"
    Instance.new("UICorner", Wrapper).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", Wrapper)
    stroke.Color = CurrentTheme.primary
    stroke.Thickness = 1.5

    -- Main frame
    MainFrame = Instance.new("Frame", Wrapper)
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.BackgroundColor3 = CurrentTheme.bg
    MainFrame.BackgroundTransparency = 1 - Config.UI.Opacity
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    -- Top bar
    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 36)
    TopBar.BackgroundColor3 = CurrentTheme.topbar
    TopBar.BorderSizePixel = 0
    local title = Instance.new("TextLabel", TopBar)
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ NEXUS Lite"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Panic button
    local panicBtn = Instance.new("TextButton", TopBar)
    panicBtn.Size = UDim2.new(0, 24, 0, 24)
    panicBtn.Position = UDim2.new(1, -80, 0.5, -12)
    panicBtn.BackgroundColor3 = Color3.fromRGB(140, 20, 20)
    panicBtn.Text = "❌"
    panicBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    panicBtn.Font = Enum.Font.GothamBold
    panicBtn.TextSize = 11
    panicBtn.BorderSizePixel = 0
    Instance.new("UICorner", panicBtn).CornerRadius = UDim.new(0, 5)
    Core:Add(panicBtn.MouseButton1Click:Connect(function()
        -- Panic: disable all toggles
        Config.ESP.Enabled = false
        Config.Aimbot.Enabled = false
        Config.Movement.Speed = false; SetSpeed(false)
        Config.Movement.NoClip = false; SetNoClip(false)
        Config.Movement.InfJump = false; SetInfJump(false)
        Config.Movement.Fly = false; SetFly(false)
        Config.Teleport.AutoMonster = false; SetAutoMonster(false)
        Config.Teleport.AutoEnemy = false; SetAutoEnemy(false)
        Config.RPG.AutoFarm = false; SetAutoFarm(false)
        Config.RPG.BlinkAttack = false; SetBlinkAttack(false)
        Notify("Panic: All features OFF", true, false)
    end))

    -- Hide button (to pill)
    local hideBtn = Instance.new("TextButton", TopBar)
    hideBtn.Size = UDim2.new(0, 24, 0, 24)
    hideBtn.Position = UDim2.new(1, -52, 0.5, -12)
    hideBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 120)
    hideBtn.Text = "👁"
    hideBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.TextSize = 11
    hideBtn.BorderSizePixel = 0
    Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 5)

    -- Minimize button
    local minBtn = Instance.new("TextButton", TopBar)
    minBtn.Size = UDim2.new(0, 24, 0, 24)
    minBtn.Position = UDim2.new(1, -24, 0.5, -12)
    minBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 12
    minBtn.BorderSizePixel = 0
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)

    -- Pill (when hidden)
    local Pill = Instance.new("TextButton", ScreenGui)
    Pill.Size = UDim2.new(0, 100, 0, 24)
    Pill.Position = startPos
    Pill.BackgroundColor3 = Color3.fromRGB(20, 60, 160)
    Pill.Text = "⚡ NEXUS"
    Pill.TextColor3 = Color3.fromRGB(255, 255, 255)
    Pill.Font = Enum.Font.GothamBold
    Pill.TextSize = 10
    Pill.BorderSizePixel = 0
    Pill.Visible = false
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", Pill).Color = CurrentTheme.primary

    -- Tab bar
    TabBar = Instance.new("ScrollingFrame", MainFrame)
    TabBar.Size = UDim2.new(1, 0, 0, 28)
    TabBar.Position = UDim2.new(0, 0, 0, 36)
    TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 27)
    TabBar.BorderSizePixel = 0
    TabBar.ScrollBarThickness = 2
    TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabBar.ScrollingDirection = Enum.ScrollingDirection.X
    TabBar.ScrollBarImageColor3 = CurrentTheme.primary
    local tabLayout = Instance.new("UIListLayout", TabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    Instance.new("UIPadding", TabBar).PaddingLeft = UDim.new(0, 4)

    -- Content
    Content = Instance.new("Frame", MainFrame)
    Content.Size = UDim2.new(1, 0, 1, -64)
    Content.Position = UDim2.new(0, 0, 0, 64)
    Content.BackgroundTransparency = 1

    -- Tab management
    Tabs = {}
    local function AddTab(name)
        local page = Instance.new("ScrollingFrame", Content)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = CurrentTheme.primary
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = false
        page.ScrollingEnabled = true
        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 4)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        local pad = Instance.new("UIPadding", page)
        pad.PaddingTop = UDim.new(0, 6)
        pad.PaddingLeft = UDim.new(0, 5)
        pad.PaddingRight = UDim.new(0, 5)
        pad.PaddingBottom = UDim.new(0, 10)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)

        local btn = Instance.new("TextButton", TabBar)
        btn.Size = UDim2.new(0, 42, 0, 22)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(150, 150, 170)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 9
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

        local tab = { page = page, button = btn, active = false }
        table.insert(Tabs, tab)

        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(Tabs) do
                t.page.Visible = false
                t.button.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
                t.button.TextColor3 = Color3.fromRGB(150, 150, 170)
                t.active = false
            end
            page.Visible = true
            btn.BackgroundColor3 = CurrentTheme.primary
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tab.active = true
        end)

        if #Tabs == 1 then
            page.Visible = true
            btn.BackgroundColor3 = CurrentTheme.primary
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tab.active = true
        end

        -- Update canvas size when layout changes
        local function refreshCanvas()
            task.wait()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)
        return page, refreshCanvas
    end

    -- Helper: Section
    local function Section(parent, text)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 20)
        frame.BackgroundTransparency = 1
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "── " .. text .. " ──"
        label.TextColor3 = CurrentTheme.primary
        label.Font = Enum.Font.GothamBold
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Center
    end

    -- Helper: Toggle
    local function Toggle(parent, text, callback, trackName)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 28)
        frame.BackgroundColor3 = Color3.fromRGB(22, 22, 33)
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -48, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(210, 210, 215)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = Config.UI.TextSize
        label.TextXAlignment = Enum.TextXAlignment.Left
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 32, 0, 18)
        btn.Position = UDim2.new(1, -38, 0.5, -9)
        btn.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
        btn.Text = ""
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame", btn)
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(140, 140, 160)
        knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local state = false
        local function setVisual(on)
            if on then
                btn.BackgroundColor3 = CurrentTheme.primary
                knob.Position = UDim2.new(1, -14, 0.5, -6)
                knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
                knob.Position = UDim2.new(0, 2, 0.5, -6)
                knob.BackgroundColor3 = Color3.fromRGB(140, 140, 160)
            end
        end
        btn.MouseButton1Click:Connect(function()
            state = not state
            setVisual(state)
            if trackName then
                -- Optional: track active features
            end
            pcall(callback, state)
            Notify(text, state)
        end)
        return function() return state end
    end

    -- Helper: Slider (touch-friendly)
    local function Slider(parent, text, minVal, maxVal, defaultValue, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.BackgroundColor3 = Color3.fromRGB(22, 22, 33)
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -10, 0, 18)
        label.Position = UDim2.new(0, 5, 0, 4)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(defaultValue)
        label.TextColor3 = Color3.fromRGB(210, 210, 215)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = Config.UI.TextSize
        label.TextXAlignment = Enum.TextXAlignment.Left
        local bg = Instance.new("Frame", frame)
        bg.Size = UDim2.new(1, -20, 0, 4)
        bg.Position = UDim2.new(0, 10, 0, 30)
        bg.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
        bg.BorderSizePixel = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame", bg)
        fill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = CurrentTheme.primary
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("TextButton", frame)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new((defaultValue - minVal) / (maxVal - minVal), -8, 0, 22)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.Text = ""
        knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local dragging = false
        local function updateSlider(inputPos)
            local rel = (inputPos.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X
            local val = math.clamp(rel, 0, 1) * (maxVal - minVal) + minVal
            val = math.floor(val)
            local percent = (val - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            knob.Position = UDim2.new(percent, -8, 0, 22)
            label.Text = text .. ": " .. tostring(val)
            pcall(callback, val)
        end
        knob.MouseButton1Down:Connect(function()
            dragging = true
            updateSlider(UserInputService:GetMouseLocation())
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                            input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input.Position)
            end
        end)
    end

    -- Helper: Choice Row
    local function ChoiceRow(parent, text, options, default, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 48)
        frame.BackgroundColor3 = Color3.fromRGB(22, 22, 33)
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 0, 18)
        label.Position = UDim2.new(0, 5, 0, 4)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(160, 160, 180)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = Config.UI.TextSize - 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        local row = Instance.new("Frame", frame)
        row.Size = UDim2.new(1, -10, 0, 24)
        row.Position = UDim2.new(0, 5, 0, 22)
        row.BackgroundTransparency = 1
        local layout = Instance.new("UIListLayout", row)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 4)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        for _, opt in ipairs(options) do
            local btn = Instance.new("TextButton", row)
            btn.Size = UDim2.new(0, 60, 0, 22)
            btn.BackgroundColor3 = (opt == default) and CurrentTheme.primary or Color3.fromRGB(35, 35, 52)
            btn.Text = opt
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 10
            btn.BorderSizePixel = 0
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            btn.MouseButton1Click:Connect(function()
                for _, b in ipairs(row:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = (b == btn) and CurrentTheme.primary or Color3.fromRGB(35, 35, 52)
                    end
                end
                pcall(callback, opt)
            end)
        end
    end

    -- Helper: Action Button
    local function ActionButton(parent, text, callback, color)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = color or CurrentTheme.primary
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = Config.UI.TextSize
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function()
            local orig = btn.BackgroundColor3
            btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            task.delay(0.1, function() btn.BackgroundColor3 = orig end)
            pcall(callback)
        end)
    end

    -- Helper: Input Row
    local function InputRow(parent, placeholder, btnLabel, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 32)
        frame.BackgroundColor3 = Color3.fromRGB(22, 22, 33)
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        local input = Instance.new("TextBox", frame)
        input.Size = UDim2.new(1, -70, 1, -4)
        input.Position = UDim2.new(0, 8, 0, 2)
        input.BackgroundTransparency = 1
        input.PlaceholderText = placeholder
        input.Text = ""
        input.TextColor3 = Color3.fromRGB(220, 220, 220)
        input.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
        input.Font = Enum.Font.Gotham
        input.TextSize = Config.UI.TextSize
        input.TextXAlignment = Enum.TextXAlignment.Left
        input.ClearTextOnFocus = false
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 60, 0, 24)
        btn.Position = UDim2.new(1, -66, 0.5, -12)
        btn.BackgroundColor3 = CurrentTheme.primary
        btn.Text = btnLabel
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        btn.MouseButton1Click:Connect(function()
            if input.Text ~= "" then
                pcall(callback, input.Text)
                input.Text = ""
            end
        end)
    end

    -- ========== Build Tabs ==========
    -- Tab 1: ESP
    local p1, _ = AddTab("ESP")
    Section(p1, "MASTER")
    Toggle(p1, "Enable ESP", function(v) Config.ESP.Enabled = v end, "ESP")
    Section(p1, "VISUAL")
    Toggle(p1, "Box", function(v) Config.ESP.ShowBox = v end)
    Toggle(p1, "Name", function(v) Config.ESP.ShowName = v end)
    Toggle(p1, "Health Bar", function(v) Config.ESP.ShowHealth = v end)
    Toggle(p1, "Distance", function(v) Config.ESP.ShowDistance = v end)
    Toggle(p1, "Snap Line", function(v) Config.ESP.ShowSnapLine = v end)
    Toggle(p1, "Head Dot", function(v) Config.ESP.ShowHeadDot = v end)
    Toggle(p1, "Skeleton", function(v) Config.ESP.ShowSkeleton = v end)
    Toggle(p1, "Chams (Neon)", function(v) Config.ESP.ShowChams = v end)

    -- Tab 2: Combat
    local p2, _ = AddTab("Combat")
    Section(p2, "AIMBOT")
    Toggle(p2, "Enable Aimbot", function(v) Config.Aimbot.Enabled = v end, "Aimbot")
    Toggle(p2, "Wall Check", function(v) Config.Aimbot.WallCheck = v end)
    Toggle(p2, "Team Check", function(v) Config.Aimbot.TeamCheck = v end)
    Slider(p2, "FOV Radius", 50, 400, Config.Aimbot.FOVRadius, function(v) Config.Aimbot.FOVRadius = v end)
    Slider(p2, "Smoothness", 0.1, 1, Config.Aimbot.Smoothness, function(v) Config.Aimbot.Smoothness = v end)
    Section(p2, "CROSSHAIR")
    Toggle(p2, "Enable Crosshair", function(v) Config.Visual.Crosshair = v; UpdateCrosshair() end)
    ChoiceRow(p2, "Style", {"Dot", "Cross", "Circle"}, Config.Visual.CrossStyle, function(s)
        Config.Visual.CrossStyle = s; UpdateCrosshair()
    end)

    -- Tab 3: Movement
    local p3, _ = AddTab("Move")
    Section(p3, "SPEED")
    Toggle(p3, "Speed Hack", function(v) Config.Movement.Speed = v; SetSpeed(v) end, "Speed")
    Slider(p3, "Speed Value", 20, 120, Config.Movement.SpeedValue, function(v)
        Config.Movement.SpeedValue = v
        if Config.Movement.Speed then SetSpeed(true) end
    end)
    Section(p3, "MOVEMENT")
    Toggle(p3, "No Clip", function(v) Config.Movement.NoClip = v; SetNoClip(v) end)
    Toggle(p3, "Infinite Jump", function(v) Config.Movement.InfJump = v; SetInfJump(v) end)
    Section(p3, "FLY")
    Toggle(p3, "Enable Fly", function(v) Config.Movement.Fly = v; SetFly(v) end, "Fly")
    Slider(p3, "Fly Speed", 20, 200, Config.Movement.FlySpeed, function(v) Config.Movement.FlySpeed = v end)
    -- Fly controls (buttons)
    local flyRow = Instance.new("Frame", p3)
    flyRow.Size = UDim2.new(1, 0, 0, 32)
    flyRow.BackgroundTransparency = 1
    local flyLayout = Instance.new("UIListLayout", flyRow)
    flyLayout.FillDirection = Enum.FillDirection.Horizontal
    flyLayout.Padding = UDim.new(0, 8)
    flyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local upBtn = Instance.new("TextButton", flyRow)
    upBtn.Size = UDim2.new(0, 80, 0, 28)
    upBtn.BackgroundColor3 = Color3.fromRGB(45, 110, 220)
    upBtn.Text = "▲ Naik"
    upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    upBtn.Font = Enum.Font.GothamBold
    upBtn.TextSize = 12
    Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 6)
    upBtn.MouseButton1Down:Connect(function() SetFlyUp(true) end)
    upBtn.MouseButton1Up:Connect(function() SetFlyUp(false) end)
    local downBtn = Instance.new("TextButton", flyRow)
    downBtn.Size = UDim2.new(0, 80, 0, 28)
    downBtn.BackgroundColor3 = Color3.fromRGB(175, 55, 55)
    downBtn.Text = "▼ Turun"
    downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    downBtn.Font = Enum.Font.GothamBold
    downBtn.TextSize = 12
    Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 6)
    downBtn.MouseButton1Down:Connect(function() SetFlyDown(true) end)
    downBtn.MouseButton1Up:Connect(function() SetFlyDown(false) end)

    -- Tab 4: Teleport
    local p4, _ = AddTab("Tele")
    Section(p4, "AUTO TELEPORT")
    Toggle(p4, "Auto to Monster", function(v) Config.Teleport.AutoMonster = v; SetAutoMonster(v) end, "Auto Monster")
    Toggle(p4, "Auto Behind Enemy", function(v) Config.Teleport.AutoEnemy = v; SetAutoEnemy(v) end, "Auto Enemy")
    Slider(p4, "Detection Radius", 100, 2000, Config.Teleport.Radius, function(v) Config.Teleport.Radius = v end)
    Section(p4, "MANUAL")
    InputRow(p4, "Player name", "Teleport", function(name) TeleportToPlayer(name) end)
    ActionButton(p4, "↩️ Back to Previous Position", function() TeleportBack() end, Color3.fromRGB(80, 50, 150))

    -- Tab 5: RPG
    local p5, _ = AddTab("RPG")
    Section(p5, "FARM")
    Toggle(p5, "Auto Farm", function(v) Config.RPG.AutoFarm = v; SetAutoFarm(v) end, "Auto Farm")
    Section(p5, "⚡ BLINK ATTACK")
    Toggle(p5, "Enable Blink Attack", function(v) Config.RPG.BlinkAttack = v; SetBlinkAttack(v) end, "Blink Attack")
    Slider(p5, "Blink Radius", 100, 1000, Config.RPG.BlinkRadius, function(v) Config.RPG.BlinkRadius = v end)
    Slider(p5, "Interval (sec)", 0.5, 5, Config.RPG.BlinkInterval, function(v) Config.RPG.BlinkInterval = v end)

    -- Tab 6: Settings
    local p6, _ = AddTab("⚙️")
    Section(p6, "UI")
    ChoiceRow(p6, "Theme", {"Blue", "Red", "Green", "Purple"}, Config.UI.Theme, function(t)
        Config.UI.Theme = t
        ApplyTheme()
        SaveConfig()
    end)
    ChoiceRow(p6, "Position", {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}, Config.UI.Position, function(pos)
        Config.UI.Position = pos
        local newPos = positions[pos] or positions.TopLeft
        Wrapper.Position = newPos
        Pill.Position = newPos
        SaveConfig()
    end)
    Slider(p6, "Opacity", 50, 100, Config.UI.Opacity * 100, function(v)
        Config.UI.Opacity = v / 100
        MainFrame.BackgroundTransparency = 1 - Config.UI.Opacity
        SaveConfig()
    end)
    Slider(p6, "Text Size", 8, 16, Config.UI.TextSize, function(v)
        Config.UI.TextSize = v
        -- Update all text labels in UI? This is simplified.
        SaveConfig()
    end)
    Section(p6, "INFO")
    Toggle(p6, "Show FPS/Ping", function(v) Config.Visual.FPSPing = v end)
    Section(p6, "CONFIG")
    ActionButton(p6, "💾 Save Config", function() SaveConfig(); Notify("Config saved", true) end)
    ActionButton(p6, "📂 Load Config", function() LoadConfig(); ApplyTheme(); Notify("Config loaded", true) end)

    -- Dragging logic
    local dragging = false
    local dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Wrapper.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            Wrapper.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Hide / Pill
    local function SetPillVisible(visible)
        if visible then
            Wrapper.Visible = false
            Pill.Visible = true
        else
            Wrapper.Visible = true
            Pill.Visible = false
        end
    end
    hideBtn.MouseButton1Click:Connect(function() SetPillVisible(true) end)
    Pill.MouseButton1Click:Connect(function() SetPillVisible(false) end)

    -- Minimize
    local function SetMinimized(min)
        minimized = min
        local targetSize = minimized and UDim2.new(0, 265, 0, 36) or UDim2.new(0, 265, 0, 455)
        TweenService:Create(Wrapper, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = targetSize}):Play()
        Content.Visible = not minimized
        TabBar.Visible = not minimized
        minBtn.Text = minimized and "+" or "—"
    end
    minBtn.MouseButton1Click:Connect(function() SetMinimized(not minimized) end)
end

-- ============================================================================
-- [12] MAIN LOOP
-- ============================================================================
local function MainLoop()
    RunService.RenderStepped:Connect(function()
        pcall(function()
            UpdateESP()
            UpdateAimbot()
        end)
    end)
end

-- ============================================================================
-- [13] INITIALIZE
-- ============================================================================
local success, err = pcall(function()
    BuildUI()
    MainLoop()
    -- Apply initial states
    SetSpeed(Config.Movement.Speed)
    SetNoClip(Config.Movement.NoClip)
    SetInfJump(Config.Movement.InfJump)
    SetFly(Config.Movement.Fly)
    SetAutoMonster(Config.Teleport.AutoMonster)
    SetAutoEnemy(Config.Teleport.AutoEnemy)
    SetAutoFarm(Config.RPG.AutoFarm)
    SetBlinkAttack(Config.RPG.BlinkAttack)
    Notify("NEXUS Lite loaded!", true)
end)

if not success then
    warn("Failed to load: " .. tostring(err))
    Notify("Error: " .. tostring(err), false, true)
end
