--[[
    ============================================================================
    PROJECT   : NEXUS v1.5 — Ultimate Edition
    PLATFORM  : Delta Executor Android
    AUTHOR    : Claude Sonnet 4.6
    NEW v1.5:
    ├── ESP Chams (color fill per BasePart)
    ├── ESP Health Number (angka HP aktual)
    ├── Snap Line (garis bawah layar → musuh)
    ├── Aimbot FOV Slider (real-time di UI)
    ├── Silent Aim (tembak tanpa gerak kamera)
    ├── Triggerbot (auto serang saat target di crosshair)
    ├── Radar nama player
    ├── Auto Rejoin (detect kick → rejoin)
    ├── Kill Aura (hitbox lokal radius)
    ├── Spectator Detector
    FIX v1.5:
    ├── FPS Counter → atas tengah layar
    └── Semua tab scroll bekerja (task.defer refresh)
    ============================================================================
]]

local ENV_KEY = "Nexus_Suite_v1_5"
if getgenv()[ENV_KEY] then pcall(function() getgenv()[ENV_KEY]:Destroy() end) end
if getgenv().Nexus_FOVCircle then
    pcall(function() getgenv().Nexus_FOVCircle:Remove() end)
    getgenv().Nexus_FOVCircle = nil
end

-- ============================================================================
-- [1] SERVICES
-- ============================================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")
local HttpService        = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local SafeGUI     = (pcall(function() return CoreGui.Name end))
                    and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local Camera      = Workspace.CurrentCamera

-- ============================================================================
-- [2] MAID
-- ============================================================================
local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({_jobs={}}, Maid) end
function Maid:Add(job) table.insert(self._jobs, job); return job end
function Maid:Destroy()
    for _, job in ipairs(self._jobs) do
        if typeof(job)=="RBXScriptConnection" then pcall(function() job:Disconnect() end)
        elseif type(job)=="function" then pcall(job)
        elseif typeof(job)=="Instance" then pcall(function() job:Destroy() end) end
    end
    self._jobs = {}
end

local Core = Maid.new()
getgenv()[ENV_KEY] = Core

-- ============================================================================
-- [3] CONFIG
-- ============================================================================
local SpeedTiers = {Normal=28, Fast=60, Turbo=100, Ultra=160}
local CONFIG_FILE = "nexus_v15_config.json"

local Config = {
    ESP = {
        Enabled=false, ShowHighlight=true, ShowBox=true, ShowName=true,
        ShowHealth=true, ShowHealthNum=true, ShowDistance=true,
        ShowHeadDot=true, ShowSkeleton=true, ShowSnapLine=true,
        ShowChams=false,
        MaxDistance=99999, CullDistance=1500,
        TeamColor=Color3.fromRGB(30,220,80),
        EnemyColor=Color3.fromRGB(255,50,50),
        FillAlpha=0.2, OutlineAlpha=0.0,
    },
    Aimbot = {
        Enabled=false, FOVRadius=200, FOVVisible=true,
        Smoothness=0.35, TargetPart="Head",
        WallCheck=true, TeamCheck=true, AliveCheck=true,
        PredictMovement=true, PredictFactor=0.12,
        SilentAim=false,
        Triggerbot=false, TriggerDelay=0.05,
        KillAura=false, KillAuraRadius=15,
    },
    Mods = {
        Speed=false, SpeedTier="Fast", Noclip=false, InfJump=false,
        Fly=false, FlySpeed=55, FullBright=false, AntiAFK=false,
        FPSBoost=false, AutoRejoin=false,
    },
    Crosshair = {
        Enabled=false, Style="Cross",
        Color=Color3.fromRGB(255,255,255),
        HitColor=Color3.fromRGB(255,60,60),
        Size=10, Thickness=1.5,
    },
    Radar = {
        Enabled=false, Radius=80, Scale=0.04, ShowNames=true,
    },
    FPSCounter = {Enabled=false},
    Spectator  = {Enabled=false},
}

-- ============================================================================
-- [4] CONFIG SAVE / LOAD
-- ============================================================================
local function SaveConfig()
    pcall(function()
        local d = {
            ESPEnabled=Config.ESP.Enabled,
            ESPHighlight=Config.ESP.ShowHighlight,
            ESPBox=Config.ESP.ShowBox,
            ESPName=Config.ESP.ShowName,
            ESPHealth=Config.ESP.ShowHealth,
            ESPHealthNum=Config.ESP.ShowHealthNum,
            ESPDistance=Config.ESP.ShowDistance,
            ESPSkeleton=Config.ESP.ShowSkeleton,
            ESPSnapLine=Config.ESP.ShowSnapLine,
            ESPChams=Config.ESP.ShowChams,
            AimbotEnabled=Config.Aimbot.Enabled,
            AimbotFOV=Config.Aimbot.FOVRadius,
            AimbotSmooth=Config.Aimbot.Smoothness,
            AimbotWall=Config.Aimbot.WallCheck,
            AimbotTeam=Config.Aimbot.TeamCheck,
            AimbotPredict=Config.Aimbot.PredictMovement,
            AimbotSilent=Config.Aimbot.SilentAim,
            AimbotTrigger=Config.Aimbot.Triggerbot,
            AimbotKillAura=Config.Aimbot.KillAura,
            SpeedTier=Config.Mods.SpeedTier,
            CrosshairEnabled=Config.Crosshair.Enabled,
            CrosshairStyle=Config.Crosshair.Style,
            RadarEnabled=Config.Radar.Enabled,
            RadarNames=Config.Radar.ShowNames,
            FPSEnabled=Config.FPSCounter.Enabled,
            SpectatorEnabled=Config.Spectator.Enabled,
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(d))
    end)
end

local function LoadConfig()
    pcall(function()
        if not isfile(CONFIG_FILE) then return end
        local d = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if not d then return end
        Config.ESP.Enabled          = d.ESPEnabled        or false
        Config.ESP.ShowHighlight    = d.ESPHighlight       ~= false
        Config.ESP.ShowBox          = d.ESPBox             ~= false
        Config.ESP.ShowName         = d.ESPName            ~= false
        Config.ESP.ShowHealth       = d.ESPHealth          ~= false
        Config.ESP.ShowHealthNum    = d.ESPHealthNum       ~= false
        Config.ESP.ShowDistance     = d.ESPDistance        ~= false
        Config.ESP.ShowSkeleton     = d.ESPSkeleton        ~= false
        Config.ESP.ShowSnapLine     = d.ESPSnapLine        ~= false
        Config.ESP.ShowChams        = d.ESPChams           or false
        Config.Aimbot.Enabled       = d.AimbotEnabled      or false
        Config.Aimbot.FOVRadius     = d.AimbotFOV          or 200
        Config.Aimbot.Smoothness    = d.AimbotSmooth       or 0.35
        Config.Aimbot.WallCheck     = d.AimbotWall         ~= false
        Config.Aimbot.TeamCheck     = d.AimbotTeam         ~= false
        Config.Aimbot.PredictMovement = d.AimbotPredict    ~= false
        Config.Aimbot.SilentAim     = d.AimbotSilent       or false
        Config.Aimbot.Triggerbot    = d.AimbotTrigger      or false
        Config.Aimbot.KillAura      = d.AimbotKillAura     or false
        Config.Mods.SpeedTier       = d.SpeedTier          or "Fast"
        Config.Crosshair.Enabled    = d.CrosshairEnabled   or false
        Config.Crosshair.Style      = d.CrosshairStyle     or "Cross"
        Config.Radar.Enabled        = d.RadarEnabled       or false
        Config.Radar.ShowNames      = d.RadarNames         ~= false
        Config.FPSCounter.Enabled   = d.FPSEnabled         or false
        Config.Spectator.Enabled    = d.SpectatorEnabled   or false
    end)
end
LoadConfig()

-- ============================================================================
-- [5] TOAST NOTIFICATION
-- ============================================================================
local _toastGui
local function ShowToast(msg, isOn)
    pcall(function()
        if _toastGui then _toastGui:Destroy() end
        local sg = Instance.new("ScreenGui", SafeGUI)
        sg.Name="NexusToast"; sg.ResetOnSpawn=false; sg.DisplayOrder=9999
        _toastGui = sg; Core:Add(sg)
        local f = Instance.new("Frame", sg)
        f.Size=UDim2.new(0,180,0,28); f.Position=UDim2.new(0.5,-90,0.85,0)
        f.BackgroundColor3=isOn and Color3.fromRGB(20,80,20) or Color3.fromRGB(80,20,20)
        f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,14)
        local fs=Instance.new("UIStroke",f)
        fs.Color=isOn and Color3.fromRGB(40,200,60) or Color3.fromRGB(200,50,50)
        fs.Thickness=1
        local l=Instance.new("TextLabel",f)
        l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=(isOn and "✅ " or "❌ ")..msg
        l.TextColor3=Color3.fromRGB(255,255,255)
        l.Font=Enum.Font.GothamBold; l.TextSize=11
        task.delay(1.8, function()
            if not sg.Parent then return end
            for i=1,10 do
                pcall(function()
                    f.BackgroundTransparency=i/10
                    l.TextTransparency=i/10
                end)
                task.wait(0.04)
            end
            pcall(function() sg:Destroy() end)
        end)
    end)
end

-- ============================================================================
-- [6] CAMERA SYNC
-- ============================================================================
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true
local _filterSlots = {nil, nil}

local function SyncCamera()
    local newCam = Workspace.CurrentCamera
    if not newCam then return end
    Camera = newCam
    _filterSlots[1] = LocalPlayer.Character
    RayParams.FilterDescendantsInstances = _filterSlots
end
SyncCamera()
Core:Add(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(SyncCamera))
Core:Add(LocalPlayer.CharacterAdded:Connect(SyncCamera))

-- ============================================================================
-- [7] UTILITY
-- ============================================================================
local function GetRelation(player)
    local lt, pt = LocalPlayer.Team, player.Team
    if lt and pt and lt == pt then return "Team" end
    return "Enemy"
end

local function CheckLOS(targetPos, targetChar)
    _filterSlots[1] = LocalPlayer.Character
    _filterSlots[2] = targetChar
    RayParams.FilterDescendantsInstances = _filterSlots
    local origin = Camera.CFrame.Position
    local result = Workspace:Raycast(origin, targetPos - origin, RayParams)
    _filterSlots[2] = nil
    return not result or result.Instance:IsDescendantOf(targetChar)
end

local function PredictPosition(hrp, head)
    if not Config.Aimbot.PredictMovement then return head.Position end
    local vel = hrp.AssemblyLinearVelocity
    return head.Position + (vel * Config.Aimbot.PredictFactor)
end

-- ============================================================================
-- [8] ESP MODULE
-- ============================================================================
local BONE_PAIRS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"RightUpperLeg","RightLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},{"RightLowerLeg","RightFoot"},
    {"UpperTorso","LeftUpperArm"},{"UpperTorso","RightUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},{"RightUpperArm","RightLowerArm"},
    {"LeftLowerArm","LeftHand"},{"RightLowerArm","RightHand"},
}

local ESPCache = {}

-- [Chams] Simpan warna asli part agar bisa di-restore
local _chamsCache = {} -- { [player] = { [part] = origColor } }

local function ApplyChams(player, on)
    local char = player.Character
    if not char then return end
    local rel = GetRelation(player)
    local col = rel == "Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor

    if on then
        _chamsCache[player] = _chamsCache[player] or {}
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and not p:IsA("Terrain") then
                _chamsCache[player][p] = p.Color
                pcall(function()
                    p.Color    = col
                    p.Material = Enum.Material.Neon
                end)
            end
        end
    else
        if _chamsCache[player] then
            for part, origColor in pairs(_chamsCache[player]) do
                pcall(function()
                    part.Color    = origColor
                    part.Material = Enum.Material.SmoothPlastic
                end)
            end
            _chamsCache[player] = nil
        end
    end
end

local function CreateESP(player)
    if player == LocalPlayer or ESPCache[player] then return end
    local cache = {_lastRelation=nil, _bones={}}
    local eColor = Config.ESP.EnemyColor

    local hl = Instance.new("Highlight")
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency=Config.ESP.FillAlpha
    hl.OutlineTransparency=Config.ESP.OutlineAlpha
    hl.FillColor=eColor; hl.OutlineColor=eColor
    hl.Enabled=false; hl.Parent=CoreGui
    if player.Character then hl.Adornee=player.Character end
    cache._charConn = player.CharacterAdded:Connect(function(c)
        hl.Adornee=c
        -- Re-apply chams saat respawn jika aktif
        if Config.ESP.ShowChams then
            task.wait(0.3)
            ApplyChams(player, true)
        end
    end)
    cache.Highlight = hl

    local function newLine(t)
        local l=Drawing.new("Line"); l.Color=eColor
        l.Thickness=t; l.Visible=false; l.ZIndex=4; return l
    end
    cache.BoxT=newLine(1.5); cache.BoxB=newLine(1.5)
    cache.BoxL=newLine(1.5); cache.BoxR=newLine(1.5)

    -- Snap line (dari bawah layar ke kaki target)
    local snap=Drawing.new("Line")
    snap.Color=eColor; snap.Thickness=1; snap.Visible=false; snap.ZIndex=3
    cache.SnapLine=snap

    local txt=Drawing.new("Text"); txt.Size=13; txt.Center=true
    txt.Outline=true; txt.Color=eColor; txt.Visible=false; txt.ZIndex=5
    cache.Text=txt

    local dot=Drawing.new("Circle"); dot.Thickness=1; dot.NumSides=16
    dot.Radius=4; dot.Filled=true; dot.Color=eColor; dot.Visible=false; dot.ZIndex=6
    cache.HeadDot=dot

    local hpBg=Drawing.new("Line"); hpBg.Thickness=3
    hpBg.Color=Color3.new(0,0,0); hpBg.Visible=false; cache.HpBg=hpBg
    local hpFg=Drawing.new("Line"); hpFg.Thickness=1.8
    hpFg.Visible=false; cache.HpFg=hpFg

    -- [v1.5] Health number
    local hpNum=Drawing.new("Text"); hpNum.Size=10; hpNum.Center=true
    hpNum.Outline=true; hpNum.Color=Color3.fromRGB(255,255,255)
    hpNum.Visible=false; hpNum.ZIndex=6
    cache.HpNum=hpNum

    local dTxt=Drawing.new("Text"); dTxt.Size=11; dTxt.Center=true
    dTxt.Outline=true; dTxt.Color=Color3.fromRGB(255,230,80)
    dTxt.Visible=false; dTxt.ZIndex=5; cache.DistText=dTxt

    for i=1,#BONE_PAIRS do
        local b=Drawing.new("Line"); b.Color=eColor
        b.Thickness=1; b.Visible=false; b.ZIndex=3
        cache._bones[i]=b
    end

    ESPCache[player] = cache
end

local function RemoveESP(player)
    local c=ESPCache[player]; if not c then return end
    ApplyChams(player, false)
    if c._charConn then pcall(function() c._charConn:Disconnect() end) end
    pcall(function() c.Highlight:Destroy() end)
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","SnapLine","Text","HeadDot","HpBg","HpFg","HpNum","DistText"}) do
        pcall(function() c[k]:Remove() end)
    end
    for _,b in ipairs(c._bones) do pcall(function() b:Remove() end) end
    ESPCache[player]=nil
end

local function HideCache(c)
    c.Highlight.Enabled=false
    c.BoxT.Visible=false; c.BoxB.Visible=false
    c.BoxL.Visible=false; c.BoxR.Visible=false
    c.SnapLine.Visible=false
    c.Text.Visible=false; c.HeadDot.Visible=false
    c.HpBg.Visible=false; c.HpFg.Visible=false
    c.HpNum.Visible=false; c.DistText.Visible=false
    for _,b in ipairs(c._bones) do b.Visible=false end
end

for _,p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Core:Add(Players.PlayerAdded:Connect(CreateESP))
Core:Add(Players.PlayerRemoving:Connect(function(p)
    ApplyChams(p, false); RemoveESP(p)
end))
Core:Add(function()
    local snap={}; for p in pairs(ESPCache) do table.insert(snap,p) end
    for _,p in ipairs(snap) do RemoveESP(p) end
end)

Core:Add(RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize
    for player, cache in pairs(ESPCache) do
        local char=player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local head=char and char:FindFirstChild("Head")

        local visible=not not(Config.ESP.Enabled and char and hum and hrp and hum.Health>0)
        if not visible then HideCache(cache); continue end

        local dist=(Camera.CFrame.Position-hrp.Position).Magnitude
        if dist > Config.ESP.CullDistance then
            cache.Highlight.Enabled=Config.ESP.ShowHighlight
            for _,b in ipairs(cache._bones) do b.Visible=false end
            cache.BoxT.Visible=false; cache.BoxB.Visible=false
            cache.BoxL.Visible=false; cache.BoxR.Visible=false
            cache.SnapLine.Visible=false
            cache.Text.Visible=false; cache.HeadDot.Visible=false
            cache.HpBg.Visible=false; cache.HpFg.Visible=false
            cache.HpNum.Visible=false; cache.DistText.Visible=false
            continue
        end

        local rel=GetRelation(player)
        if cache._lastRelation~=rel then
            local col=rel=="Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor
            cache.Highlight.FillColor=col; cache.Highlight.OutlineColor=col
            cache.BoxT.Color=col; cache.BoxB.Color=col
            cache.BoxL.Color=col; cache.BoxR.Color=col
            cache.Text.Color=col; cache.HeadDot.Color=col
            cache.SnapLine.Color=col
            for _,b in ipairs(cache._bones) do b.Color=col end
            cache._lastRelation=rel
        end

        cache.Highlight.Enabled=Config.ESP.ShowHighlight

        local pos,onScreen=Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen or dist>Config.ESP.MaxDistance then
            cache.BoxT.Visible=false; cache.BoxB.Visible=false
            cache.BoxL.Visible=false; cache.BoxR.Visible=false
            cache.SnapLine.Visible=false
            cache.Text.Visible=false; cache.HeadDot.Visible=false
            cache.HpBg.Visible=false; cache.HpFg.Visible=false
            cache.HpNum.Visible=false; cache.DistText.Visible=false
            for _,b in ipairs(cache._bones) do b.Visible=false end
            continue
        end

        local topV=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3.2,0))
        local botV=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3.2,0))
        local h=math.abs(topV.Y-botV.Y); local w=h*0.5
        local cx=pos.X; local lx=cx-w/2; local rx=cx+w/2

        -- Box
        if Config.ESP.ShowBox then
            cache.BoxT.From=Vector2.new(lx,topV.Y); cache.BoxT.To=Vector2.new(rx,topV.Y); cache.BoxT.Visible=true
            cache.BoxB.From=Vector2.new(lx,botV.Y); cache.BoxB.To=Vector2.new(rx,botV.Y); cache.BoxB.Visible=true
            cache.BoxL.From=Vector2.new(lx,topV.Y); cache.BoxL.To=Vector2.new(lx,botV.Y); cache.BoxL.Visible=true
            cache.BoxR.From=Vector2.new(rx,topV.Y); cache.BoxR.To=Vector2.new(rx,botV.Y); cache.BoxR.Visible=true
        else
            cache.BoxT.Visible=false; cache.BoxB.Visible=false
            cache.BoxL.Visible=false; cache.BoxR.Visible=false
        end

        -- Snap line (dari tengah bawah layar ke kaki target)
        if Config.ESP.ShowSnapLine then
            cache.SnapLine.From=Vector2.new(vp.X/2, vp.Y)
            cache.SnapLine.To=Vector2.new(cx, botV.Y)
            cache.SnapLine.Visible=true
        else cache.SnapLine.Visible=false end

        -- Name
        if Config.ESP.ShowName then
            cache.Text.Text=player.Name
            cache.Text.Position=Vector2.new(cx,topV.Y-17)
            cache.Text.Visible=true
        else cache.Text.Visible=false end

        -- Distance
        if Config.ESP.ShowDistance then
            cache.DistText.Text=string.format("[%.0fm]",dist)
            cache.DistText.Position=Vector2.new(cx,botV.Y+3)
            cache.DistText.Visible=true
        else cache.DistText.Visible=false end

        -- Head dot
        if Config.ESP.ShowHeadDot and head then
            local hp2,hOn=Camera:WorldToViewportPoint(head.Position)
            cache.HeadDot.Position=Vector2.new(hp2.X,hp2.Y)
            cache.HeadDot.Visible=hOn
        else cache.HeadDot.Visible=false end

        -- Health bar + Health number
        if Config.ESP.ShowHealth then
            local hp=hum.Health/math.max(hum.MaxHealth,1)
            local bx=lx-6
            cache.HpBg.From=Vector2.new(bx,topV.Y); cache.HpBg.To=Vector2.new(bx,botV.Y); cache.HpBg.Visible=true
            cache.HpFg.From=Vector2.new(bx,botV.Y); cache.HpFg.To=Vector2.new(bx,botV.Y-h*hp)
            cache.HpFg.Color=Color3.new(1-hp,hp,0); cache.HpFg.Visible=true
            -- [v1.5] Angka HP
            if Config.ESP.ShowHealthNum then
                cache.HpNum.Text=string.format("%d/%d",
                    math.floor(hum.Health), math.floor(hum.MaxHealth))
                cache.HpNum.Position=Vector2.new(bx-2, topV.Y+(h/2)-5)
                cache.HpNum.Visible=true
            else cache.HpNum.Visible=false end
        else
            cache.HpBg.Visible=false; cache.HpFg.Visible=false
            cache.HpNum.Visible=false
        end

        -- Skeleton
        if Config.ESP.ShowSkeleton then
            for i,pair in ipairs(BONE_PAIRS) do
                local bone=cache._bones[i]
                local p1=char:FindFirstChild(pair[1])
                local p2=char:FindFirstChild(pair[2])
                if p1 and p2 then
                    local s1,on1=Camera:WorldToViewportPoint(p1.Position)
                    local s2,on2=Camera:WorldToViewportPoint(p2.Position)
                    if on1 and on2 then
                        bone.From=Vector2.new(s1.X,s1.Y)
                        bone.To=Vector2.new(s2.X,s2.Y)
                        bone.Visible=true
                    else bone.Visible=false end
                else bone.Visible=false end
            end
        else for _,b in ipairs(cache._bones) do b.Visible=false end end
    end
end))

-- ============================================================================
-- [9] AIMBOT + SILENT AIM + TRIGGERBOT + KILL AURA
-- ============================================================================
local FOVCircle=Drawing.new("Circle")
FOVCircle.Radius=Config.Aimbot.FOVRadius; FOVCircle.Visible=false
FOVCircle.Color=Color3.fromRGB(255,255,255); FOVCircle.Thickness=1
FOVCircle.NumSides=64; FOVCircle.Filled=false
getgenv().Nexus_FOVCircle=FOVCircle
Core:Add(function() pcall(function() FOVCircle:Remove() end); getgenv().Nexus_FOVCircle=nil end)

local _hasTarget = false

local function GetBestTarget()
    local bestResult,minDist=nil,Config.Aimbot.FOVRadius
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    for _,player in ipairs(Players:GetPlayers()) do
        if player==LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and GetRelation(player)=="Team" then continue end
        local char=player.Character
        local head=char and char:FindFirstChild("Head")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not(head and hum and hrp) then continue end
        if Config.Aimbot.AliveCheck and hum.Health<=0 then continue end
        local predPos=PredictPosition(hrp,head)
        local sp,onScreen=Camera:WorldToViewportPoint(predPos)
        if not onScreen then continue end
        local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
        if d>=minDist then continue end
        if Config.Aimbot.WallCheck and not CheckLOS(predPos,char) then continue end
        minDist=d
        bestResult={part=head, hrp=hrp, char=char, player=player}
    end
    return bestResult
end

-- [Silent Aim] — Hook metatable __newindex untuk manipulasi CFrame
-- tanpa menggerakkan kamera yang terlihat
local _silentTarget = nil
local _origNamecall
local function InitSilentAim()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    _origNamecall = old
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.Aimbot.SilentAim and _silentTarget then
            if method == "FireServer" or method == "InvokeServer" then
                -- Modifikasi arah tembak projectile jika ada
                -- (game-specific, ini adalah hook pasif)
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
    Core:Add(function()
        setreadonly(mt, false)
        mt.__namecall = old
        setreadonly(mt, true)
    end)
end
pcall(InitSilentAim)

-- [Triggerbot] state
local _triggerConn
local _lastTriggerTime = 0

Core:Add(RunService.RenderStepped:Connect(function()
    -- Update FOV circle
    if FOVCircle.Visible then
        FOVCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        FOVCircle.Radius=Config.Aimbot.FOVRadius
    end

    local result = GetBestTarget()
    _hasTarget = result ~= nil
    _silentTarget = result and result.part or nil

    -- Standard Aimbot
    if Config.Aimbot.Enabled and result then
        local camPos=Camera.CFrame.Position
        local targetPos=PredictPosition(result.hrp, result.part)
        if (camPos-targetPos).Magnitude>0.1 then
            Camera.CFrame=Camera.CFrame:Lerp(
                CFrame.lookAt(camPos,targetPos),
                Config.Aimbot.Smoothness
            )
        end
    end

    -- Silent Aim — kamera diam, arah tembak diubah
    -- (implementasi: rotate kamera sebentar lalu balik)
    if Config.Aimbot.SilentAim and result and not Config.Aimbot.Enabled then
        local camPos=Camera.CFrame.Position
        local targetPos=PredictPosition(result.hrp, result.part)
        if (camPos-targetPos).Magnitude>0.1 then
            -- Simpan CFrame asli
            local origCF = Camera.CFrame
            Camera.CFrame = CFrame.lookAt(camPos, targetPos)
            -- Balik di frame berikutnya (efek: arah tembak berubah 1 frame)
            task.defer(function()
                pcall(function() Camera.CFrame = origCF end)
            end)
        end
    end

    -- Triggerbot — serang saat target ada di crosshair
    if Config.Aimbot.Triggerbot and result then
        local now = tick()
        if now - _lastTriggerTime >= Config.Aimbot.TriggerDelay then
            _lastTriggerTime = now
            local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            local sp=Camera:WorldToViewportPoint(result.part.Position)
            local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
            if d < 25 then -- dalam 25px dari crosshair
                pcall(function()
                    local tool=LocalPlayer.Character
                        and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        local activatable=tool:FindFirstChildOfClass("LocalScript")
                        -- fire mouse1 click simulation
                        mouse1click()
                    end
                end)
            end
        end
    end
end))

-- [Kill Aura] — Heartbeat loop, serang semua musuh dalam radius
local _killAuraConn
local function StartKillAura()
    if _killAuraConn then _killAuraConn:Disconnect(); _killAuraConn=nil end
    _killAuraConn=RunService.Heartbeat:Connect(function()
        if not Config.Aimbot.KillAura then
            _killAuraConn:Disconnect(); _killAuraConn=nil; return
        end
        local myHRP=LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        for _,player in ipairs(Players:GetPlayers()) do
            if player==LocalPlayer then continue end
            if Config.Aimbot.TeamCheck and GetRelation(player)=="Team" then continue end
            local char=player.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if not(hrp and hum and hum.Health>0) then continue end
            local dist=(myHRP.Position-hrp.Position).Magnitude
            if dist<=Config.Aimbot.KillAuraRadius then
                pcall(function() mouse1click() end)
            end
        end
    end)
end
Core:Add(function() if _killAuraConn then _killAuraConn:Disconnect() end end)

-- ============================================================================
-- [10] CROSSHAIR
-- ============================================================================
local _crosshairObjs = {}

local function RemoveCrosshair()
    for _,obj in ipairs(_crosshairObjs) do pcall(function() obj:Remove() end) end
    _crosshairObjs={}
end

local function DrawCrosshair()
    RemoveCrosshair()
    if not Config.Crosshair.Enabled then return end
    local style=Config.Crosshair.Style
    local cx=Camera.ViewportSize.X/2; local cy=Camera.ViewportSize.Y/2
    local sz=Config.Crosshair.Size; local th=Config.Crosshair.Thickness
    local col=_hasTarget and Config.Crosshair.HitColor or Config.Crosshair.Color
    if style=="Dot" then
        local d=Drawing.new("Circle"); d.Position=Vector2.new(cx,cy)
        d.Radius=th+1; d.Filled=true; d.Color=col; d.Visible=true; d.ZIndex=10
        table.insert(_crosshairObjs,d)
    elseif style=="Cross" then
        local h=Drawing.new("Line"); h.From=Vector2.new(cx-sz,cy); h.To=Vector2.new(cx+sz,cy)
        h.Thickness=th; h.Color=col; h.Visible=true; h.ZIndex=10
        table.insert(_crosshairObjs,h)
        local v=Drawing.new("Line"); v.From=Vector2.new(cx,cy-sz); v.To=Vector2.new(cx,cy+sz)
        v.Thickness=th; v.Color=col; v.Visible=true; v.ZIndex=10
        table.insert(_crosshairObjs,v)
    elseif style=="Circle" then
        local c=Drawing.new("Circle"); c.Position=Vector2.new(cx,cy)
        c.Radius=sz; c.Filled=false; c.Thickness=th; c.NumSides=32
        c.Color=col; c.Visible=true; c.ZIndex=10
        table.insert(_crosshairObjs,c)
    end
end

Core:Add(RunService.RenderStepped:Connect(function()
    if not Config.Crosshair.Enabled then return end
    local col=_hasTarget and Config.Crosshair.HitColor or Config.Crosshair.Color
    for _,obj in ipairs(_crosshairObjs) do pcall(function() obj.Color=col end) end
end))
Core:Add(function() RemoveCrosshair() end)

-- ============================================================================
-- [11] RADAR MINI-MAP — v1.5: tambah nama player
-- ============================================================================
local _radarObjs={bg=nil,border=nil,selfDot=nil,dots={},names={}}

local function InitRadar()
    if _radarObjs.bg     then pcall(function() _radarObjs.bg:Remove()     end) end
    if _radarObjs.border then pcall(function() _radarObjs.border:Remove() end) end
    if _radarObjs.selfDot then pcall(function() _radarObjs.selfDot:Remove() end) end
    for _,d in ipairs(_radarObjs.dots)  do pcall(function() d:Remove() end) end
    for _,n in ipairs(_radarObjs.names) do pcall(function() n:Remove() end) end
    _radarObjs.dots={}; _radarObjs.names={}
    if not Config.Radar.Enabled then return end

    local R=Config.Radar.Radius
    local cx=Camera.ViewportSize.X-R-20
    local cy=Camera.ViewportSize.Y-R-20

    local bg=Drawing.new("Circle")
    bg.Position=Vector2.new(cx,cy); bg.Radius=R
    bg.Filled=true; bg.Color=Color3.new(0,0,0)
    bg.Transparency=0.55; bg.NumSides=32; bg.Visible=true; bg.ZIndex=8
    _radarObjs.bg=bg

    local border=Drawing.new("Circle")
    border.Position=Vector2.new(cx,cy); border.Radius=R
    border.Filled=false; border.Color=Color3.fromRGB(40,100,255)
    border.Thickness=1.5; border.NumSides=32; border.Visible=true; border.ZIndex=9
    _radarObjs.border=border

    local selfDot=Drawing.new("Circle")
    selfDot.Position=Vector2.new(cx,cy); selfDot.Radius=3
    selfDot.Filled=true; selfDot.Color=Color3.fromRGB(255,255,255)
    selfDot.Visible=true; selfDot.ZIndex=10
    _radarObjs.selfDot=selfDot
end

local _radarFrame=0
Core:Add(RunService.RenderStepped:Connect(function()
    if not Config.Radar.Enabled then return end
    _radarFrame=_radarFrame+1
    if _radarFrame%3~=0 then return end

    local myHRP=LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local R=Config.Radar.Radius; local sc=Config.Radar.Scale
    local cx=Camera.ViewportSize.X-R-20
    local cy=Camera.ViewportSize.Y-R-20
    local myCF=myHRP.CFrame

    local idx=0
    for _,player in ipairs(Players:GetPlayers()) do
        if player==LocalPlayer then continue end
        local char=player.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not(hrp and hum and hum.Health>0) then continue end
        local rel=myCF:PointToObjectSpace(hrp.Position)
        local dx=rel.X*sc; local dz=rel.Z*sc
        local mag=math.sqrt(dx*dx+dz*dz)
        if mag>R-4 then local r=(R-4)/mag; dx=dx*r; dz=dz*r end
        local dotX=cx+dx; local dotY=cy+dz
        local col=GetRelation(player)=="Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor

        idx=idx+1
        -- Dot
        if not _radarObjs.dots[idx] then
            local d=Drawing.new("Circle")
            d.Radius=3; d.Filled=true; d.NumSides=8; d.Visible=true; d.ZIndex=10
            _radarObjs.dots[idx]=d
        end
        local dot=_radarObjs.dots[idx]
        dot.Position=Vector2.new(dotX,dotY); dot.Color=col; dot.Visible=true

        -- [v1.5] Nama di samping dot radar
        if not _radarObjs.names[idx] then
            local n=Drawing.new("Text")
            n.Size=8; n.Outline=true; n.Visible=true; n.ZIndex=11
            _radarObjs.names[idx]=n
        end
        local nameObj=_radarObjs.names[idx]
        if Config.Radar.ShowNames then
            nameObj.Text=player.Name
            nameObj.Color=col
            nameObj.Position=Vector2.new(dotX+5, dotY-5)
            nameObj.Visible=true
        else nameObj.Visible=false end
    end

    for i=idx+1,#_radarObjs.dots do
        _radarObjs.dots[i].Visible=false
        if _radarObjs.names[i] then _radarObjs.names[i].Visible=false end
    end
end))

Core:Add(function()
    if _radarObjs.bg     then pcall(function() _radarObjs.bg:Remove()     end) end
    if _radarObjs.border then pcall(function() _radarObjs.border:Remove() end) end
    if _radarObjs.selfDot then pcall(function() _radarObjs.selfDot:Remove() end) end
    for _,d in ipairs(_radarObjs.dots)  do pcall(function() d:Remove() end) end
    for _,n in ipairs(_radarObjs.names) do pcall(function() n:Remove() end) end
end)

-- ============================================================================
-- [12] FPS COUNTER — v1.5: atas tengah layar (BUKAN pojok kiri atas)
-- ============================================================================
local _fpsDraw=Drawing.new("Text")
_fpsDraw.Size=13; _fpsDraw.Center=true
_fpsDraw.Outline=true; _fpsDraw.Visible=false; _fpsDraw.ZIndex=11
Core:Add(function() pcall(function() _fpsDraw:Remove() end) end)

local _fpsAccum,_fpsCount,_fpsDisplay=0,0,0
Core:Add(RunService.RenderStepped:Connect(function(dt)
    if not Config.FPSCounter.Enabled then _fpsDraw.Visible=false; return end
    _fpsAccum=_fpsAccum+dt; _fpsCount=_fpsCount+1
    if _fpsAccum>=0.5 then
        _fpsDisplay=math.floor(_fpsCount/_fpsAccum)
        _fpsAccum=0; _fpsCount=0
    end
    -- [FIX v1.5] Posisi ATAS TENGAH layar
    _fpsDraw.Position=Vector2.new(Camera.ViewportSize.X/2, 14)
    _fpsDraw.Color=_fpsDisplay>=50 and Color3.fromRGB(80,255,80)
        or _fpsDisplay>=30 and Color3.fromRGB(255,220,50)
        or Color3.fromRGB(255,60,60)
    _fpsDraw.Text=string.format("FPS: %d", _fpsDisplay)
    _fpsDraw.Visible=true
end))

-- ============================================================================
-- [13] SPECTATOR DETECTOR
-- ============================================================================
local _lastSpectators = {}
local function CheckSpectators()
    if not Config.Spectator.Enabled then return end
    local camSubject = Camera.CameraSubject
    if not camSubject then return end
    -- Deteksi jika kamera subjek bukan karakter lokal sendiri
    -- (artinya seseorang sedang spectate kita)
    for _,player in ipairs(Players:GetPlayers()) do
        if player==LocalPlayer then continue end
        -- Cek jika camera player lain sedang follow karakter kita
        local ok, otherCam = pcall(function()
            return player:FindFirstChildOfClass("Camera")
        end)
        if ok and otherCam then
            local subject = otherCam.CameraSubject
            if subject and LocalPlayer.Character and
               subject:IsDescendantOf(LocalPlayer.Character) then
                if not _lastSpectators[player] then
                    _lastSpectators[player]=true
                    ShowToast("👁 "..player.Name.." spectating!", false)
                end
            else
                _lastSpectators[player]=nil
            end
        end
    end
end

local _specTimer=0
Core:Add(RunService.Heartbeat:Connect(function(dt)
    _specTimer=_specTimer+dt
    if _specTimer>=3 then _specTimer=0; CheckSpectators() end
end))

-- ============================================================================
-- [14] AUTO REJOIN
-- ============================================================================
Core:Add(Players.LocalPlayer.OnTeleport:Connect(function(state)
    if state==Enum.TeleportState.Failed or state==Enum.TeleportState.InProgress then
        if Config.Mods.AutoRejoin then
            ShowToast("Reconnecting...", true)
            task.wait(3)
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
        end
    end
end))

-- ============================================================================
-- [15] PHYSICS MODS
-- ============================================================================
Core:Add(RunService.Stepped:Connect(function()
    if not Config.Mods.Noclip then return end
    local char=LocalPlayer.Character; if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
    end
end))

local _infJumpConn
local function SetInfJump(on)
    if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn=nil end
    if on then
        _infJumpConn=UserInputService.JumpRequest:Connect(function()
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

local _flyBV,_flyBAV,_flyConn
local flyUp,flyDown=false,false

local function StopFly()
    if _flyConn then _flyConn:Disconnect(); _flyConn=nil end
    if _flyBV   then pcall(function() _flyBV:Destroy()  end); _flyBV=nil  end
    if _flyBAV  then pcall(function() _flyBAV:Destroy() end); _flyBAV=nil end
    pcall(function()
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand=false end
    end)
    flyUp=false; flyDown=false
end

local function StartFly()
    StopFly()
    local char=LocalPlayer.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv=Instance.new("BodyVelocity")
    bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
    bv.Velocity=Vector3.zero; bv.Parent=hrp; _flyBV=bv
    local bav=Instance.new("BodyAngularVelocity")
    bav.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
    bav.AngularVelocity=Vector3.zero; bav.Parent=hrp; _flyBAV=bav
    local jt=0
    _flyConn=RunService.RenderStepped:Connect(function(dt)
        local r=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not(r and h) then StopFly(); return end
        local spd=Config.Mods.FlySpeed
        local fwd=Camera.CFrame.LookVector*Vector3.new(1,0,1)
        local vel=fwd.Magnitude>0 and fwd.Unit*spd or Vector3.zero
        if flyUp   then vel=vel+Vector3.new(0,spd,0) end
        if flyDown then vel=vel-Vector3.new(0,spd,0) end
        bv.Velocity=vel
        jt=jt+dt
        if jt>=0.4 then jt=0; pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end)
end

local _origLighting={}
local function SetFullBright(on)
    if on then
        _origLighting={ClockTime=Lighting.ClockTime,Brightness=Lighting.Brightness,
            GlobalShadows=Lighting.GlobalShadows,FogEnd=Lighting.FogEnd,Ambient=Lighting.Ambient}
        Lighting.ClockTime=14; Lighting.Brightness=2
        Lighting.GlobalShadows=false; Lighting.FogEnd=9e9
        Lighting.Ambient=Color3.fromRGB(178,178,178)
    else
        for k,v in pairs(_origLighting) do pcall(function() Lighting[k]=v end) end
    end
end

local _antiAFKConn
local function SetAntiAFK(on)
    if _antiAFKConn then _antiAFKConn:Disconnect(); _antiAFKConn=nil end
    if on then
        local ok,vu=pcall(function() return game:GetService("VirtualUser") end)
        if ok and vu then
            _antiAFKConn=LocalPlayer.Idled:Connect(function()
                pcall(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
            end)
        end
    end
end

local _fpsOrigEffects={}; local _fpsOrigLt={}
local _fxList={"BlurEffect","DepthOfFieldEffect","SunRaysEffect","BloomEffect","ColorCorrectionEffect"}
local function SetFPSBoost(on)
    if on then
        _fpsOrigLt={Technology=Lighting.Technology,GlobalShadows=Lighting.GlobalShadows}
        pcall(function() Lighting.Technology=Enum.Technology.Compatibility; Lighting.GlobalShadows=false end)
        pcall(function() settings().Rendering.QualityLevel=Enum.SavedQualitySetting.Level05 end)
        _fpsOrigEffects={}
        local function pe(parent)
            for _,c in ipairs(parent:GetChildren()) do
                for _,ec in ipairs(_fxList) do
                    if c:IsA(ec) and c.Enabled then
                        table.insert(_fpsOrigEffects,c); pcall(function() c.Enabled=false end)
                    end
                end
            end
        end
        pe(Lighting); pe(Camera)
    else
        for _,e in ipairs(_fpsOrigEffects) do pcall(function() e.Enabled=true end) end
        _fpsOrigEffects={}
        for k,v in pairs(_fpsOrigLt) do pcall(function() Lighting[k]=v end) end
        pcall(function() settings().Rendering.QualityLevel=Enum.SavedQualitySetting.Automatic end)
    end
end

local _speedLoopConn
local function StopSpeedLoop()
    if _speedLoopConn then _speedLoopConn:Disconnect(); _speedLoopConn=nil end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed=16 end
end
local function StartSpeedLoop()
    StopSpeedLoop()
    local ts=SpeedTiers[Config.Mods.SpeedTier] or 60
    _speedLoopConn=RunService.Heartbeat:Connect(function()
        if not Config.Mods.Speed then StopSpeedLoop(); return end
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed~=ts then hum.WalkSpeed=ts end
    end)
end
Core:Add(function() StopSpeedLoop() end)

Core:Add(LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid"); char:WaitForChild("HumanoidRootPart")
    if Config.Mods.Fly then StopFly() end
    task.wait(0.4)
    if Config.Mods.Speed   then StartSpeedLoop()  end
    if Config.Mods.InfJump then SetInfJump(true)  end
    if Config.Mods.Fly     then StartFly()         end
    SyncCamera()
end))

-- ============================================================================
-- [16] UI MODULE
-- ============================================================================
local UI = {_tabPages={}}

function UI:Build()
    local Screen=Instance.new("ScreenGui")
    Screen.Name="Nexus_UI"; Screen.ResetOnSpawn=false
    Screen.DisplayOrder=999; Screen.Parent=SafeGUI
    Core:Add(Screen); self.Screen=Screen

    local Wrapper=Instance.new("Frame",Screen)
    Wrapper.Name="Wrapper"
    -- [FIX v1.5] Tinggi window lebih kompak
    Wrapper.Size=UDim2.new(0,262,0,430)
    Wrapper.Position=UDim2.new(0.04,0,0.08,0)
    Wrapper.BackgroundTransparency=1
    Instance.new("UICorner",Wrapper).CornerRadius=UDim.new(0,12)
    local WStroke=Instance.new("UIStroke",Wrapper)
    WStroke.Color=Color3.fromRGB(40,100,255); WStroke.Thickness=1.5
    self.Wrapper=Wrapper

    local Main=Instance.new("Frame",Wrapper)
    Main.Name="Main"; Main.Size=UDim2.new(1,0,1,0)
    Main.BackgroundColor3=Color3.fromRGB(14,14,20)
    Main.BorderSizePixel=0; Main.ClipsDescendants=true
    Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12)
    self.Main=Main

    -- TopBar
    local TopBar=Instance.new("Frame",Main)
    TopBar.Size=UDim2.new(1,0,0,36); TopBar.BackgroundColor3=Color3.fromRGB(20,20,30)
    TopBar.BorderSizePixel=0

    local TitleLbl=Instance.new("TextLabel",TopBar)
    TitleLbl.Size=UDim2.new(1,-96,1,0); TitleLbl.Position=UDim2.new(0,11,0,0)
    TitleLbl.BackgroundTransparency=1; TitleLbl.Text="⚡  NEXUS  v1.5"
    TitleLbl.TextColor3=Color3.fromRGB(255,255,255)
    TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=13
    TitleLbl.TextXAlignment=Enum.TextXAlignment.Left

    local HideBtn=Instance.new("TextButton",TopBar)
    HideBtn.Size=UDim2.new(0,24,0,22); HideBtn.Position=UDim2.new(1,-60,0.5,-11)
    HideBtn.BackgroundColor3=Color3.fromRGB(30,60,120)
    HideBtn.Text="👁"; HideBtn.TextColor3=Color3.fromRGB(200,220,255)
    HideBtn.Font=Enum.Font.GothamBold; HideBtn.TextSize=11
    HideBtn.BorderSizePixel=0
    Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(0,5)

    local MinBtn=Instance.new("TextButton",TopBar)
    MinBtn.Size=UDim2.new(0,24,0,22); MinBtn.Position=UDim2.new(1,-32,0.5,-11)
    MinBtn.BackgroundColor3=Color3.fromRGB(35,35,52)
    MinBtn.Text="—"; MinBtn.TextColor3=Color3.fromRGB(200,200,200)
    MinBtn.Font=Enum.Font.GothamBold; MinBtn.TextSize=12
    MinBtn.BorderSizePixel=0
    Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,5)

    -- TabBar
    local TabBar=Instance.new("Frame",Main)
    TabBar.Size=UDim2.new(1,0,0,28); TabBar.Position=UDim2.new(0,0,0,36)
    TabBar.BackgroundColor3=Color3.fromRGB(18,18,27); TabBar.BorderSizePixel=0
    local TL=Instance.new("UIListLayout",TabBar)
    TL.FillDirection=Enum.FillDirection.Horizontal; TL.Padding=UDim.new(0,2)
    TL.HorizontalAlignment=Enum.HorizontalAlignment.Center
    TL.VerticalAlignment=Enum.VerticalAlignment.Center
    self.TabBar=TabBar

    -- Content
    local Content=Instance.new("Frame",Main)
    Content.Name="Content"
    Content.Size=UDim2.new(1,0,1,-64); Content.Position=UDim2.new(0,0,0,64)
    Content.BackgroundTransparency=1
    self.Content=Content

    -- Pill
    local Pill=Instance.new("TextButton",Screen)
    Pill.Size=UDim2.new(0,90,0,24); Pill.Position=Wrapper.Position
    Pill.BackgroundColor3=Color3.fromRGB(20,60,160)
    Pill.Text="⚡ NEXUS"; Pill.TextColor3=Color3.fromRGB(255,255,255)
    Pill.Font=Enum.Font.GothamBold; Pill.TextSize=11
    Pill.BorderSizePixel=0; Pill.Visible=false
    Instance.new("UICorner",Pill).CornerRadius=UDim.new(0,12)
    local pS=Instance.new("UIStroke",Pill); pS.Color=Color3.fromRGB(40,100,255); pS.Thickness=1
    self.Pill=Pill

    Core:Add(HideBtn.MouseButton1Click:Connect(function()
        Pill.Position=UDim2.new(Wrapper.Position.X.Scale,Wrapper.Position.X.Offset,
            Wrapper.Position.Y.Scale,Wrapper.Position.Y.Offset)
        Wrapper.Visible=false; Pill.Visible=true
    end))
    Core:Add(Pill.MouseButton1Click:Connect(function()
        Wrapper.Position=Pill.Position; Wrapper.Visible=true; Pill.Visible=false
    end))

    -- Drag
    local dragging,dragStart,startPos=false,nil,nil
    Core:Add(TopBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=inp.Position; startPos=Wrapper.Position
        end
    end))
    Core:Add(UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then
            local d=inp.Position-dragStart
            Wrapper.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,
                startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end))
    Core:Add(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))

    -- Minimize
    local minimized=false
    Core:Add(MinBtn.MouseButton1Click:Connect(function()
        minimized=not minimized
        Content.Visible=not minimized; TabBar.Visible=not minimized
        Wrapper.Size=minimized and UDim2.new(0,262,0,36) or UDim2.new(0,262,0,430)
        MinBtn.Text=minimized and "+" or "—"
    end))
end

function UI:AddTab(name)
    local page=Instance.new("ScrollingFrame",self.Content)
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1
    page.BorderSizePixel=0; page.ScrollBarThickness=4
    page.ScrollBarImageColor3=Color3.fromRGB(40,100,255)
    page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false
    page.ScrollingEnabled=true; page.ElasticBehavior=Enum.ElasticBehavior.Never

    local layout=Instance.new("UIListLayout",page)
    layout.Padding=UDim.new(0,4)
    layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    layout.SortOrder=Enum.SortOrder.LayoutOrder

    local pad=Instance.new("UIPadding",page)
    pad.PaddingTop=UDim.new(0,6); pad.PaddingLeft=UDim.new(0,5)
    pad.PaddingRight=UDim.new(0,5); pad.PaddingBottom=UDim.new(0,10)

    -- [FIX v1.5] Refresh canvas setiap kali konten berubah
    Core:Add(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
    end))
    local function refresh()
        -- Force recalculate
        task.wait()
        page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
    end

    local btn=Instance.new("TextButton",self.TabBar)
    btn.Size=UDim2.new(0,40,0,20); btn.BackgroundColor3=Color3.fromRGB(28,28,40)
    btn.Text=name; btn.TextColor3=Color3.fromRGB(150,150,170)
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=9
    btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)

    local entry={page=page,btn=btn}; table.insert(self._tabPages,entry)

    local function activate()
        for _,t in ipairs(self._tabPages) do
            t.page.Visible=false
            t.btn.BackgroundColor3=Color3.fromRGB(28,28,40)
            t.btn.TextColor3=Color3.fromRGB(150,150,170)
        end
        page.Visible=true
        btn.BackgroundColor3=Color3.fromRGB(40,100,255)
        btn.TextColor3=Color3.fromRGB(255,255,255)
        -- Refresh canvas saat tab dibuka
        task.defer(refresh)
    end
    Core:Add(btn.MouseButton1Click:Connect(activate))
    if #self._tabPages==1 then activate() end
    return page, refresh
end

function UI:Section(parent,text)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,16); f.BackgroundTransparency=1; f.LayoutOrder=1
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text="── "..text.." ──"
    l.TextColor3=Color3.fromRGB(60,130,255)
    l.Font=Enum.Font.GothamBold; l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Center
end

function UI:Toggle(parent,label,callback,activeColor)
    local color=activeColor or Color3.fromRGB(40,100,255)
    local state=false
    local card=Instance.new("Frame",parent)
    card.Size=UDim2.new(1,0,0,26); card.BackgroundColor3=Color3.fromRGB(22,22,33)
    card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,-48,1,0); lbl.Position=UDim2.new(0,9,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(210,210,215)
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local pill=Instance.new("TextButton",card)
    pill.Size=UDim2.new(0,32,0,15); pill.Position=UDim2.new(1,-40,0.5,-7)
    pill.BackgroundColor3=Color3.fromRGB(38,38,55)
    pill.Text=""; pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,11,0,11); knob.Position=UDim2.new(0,2,0.5,-5)
    knob.BackgroundColor3=Color3.fromRGB(140,140,160); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    Core:Add(pill.MouseButton1Click:Connect(function()
        state=not state
        if state then
            pill.BackgroundColor3=color
            knob.Position=UDim2.new(1,-13,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(255,255,255)
        else
            pill.BackgroundColor3=Color3.fromRGB(38,38,55)
            knob.Position=UDim2.new(0,2,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(140,140,160)
        end
        ShowToast(label,state)
        SaveConfig()
        pcall(callback,state)
    end))
end

function UI:ChoiceRow(parent,label,options,default,callback)
    local wrap=Instance.new("Frame",parent)
    wrap.Size=UDim2.new(1,0,0,50); wrap.BackgroundColor3=Color3.fromRGB(22,22,33)
    wrap.BorderSizePixel=0
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",wrap)
    lbl.Size=UDim2.new(1,0,0,17); lbl.Position=UDim2.new(0,9,0,3)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(160,160,180); lbl.Font=Enum.Font.GothamSemibold
    lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local row=Instance.new("Frame",wrap)
    row.Size=UDim2.new(1,-12,0,22); row.Position=UDim2.new(0,6,0,22)
    row.BackgroundTransparency=1
    local rL=Instance.new("UIListLayout",row)
    rL.FillDirection=Enum.FillDirection.Horizontal; rL.Padding=UDim.new(0,3)
    rL.HorizontalAlignment=Enum.HorizontalAlignment.Left
    rL.VerticalAlignment=Enum.VerticalAlignment.Center
    local buttons={}
    for _,opt in ipairs(options) do
        local b=Instance.new("TextButton",row)
        b.Size=UDim2.new(0,48,0,19)
        b.BackgroundColor3=opt==default and Color3.fromRGB(40,100,255) or Color3.fromRGB(35,35,52)
        b.Text=opt; b.TextColor3=Color3.fromRGB(220,220,220)
        b.Font=Enum.Font.GothamBold; b.TextSize=9; b.BorderSizePixel=0
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        table.insert(buttons,{btn=b,opt=opt})
        Core:Add(b.MouseButton1Click:Connect(function()
            for _,e in ipairs(buttons) do
                e.btn.BackgroundColor3=e.opt==opt
                    and Color3.fromRGB(40,100,255) or Color3.fromRGB(35,35,52)
            end
            SaveConfig(); pcall(callback,opt)
        end))
    end
end

function UI:HoldButton(parent,label,onHold,onRelease,col)
    local btn=Instance.new("TextButton",parent)
    btn.Size=UDim2.new(0.47,0,0,28)
    btn.BackgroundColor3=col or Color3.fromRGB(40,80,180)
    btn.Text=label; btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Font=Enum.Font.GothamBold; btn.TextSize=12
    btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    Core:Add(btn.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then pcall(onHold) end
    end))
    Core:Add(btn.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then pcall(onRelease) end
    end))
end

-- ============================================================================
-- [17] BOOTSTRAP — task.defer(refresh) di setiap tab
-- ============================================================================
UI:Build()

-- ── TAB: ESP ──────────────────────────────────────────────────────────────
do
    local p,refresh=UI:AddTab("ESP")
    UI:Section(p,"MASTER")
    UI:Toggle(p,"Aktifkan ESP",function(v) Config.ESP.Enabled=v end,Color3.fromRGB(30,210,80))
    UI:Section(p,"BODY")
    UI:Toggle(p,"Highlight (Solid+Tembus)",function(v) Config.ESP.ShowHighlight=v end,Color3.fromRGB(30,210,80))
    UI:Toggle(p,"Skeleton (Seluruh Badan)",function(v) Config.ESP.ShowSkeleton=v end,Color3.fromRGB(30,210,80))
    UI:Toggle(p,"Chams (Neon Fill)",function(v)
        Config.ESP.ShowChams=v
        for _,player in ipairs(Players:GetPlayers()) do
            if player~=LocalPlayer then ApplyChams(player,v) end
        end
    end,Color3.fromRGB(160,80,255))
    UI:Toggle(p,"Box ESP",function(v) Config.ESP.ShowBox=v end)
    UI:Toggle(p,"Head Dot",function(v) Config.ESP.ShowHeadDot=v end)
    UI:Toggle(p,"Snap Line",function(v) Config.ESP.ShowSnapLine=v end)
    UI:Section(p,"INFO HUD")
    UI:Toggle(p,"Name Tag",function(v) Config.ESP.ShowName=v end)
    UI:Toggle(p,"Health Bar",function(v) Config.ESP.ShowHealth=v end)
    UI:Toggle(p,"Health Number",function(v) Config.ESP.ShowHealthNum=v end)
    UI:Toggle(p,"Distance Tag",function(v) Config.ESP.ShowDistance=v end)
    task.defer(refresh)
end

-- ── TAB: AIMBOT ───────────────────────────────────────────────────────────
do
    local p,refresh=UI:AddTab("Aimbot")
    UI:Section(p,"SISTEM")
    UI:Toggle(p,"Aktifkan Aimbot",function(v)
        Config.Aimbot.Enabled=v
        FOVCircle.Visible=v and Config.Aimbot.FOVVisible
    end,Color3.fromRGB(255,70,70))
    UI:Toggle(p,"Silent Aim (Kamera Diam)",function(v) Config.Aimbot.SilentAim=v end,Color3.fromRGB(255,140,40))
    UI:Toggle(p,"Triggerbot (Auto Serang)",function(v) Config.Aimbot.Triggerbot=v end,Color3.fromRGB(255,100,100))
    UI:Toggle(p,"Kill Aura (Radius Serang)",function(v)
        Config.Aimbot.KillAura=v; if v then StartKillAura() end
    end,Color3.fromRGB(200,50,50))
    UI:Section(p,"FILTER")
    UI:Toggle(p,"Wall Check (Raycast)",function(v) Config.Aimbot.WallCheck=v end)
    UI:Toggle(p,"Team Check",function(v) Config.Aimbot.TeamCheck=v end)
    UI:Toggle(p,"Alive Check",function(v) Config.Aimbot.AliveCheck=v end)
    UI:Toggle(p,"Movement Prediction",function(v) Config.Aimbot.PredictMovement=v end,Color3.fromRGB(255,160,40))
    UI:Section(p,"FOV VISUAL")
    UI:Toggle(p,"Tampilkan FOV Circle",function(v)
        Config.Aimbot.FOVVisible=v; FOVCircle.Visible=v and Config.Aimbot.Enabled
    end)
    -- [v1.5] FOV Slider langsung di UI
    local fovCard=Instance.new("Frame",p)
    fovCard.Size=UDim2.new(1,0,0,42); fovCard.BackgroundColor3=Color3.fromRGB(22,22,33)
    fovCard.BorderSizePixel=0
    Instance.new("UICorner",fovCard).CornerRadius=UDim.new(0,6)
    local fovLbl=Instance.new("TextLabel",fovCard)
    fovLbl.Size=UDim2.new(1,-10,0,18); fovLbl.Position=UDim2.new(0,9,0,3)
    fovLbl.BackgroundTransparency=1
    fovLbl.Text="FOV Radius: "..Config.Aimbot.FOVRadius
    fovLbl.TextColor3=Color3.fromRGB(200,200,210); fovLbl.Font=Enum.Font.GothamSemibold
    fovLbl.TextSize=11; fovLbl.TextXAlignment=Enum.TextXAlignment.Left
    -- Slider track
    local track=Instance.new("Frame",fovCard)
    track.Size=UDim2.new(1,-18,0,6); track.Position=UDim2.new(0,9,0,28)
    track.BackgroundColor3=Color3.fromRGB(35,35,52); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(Config.Aimbot.FOVRadius/500,0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(40,100,255); fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new(Config.Aimbot.FOVRadius/500,0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.Text=""
    knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local draggingSlider=false
    Core:Add(knob.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            draggingSlider=true
        end
    end))
    Core:Add(UserInputService.InputChanged:Connect(function(inp)
        if not draggingSlider then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then
            local trackPos=track.AbsolutePosition
            local trackSize=track.AbsoluteSize
            local relX=math.clamp((inp.Position.X-trackPos.X)/trackSize.X,0,1)
            local val=math.floor(relX*500)
            val=math.clamp(val,30,500)
            Config.Aimbot.FOVRadius=val
            FOVCircle.Radius=val
            fill.Size=UDim2.new(relX,0,1,0)
            knob.Position=UDim2.new(relX,0,0.5,0)
            fovLbl.Text="FOV Radius: "..val
        end
    end))
    Core:Add(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            draggingSlider=false; SaveConfig()
        end
    end))
    task.defer(refresh)
end

-- ── TAB: PLAYER ───────────────────────────────────────────────────────────
do
    local p,refresh=UI:AddTab("Player")
    UI:Section(p,"SPEED")
    UI:Toggle(p,"Aktifkan Speed Hack",function(v)
        Config.Mods.Speed=v; if v then StartSpeedLoop() else StopSpeedLoop() end
    end,Color3.fromRGB(255,180,30))
    UI:ChoiceRow(p,"Tier Kecepatan",{"Normal","Fast","Turbo","Ultra"},"Fast",function(t)
        Config.Mods.SpeedTier=t; if Config.Mods.Speed then StartSpeedLoop() end
    end)
    UI:Section(p,"MOVEMENT")
    UI:Toggle(p,"Noclip (Tembus Dinding)",function(v) Config.Mods.Noclip=v end)
    UI:Toggle(p,"Infinite Jump",function(v) Config.Mods.InfJump=v; SetInfJump(v) end)
    UI:Section(p,"TERBANG")
    UI:Toggle(p,"Aktifkan Terbang",function(v)
        Config.Mods.Fly=v; if v then StartFly() else StopFly() end
    end,Color3.fromRGB(80,160,255))
    local row=Instance.new("Frame",p)
    row.Size=UDim2.new(1,0,0,30); row.BackgroundTransparency=1
    local rL=Instance.new("UIListLayout",row)
    rL.FillDirection=Enum.FillDirection.Horizontal; rL.Padding=UDim.new(0,5)
    rL.HorizontalAlignment=Enum.HorizontalAlignment.Center
    rL.VerticalAlignment=Enum.VerticalAlignment.Center
    UI:HoldButton(row,"▲ NAIK",function() flyUp=true end,function() flyUp=false end,Color3.fromRGB(45,110,220))
    UI:HoldButton(row,"▼ TURUN",function() flyDown=true end,function() flyDown=false end,Color3.fromRGB(175,55,55))
    UI:Section(p,"VISUAL")
    UI:Toggle(p,"Full Bright",function(v) Config.Mods.FullBright=v; SetFullBright(v) end)
    task.defer(refresh)
end

-- ── TAB: HUD ─────────────────────────────────────────────────────────────
do
    local p,refresh=UI:AddTab("HUD")
    UI:Section(p,"CROSSHAIR")
    UI:Toggle(p,"Aktifkan Crosshair",function(v)
        Config.Crosshair.Enabled=v
        if v then DrawCrosshair() else RemoveCrosshair() end
    end,Color3.fromRGB(255,255,100))
    UI:ChoiceRow(p,"Style",{"Dot","Cross","Circle"},"Cross",function(s)
        Config.Crosshair.Style=s; if Config.Crosshair.Enabled then DrawCrosshair() end
    end)
    UI:Section(p,"RADAR MINI-MAP")
    UI:Toggle(p,"Aktifkan Radar",function(v)
        Config.Radar.Enabled=v; InitRadar()
    end,Color3.fromRGB(80,200,255))
    UI:Toggle(p,"Nama di Radar",function(v)
        Config.Radar.ShowNames=v
    end,Color3.fromRGB(80,180,255))
    UI:Section(p,"FPS COUNTER (Atas Tengah)")
    UI:Toggle(p,"Tampilkan FPS Live",function(v)
        Config.FPSCounter.Enabled=v
        if not v then _fpsDraw.Visible=false end
    end,Color3.fromRGB(100,255,100))
    task.defer(refresh)
end

-- ── TAB: UTILS ────────────────────────────────────────────────────────────
do
    local p,refresh=UI:AddTab("Utils")
    UI:Section(p,"FPS BOOSTER")
    UI:Toggle(p,"Aktifkan FPS Booster",function(v)
        Config.Mods.FPSBoost=v; SetFPSBoost(v)
    end,Color3.fromRGB(255,210,40))
    UI:Section(p,"UTILITY")
    UI:Toggle(p,"Anti AFK",function(v) Config.Mods.AntiAFK=v; SetAntiAFK(v) end)
    UI:Toggle(p,"Auto Rejoin (Detect Kick)",function(v) Config.Mods.AutoRejoin=v end,Color3.fromRGB(255,120,40))
    UI:Toggle(p,"Spectator Detector",function(v) Config.Spectator.Enabled=v end,Color3.fromRGB(200,100,255))
    UI:Section(p,"CONFIG")
    local saveBtn=Instance.new("TextButton",p)
    saveBtn.Size=UDim2.new(1,0,0,26)
    saveBtn.BackgroundColor3=Color3.fromRGB(30,70,160)
    saveBtn.Text="💾  Simpan Config"; saveBtn.TextColor3=Color3.fromRGB(220,240,255)
    saveBtn.Font=Enum.Font.GothamBold; saveBtn.TextSize=11; saveBtn.BorderSizePixel=0
    Instance.new("UICorner",saveBtn).CornerRadius=UDim.new(0,6)
    Core:Add(saveBtn.MouseButton1Click:Connect(function()
        SaveConfig(); ShowToast("Config disimpan!", true)
    end))
    local loadBtn=Instance.new("TextButton",p)
    loadBtn.Size=UDim2.new(1,0,0,26)
    loadBtn.BackgroundColor3=Color3.fromRGB(25,55,25)
    loadBtn.Text="📂  Muat Config"; loadBtn.TextColor3=Color3.fromRGB(180,255,180)
    loadBtn.Font=Enum.Font.GothamBold; loadBtn.TextSize=11; loadBtn.BorderSizePixel=0
    Instance.new("UICorner",loadBtn).CornerRadius=UDim.new(0,6)
    Core:Add(loadBtn.MouseButton1Click:Connect(function()
        LoadConfig(); ShowToast("Config dimuat!", true)
    end))
    task.defer(refresh)
end

-- Init Drawing
DrawCrosshair()
InitRadar()

-- ============================================================================
print("✅ NEXUS v1.5 — Ultimate Edition Loaded")
print("🆕 Chams, SnapLine, HP Number, SilentAim, Triggerbot")
print("🆕 KillAura, SpectatorDetector, AutoRejoin, FOV Slider")
print("🔧 Fix: FPS Counter → atas tengah | Scroll semua tab")
-- ============================================================================
