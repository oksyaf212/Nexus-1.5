--[[
    ============================================================================
    PROJECT   : NEXUS v1.6 — Phenomenon Edition (Fixed)
    PLATFORM  : Delta Executor Android
    AUTHOR    : Claude Sonnet 4.6
    FIX v1.6:
    ├── Tab Bar → ScrollingFrame horizontal (geser kiri/kanan)
    ├── Blink Attack → Otomatis + kamera diarahkan sebelum serang
    └── Toggle → State independen, tidak saling mempengaruhi
    ============================================================================
]]

local ENV_KEY="Nexus_Suite_v1_6"
if getgenv()[ENV_KEY] then pcall(function() getgenv()[ENV_KEY]:Destroy() end) end
if getgenv().Nexus_FOVCircle then
    pcall(function() getgenv().Nexus_FOVCircle:Remove() end)
    getgenv().Nexus_FOVCircle=nil
end

-- ============================================================================
-- [1] SERVICES
-- ============================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local SafeGUI     = (pcall(function() return CoreGui.Name end))
                    and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local Camera      = Workspace.CurrentCamera

-- ============================================================================
-- [2] MAID
-- ============================================================================
local Maid={}; Maid.__index=Maid
function Maid.new() return setmetatable({_jobs={}},Maid) end
function Maid:Add(job) table.insert(self._jobs,job); return job end
function Maid:Destroy()
    for _,job in ipairs(self._jobs) do
        if typeof(job)=="RBXScriptConnection" then pcall(function() job:Disconnect() end)
        elseif type(job)=="function" then pcall(job)
        elseif typeof(job)=="Instance" then pcall(function() job:Destroy() end) end
    end
    self._jobs={}
end

local Core=Maid.new()
getgenv()[ENV_KEY]=Core

-- ============================================================================
-- [3] THEMES
-- ============================================================================
local Themes={
    Blue  ={primary=Color3.fromRGB(40,100,255), bg=Color3.fromRGB(14,14,20),  topbar=Color3.fromRGB(20,20,30)},
    Red   ={primary=Color3.fromRGB(220,40,40),  bg=Color3.fromRGB(18,10,10),  topbar=Color3.fromRGB(28,12,12)},
    Green ={primary=Color3.fromRGB(30,200,80),  bg=Color3.fromRGB(10,18,12),  topbar=Color3.fromRGB(12,26,16)},
    Purple={primary=Color3.fromRGB(150,50,255), bg=Color3.fromRGB(14,10,20),  topbar=Color3.fromRGB(20,12,30)},
    Gold  ={primary=Color3.fromRGB(220,170,20), bg=Color3.fromRGB(18,15,8),   topbar=Color3.fromRGB(26,22,10)},
}
local CurrentTheme=Themes.Blue

-- ============================================================================
-- [4] CONFIG
-- ============================================================================
local SpeedTiers={Normal=28,Fast=60,Turbo=100,Ultra=160}
local CONFIG_FILE="nexus_v16_config.json"

local Config={
    ESP={
        Enabled=false,ShowHighlight=true,ShowBox=true,ShowName=true,
        ShowHealth=true,ShowHealthNum=true,ShowDistance=true,
        ShowHeadDot=true,ShowSkeleton=true,ShowSnapLine=true,
        ShowChams=false,ShowLevelTag=true,AdaptiveOpacity=false,
        MaxDistance=99999,CullDistance=1500,
        TeamColor=Color3.fromRGB(30,220,80),EnemyColor=Color3.fromRGB(255,50,50),
        FillAlpha=0.2,OutlineAlpha=0.0,
    },
    Aimbot={
        Enabled=false,FOVRadius=200,FOVVisible=true,Smoothness=0.35,
        TargetPart="Head",WallCheck=true,TeamCheck=true,AliveCheck=true,
        PredictMovement=true,PredictFactor=0.12,SilentAim=false,
        Triggerbot=false,TriggerDelay=0.05,KillAura=false,KillAuraRadius=15,
        Priority="FOV",NoRecoil=false,RapidFire=false,
    },
    Mods={
        Speed=false,SpeedTier="Fast",Noclip=false,InfJump=false,
        Fly=false,FlySpeed=55,FullBright=false,AntiAFK=false,
        FPSBoost=false,AutoRejoin=false,InfStamina=false,AntiVoid=false,BunnyHop=false,
    },
    Crosshair={
        Enabled=false,Style="Cross",
        Color=Color3.fromRGB(255,255,255),
        HitColor=Color3.fromRGB(255,60,60),
        Size=10,Thickness=1.5,
    },
    Radar={Enabled=false,Radius=80,Scale=0.04,ShowNames=true},
    FPSCounter={Enabled=false},
    Spectator={Enabled=false},
    UI={Theme="Blue",Opacity=1.0,UndetectedMode=false},
    RPG={
        AutoFarm=false,BlinkAttack=false,BlinkRadius=400,BlinkInterval=0.6,
        AutoCollect=false,CollectRadius=50,AutoQuest=false,DungeonHelper=false,
    },
    Combat={AutoCombo=false,ComboDelay=0.1,BlockPredict=false,ParryTiming=false},
    Sim={AutoClick=false,AutoClickDelay=0.05,AutoRebirth=false,MultiplierESP=false},
    World={WorldESP=false,SafeZoneDetect=false,WeatherAlert=false},
    Chat={Bypass=false},
}

-- ============================================================================
-- [5] CONFIG SAVE / LOAD
-- ============================================================================
local function SaveConfig()
    pcall(function()
        local d={
            ESPEnabled=Config.ESP.Enabled,
            AimbotEnabled=Config.Aimbot.Enabled,
            AimbotFOV=Config.Aimbot.FOVRadius,
            AimbotSmooth=Config.Aimbot.Smoothness,
            AimbotPriority=Config.Aimbot.Priority,
            SpeedTier=Config.Mods.SpeedTier,
            UITheme=Config.UI.Theme,
            UIOpacity=Config.UI.Opacity,
            CrosshairEnabled=Config.Crosshair.Enabled,
            CrosshairStyle=Config.Crosshair.Style,
            RadarEnabled=Config.Radar.Enabled,
            FPSEnabled=Config.FPSCounter.Enabled,
        }
        writefile(CONFIG_FILE,HttpService:JSONEncode(d))
    end)
end

local function LoadConfig()
    pcall(function()
        if not isfile(CONFIG_FILE) then return end
        local d=HttpService:JSONDecode(readfile(CONFIG_FILE))
        if not d then return end
        -- Hanya load setting non-toggle
        -- Toggle state TIDAK di-load otomatis
        -- agar tidak menyebabkan semua fitur aktif sendiri
        Config.Aimbot.FOVRadius=d.AimbotFOV or 200
        Config.Aimbot.Smoothness=d.AimbotSmooth or 0.35
        Config.Aimbot.Priority=d.AimbotPriority or "FOV"
        Config.Mods.SpeedTier=d.SpeedTier or "Fast"
        Config.UI.Theme=d.UITheme or "Blue"
        Config.UI.Opacity=d.UIOpacity or 1.0
        Config.Crosshair.Style=d.CrosshairStyle or "Cross"
        CurrentTheme=Themes[Config.UI.Theme] or Themes.Blue
    end)
end
LoadConfig()

-- ============================================================================
-- [6] TOAST
-- ============================================================================
local _toastGui
local function ShowToast(msg,isOn)
    pcall(function()
        if _toastGui then _toastGui:Destroy() end
        local sg=Instance.new("ScreenGui",SafeGUI)
        sg.Name="NexusToast"; sg.ResetOnSpawn=false; sg.DisplayOrder=9999
        _toastGui=sg; Core:Add(sg)
        local f=Instance.new("Frame",sg)
        f.Size=UDim2.new(0,200,0,28); f.Position=UDim2.new(0.5,-100,0.85,0)
        f.BackgroundColor3=isOn and Color3.fromRGB(20,80,20) or Color3.fromRGB(80,20,20)
        f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,14)
        local fs=Instance.new("UIStroke",f)
        fs.Color=isOn and Color3.fromRGB(40,200,60) or Color3.fromRGB(200,50,50); fs.Thickness=1
        local l=Instance.new("TextLabel",f)
        l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=(isOn and "✅ " or "❌ ")..msg
        l.TextColor3=Color3.fromRGB(255,255,255); l.Font=Enum.Font.GothamBold; l.TextSize=11
        task.delay(1.8,function()
            for i=1,10 do
                pcall(function() f.BackgroundTransparency=i/10; l.TextTransparency=i/10 end)
                task.wait(0.04)
            end
            pcall(function() sg:Destroy() end)
        end)
    end)
end

-- ============================================================================
-- [7] CAMERA SYNC
-- ============================================================================
local RayParams=RaycastParams.new()
RayParams.FilterType=Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater=true
local _fs={nil,nil}

local function SyncCamera()
    local nc=Workspace.CurrentCamera; if not nc then return end
    Camera=nc; _fs[1]=LocalPlayer.Character
    RayParams.FilterDescendantsInstances=_fs
end
SyncCamera()
Core:Add(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(SyncCamera))
Core:Add(LocalPlayer.CharacterAdded:Connect(SyncCamera))

-- ============================================================================
-- [8] UTILITY
-- ============================================================================
local function GetRelation(player)
    local lt,pt=LocalPlayer.Team,player.Team
    if lt and pt and lt==pt then return "Team" end
    return "Enemy"
end

local function CheckLOS(tPos,tChar)
    _fs[1]=LocalPlayer.Character; _fs[2]=tChar
    RayParams.FilterDescendantsInstances=_fs
    local r=Workspace:Raycast(Camera.CFrame.Position,tPos-Camera.CFrame.Position,RayParams)
    _fs[2]=nil
    return not r or r.Instance:IsDescendantOf(tChar)
end

local function PredictPos(hrp,head)
    if not Config.Aimbot.PredictMovement then return head.Position end
    return head.Position+(hrp.AssemblyLinearVelocity*Config.Aimbot.PredictFactor)
end

local function GetNearestMonster(radius)
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local nearest,minDist=nil,radius or math.huge
    local function scanFolder(folder)
        if not folder then return end
        for _,obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") then
                local hum=obj:FindFirstChildOfClass("Humanoid")
                local hrp=obj:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health>0 then
                    local dist=(hrp.Position-myHRP.Position).Magnitude
                    if dist<minDist then minDist=dist; nearest=obj end
                end
            end
        end
    end
    for _,name in ipairs({"Enemies","NPCs","Mobs","Monsters","Enemy","Monster"}) do
        scanFolder(Workspace:FindFirstChild(name))
    end
    for _,obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj~=LocalPlayer.Character then
            local hum=obj:FindFirstChildOfClass("Humanoid")
            local hrp=obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health>0 and hum.MaxHealth>0 then
                local dist=(hrp.Position-myHRP.Position).Magnitude
                if dist<minDist then minDist=dist; nearest=obj end
            end
        end
    end
    return nearest
end

-- ============================================================================
-- [9] ESP MODULE
-- ============================================================================
local BONES={
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"RightUpperLeg","RightLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},{"RightLowerLeg","RightFoot"},
    {"UpperTorso","LeftUpperArm"},{"UpperTorso","RightUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},{"RightUpperArm","RightLowerArm"},
    {"LeftLowerArm","LeftHand"},{"RightLowerArm","RightHand"},
}

local ESPCache={}
local _chamsCache={}

local function ApplyChams(player,on)
    local char=player.Character; if not char then return end
    local col=GetRelation(player)=="Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor
    if on then
        _chamsCache[player]=_chamsCache[player] or {}
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                _chamsCache[player][p]=p.Color
                pcall(function() p.Color=col; p.Material=Enum.Material.Neon end)
            end
        end
    else
        if _chamsCache[player] then
            for part,oc in pairs(_chamsCache[player]) do
                pcall(function() part.Color=oc; part.Material=Enum.Material.SmoothPlastic end)
            end
            _chamsCache[player]=nil
        end
    end
end

local function CreateESP(player)
    if player==LocalPlayer or ESPCache[player] then return end
    local c={_lastRelation=nil,_bones={}}
    local ec=Config.ESP.EnemyColor
    local hl=Instance.new("Highlight")
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency=Config.ESP.FillAlpha; hl.OutlineTransparency=Config.ESP.OutlineAlpha
    hl.FillColor=ec; hl.OutlineColor=ec; hl.Enabled=false; hl.Parent=CoreGui
    if player.Character then hl.Adornee=player.Character end
    c._charConn=player.CharacterAdded:Connect(function(ch)
        hl.Adornee=ch
        if Config.ESP.ShowChams then task.wait(0.3); ApplyChams(player,true) end
    end)
    c.Highlight=hl
    local function nL(t)
        local l=Drawing.new("Line"); l.Color=ec; l.Thickness=t; l.Visible=false; l.ZIndex=4; return l
    end
    c.BoxT=nL(1.5); c.BoxB=nL(1.5); c.BoxL=nL(1.5); c.BoxR=nL(1.5)
    local snap=Drawing.new("Line"); snap.Color=ec; snap.Thickness=1; snap.Visible=false; snap.ZIndex=3; c.SnapLine=snap
    local txt=Drawing.new("Text"); txt.Size=13; txt.Center=true; txt.Outline=true; txt.Color=ec; txt.Visible=false; txt.ZIndex=5; c.Text=txt
    local dot=Drawing.new("Circle"); dot.Thickness=1; dot.NumSides=16; dot.Radius=4; dot.Filled=true; dot.Color=ec; dot.Visible=false; dot.ZIndex=6; c.HeadDot=dot
    local hpBg=Drawing.new("Line"); hpBg.Thickness=3; hpBg.Color=Color3.new(0,0,0); hpBg.Visible=false; c.HpBg=hpBg
    local hpFg=Drawing.new("Line"); hpFg.Thickness=1.8; hpFg.Visible=false; c.HpFg=hpFg
    local hpN=Drawing.new("Text"); hpN.Size=10; hpN.Center=true; hpN.Outline=true; hpN.Color=Color3.fromRGB(255,255,255); hpN.Visible=false; hpN.ZIndex=6; c.HpNum=hpN
    local dT=Drawing.new("Text"); dT.Size=11; dT.Center=true; dT.Outline=true; dT.Color=Color3.fromRGB(255,230,80); dT.Visible=false; dT.ZIndex=5; c.DistText=dT
    local lvl=Drawing.new("Text"); lvl.Size=11; lvl.Center=true; lvl.Outline=true; lvl.Color=Color3.fromRGB(200,200,255); lvl.Visible=false; lvl.ZIndex=5; c.LevelTag=lvl
    for i=1,#BONES do
        local b=Drawing.new("Line"); b.Color=ec; b.Thickness=1; b.Visible=false; b.ZIndex=3; c._bones[i]=b
    end
    ESPCache[player]=c
end

local function RemoveESP(player)
    local c=ESPCache[player]; if not c then return end
    ApplyChams(player,false)
    if c._charConn then pcall(function() c._charConn:Disconnect() end) end
    pcall(function() c.Highlight:Destroy() end)
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","SnapLine","Text","HeadDot","HpBg","HpFg","HpNum","DistText","LevelTag"}) do
        pcall(function() c[k]:Remove() end)
    end
    for _,b in ipairs(c._bones) do pcall(function() b:Remove() end) end
    ESPCache[player]=nil
end

local function HideAll(c)
    c.Highlight.Enabled=false
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","SnapLine","Text","HeadDot","HpBg","HpFg","HpNum","DistText","LevelTag"}) do c[k].Visible=false end
    for _,b in ipairs(c._bones) do b.Visible=false end
end

for _,p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Core:Add(Players.PlayerAdded:Connect(CreateESP))
Core:Add(Players.PlayerRemoving:Connect(function(p) ApplyChams(p,false); RemoveESP(p) end))
Core:Add(function()
    local s={}; for p in pairs(ESPCache) do table.insert(s,p) end
    for _,p in ipairs(s) do RemoveESP(p) end
end)

Core:Add(RunService.RenderStepped:Connect(function()
    local vp=Camera.ViewportSize
    for player,c in pairs(ESPCache) do
        local char=player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local head=char and char:FindFirstChild("Head")
        local vis=not not(Config.ESP.Enabled and char and hum and hrp and hum.Health>0)
        if not vis then HideAll(c); continue end
        local dist=(Camera.CFrame.Position-hrp.Position).Magnitude
        if Config.ESP.AdaptiveOpacity then
            c.Highlight.FillTransparency=math.clamp(dist/Config.ESP.MaxDistance,0.15,0.85)
        else
            c.Highlight.FillTransparency=Config.ESP.FillAlpha
        end
        if dist>Config.ESP.CullDistance then
            c.Highlight.Enabled=Config.ESP.ShowHighlight
            for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","SnapLine","Text","HeadDot","HpBg","HpFg","HpNum","DistText","LevelTag"}) do c[k].Visible=false end
            for _,b in ipairs(c._bones) do b.Visible=false end
            continue
        end
        local rel=GetRelation(player)
        if c._lastRelation~=rel then
            local col=rel=="Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor
            c.Highlight.FillColor=col; c.Highlight.OutlineColor=col
            c.BoxT.Color=col; c.BoxB.Color=col; c.BoxL.Color=col; c.BoxR.Color=col
            c.Text.Color=col; c.HeadDot.Color=col; c.SnapLine.Color=col
            for _,b in ipairs(c._bones) do b.Color=col end
            c._lastRelation=rel
        end
        c.Highlight.Enabled=Config.ESP.ShowHighlight
        local pos,onScreen=Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen or dist>Config.ESP.MaxDistance then
            for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","SnapLine","Text","HeadDot","HpBg","HpFg","HpNum","DistText","LevelTag"}) do c[k].Visible=false end
            for _,b in ipairs(c._bones) do b.Visible=false end
            continue
        end
        local tV=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3.2,0))
        local bV=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3.2,0))
        local h=math.abs(tV.Y-bV.Y); local w=h*0.5
        local cx=pos.X; local lx=cx-w/2; local rx=cx+w/2
        if Config.ESP.ShowBox then
            c.BoxT.From=Vector2.new(lx,tV.Y); c.BoxT.To=Vector2.new(rx,tV.Y); c.BoxT.Visible=true
            c.BoxB.From=Vector2.new(lx,bV.Y); c.BoxB.To=Vector2.new(rx,bV.Y); c.BoxB.Visible=true
            c.BoxL.From=Vector2.new(lx,tV.Y); c.BoxL.To=Vector2.new(lx,bV.Y); c.BoxL.Visible=true
            c.BoxR.From=Vector2.new(rx,tV.Y); c.BoxR.To=Vector2.new(rx,bV.Y); c.BoxR.Visible=true
        else c.BoxT.Visible=false; c.BoxB.Visible=false; c.BoxL.Visible=false; c.BoxR.Visible=false end
        if Config.ESP.ShowSnapLine then
            c.SnapLine.From=Vector2.new(vp.X/2,vp.Y); c.SnapLine.To=Vector2.new(cx,bV.Y); c.SnapLine.Visible=true
        else c.SnapLine.Visible=false end
        if Config.ESP.ShowName then c.Text.Text=player.Name; c.Text.Position=Vector2.new(cx,tV.Y-17); c.Text.Visible=true else c.Text.Visible=false end
        if Config.ESP.ShowDistance then c.DistText.Text=string.format("[%.0fm]",dist); c.DistText.Position=Vector2.new(cx,bV.Y+3); c.DistText.Visible=true else c.DistText.Visible=false end
        if Config.ESP.ShowHeadDot and head then
            local hp2,hOn=Camera:WorldToViewportPoint(head.Position)
            c.HeadDot.Position=Vector2.new(hp2.X,hp2.Y); c.HeadDot.Visible=hOn
        else c.HeadDot.Visible=false end
        if Config.ESP.ShowHealth then
            local hp=hum.Health/math.max(hum.MaxHealth,1); local bx=lx-6
            c.HpBg.From=Vector2.new(bx,tV.Y); c.HpBg.To=Vector2.new(bx,bV.Y); c.HpBg.Visible=true
            c.HpFg.From=Vector2.new(bx,bV.Y); c.HpFg.To=Vector2.new(bx,bV.Y-h*hp)
            c.HpFg.Color=Color3.new(1-hp,hp,0); c.HpFg.Visible=true
            if Config.ESP.ShowHealthNum then
                c.HpNum.Text=string.format("%d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth))
                c.HpNum.Position=Vector2.new(bx-2,tV.Y+(h/2)-5); c.HpNum.Visible=true
            else c.HpNum.Visible=false end
        else c.HpBg.Visible=false; c.HpFg.Visible=false; c.HpNum.Visible=false end
        if Config.ESP.ShowLevelTag then
            local ls=player:FindFirstChild("leaderstats")
            local lv=ls and(ls:FindFirstChild("Level") or ls:FindFirstChild("Lvl") or ls:FindFirstChild("LV"))
            if lv then c.LevelTag.Text="Lv."..tostring(lv.Value); c.LevelTag.Position=Vector2.new(cx,tV.Y-28); c.LevelTag.Visible=true
            else c.LevelTag.Visible=false end
        else c.LevelTag.Visible=false end
        if Config.ESP.ShowSkeleton then
            for i,pair in ipairs(BONES) do
                local b=c._bones[i]
                local p1=char:FindFirstChild(pair[1]); local p2=char:FindFirstChild(pair[2])
                if p1 and p2 then
                    local s1,o1=Camera:WorldToViewportPoint(p1.Position)
                    local s2,o2=Camera:WorldToViewportPoint(p2.Position)
                    if o1 and o2 then b.From=Vector2.new(s1.X,s1.Y); b.To=Vector2.new(s2.X,s2.Y); b.Visible=true else b.Visible=false end
                else b.Visible=false end
            end
        else for _,b in ipairs(c._bones) do b.Visible=false end end
    end
end))

-- ============================================================================
-- [10] AIMBOT
-- ============================================================================
local FOVCircle=Drawing.new("Circle")
FOVCircle.Radius=Config.Aimbot.FOVRadius; FOVCircle.Visible=false
FOVCircle.Color=Color3.fromRGB(255,255,255); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false
getgenv().Nexus_FOVCircle=FOVCircle
Core:Add(function() pcall(function() FOVCircle:Remove() end); getgenv().Nexus_FOVCircle=nil end)

local _hasTarget=false

local function GetBestTarget()
    local best,bestScore=nil,math.huge
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and GetRelation(pl)=="Team" then continue end
        local char=pl.Character
        local head=char and char:FindFirstChild("Head")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not(head and hum and hrp) then continue end
        if Config.Aimbot.AliveCheck and hum.Health<=0 then continue end
        local predPos=PredictPos(hrp,head)
        local sp,onScreen=Camera:WorldToViewportPoint(predPos)
        if not onScreen then continue end
        local screenDist=(Vector2.new(sp.X,sp.Y)-center).Magnitude
        if screenDist>=Config.Aimbot.FOVRadius then continue end
        if Config.Aimbot.WallCheck and not CheckLOS(predPos,char) then continue end
        local score
        if Config.Aimbot.Priority=="LowestHP" then score=hum.Health
        elseif Config.Aimbot.Priority=="Nearest" then
            score=myHRP and (myHRP.Position-hrp.Position).Magnitude or screenDist
        else score=screenDist end
        if score<bestScore then bestScore=score; best={part=head,hrp=hrp,char=char,player=pl} end
    end
    return best
end

local _lastTrig=0
Core:Add(RunService.RenderStepped:Connect(function()
    if FOVCircle.Visible then
        FOVCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        FOVCircle.Radius=Config.Aimbot.FOVRadius
    end
    local result=GetBestTarget(); _hasTarget=result~=nil
    if Config.Aimbot.Enabled and result then
        local cp=Camera.CFrame.Position; local tp=PredictPos(result.hrp,result.part)
        if (cp-tp).Magnitude>0.1 then Camera.CFrame=Camera.CFrame:Lerp(CFrame.lookAt(cp,tp),Config.Aimbot.Smoothness) end
    end
    if Config.Aimbot.SilentAim and result and not Config.Aimbot.Enabled then
        local cp=Camera.CFrame.Position; local tp=PredictPos(result.hrp,result.part)
        if (cp-tp).Magnitude>0.1 then
            local orig=Camera.CFrame; Camera.CFrame=CFrame.lookAt(cp,tp)
            task.defer(function() pcall(function() Camera.CFrame=orig end) end)
        end
    end
    if Config.Aimbot.Triggerbot and result then
        local now=tick()
        if now-_lastTrig>=Config.Aimbot.TriggerDelay then
            _lastTrig=now
            local ctr=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            local sp=Camera:WorldToViewportPoint(result.part.Position)
            if (Vector2.new(sp.X,sp.Y)-ctr).Magnitude<25 then pcall(function() mouse1click() end) end
        end
    end
end))

local _killAuraConn
local function StartKillAura()
    if _killAuraConn then _killAuraConn:Disconnect(); _killAuraConn=nil end
    _killAuraConn=RunService.Heartbeat:Connect(function()
        if not Config.Aimbot.KillAura then _killAuraConn:Disconnect(); _killAuraConn=nil; return end
        local mh=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not mh then return end
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl==LocalPlayer then continue end
            if Config.Aimbot.TeamCheck and GetRelation(pl)=="Team" then continue end
            local hr=pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
            local hm=pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
            if not(hr and hm and hm.Health>0) then continue end
            if (mh.Position-hr.Position).Magnitude<=Config.Aimbot.KillAuraRadius then pcall(function() mouse1click() end) end
        end
    end)
end
Core:Add(function() if _killAuraConn then _killAuraConn:Disconnect() end end)

-- ============================================================================
-- [11] CROSSHAIR
-- ============================================================================
local _crossObjs={}
local function RemoveCrosshair()
    for _,o in ipairs(_crossObjs) do pcall(function() o:Remove() end) end; _crossObjs={}
end
local function DrawCrosshair()
    RemoveCrosshair(); if not Config.Crosshair.Enabled then return end
    local st=Config.Crosshair.Style; local cx=Camera.ViewportSize.X/2; local cy=Camera.ViewportSize.Y/2
    local sz=Config.Crosshair.Size; local th=Config.Crosshair.Thickness
    local col=_hasTarget and Config.Crosshair.HitColor or Config.Crosshair.Color
    if st=="Dot" then
        local d=Drawing.new("Circle"); d.Position=Vector2.new(cx,cy); d.Radius=th+1; d.Filled=true; d.Color=col; d.Visible=true; d.ZIndex=10; table.insert(_crossObjs,d)
    elseif st=="Cross" then
        local h=Drawing.new("Line"); h.From=Vector2.new(cx-sz,cy); h.To=Vector2.new(cx+sz,cy); h.Thickness=th; h.Color=col; h.Visible=true; h.ZIndex=10; table.insert(_crossObjs,h)
        local v=Drawing.new("Line"); v.From=Vector2.new(cx,cy-sz); v.To=Vector2.new(cx,cy+sz); v.Thickness=th; v.Color=col; v.Visible=true; v.ZIndex=10; table.insert(_crossObjs,v)
    elseif st=="Circle" then
        local c=Drawing.new("Circle"); c.Position=Vector2.new(cx,cy); c.Radius=sz; c.Filled=false; c.Thickness=th; c.NumSides=32; c.Color=col; c.Visible=true; c.ZIndex=10; table.insert(_crossObjs,c)
    end
end
Core:Add(RunService.RenderStepped:Connect(function()
    if not Config.Crosshair.Enabled then return end
    local col=_hasTarget and Config.Crosshair.HitColor or Config.Crosshair.Color
    for _,o in ipairs(_crossObjs) do pcall(function() o.Color=col end) end
end))
Core:Add(function() RemoveCrosshair() end)

-- ============================================================================
-- [12] RADAR
-- ============================================================================
local _ro={bg=nil,border=nil,selfDot=nil,dots={},names={}}
local function InitRadar()
    if _ro.bg then pcall(function() _ro.bg:Remove() end) end
    if _ro.border then pcall(function() _ro.border:Remove() end) end
    if _ro.selfDot then pcall(function() _ro.selfDot:Remove() end) end
    for _,d in ipairs(_ro.dots) do pcall(function() d:Remove() end) end
    for _,n in ipairs(_ro.names) do pcall(function() n:Remove() end) end
    _ro.dots={}; _ro.names={}
    if not Config.Radar.Enabled then return end
    local R=Config.Radar.Radius; local cx=Camera.ViewportSize.X-R-20; local cy=Camera.ViewportSize.Y-R-20
    local bg=Drawing.new("Circle"); bg.Position=Vector2.new(cx,cy); bg.Radius=R; bg.Filled=true; bg.Color=Color3.new(0,0,0); bg.Transparency=0.55; bg.NumSides=32; bg.Visible=true; bg.ZIndex=8; _ro.bg=bg
    local border=Drawing.new("Circle"); border.Position=Vector2.new(cx,cy); border.Radius=R; border.Filled=false; border.Color=CurrentTheme.primary; border.Thickness=1.5; border.NumSides=32; border.Visible=true; border.ZIndex=9; _ro.border=border
    local sd=Drawing.new("Circle"); sd.Position=Vector2.new(cx,cy); sd.Radius=3; sd.Filled=true; sd.Color=Color3.fromRGB(255,255,255); sd.Visible=true; sd.ZIndex=10; _ro.selfDot=sd
end
local _rf=0
Core:Add(RunService.RenderStepped:Connect(function()
    if not Config.Radar.Enabled then return end
    _rf=_rf+1; if _rf%3~=0 then return end
    local mh=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not mh then return end
    local R=Config.Radar.Radius; local sc=Config.Radar.Scale
    local cx=Camera.ViewportSize.X-R-20; local cy=Camera.ViewportSize.Y-R-20
    local mCF=mh.CFrame; local idx=0
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LocalPlayer then continue end
        local hr=pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
        local hm=pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
        if not(hr and hm and hm.Health>0) then continue end
        local rel=mCF:PointToObjectSpace(hr.Position)
        local dx=rel.X*sc; local dz=rel.Z*sc
        local mag=math.sqrt(dx*dx+dz*dz)
        if mag>R-4 then local r=(R-4)/mag; dx=dx*r; dz=dz*r end
        local col=GetRelation(pl)=="Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor
        idx=idx+1
        if not _ro.dots[idx] then
            local d=Drawing.new("Circle"); d.Radius=3; d.Filled=true; d.NumSides=8; d.Visible=true; d.ZIndex=10; _ro.dots[idx]=d
        end
        _ro.dots[idx].Position=Vector2.new(cx+dx,cy+dz); _ro.dots[idx].Color=col; _ro.dots[idx].Visible=true
        if not _ro.names[idx] then
            local n=Drawing.new("Text"); n.Size=8; n.Outline=true; n.Visible=true; n.ZIndex=11; _ro.names[idx]=n
        end
        if Config.Radar.ShowNames then
            _ro.names[idx].Text=pl.Name; _ro.names[idx].Color=col
            _ro.names[idx].Position=Vector2.new(cx+dx+5,cy+dz-5); _ro.names[idx].Visible=true
        else _ro.names[idx].Visible=false end
    end
    for i=idx+1,#_ro.dots do
        _ro.dots[i].Visible=false
        if _ro.names[i] then _ro.names[i].Visible=false end
    end
end))
Core:Add(function()
    if _ro.bg then pcall(function() _ro.bg:Remove() end) end
    if _ro.border then pcall(function() _ro.border:Remove() end) end
    if _ro.selfDot then pcall(function() _ro.selfDot:Remove() end) end
    for _,d in ipairs(_ro.dots) do pcall(function() d:Remove() end) end
    for _,n in ipairs(_ro.names) do pcall(function() n:Remove() end) end
end)

-- ============================================================================
-- [13] FPS COUNTER
-- ============================================================================
local _fpsDraw=Drawing.new("Text")
_fpsDraw.Size=13; _fpsDraw.Center=true; _fpsDraw.Outline=true; _fpsDraw.Visible=false; _fpsDraw.ZIndex=11
Core:Add(function() pcall(function() _fpsDraw:Remove() end) end)
local _fa,_fc,_fd=0,0,0
Core:Add(RunService.RenderStepped:Connect(function(dt)
    if not Config.FPSCounter.Enabled then _fpsDraw.Visible=false; return end
    _fa=_fa+dt; _fc=_fc+1
    if _fa>=0.5 then _fd=math.floor(_fc/_fa); _fa=0; _fc=0 end
    _fpsDraw.Position=Vector2.new(Camera.ViewportSize.X/2,14)
    _fpsDraw.Color=_fd>=50 and Color3.fromRGB(80,255,80) or _fd>=30 and Color3.fromRGB(255,220,50) or Color3.fromRGB(255,60,60)
    _fpsDraw.Text=string.format("FPS: %d",_fd); _fpsDraw.Visible=true
end))

-- ============================================================================
-- [14] SPECTATOR DETECTOR
-- ============================================================================
local _lastSpec={}; local _specT=0
Core:Add(RunService.Heartbeat:Connect(function(dt)
    if not Config.Spectator.Enabled then return end
    _specT=_specT+dt; if _specT<3 then return end; _specT=0
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LocalPlayer then continue end
        local ok,oc=pcall(function() return pl:FindFirstChildOfClass("Camera") end)
        if ok and oc then
            local sub=oc.CameraSubject
            if sub and LocalPlayer.Character and sub:IsDescendantOf(LocalPlayer.Character) then
                if not _lastSpec[pl] then _lastSpec[pl]=true; ShowToast("👁 "..pl.Name.." spectating!",false) end
            else _lastSpec[pl]=nil end
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

Core:Add(RunService.Heartbeat:Connect(function()
    if not Config.Mods.InfStamina then return end
    local char=LocalPlayer.Character; if not char then return end
    for _,v in ipairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name=v.Name:lower()
            if name:find("stamina") or name:find("energy") or name:find("mana") then
                pcall(function() if v.Value<100 then v.Value=v.MaxValue or 100 end end)
            end
        end
    end
end))

local _lastSafePos
Core:Add(RunService.Heartbeat:Connect(function()
    if not Config.Mods.AntiVoid then return end
    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if hrp.Position.Y>-100 then _lastSafePos=hrp.CFrame
    elseif _lastSafePos then hrp.CFrame=_lastSafePos; ShowToast("Anti Void!",true) end
end))

local _bhConn
local function SetBunnyHop(on)
    if _bhConn then _bhConn:Disconnect(); _bhConn=nil end
    if on then
        _bhConn=RunService.Stepped:Connect(function()
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState()==Enum.HumanoidStateType.Landed then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end
Core:Add(function() if _bhConn then _bhConn:Disconnect() end end)

local _ijConn
local function SetInfJump(on)
    if _ijConn then _ijConn:Disconnect(); _ijConn=nil end
    if on then
        _ijConn=UserInputService.JumpRequest:Connect(function()
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

local _flyBV,_flyBAV,_flyConn
local flyUp,flyDown=false,false

local function StopFly()
    if _flyConn then _flyConn:Disconnect(); _flyConn=nil end
    if _flyBV then pcall(function() _flyBV:Destroy() end); _flyBV=nil end
    if _flyBAV then pcall(function() _flyBAV:Destroy() end); _flyBAV=nil end
    pcall(function()
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand=false end
    end)
    flyUp=false; flyDown=false
end

local function StartFly()
    StopFly()
    local char=LocalPlayer.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bv.Velocity=Vector3.zero; bv.Parent=hrp; _flyBV=bv
    local bav=Instance.new("BodyAngularVelocity"); bav.MaxTorque=Vector3.new(math.huge,math.huge,math.huge); bav.AngularVelocity=Vector3.zero; bav.Parent=hrp; _flyBAV=bav
    local jt=0
    _flyConn=RunService.RenderStepped:Connect(function(dt)
        local r=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not(r and h) then StopFly(); return end
        local spd=Config.Mods.FlySpeed; local fwd=Camera.CFrame.LookVector*Vector3.new(1,0,1)
        local vel=fwd.Magnitude>0 and fwd.Unit*spd or Vector3.zero
        if flyUp then vel=vel+Vector3.new(0,spd,0) end
        if flyDown then vel=vel-Vector3.new(0,spd,0) end
        bv.Velocity=vel; jt=jt+dt
        if jt>=0.4 then jt=0; pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end)
end

local _origL={}
local function SetFullBright(on)
    if on then
        _origL={ClockTime=Lighting.ClockTime,Brightness=Lighting.Brightness,GlobalShadows=Lighting.GlobalShadows,FogEnd=Lighting.FogEnd,Ambient=Lighting.Ambient}
        Lighting.ClockTime=14; Lighting.Brightness=2; Lighting.GlobalShadows=false; Lighting.FogEnd=9e9; Lighting.Ambient=Color3.fromRGB(178,178,178)
    else for k,v in pairs(_origL) do pcall(function() Lighting[k]=v end) end end
end

local _aafkConn
local function SetAntiAFK(on)
    if _aafkConn then _aafkConn:Disconnect(); _aafkConn=nil end
    if on then
        local ok,vu=pcall(function() return game:GetService("VirtualUser") end)
        if ok and vu then _aafkConn=LocalPlayer.Idled:Connect(function() pcall(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end) end) end
    end
end

local _fpOrig={}; local _fpOrigL={}
local _fxL={"BlurEffect","DepthOfFieldEffect","SunRaysEffect","BloomEffect","ColorCorrectionEffect"}
local function SetFPSBoost(on)
    if on then
        _fpOrigL={Technology=Lighting.Technology,GlobalShadows=Lighting.GlobalShadows}
        pcall(function() Lighting.Technology=Enum.Technology.Compatibility; Lighting.GlobalShadows=false end)
        pcall(function() settings().Rendering.QualityLevel=Enum.SavedQualitySetting.Level05 end)
        _fpOrig={}
        local function pe(p) for _,c in ipairs(p:GetChildren()) do for _,ec in ipairs(_fxL) do if c:IsA(ec) and c.Enabled then table.insert(_fpOrig,c); pcall(function() c.Enabled=false end) end end end end
        pe(Lighting); pe(Camera)
    else
        for _,e in ipairs(_fpOrig) do pcall(function() e.Enabled=true end) end; _fpOrig={}
        for k,v in pairs(_fpOrigL) do pcall(function() Lighting[k]=v end) end
        pcall(function() settings().Rendering.QualityLevel=Enum.SavedQualitySetting.Automatic end)
    end
end

local _slConn
local function StopSpeedLoop()
    if _slConn then _slConn:Disconnect(); _slConn=nil end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed=16 end
end
local function StartSpeedLoop()
    StopSpeedLoop()
    local ts=SpeedTiers[Config.Mods.SpeedTier] or 60
    _slConn=RunService.Heartbeat:Connect(function()
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
    if Config.Mods.Speed    then StartSpeedLoop()    end
    if Config.Mods.InfJump  then SetInfJump(true)    end
    if Config.Mods.Fly      then StartFly()           end
    if Config.Mods.BunnyHop then SetBunnyHop(true)   end
    SyncCamera()
end))

Core:Add(LocalPlayer.OnTeleport:Connect(function(state)
    if state==Enum.TeleportState.Failed and Config.Mods.AutoRejoin then
        ShowToast("Reconnecting...",true); task.wait(3)
        pcall(function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end)
    end
end))

-- ============================================================================
-- [16] RPG MODULE — BLINK ATTACK OTOMATIS v2
-- ============================================================================

--[[
    BLINK ATTACK OTOMATIS:
    Loop Heartbeat setiap BlinkInterval detik
    1. Cari monster terdekat dalam BlinkRadius
    2. Arahkan kamera ke monster (agar serangan kena)
    3. Teleport ke monster
    4. Arahkan kamera lagi setelah teleport
    5. Serang (mouse1click)
    6. Tunggu sebentar
    7. Teleport balik ke posisi asal
    8. Arahkan kamera ke monster dari posisi asal
    9. Serang lagi
    Ulangi setiap interval
]]
local _blinkLoopConn
local _blinkOrigin=nil

local function StartBlinkLoop()
    if _blinkLoopConn then _blinkLoopConn:Disconnect(); _blinkLoopConn=nil end
    _blinkOrigin=nil
    local t=0
    _blinkLoopConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.RPG.BlinkAttack then
            -- Pastikan kembali ke posisi asal jika masih blink
            if _blinkOrigin then
                local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame=_blinkOrigin end
                _blinkOrigin=nil
            end
            _blinkLoopConn:Disconnect(); _blinkLoopConn=nil; return
        end
        t=t+dt
        if t<Config.RPG.BlinkInterval then return end
        t=0
        local char=LocalPlayer.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        -- Jangan blink jika sedang dalam proses blink sebelumnya
        if _blinkOrigin then return end
        task.spawn(function()
            local target=GetNearestMonster(Config.RPG.BlinkRadius)
            if not target then return end
            local tHRP=target:FindFirstChild("HumanoidRootPart")
            if not tHRP then return end

            -- Simpan posisi asal
            _blinkOrigin=hrp.CFrame

            -- [FIX] Arahkan kamera ke monster SEBELUM teleport
            Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,tHRP.Position)
            task.wait(0.06)

            -- Teleport ke monster
            hrp.CFrame=tHRP.CFrame*CFrame.new(0,0,-3)
            task.wait(0.06)

            -- [FIX] Arahkan kamera lagi setelah teleport
            Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,tHRP.Position)
            task.wait(0.06)

            -- Serangan pertama
            pcall(function() mouse1click() end)
            task.wait(0.18)

            -- Teleport balik ke posisi asal
            if _blinkOrigin then
                hrp.CFrame=_blinkOrigin
                task.wait(0.06)

                -- [FIX] Arahkan kamera ke monster dari posisi asal
                -- Ini memastikan serangan kedua juga mengenai target
                if tHRP and tHRP.Parent then
                    Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,tHRP.Position)
                    task.wait(0.06)
                    -- Serangan kedua
                    pcall(function() mouse1click() end)
                end

                _blinkOrigin=nil
            end
        end)
    end)
end

Core:Add(function()
    if _blinkLoopConn then _blinkLoopConn:Disconnect() end
    -- Kembalikan ke posisi asal saat cleanup
    if _blinkOrigin then
        local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.CFrame=_blinkOrigin end) end
        _blinkOrigin=nil
    end
end)

-- Auto Farm
local _farmConn
local function StartAutoFarm()
    if _farmConn then _farmConn:Disconnect(); _farmConn=nil end
    local t=0
    _farmConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.RPG.AutoFarm then _farmConn:Disconnect(); _farmConn=nil; return end
        t=t+dt; if t<0.25 then return end; t=0
        task.spawn(function()
            local target=GetNearestMonster(500); if not target then return end
            local tHRP=target:FindFirstChild("HumanoidRootPart")
            local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not(tHRP and myHRP) then return end
            myHRP.CFrame=tHRP.CFrame*CFrame.new(0,0,-4)
            task.wait(0.05)
            Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,tHRP.Position)
            task.wait(0.05)
            pcall(function() mouse1click() end)
        end)
    end)
end
Core:Add(function() if _farmConn then _farmConn:Disconnect() end end)

-- Auto Collect
local _collectConn
local function StartAutoCollect()
    if _collectConn then _collectConn:Disconnect(); _collectConn=nil end
    local t=0
    _collectConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.RPG.AutoCollect then _collectConn:Disconnect(); _collectConn=nil; return end
        t=t+dt; if t<1 then return end; t=0
        local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name=obj.Name:lower()
                if name:find("drop") or name:find("loot") or name:find("item") or name:find("coin") or name:find("gem") then
                    if (obj.Position-myHRP.Position).Magnitude<=Config.RPG.CollectRadius then
                        myHRP.CFrame=CFrame.new(obj.Position+Vector3.new(0,3,0))
                        task.wait(0.1)
                        pcall(function() firetouchinterest(myHRP,obj,0) end)
                    end
                end
            end
        end
    end)
end
Core:Add(function() if _collectConn then _collectConn:Disconnect() end end)

-- Auto Quest
local _questConn
local function StartAutoQuest()
    if _questConn then _questConn:Disconnect(); _questConn=nil end
    local t=0
    _questConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.RPG.AutoQuest then _questConn:Disconnect(); _questConn=nil; return end
        t=t+dt; if t<3 then return end; t=0
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local name=obj.Name:lower()
                if name:find("quest") or name:find("npc") or name:find("giver") then
                    local hrp=obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and myHRP and (hrp.Position-myHRP.Position).Magnitude<=30 then
                        pcall(function() firetouchinterest(myHRP,hrp,0) end)
                    end
                end
            end
        end
    end)
end
Core:Add(function() if _questConn then _questConn:Disconnect() end end)

-- Dungeon Helper
local _dungeonConn
local function StartDungeonHelper()
    if _dungeonConn then _dungeonConn:Disconnect(); _dungeonConn=nil end
    local t=0
    _dungeonConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.RPG.DungeonHelper then _dungeonConn:Disconnect(); _dungeonConn=nil; return end
        t=t+dt; if t<2 then return end; t=0
        local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name=obj.Name:lower()
                if name:find("dungeon") or name:find("portal") or name:find("gate") or name:find("door") then
                    if (obj.Position-myHRP.Position).Magnitude<=10 then
                        pcall(function() firetouchinterest(myHRP,obj,0) end)
                        ShowToast("Dungeon detected!",true)
                    end
                end
            end
        end
    end)
end
Core:Add(function() if _dungeonConn then _dungeonConn:Disconnect() end end)

-- ============================================================================
-- [17] COMBAT MODULE
-- ============================================================================
local _comboConn
local function StartAutoCombo()
    if _comboConn then _comboConn:Disconnect(); _comboConn=nil end
    local t=0
    _comboConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.Combat.AutoCombo then _comboConn:Disconnect(); _comboConn=nil; return end
        t=t+dt; if t<Config.Combat.ComboDelay then return end; t=0
        if _hasTarget then pcall(function() mouse1click() end) end
    end)
end
Core:Add(function() if _comboConn then _comboConn:Disconnect() end end)

local _blockConn
local function StartBlockPredict()
    if _blockConn then _blockConn:Disconnect(); _blockConn=nil end
    if not Config.Combat.BlockPredict then return end
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    _blockConn=hum.HealthChanged:Connect(function(health)
        if health<hum.MaxHealth then pcall(function() fireproximityprompt(char) end) end
    end)
end

local _parryConn
local function StartParryTiming()
    if _parryConn then _parryConn:Disconnect(); _parryConn=nil end
    if not Config.Combat.ParryTiming then return end
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    _parryConn=hum.HealthChanged:Connect(function(health)
        if health<hum.MaxHealth then task.wait(0.02); pcall(function() mouse2click() end) end
    end)
end

Core:Add(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Config.Combat.BlockPredict then StartBlockPredict() end
    if Config.Combat.ParryTiming  then StartParryTiming()  end
end))

-- ============================================================================
-- [18] SIMULATOR MODULE
-- ============================================================================
local _autoClickConn
local function StartAutoClick()
    if _autoClickConn then _autoClickConn:Disconnect(); _autoClickConn=nil end
    local t=0
    _autoClickConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.Sim.AutoClick then _autoClickConn:Disconnect(); _autoClickConn=nil; return end
        t=t+dt; if t<Config.Sim.AutoClickDelay then return end; t=0
        pcall(function() mouse1click() end)
    end)
end
Core:Add(function() if _autoClickConn then _autoClickConn:Disconnect() end end)

local _rebirthConn
local function StartAutoRebirth()
    if _rebirthConn then _rebirthConn:Disconnect(); _rebirthConn=nil end
    local t=0
    _rebirthConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.Sim.AutoRebirth then _rebirthConn:Disconnect(); _rebirthConn=nil; return end
        t=t+dt; if t<2 then return end; t=0
        local function scanGui(parent)
            for _,obj in ipairs(parent:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local name=obj.Name:lower()
                    local text=(obj:IsA("TextButton") and obj.Text:lower()) or ""
                    if name:find("rebirth") or text:find("rebirth") or name:find("prestige") or text:find("prestige") then
                        pcall(function() obj.MouseButton1Click:Fire() end)
                        ShowToast("Auto Rebirth!",true)
                    end
                end
            end
        end
        pcall(function() scanGui(LocalPlayer.PlayerGui) end)
    end)
end
Core:Add(function() if _rebirthConn then _rebirthConn:Disconnect() end end)

local _multObjs={}
Core:Add(RunService.RenderStepped:Connect(function()
    if not Config.Sim.MultiplierESP then
        for _,o in ipairs(_multObjs) do pcall(function() o:Remove() end) end; _multObjs={}; return
    end
    for _,o in ipairs(_multObjs) do pcall(function() o:Remove() end) end; _multObjs={}
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    for _,obj in ipairs(Workspace:GetDescendants()) do
        local name=obj.Name:lower()
        if name:find("zone") or name:find("area") or name:find("mult") then
            local part=obj:IsA("BasePart") and obj or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
            if part and (part.Position-myHRP.Position).Magnitude<500 then
                local sp,on=Camera:WorldToViewportPoint(part.Position+Vector3.new(0,4,0))
                if on then
                    local t=Drawing.new("Text"); t.Size=12; t.Center=true; t.Outline=true
                    t.Color=Color3.fromRGB(255,220,50); t.Text="⚡ "..obj.Name
                    t.Position=Vector2.new(sp.X,sp.Y); t.Visible=true; t.ZIndex=7
                    table.insert(_multObjs,t)
                end
            end
        end
    end
end))
Core:Add(function() for _,o in ipairs(_multObjs) do pcall(function() o:Remove() end) end end)

-- ============================================================================
-- [19] WORLD MODULE
-- ============================================================================
local _worldObjs={}; local _worldTimer=0
Core:Add(RunService.RenderStepped:Connect(function(dt)
    if not Config.World.WorldESP then
        for _,o in ipairs(_worldObjs) do pcall(function() o:Remove() end) end; _worldObjs={}; return
    end
    _worldTimer=_worldTimer+dt; if _worldTimer<2 then return end; _worldTimer=0
    for _,o in ipairs(_worldObjs) do pcall(function() o:Remove() end) end; _worldObjs={}
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local keywords={"chest","treasure","boss","shop","spawn","portal","island","coin","gem"}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name=obj.Name:lower()
            for _,kw in ipairs(keywords) do
                if name:find(kw) then
                    local part=obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                    if part and (part.Position-myHRP.Position).Magnitude<2000 then
                        local sp,on=Camera:WorldToViewportPoint(part.Position+Vector3.new(0,4,0))
                        if on then
                            local t=Drawing.new("Text"); t.Size=12; t.Center=true; t.Outline=true
                            t.Color=Color3.fromRGB(255,255,100)
                            t.Text=string.format("📍 %s [%.0fm]",obj.Name,(part.Position-myHRP.Position).Magnitude)
                            t.Position=Vector2.new(sp.X,sp.Y); t.Visible=true; t.ZIndex=7
                            table.insert(_worldObjs,t)
                        end
                    end
                    break
                end
            end
        end
    end
end))
Core:Add(function() for _,o in ipairs(_worldObjs) do pcall(function() o:Remove() end) end end)

local _inSafeZone=false; local _safeTimer=0
Core:Add(RunService.Heartbeat:Connect(function(dt)
    if not Config.World.SafeZoneDetect then return end
    _safeTimer=_safeTimer+dt; if _safeTimer<2 then return end; _safeTimer=0
    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local isSafe=false
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name=obj.Name:lower()
            if name:find("safe") or name:find("lobby") or name:find("spawn") or name:find("town") then
                if (obj.Position-hrp.Position).Magnitude<50 then isSafe=true; break end
            end
        end
    end
    if isSafe~=_inSafeZone then _inSafeZone=isSafe; ShowToast(isSafe and "✅ Safe Zone" or "⚠️ Danger Zone",isSafe) end
end))

local _lastWeather=""; local _weatherTimer=0
Core:Add(RunService.Heartbeat:Connect(function(dt)
    if not Config.World.WeatherAlert then return end
    _weatherTimer=_weatherTimer+dt; if _weatherTimer<5 then return end; _weatherTimer=0
    local weather=Lighting.FogEnd<1000 and "🌫️ Foggy" or (Lighting.ClockTime<6 or Lighting.ClockTime>20) and "🌙 Night" or Lighting.Brightness>3 and "☀️ Bright" or "🌤️ Day"
    if weather~=_lastWeather then _lastWeather=weather; ShowToast("Weather: "..weather,true) end
end))

-- ============================================================================
-- [20] QoL
-- ============================================================================
local function TeleportToPlayer(name)
    local target
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl.Name:lower():find(name:lower()) then target=pl; break end
    end
    if not target then ShowToast("Player tidak ditemukan",false); return end
    local tHRP=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if tHRP and myHRP then myHRP.CFrame=tHRP.CFrame*CFrame.new(0,0,-4); ShowToast("Teleport → "..target.Name,true) end
end

local function SendChat(msg)
    local bypassed=msg
    if Config.Chat.Bypass then
        bypassed=""
        for i=1,#msg do bypassed=bypassed..msg:sub(i,i)..string.char(8203) end
    end
    pcall(function()
        game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            :FindFirstChild("SayMessageRequest"):FireServer(bypassed,"All")
    end)
end

local function SetUndetectedMode(on)
    Config.UI.UndetectedMode=on
    for _,c in pairs(ESPCache) do
        for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","SnapLine","Text","HeadDot","HpBg","HpFg","HpNum","DistText","LevelTag"}) do
            pcall(function() c[k].Visible=not on end)
        end
        c.Highlight.Enabled=not on
    end
    _fpsDraw.Visible=not on; FOVCircle.Visible=not on
    local ui=SafeGUI:FindFirstChild("Nexus_UI")
    if ui then ui.Enabled=not on end
    ShowToast(on and "Undetected ON" or "Undetected OFF",not on)
end

-- ============================================================================
-- [21] UI MODULE
-- ============================================================================
local UI={_tabPages={},_themeRefs={}}

local function ApplyTheme(name)
    local theme=Themes[name]; if not theme then return end
    CurrentTheme=theme; Config.UI.Theme=name
    for _,ref in ipairs(UI._themeRefs) do
        pcall(function()
            if ref.type=="stroke" then ref.obj.Color=theme.primary
            elseif ref.type=="topbar" then ref.obj.BackgroundColor3=theme.topbar
            elseif ref.type=="scrollbar" then ref.obj.ScrollBarImageColor3=theme.primary end
        end)
    end
    if _ro.border then _ro.border.Color=theme.primary end
end

function UI:Build()
    local Screen=Instance.new("ScreenGui")
    Screen.Name="Nexus_UI"; Screen.ResetOnSpawn=false; Screen.DisplayOrder=999; Screen.Parent=SafeGUI
    Core:Add(Screen); self.Screen=Screen

    local Wrapper=Instance.new("Frame",Screen)
    Wrapper.Name="Wrapper"; Wrapper.Size=UDim2.new(0,262,0,450); Wrapper.Position=UDim2.new(0.04,0,0.06,0)
    Wrapper.BackgroundTransparency=1
    Instance.new("UICorner",Wrapper).CornerRadius=UDim.new(0,12)
    local WStroke=Instance.new("UIStroke",Wrapper); WStroke.Color=CurrentTheme.primary; WStroke.Thickness=1.5
    table.insert(self._themeRefs,{type="stroke",obj=WStroke})
    self.Wrapper=Wrapper

    local Main=Instance.new("Frame",Wrapper)
    Main.Name="Main"; Main.Size=UDim2.new(1,0,1,0)
    Main.BackgroundColor3=CurrentTheme.bg; Main.BackgroundTransparency=1-Config.UI.Opacity
    Main.BorderSizePixel=0; Main.ClipsDescendants=true
    Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12)
    self.Main=Main

    local TopBar=Instance.new("Frame",Main)
    TopBar.Size=UDim2.new(1,0,0,36); TopBar.BackgroundColor3=CurrentTheme.topbar; TopBar.BorderSizePixel=0
    table.insert(self._themeRefs,{type="topbar",obj=TopBar})

    local TL=Instance.new("TextLabel",TopBar)
    TL.Size=UDim2.new(1,-96,1,0); TL.Position=UDim2.new(0,11,0,0); TL.BackgroundTransparency=1
    TL.Text="⚡  NEXUS  v1.6"; TL.TextColor3=Color3.fromRGB(255,255,255)
    TL.Font=Enum.Font.GothamBold; TL.TextSize=13; TL.TextXAlignment=Enum.TextXAlignment.Left

    local HideBtn=Instance.new("TextButton",TopBar)
    HideBtn.Size=UDim2.new(0,24,0,22); HideBtn.Position=UDim2.new(1,-60,0.5,-11)
    HideBtn.BackgroundColor3=Color3.fromRGB(30,60,120); HideBtn.Text="👁"; HideBtn.TextColor3=Color3.fromRGB(200,220,255)
    HideBtn.Font=Enum.Font.GothamBold; HideBtn.TextSize=11; HideBtn.BorderSizePixel=0
    Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(0,5)

    local MinBtn=Instance.new("TextButton",TopBar)
    MinBtn.Size=UDim2.new(0,24,0,22); MinBtn.Position=UDim2.new(1,-32,0.5,-11)
    MinBtn.BackgroundColor3=Color3.fromRGB(35,35,52); MinBtn.Text="—"; MinBtn.TextColor3=Color3.fromRGB(200,200,200)
    MinBtn.Font=Enum.Font.GothamBold; MinBtn.TextSize=12; MinBtn.BorderSizePixel=0
    Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,5)

    -- [FIX 1] TabBar → ScrollingFrame horizontal (geser kiri/kanan)
    local TabBar=Instance.new("ScrollingFrame",Main)
    TabBar.Size=UDim2.new(1,0,0,28); TabBar.Position=UDim2.new(0,0,0,36)
    TabBar.BackgroundColor3=Color3.fromRGB(18,18,27); TabBar.BorderSizePixel=0
    TabBar.ScrollBarThickness=2; TabBar.ScrollBarImageColor3=CurrentTheme.primary
    TabBar.CanvasSize=UDim2.new(0,0,0,0)
    TabBar.ScrollingDirection=Enum.ScrollingDirection.X
    table.insert(self._themeRefs,{type="scrollbar",obj=TabBar})
    local TLayout=Instance.new("UIListLayout",TabBar)
    TLayout.FillDirection=Enum.FillDirection.Horizontal; TLayout.Padding=UDim.new(0,2)
    TLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    local tabPad=Instance.new("UIPadding",TabBar)
    tabPad.PaddingLeft=UDim.new(0,4); tabPad.PaddingRight=UDim.new(0,4)
    -- Auto resize canvas TabBar
    TLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabBar.CanvasSize=UDim2.new(0,TLayout.AbsoluteContentSize.X+8,0,0)
    end)
    self.TabBar=TabBar

    local Content=Instance.new("Frame",Main)
    Content.Name="Content"; Content.Size=UDim2.new(1,0,1,-64); Content.Position=UDim2.new(0,0,0,64)
    Content.BackgroundTransparency=1; self.Content=Content

    local Pill=Instance.new("TextButton",Screen)
    Pill.Size=UDim2.new(0,90,0,24); Pill.Position=Wrapper.Position
    Pill.BackgroundColor3=Color3.fromRGB(20,60,160); Pill.Text="⚡ NEXUS"
    Pill.TextColor3=Color3.fromRGB(255,255,255); Pill.Font=Enum.Font.GothamBold
    Pill.TextSize=11; Pill.BorderSizePixel=0; Pill.Visible=false
    Instance.new("UICorner",Pill).CornerRadius=UDim.new(0,12)
    Instance.new("UIStroke",Pill).Color=CurrentTheme.primary
    self.Pill=Pill

    Core:Add(HideBtn.MouseButton1Click:Connect(function()
        Pill.Position=UDim2.new(Wrapper.Position.X.Scale,Wrapper.Position.X.Offset,Wrapper.Position.Y.Scale,Wrapper.Position.Y.Offset)
        Wrapper.Visible=false; Pill.Visible=true
    end))
    Core:Add(Pill.MouseButton1Click:Connect(function()
        Wrapper.Position=Pill.Position; Wrapper.Visible=true; Pill.Visible=false
    end))

    local drag,ds,sp=false,nil,nil
    Core:Add(TopBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=Wrapper.Position
        end
    end))
    Core:Add(UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-ds
            Wrapper.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end))
    Core:Add(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end))

    local mini=false
    Core:Add(MinBtn.MouseButton1Click:Connect(function()
        mini=not mini; Content.Visible=not mini; TabBar.Visible=not mini
        Wrapper.Size=mini and UDim2.new(0,262,0,36) or UDim2.new(0,262,0,450)
        MinBtn.Text=mini and "+" or "—"
    end))
end

function UI:AddTab(name)
    local page=Instance.new("ScrollingFrame",self.Content)
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1
    page.BorderSizePixel=0; page.ScrollBarThickness=4
    page.ScrollBarImageColor3=CurrentTheme.primary
    page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false; page.ScrollingEnabled=true
    table.insert(self._themeRefs,{type="scrollbar",obj=page})

    local layout=Instance.new("UIListLayout",page)
    layout.Padding=UDim.new(0,4); layout.HorizontalAlignment=Enum.HorizontalAlignment.Center

    local pad=Instance.new("UIPadding",page)
    pad.PaddingTop=UDim.new(0,6); pad.PaddingLeft=UDim.new(0,5)
    pad.PaddingRight=UDim.new(0,5); pad.PaddingBottom=UDim.new(0,10)

    Core:Add(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
    end))
    local function refresh()
        task.wait(); page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
    end

    local btn=Instance.new("TextButton",self.TabBar)
    btn.Size=UDim2.new(0,38,0,22); btn.BackgroundColor3=Color3.fromRGB(28,28,40)
    btn.Text=name; btn.TextColor3=Color3.fromRGB(150,150,170)
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=9; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)

    local entry={page=page,btn=btn}; table.insert(self._tabPages,entry)

    local function activate()
        for _,t in ipairs(self._tabPages) do
            t.page.Visible=false; t.btn.BackgroundColor3=Color3.fromRGB(28,28,40); t.btn.TextColor3=Color3.fromRGB(150,150,170)
        end
        page.Visible=true; btn.BackgroundColor3=CurrentTheme.primary; btn.TextColor3=Color3.fromRGB(255,255,255)
        task.defer(refresh)
    end
    Core:Add(btn.MouseButton1Click:Connect(activate))
    if #self._tabPages==1 then activate() end
    return page,refresh
end

function UI:Section(parent,text)
    local f=Instance.new("Frame",parent); f.Size=UDim2.new(1,0,0,16); f.BackgroundTransparency=1
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text="── "..text.." ──"; l.TextColor3=CurrentTheme.primary
    l.Font=Enum.Font.GothamBold; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Center
end

-- [FIX 3] Toggle — state LOKAL, TIDAK panggil SaveConfig otomatis
-- Mencegah satu toggle mempengaruhi toggle lain
function UI:Toggle(parent,label,callback,col)
    local color=col or CurrentTheme.primary
    local state=false  -- state independen per toggle

    local card=Instance.new("Frame",parent)
    card.Size=UDim2.new(1,0,0,26); card.BackgroundColor3=Color3.fromRGB(22,22,33); card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,-48,1,0); lbl.Position=UDim2.new(0,9,0,0); lbl.BackgroundTransparency=1
    lbl.Text=label; lbl.TextColor3=Color3.fromRGB(210,210,215)
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local pill=Instance.new("TextButton",card)
    pill.Size=UDim2.new(0,32,0,15); pill.Position=UDim2.new(1,-40,0.5,-7)
    pill.BackgroundColor3=Color3.fromRGB(38,38,55); pill.Text=""; pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,11,0,11); knob.Position=UDim2.new(0,2,0.5,-5)
    knob.BackgroundColor3=Color3.fromRGB(140,140,160); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local function setVisual(on)
        if on then
            pill.BackgroundColor3=color; knob.Position=UDim2.new(1,-13,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(255,255,255)
        else
            pill.BackgroundColor3=Color3.fromRGB(38,38,55); knob.Position=UDim2.new(0,2,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(140,140,160)
        end
    end

    Core:Add(pill.MouseButton1Click:Connect(function()
        state=not state
        setVisual(state)
        ShowToast(label,state)
        -- [FIX] TIDAK panggil SaveConfig() di sini
        -- Cegah side effect ke toggle lain
        pcall(callback,state)
    end))
end

function UI:ChoiceRow(parent,label,opts,def,cb)
    local w=Instance.new("Frame",parent)
    w.Size=UDim2.new(1,0,0,50); w.BackgroundColor3=Color3.fromRGB(22,22,33); w.BorderSizePixel=0
    Instance.new("UICorner",w).CornerRadius=UDim.new(0,6)
    local l=Instance.new("TextLabel",w)
    l.Size=UDim2.new(1,0,0,17); l.Position=UDim2.new(0,9,0,3); l.BackgroundTransparency=1
    l.Text=label; l.TextColor3=Color3.fromRGB(160,160,180); l.Font=Enum.Font.GothamSemibold
    l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left
    local row=Instance.new("Frame",w)
    row.Size=UDim2.new(1,-12,0,22); row.Position=UDim2.new(0,6,0,22); row.BackgroundTransparency=1
    local rL=Instance.new("UIListLayout",row)
    rL.FillDirection=Enum.FillDirection.Horizontal; rL.Padding=UDim.new(0,3)
    rL.HorizontalAlignment=Enum.HorizontalAlignment.Left; rL.VerticalAlignment=Enum.VerticalAlignment.Center
    local btns={}
    for _,opt in ipairs(opts) do
        local b=Instance.new("TextButton",row)
        b.Size=UDim2.new(0,48,0,19)
        b.BackgroundColor3=opt==def and CurrentTheme.primary or Color3.fromRGB(35,35,52)
        b.Text=opt; b.TextColor3=Color3.fromRGB(220,220,220)
        b.Font=Enum.Font.GothamBold; b.TextSize=9; b.BorderSizePixel=0
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        table.insert(btns,{btn=b,opt=opt})
        Core:Add(b.MouseButton1Click:Connect(function()
            for _,e in ipairs(btns) do
                e.btn.BackgroundColor3=e.opt==opt and CurrentTheme.primary or Color3.fromRGB(35,35,52)
            end
            pcall(cb,opt)
        end))
    end
end

function UI:ActionBtn(parent,label,col,cb)
    local btn=Instance.new("TextButton",parent)
    btn.Size=UDim2.new(1,0,0,28); btn.BackgroundColor3=col or CurrentTheme.primary
    btn.Text=label; btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Font=Enum.Font.GothamBold; btn.TextSize=11; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    Core:Add(btn.MouseButton1Click:Connect(function()
        local oc=btn.BackgroundColor3; btn.BackgroundColor3=Color3.fromRGB(255,255,255)
        task.delay(0.1,function() btn.BackgroundColor3=oc end)
        pcall(cb)
    end))
end

function UI:InputRow(parent,placeholder,btnLabel,col,cb)
    local frame=Instance.new("Frame",parent)
    frame.Size=UDim2.new(1,0,0,30); frame.BackgroundColor3=Color3.fromRGB(22,22,33); frame.BorderSizePixel=0
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,6)
    local input=Instance.new("TextBox",frame)
    input.Size=UDim2.new(1,-70,1,-8); input.Position=UDim2.new(0,8,0,4)
    input.BackgroundTransparency=1; input.PlaceholderText=placeholder
    input.Text=""; input.TextColor3=Color3.fromRGB(220,220,220)
    input.PlaceholderColor3=Color3.fromRGB(100,100,120)
    input.Font=Enum.Font.Gotham; input.TextSize=11
    input.TextXAlignment=Enum.TextXAlignment.Left; input.ClearTextOnFocus=false
    local btn=Instance.new("TextButton",frame)
    btn.Size=UDim2.new(0,58,0,22); btn.Position=UDim2.new(1,-64,0.5,-11)
    btn.BackgroundColor3=col or CurrentTheme.primary
    btn.Text=btnLabel; btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Font=Enum.Font.GothamBold; btn.TextSize=10; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    Core:Add(btn.MouseButton1Click:Connect(function()
        if input.Text~="" then pcall(cb,input.Text); input.Text="" end
    end))
end

function UI:HoldButton(parent,label,onH,onR,col)
    local btn=Instance.new("TextButton",parent)
    btn.Size=UDim2.new(0.47,0,0,28); btn.BackgroundColor3=col or CurrentTheme.primary
    btn.Text=label; btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Font=Enum.Font.GothamBold; btn.TextSize=12; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    Core:Add(btn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pcall(onH) end
    end))
    Core:Add(btn.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then pcall(onR) end
    end))
end

-- FOV Slider helper
local function MakeSlider(parent,labelText,initVal,minVal,maxVal,onChange)
    local fc=Instance.new("Frame",parent)
    fc.Size=UDim2.new(1,0,0,42); fc.BackgroundColor3=Color3.fromRGB(22,22,33); fc.BorderSizePixel=0
    Instance.new("UICorner",fc).CornerRadius=UDim.new(0,6)
    local fl=Instance.new("TextLabel",fc)
    fl.Size=UDim2.new(1,-10,0,18); fl.Position=UDim2.new(0,9,0,3); fl.BackgroundTransparency=1
    fl.Text=labelText..": "..initVal
    fl.TextColor3=Color3.fromRGB(200,200,210); fl.Font=Enum.Font.GothamSemibold; fl.TextSize=11; fl.TextXAlignment=Enum.TextXAlignment.Left
    local tr=Instance.new("Frame",fc)
    tr.Size=UDim2.new(1,-18,0,6); tr.Position=UDim2.new(0,9,0,28)
    tr.BackgroundColor3=Color3.fromRGB(35,35,52); tr.BorderSizePixel=0
    Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local ratio=(initVal-minVal)/(maxVal-minVal)
    local fi=Instance.new("Frame",tr)
    fi.Size=UDim2.new(ratio,0,1,0); fi.BackgroundColor3=CurrentTheme.primary; fi.BorderSizePixel=0
    Instance.new("UICorner",fi).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("TextButton",tr)
    kn.Size=UDim2.new(0,14,0,14); kn.AnchorPoint=Vector2.new(0.5,0.5)
    kn.Position=UDim2.new(ratio,0,0.5,0)
    kn.BackgroundColor3=Color3.fromRGB(255,255,255); kn.Text=""; kn.BorderSizePixel=0
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local ds=false
    Core:Add(kn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true end
    end))
    Core:Add(UserInputService.InputChanged:Connect(function(i)
        if not ds then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local tp=tr.AbsolutePosition; local ts=tr.AbsoluteSize
            local rx=math.clamp((i.Position.X-tp.X)/ts.X,0,1)
            local val=math.floor(minVal+(maxVal-minVal)*rx)
            fi.Size=UDim2.new(rx,0,1,0); kn.Position=UDim2.new(rx,0,0.5,0)
            fl.Text=labelText..": "..val
            pcall(onChange,val)
        end
    end))
    Core:Add(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then ds=false end
    end))
end

-- ============================================================================
-- [22] BOOTSTRAP
-- ============================================================================
UI:Build()

-- ── TAB: ESP ──────────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("ESP")
    UI:Section(p,"MASTER")
    UI:Toggle(p,"Aktifkan ESP",function(v) Config.ESP.Enabled=v end,Color3.fromRGB(30,210,80))
    UI:Section(p,"BODY")
    UI:Toggle(p,"Highlight",function(v) Config.ESP.ShowHighlight=v end,Color3.fromRGB(30,210,80))
    UI:Toggle(p,"Skeleton (Badan)",function(v) Config.ESP.ShowSkeleton=v end,Color3.fromRGB(30,210,80))
    UI:Toggle(p,"Chams (Neon)",function(v)
        Config.ESP.ShowChams=v
        for _,pl in ipairs(Players:GetPlayers()) do if pl~=LocalPlayer then ApplyChams(pl,v) end end
    end,Color3.fromRGB(160,80,255))
    UI:Toggle(p,"Adaptive Opacity",function(v) Config.ESP.AdaptiveOpacity=v end,Color3.fromRGB(120,80,255))
    UI:Toggle(p,"Box ESP",function(v) Config.ESP.ShowBox=v end)
    UI:Toggle(p,"Head Dot",function(v) Config.ESP.ShowHeadDot=v end)
    UI:Toggle(p,"Snap Line",function(v) Config.ESP.ShowSnapLine=v end)
    UI:Section(p,"INFO HUD")
    UI:Toggle(p,"Name Tag",function(v) Config.ESP.ShowName=v end)
    UI:Toggle(p,"Health Bar",function(v) Config.ESP.ShowHealth=v end)
    UI:Toggle(p,"Health Number",function(v) Config.ESP.ShowHealthNum=v end)
    UI:Toggle(p,"Distance Tag",function(v) Config.ESP.ShowDistance=v end)
    UI:Toggle(p,"Level Tag",function(v) Config.ESP.ShowLevelTag=v end,Color3.fromRGB(180,180,255))
    task.defer(r)
end

-- ── TAB: AIMBOT ───────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("Aim")
    UI:Section(p,"SISTEM")
    UI:Toggle(p,"Aktifkan Aimbot",function(v)
        Config.Aimbot.Enabled=v; FOVCircle.Visible=v and Config.Aimbot.FOVVisible
    end,Color3.fromRGB(255,70,70))
    UI:Toggle(p,"Silent Aim",function(v) Config.Aimbot.SilentAim=v end,Color3.fromRGB(255,140,40))
    UI:Toggle(p,"Triggerbot",function(v) Config.Aimbot.Triggerbot=v end,Color3.fromRGB(255,100,100))
    UI:Toggle(p,"Kill Aura",function(v) Config.Aimbot.KillAura=v; if v then StartKillAura() end end,Color3.fromRGB(200,50,50))
    UI:Toggle(p,"No Recoil",function(v) Config.Aimbot.NoRecoil=v end,Color3.fromRGB(255,160,80))
    UI:Section(p,"PRIORITY")
    UI:ChoiceRow(p,"Target Priority",{"FOV","LowestHP","Nearest"},"FOV",function(v) Config.Aimbot.Priority=v end)
    UI:Section(p,"FILTER")
    UI:Toggle(p,"Wall Check",function(v) Config.Aimbot.WallCheck=v end)
    UI:Toggle(p,"Team Check",function(v) Config.Aimbot.TeamCheck=v end)
    UI:Toggle(p,"Alive Check",function(v) Config.Aimbot.AliveCheck=v end)
    UI:Toggle(p,"Prediction",function(v) Config.Aimbot.PredictMovement=v end,Color3.fromRGB(255,160,40))
    UI:Section(p,"FOV")
    UI:Toggle(p,"Tampilkan FOV Circle",function(v)
        Config.Aimbot.FOVVisible=v; FOVCircle.Visible=v and Config.Aimbot.Enabled
    end)
    MakeSlider(p,"FOV Radius",Config.Aimbot.FOVRadius,30,500,function(val)
        Config.Aimbot.FOVRadius=val; FOVCircle.Radius=val
    end)
    task.defer(r)
end

-- ── TAB: PLAYER ───────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("Move")
    UI:Section(p,"SPEED")
    UI:Toggle(p,"Speed Hack",function(v)
        Config.Mods.Speed=v; if v then StartSpeedLoop() else StopSpeedLoop() end
    end,Color3.fromRGB(255,180,30))
    UI:ChoiceRow(p,"Tier",{"Normal","Fast","Turbo","Ultra"},"Fast",function(t)
        Config.Mods.SpeedTier=t; if Config.Mods.Speed then StartSpeedLoop() end
    end)
    UI:Section(p,"MOVEMENT")
    UI:Toggle(p,"Noclip",function(v) Config.Mods.Noclip=v end)
    UI:Toggle(p,"Infinite Jump",function(v) Config.Mods.InfJump=v; SetInfJump(v) end)
    UI:Toggle(p,"Bunny Hop",function(v) Config.Mods.BunnyHop=v; SetBunnyHop(v) end,Color3.fromRGB(200,150,255))
    UI:Toggle(p,"Inf Stamina",function(v) Config.Mods.InfStamina=v end,Color3.fromRGB(100,200,255))
    UI:Toggle(p,"Anti Void",function(v) Config.Mods.AntiVoid=v end,Color3.fromRGB(255,100,50))
    UI:Section(p,"TERBANG")
    UI:Toggle(p,"Aktifkan Terbang",function(v)
        Config.Mods.Fly=v; if v then StartFly() else StopFly() end
    end,Color3.fromRGB(80,160,255))
    local row=Instance.new("Frame",p)
    row.Size=UDim2.new(1,0,0,30); row.BackgroundTransparency=1
    local rL=Instance.new("UIListLayout",row)
    rL.FillDirection=Enum.FillDirection.Horizontal; rL.Padding=UDim.new(0,5)
    rL.HorizontalAlignment=Enum.HorizontalAlignment.Center; rL.VerticalAlignment=Enum.VerticalAlignment.Center
    UI:HoldButton(row,"▲ NAIK",function() flyUp=true end,function() flyUp=false end,Color3.fromRGB(45,110,220))
    UI:HoldButton(row,"▼ TURUN",function() flyDown=true end,function() flyDown=false end,Color3.fromRGB(175,55,55))
    UI:Section(p,"VISUAL")
    UI:Toggle(p,"Full Bright",function(v) Config.Mods.FullBright=v; SetFullBright(v) end)
    task.defer(r)
end

-- ── TAB: RPG ──────────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("RPG")
    UI:Section(p,"AUTO SYSTEMS")
    UI:Toggle(p,"Auto Farm",function(v) Config.RPG.AutoFarm=v; if v then StartAutoFarm() end end,Color3.fromRGB(255,80,80))
    UI:Toggle(p,"Auto Quest",function(v) Config.RPG.AutoQuest=v; if v then StartAutoQuest() end end,Color3.fromRGB(80,200,80))
    UI:Toggle(p,"Auto Collect",function(v) Config.RPG.AutoCollect=v; if v then StartAutoCollect() end end,Color3.fromRGB(255,200,50))
    UI:Toggle(p,"Dungeon Helper",function(v) Config.RPG.DungeonHelper=v; if v then StartDungeonHelper() end end,Color3.fromRGB(200,100,255))

    UI:Section(p,"⚡ BLINK ATTACK (Otomatis)")
    -- Info card
    local ic=Instance.new("Frame",p)
    ic.Size=UDim2.new(1,0,0,52); ic.BackgroundColor3=Color3.fromRGB(14,22,14); ic.BorderSizePixel=0
    Instance.new("UICorner",ic).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",ic).Color=Color3.fromRGB(40,150,40)
    local il=Instance.new("TextLabel",ic)
    il.Size=UDim2.new(1,-14,1,-10); il.Position=UDim2.new(0,7,0,5); il.BackgroundTransparency=1
    il.Text="Otomatis: Blink ke monster → Serang\nTeleport balik → Serang lagi"
    il.TextColor3=Color3.fromRGB(100,220,100); il.Font=Enum.Font.Gotham
    il.TextSize=10; il.TextXAlignment=Enum.TextXAlignment.Left
    il.TextYAlignment=Enum.TextYAlignment.Top; il.TextWrapped=true

    UI:Toggle(p,"Aktifkan Blink Attack",function(v)
        Config.RPG.BlinkAttack=v
        if v then StartBlinkLoop() end
    end,Color3.fromRGB(0,200,255))

    MakeSlider(p,"Radius Blink (m)",Config.RPG.BlinkRadius,50,1000,function(val)
        Config.RPG.BlinkRadius=val
    end)
    MakeSlider(p,"Interval Blink (x10 detik)",math.floor(Config.RPG.BlinkInterval*10),3,20,function(val)
        Config.RPG.BlinkInterval=val/10
    end)
    task.defer(r)
end

-- ── TAB: FIGHT ────────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("Fight")
    UI:Section(p,"COMBAT")
    UI:Toggle(p,"Auto Combo",function(v) Config.Combat.AutoCombo=v; if v then StartAutoCombo() end end,Color3.fromRGB(255,80,80))
    UI:Toggle(p,"Block Predict",function(v) Config.Combat.BlockPredict=v; StartBlockPredict() end,Color3.fromRGB(40,160,255))
    UI:Toggle(p,"Parry Timing",function(v) Config.Combat.ParryTiming=v; StartParryTiming() end,Color3.fromRGB(255,200,40))
    UI:Section(p,"SIMULATOR")
    UI:Toggle(p,"Auto Click",function(v) Config.Sim.AutoClick=v; if v then StartAutoClick() end end,Color3.fromRGB(255,120,40))
    UI:Toggle(p,"Auto Rebirth",function(v) Config.Sim.AutoRebirth=v; if v then StartAutoRebirth() end end,Color3.fromRGB(200,80,255))
    UI:Toggle(p,"Multiplier ESP",function(v) Config.Sim.MultiplierESP=v end,Color3.fromRGB(255,220,40))
    task.defer(r)
end

-- ── TAB: WORLD ────────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("World")
    UI:Section(p,"WORLD AWARENESS")
    UI:Toggle(p,"World ESP",function(v) Config.World.WorldESP=v end,Color3.fromRGB(255,220,50))
    UI:Toggle(p,"Safe Zone Detect",function(v) Config.World.SafeZoneDetect=v end,Color3.fromRGB(40,200,100))
    UI:Toggle(p,"Weather Alert",function(v) Config.World.WeatherAlert=v end,Color3.fromRGB(100,180,255))
    UI:Section(p,"TELEPORT")
    UI:InputRow(p,"Nama player...","Go",CurrentTheme.primary,function(name) TeleportToPlayer(name) end)
    UI:Section(p,"CHAT")
    UI:Toggle(p,"Chat Bypass",function(v) Config.Chat.Bypass=v end,Color3.fromRGB(200,160,255))
    UI:InputRow(p,"Tulis pesan...","Kirim",Color3.fromRGB(60,120,60),function(msg) SendChat(msg) end)
    task.defer(r)
end

-- ── TAB: HUD ─────────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("HUD")
    UI:Section(p,"CROSSHAIR")
    UI:Toggle(p,"Aktifkan Crosshair",function(v)
        Config.Crosshair.Enabled=v; if v then DrawCrosshair() else RemoveCrosshair() end
    end,Color3.fromRGB(255,255,100))
    UI:ChoiceRow(p,"Style",{"Dot","Cross","Circle"},"Cross",function(s)
        Config.Crosshair.Style=s; if Config.Crosshair.Enabled then DrawCrosshair() end
    end)
    UI:Section(p,"RADAR")
    UI:Toggle(p,"Aktifkan Radar",function(v) Config.Radar.Enabled=v; InitRadar() end,Color3.fromRGB(80,200,255))
    UI:Toggle(p,"Nama di Radar",function(v) Config.Radar.ShowNames=v end)
    UI:Section(p,"FPS (Atas Tengah)")
    UI:Toggle(p,"FPS Counter",function(v)
        Config.FPSCounter.Enabled=v; if not v then _fpsDraw.Visible=false end
    end,Color3.fromRGB(100,255,100))
    task.defer(r)
end

-- ── TAB: SETTINGS ─────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("⚙️")
    UI:Section(p,"THEME GUI")
    UI:ChoiceRow(p,"Pilih Tema",{"Blue","Red","Green","Purple","Gold"},"Blue",function(t)
        ApplyTheme(t); ShowToast("Theme: "..t,true)
    end)
    UI:Section(p,"OPACITY GUI")
    MakeSlider(p,"Opacity",math.floor(Config.UI.Opacity*100),20,100,function(val)
        Config.UI.Opacity=val/100
        if UI.Main then UI.Main.BackgroundTransparency=1-(val/100) end
    end)
    UI:Section(p,"UTILITY")
    UI:Toggle(p,"Anti AFK",function(v) Config.Mods.AntiAFK=v; SetAntiAFK(v) end)
    UI:Toggle(p,"FPS Booster",function(v) Config.Mods.FPSBoost=v; SetFPSBoost(v) end,Color3.fromRGB(255,210,40))
    UI:Toggle(p,"Auto Rejoin",function(v) Config.Mods.AutoRejoin=v end,Color3.fromRGB(255,120,40))
    UI:Toggle(p,"Spectator Detect",function(v) Config.Spectator.Enabled=v end,Color3.fromRGB(200,100,255))
    UI:Toggle(p,"Undetected Mode",function(v) SetUndetectedMode(v) end,Color3.fromRGB(80,80,80))
    UI:Section(p,"SERVER INFO")
    UI:ActionBtn(p,"📊  Info Server",Color3.fromRGB(40,80,150),function()
        ShowToast(string.format("Players: %d | Place: %d",#Players:GetPlayers(),game.PlaceId),true)
    end)
    UI:Section(p,"CONFIG")
    UI:ActionBtn(p,"💾  Simpan Config",Color3.fromRGB(30,70,160),function()
        SaveConfig(); ShowToast("Config disimpan!",true)
    end)
    UI:ActionBtn(p,"📂  Muat Config",Color3.fromRGB(25,55,25),function()
        LoadConfig(); ShowToast("Config dimuat!",true)
    end)
    task.defer(r)
end

-- Init
DrawCrosshair()
InitRadar()
ApplyTheme(Config.UI.Theme)

-- ============================================================================
print("✅ NEXUS v1.6 — Phenomenon Edition (Fixed)")
print("🔧 Fix 1: Tab geser kiri/kanan")
print("🔧 Fix 2: Blink Attack otomatis + kamera akurat")
print("🔧 Fix 3: Toggle independen — tidak saling aktifkan")
-- ============================================================================
