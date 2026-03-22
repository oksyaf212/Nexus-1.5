--[[
    ============================================================================
    PROJECT   : NEXUS — Fortline Suite (Fixed)
    GAME      : FORTLINE (Deathmatch·Ranked·No Rules)
    PLATFORM  : Delta Executor Android
    AUTHOR    : Claude Sonnet 4.6
    FITUR:
    ├── Aimbot (kamera lock ke kepala)
    ├── Triggerbot (auto tembak saat musuh di crosshair)
    ├── Silent Aim (hook WeaponFired)
    ├── Rapid Fire (spam WeaponActivated)
    ├── Auto Reload (WeaponReloadRequest otomatis)
    ├── No Reload Cancel
    ├── ESP (box/name/hp/distance/snapline)
    ├── Kill Feed Monitor
    ├── Auto Respawn
    └── FPS + Ping otomatis aktif
    ============================================================================
]]

local ENV_KEY="NexusFortline"
if getgenv()[ENV_KEY] then pcall(function() getgenv()[ENV_KEY]:Destroy() end) end

-- ============================================================================
-- [1] SERVICES
-- ============================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

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
-- [3] REMOTE LOADER
-- ============================================================================
local RS=ReplicatedStorage
local Events=RS:FindFirstChild("Events")
local WeaponNet=RS:FindFirstChild("WeaponsSystem")
    and RS.WeaponsSystem:FindFirstChild("Network")

local function GetR(parent,name)
    if not parent then return nil end
    return parent:FindFirstChild(name)
end

local R={}
R.WeaponActivated   = GetR(WeaponNet,"WeaponActivated")
R.WeaponFired       = GetR(WeaponNet,"WeaponFired")
R.WeaponHit         = GetR(WeaponNet,"WeaponHit")
R.WeaponReload      = GetR(WeaponNet,"WeaponReloadRequest")
R.WeaponReloaded    = GetR(WeaponNet,"WeaponReloaded")
R.WeaponReloadCancel= GetR(WeaponNet,"WeaponReloadCanceled")
R.KillRace          = GetR(Events,"KillRaceEvent")
R.SquadKillFeed     = GetR(Events,"SquadKillFeed")
R.QuestEvent        = GetR(Events,"QuestEvent")
R.Respawn           = GetR(Events,"RespawnRequest")
R.XPBoost           = GetR(Events,"XPBoostEvent")
R.DailyReward       = GetR(Events,"DailyRewardEvent")
R.Revenge           = GetR(Events,"RevengeEvent")

-- ============================================================================
-- [4] CONFIG
-- ============================================================================
local Config={
    Aimbot={
        Enabled=false,FOVRadius=150,Smoothness=0.3,
        TargetPart="Head",TeamCheck=true,WallCheck=true,FOVVisible=true,
    },
    Triggerbot={Enabled=false,Threshold=30,Delay=0.05},
    SilentAim={Enabled=false},
    Weapon={RapidFire=false,RapidDelay=0.05,AutoReload=false,NoReload=false},
    ESP={
        Enabled=false,ShowBox=false,ShowName=false,
        ShowHealth=false,ShowDistance=false,ShowSnapLine=false,
        MaxDistance=99999,
        EnemyColor=Color3.fromRGB(255,50,50),
        TeamColor=Color3.fromRGB(30,220,80),
    },
    AutoRespawn=false,
    KillFeedMonitor=false,
}

-- ============================================================================
-- [5] UTILITY
-- ============================================================================
local function ShowToast(msg,isOn)
    pcall(function()
        local existing=SafeGUI:FindFirstChild("FortlineToast")
        if existing then existing:Destroy() end
        local sg=Instance.new("ScreenGui",SafeGUI)
        sg.Name="FortlineToast"; sg.ResetOnSpawn=false; sg.DisplayOrder=9999
        Core:Add(sg)
        local f=Instance.new("Frame",sg)
        f.Size=UDim2.new(0,220,0,28); f.Position=UDim2.new(0.5,-110,0.85,0)
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
        task.delay(2,function()
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

local function GetRelation(player)
    local lt,pt=LocalPlayer.Team,player.Team
    if lt and pt and lt==pt then return "Team" end
    return "Enemy"
end

local RayParams=RaycastParams.new()
RayParams.FilterType=Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater=true

local function CheckLOS(tPos,tChar)
    RayParams.FilterDescendantsInstances={LocalPlayer.Character,tChar}
    local origin=Camera.CFrame.Position
    local result=Workspace:Raycast(origin,tPos-origin,RayParams)
    return not result or result.Instance:IsDescendantOf(tChar)
end

-- ============================================================================
-- [6] AIMBOT
-- ============================================================================
local FOVCircle=Drawing.new("Circle")
FOVCircle.Radius=Config.Aimbot.FOVRadius; FOVCircle.Visible=false
FOVCircle.Color=Color3.fromRGB(255,80,80); FOVCircle.Thickness=1.5
FOVCircle.NumSides=64; FOVCircle.Filled=false
Core:Add(function() pcall(function() FOVCircle:Remove() end) end)

local _hasTarget=false
local _currentTarget=nil

local function GetBestTarget()
    local best,minDist=nil,Config.Aimbot.FOVRadius
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    for _,player in ipairs(Players:GetPlayers()) do
        if player==LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and GetRelation(player)=="Team" then continue end
        local char=player.Character
        local head=char and char:FindFirstChild(Config.Aimbot.TargetPart)
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not(head and hum and hrp and hum.Health>0) then continue end
        local sp,onScreen=Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local dist=(Vector2.new(sp.X,sp.Y)-center).Magnitude
        if dist>=minDist then continue end
        if Config.Aimbot.WallCheck and not CheckLOS(head.Position,char) then continue end
        minDist=dist
        best={part=head,hrp=hrp,char=char,player=player}
    end
    return best
end

-- Silent Aim hook
local _silentHooked=false
local function InitSilentAim()
    if _silentHooked then return end
    _silentHooked=true
    pcall(function()
        local mt=getrawmetatable(game)
        local old=mt.__namecall
        setreadonly(mt,false)
        mt.__namecall=newcclosure(function(self,...)
            local method=getnamecallmethod()
            if Config.SilentAim.Enabled and _currentTarget then
                if method=="FireServer" then
                    local ok,selfName=pcall(function() return self:GetFullName() end)
                    if ok and (selfName:find("WeaponFired") or selfName:find("WeaponHit")) then
                        local args={...}
                        local targetPos=_currentTarget.part.Position
                        for i,arg in ipairs(args) do
                            if typeof(arg)=="Vector3" then
                                args[i]=targetPos; break
                            elseif typeof(arg)=="CFrame" then
                                args[i]=CFrame.new(targetPos); break
                            end
                        end
                        return old(self,table.unpack(args))
                    end
                end
            end
            return old(self,...)
        end)
        setreadonly(mt,true)
        Core:Add(function()
            setreadonly(mt,false)
            mt.__namecall=old
            setreadonly(mt,true)
        end)
    end)
end
pcall(InitSilentAim)

local _lastTrig=0
Core:Add(RunService.RenderStepped:Connect(function()
    if FOVCircle.Visible then
        FOVCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        FOVCircle.Radius=Config.Aimbot.FOVRadius
    end
    local result=GetBestTarget()
    _hasTarget=result~=nil
    _currentTarget=result
    if Config.Aimbot.Enabled and result then
        local cp=Camera.CFrame.Position
        local tp=result.part.Position
        if (cp-tp).Magnitude>0.1 then
            Camera.CFrame=Camera.CFrame:Lerp(
                CFrame.lookAt(cp,tp),
                Config.Aimbot.Smoothness
            )
        end
    end
    if Config.Triggerbot.Enabled and result then
        local now=tick()
        if now-_lastTrig>=Config.Triggerbot.Delay then
            _lastTrig=now
            local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            local sp=Camera:WorldToViewportPoint(result.part.Position)
            local dist=(Vector2.new(sp.X,sp.Y)-center).Magnitude
            if dist<Config.Triggerbot.Threshold then
                pcall(function()
                    if R.WeaponActivated then R.WeaponActivated:FireServer() end
                end)
                pcall(function() mouse1click() end)
            end
        end
    end
end))

-- ============================================================================
-- [7] WEAPON MODS
-- ============================================================================
local _rapidConn
local function StartRapidFire()
    if _rapidConn then _rapidConn:Disconnect(); _rapidConn=nil end
    local t=0
    _rapidConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.Weapon.RapidFire then
            _rapidConn:Disconnect(); _rapidConn=nil; return
        end
        t=t+dt; if t<Config.Weapon.RapidDelay then return end; t=0
        if not _hasTarget then return end
        pcall(function()
            if R.WeaponActivated then R.WeaponActivated:FireServer() end
        end)
    end)
end
Core:Add(function() if _rapidConn then _rapidConn:Disconnect() end end)

local _reloadConn
local function StartAutoReload()
    if _reloadConn then _reloadConn:Disconnect(); _reloadConn=nil end
    _reloadConn=RunService.Heartbeat:Connect(function()
        if not Config.Weapon.AutoReload then return end
        local tool=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if not tool then return end
        local ammo=tool:GetAttribute("Ammo") or tool:GetAttribute("ammo")
            or tool:GetAttribute("Bullets") or tool:GetAttribute("bullets")
        if ammo and ammo<=0 then
            pcall(function()
                if R.WeaponReload then R.WeaponReload:FireServer() end
            end)
        end
    end)
end
Core:Add(function() if _reloadConn then _reloadConn:Disconnect() end end)

local _noReloadConn
local function StartNoReload()
    if _noReloadConn then _noReloadConn:Disconnect(); _noReloadConn=nil end
    _noReloadConn=RunService.Heartbeat:Connect(function()
        if not Config.Weapon.NoReload then
            _noReloadConn:Disconnect(); _noReloadConn=nil; return
        end
        pcall(function()
            if R.WeaponReloadCancel then R.WeaponReloadCancel:FireServer() end
        end)
    end)
end
Core:Add(function() if _noReloadConn then _noReloadConn:Disconnect() end end)

-- ============================================================================
-- [8] ESP
-- ============================================================================
local ESPCache={}

local function CreateESP(player)
    if player==LocalPlayer or ESPCache[player] then return end
    local c={}
    local ec=Config.ESP.EnemyColor
    local function nL(t)
        local l=Drawing.new("Line"); l.Color=ec
        l.Thickness=t; l.Visible=false; l.ZIndex=4; return l
    end
    c.BoxT=nL(1.5); c.BoxB=nL(1.5); c.BoxL=nL(1.5); c.BoxR=nL(1.5)
    local txt=Drawing.new("Text"); txt.Size=12; txt.Center=true
    txt.Outline=true; txt.Color=ec; txt.Visible=false; txt.ZIndex=5; c.Text=txt
    local hpBg=Drawing.new("Line"); hpBg.Thickness=3
    hpBg.Color=Color3.new(0,0,0); hpBg.Visible=false; c.HpBg=hpBg
    local hpFg=Drawing.new("Line"); hpFg.Thickness=1.8
    hpFg.Visible=false; c.HpFg=hpFg
    local dTxt=Drawing.new("Text"); dTxt.Size=10; dTxt.Center=true
    dTxt.Outline=true; dTxt.Color=Color3.fromRGB(255,230,80)
    dTxt.Visible=false; dTxt.ZIndex=5; c.DistText=dTxt
    local snap=Drawing.new("Line"); snap.Color=ec
    snap.Thickness=1; snap.Visible=false; snap.ZIndex=3; c.SnapLine=snap
    local hl=Instance.new("Highlight")
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency=0.7; hl.OutlineTransparency=0.0
    hl.FillColor=ec; hl.OutlineColor=ec
    hl.Enabled=false; hl.Parent=CoreGui
    if player.Character then hl.Adornee=player.Character end
    c._charConn=player.CharacterAdded:Connect(function(ch) hl.Adornee=ch end)
    c.Highlight=hl
    ESPCache[player]=c
end

local function RemoveESP(player)
    local c=ESPCache[player]; if not c then return end
    if c._charConn then pcall(function() c._charConn:Disconnect() end) end
    pcall(function() c.Highlight:Destroy() end)
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","DistText","SnapLine"}) do
        pcall(function() c[k]:Remove() end)
    end
    ESPCache[player]=nil
end

local function HideESP(c)
    c.Highlight.Enabled=false
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","DistText","SnapLine"}) do
        c[k].Visible=false
    end
end

for _,p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Core:Add(Players.PlayerAdded:Connect(CreateESP))
Core:Add(Players.PlayerRemoving:Connect(RemoveESP))
Core:Add(function()
    local s={}; for p in pairs(ESPCache) do table.insert(s,p) end
    for _,p in ipairs(s) do RemoveESP(p) end
end)

Core:Add(RunService.RenderStepped:Connect(function()
    local vp=Camera.ViewportSize
    for player,c in pairs(ESPCache) do
        if not Config.ESP.Enabled then HideESP(c); continue end
        local char=player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not(char and hum and hrp and hum.Health>0) then HideESP(c); continue end
        local dist=(Camera.CFrame.Position-hrp.Position).Magnitude
        if dist>Config.ESP.MaxDistance then HideESP(c); continue end
        local rel=GetRelation(player)
        local col=rel=="Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor
        c.Highlight.FillColor=col; c.Highlight.OutlineColor=col
        c.BoxT.Color=col; c.BoxB.Color=col; c.BoxL.Color=col; c.BoxR.Color=col
        c.Text.Color=col; c.SnapLine.Color=col
        c.Highlight.Enabled=true
        local pos,onScreen=Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","DistText","SnapLine"}) do
                c[k].Visible=false
            end
            continue
        end
        local tV=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3.2,0))
        local bV=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3.2,0))
        local h=math.abs(tV.Y-bV.Y); local w=h*0.45
        local cx=pos.X; local lx=cx-w/2; local rx=cx+w/2
        if Config.ESP.ShowBox then
            c.BoxT.From=Vector2.new(lx,tV.Y); c.BoxT.To=Vector2.new(rx,tV.Y); c.BoxT.Visible=true
            c.BoxB.From=Vector2.new(lx,bV.Y); c.BoxB.To=Vector2.new(rx,bV.Y); c.BoxB.Visible=true
            c.BoxL.From=Vector2.new(lx,tV.Y); c.BoxL.To=Vector2.new(lx,bV.Y); c.BoxL.Visible=true
            c.BoxR.From=Vector2.new(rx,tV.Y); c.BoxR.To=Vector2.new(rx,bV.Y); c.BoxR.Visible=true
        else c.BoxT.Visible=false; c.BoxB.Visible=false; c.BoxL.Visible=false; c.BoxR.Visible=false end
        if Config.ESP.ShowName then
            local tool=char:FindFirstChildOfClass("Tool")
            local wn=tool and " ["..tool.Name.."]" or ""
            c.Text.Text=player.Name..wn
            c.Text.Position=Vector2.new(cx,tV.Y-16); c.Text.Visible=true
        else c.Text.Visible=false end
        if Config.ESP.ShowDistance then
            c.DistText.Text=string.format("[%.0fm]",dist)
            c.DistText.Position=Vector2.new(cx,bV.Y+3); c.DistText.Visible=true
        else c.DistText.Visible=false end
        if Config.ESP.ShowHealth then
            local hp=hum.Health/math.max(hum.MaxHealth,1); local bx=lx-6
            c.HpBg.From=Vector2.new(bx,tV.Y); c.HpBg.To=Vector2.new(bx,bV.Y); c.HpBg.Visible=true
            c.HpFg.From=Vector2.new(bx,bV.Y); c.HpFg.To=Vector2.new(bx,bV.Y-h*hp)
            c.HpFg.Color=Color3.new(1-hp,hp,0); c.HpFg.Visible=true
        else c.HpBg.Visible=false; c.HpFg.Visible=false end
        if Config.ESP.ShowSnapLine then
            c.SnapLine.From=Vector2.new(vp.X/2,vp.Y)
            c.SnapLine.To=Vector2.new(cx,bV.Y); c.SnapLine.Visible=true
        else c.SnapLine.Visible=false end
    end
end))

-- ============================================================================
-- [9] KILL FEED
-- ============================================================================
local _killFeedFrame
local function ShowKillFeed(msg,color)
    pcall(function()
        if not _killFeedFrame or not _killFeedFrame.Parent then
            local sg=Instance.new("ScreenGui",SafeGUI)
            sg.Name="FortlineKillFeed"; sg.ResetOnSpawn=false; sg.DisplayOrder=998
            Core:Add(sg)
            local frame=Instance.new("Frame",sg)
            frame.Name="Frame"; frame.Size=UDim2.new(0,220,0,200)
            frame.Position=UDim2.new(1,-230,0.5,-100)
            frame.BackgroundTransparency=1
            local layout=Instance.new("UIListLayout",frame)
            layout.Padding=UDim.new(0,3)
            layout.VerticalAlignment=Enum.VerticalAlignment.Bottom
            _killFeedFrame=frame
        end
        local entry=Instance.new("Frame",_killFeedFrame)
        entry.Size=UDim2.new(1,0,0,22)
        entry.BackgroundColor3=Color3.fromRGB(0,0,0)
        entry.BackgroundTransparency=0.4; entry.BorderSizePixel=0
        Instance.new("UICorner",entry).CornerRadius=UDim.new(0,5)
        local l=Instance.new("TextLabel",entry)
        l.Size=UDim2.new(1,-8,1,0); l.Position=UDim2.new(0,4,0,0)
        l.BackgroundTransparency=1; l.Text=msg
        l.TextColor3=color or Color3.fromRGB(255,255,255)
        l.Font=Enum.Font.GothamBold; l.TextSize=10
        l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
        task.delay(4,function()
            for i=1,10 do
                pcall(function()
                    entry.BackgroundTransparency=0.4+(i*0.06)
                    l.TextTransparency=i/10
                end)
                task.wait(0.05)
            end
            pcall(function() entry:Destroy() end)
        end)
    end)
end

if R.SquadKillFeed then
    Core:Add(R.SquadKillFeed.OnClientEvent:Connect(function(data)
        if not Config.KillFeedMonitor then return end
        local msg="💀 "..tostring(data)
        if type(data)=="table" then
            local killer=tostring(data.Killer or data.killer or "?")
            local victim=tostring(data.Victim or data.victim or "?")
            local weapon=tostring(data.Weapon or data.weapon or "?")
            msg=string.format("💀 %s → %s [%s]",killer,victim,weapon)
        end
        ShowKillFeed(msg,Color3.fromRGB(255,200,50))
    end))
end

if R.Revenge then
    Core:Add(R.Revenge.OnClientEvent:Connect(function()
        if not Config.KillFeedMonitor then return end
        ShowKillFeed("⚔️ REVENGE!",Color3.fromRGB(255,100,100))
    end))
end

-- Auto Respawn
Core:Add(LocalPlayer.CharacterAdded:Connect(function()
    if Config.AutoRespawn and R.Respawn then
        task.wait(0.5)
        pcall(function() R.Respawn:FireServer() end)
    end
end))

-- ============================================================================
-- [10] FPS + PING — otomatis aktif
-- ============================================================================
local _fpsDraw=Drawing.new("Text")
_fpsDraw.Size=13; _fpsDraw.Center=true
_fpsDraw.Outline=true; _fpsDraw.Visible=true; _fpsDraw.ZIndex=11
Core:Add(function() pcall(function() _fpsDraw:Remove() end) end)

local _fa,_fc,_fd,_ping=0,0,0,0
Core:Add(RunService.RenderStepped:Connect(function(dt)
    _fa=_fa+dt; _fc=_fc+1
    if _fa>=0.5 then _fd=math.floor(_fc/_fa); _fa=0; _fc=0 end
    pcall(function() _ping=math.floor(LocalPlayer.NetworkPing*1000) end)
    local col=(_fd>=50 and _ping<=80) and Color3.fromRGB(80,255,80)
        or (_fd>=30 and _ping<=150) and Color3.fromRGB(255,220,50)
        or Color3.fromRGB(255,60,60)
    _fpsDraw.Color=col
    _fpsDraw.Text=string.format("FPS: %d  |  Ping: %dms",_fd,_ping)
    _fpsDraw.Position=Vector2.new(Camera.ViewportSize.X/2,14)
end))

-- ============================================================================
-- [11] UI
-- ============================================================================
local UI={_tabPages={}}

function UI:Build()
    local Screen=Instance.new("ScreenGui",SafeGUI)
    Screen.Name="FortlineUI"; Screen.ResetOnSpawn=false; Screen.DisplayOrder=999
    Core:Add(Screen)

    local Wrapper=Instance.new("Frame",Screen)
    Wrapper.Size=UDim2.new(0,255,0,420)
    Wrapper.Position=UDim2.new(0.04,0,0.08,0)
    Wrapper.BackgroundTransparency=1
    Instance.new("UICorner",Wrapper).CornerRadius=UDim.new(0,12)
    local WStroke=Instance.new("UIStroke",Wrapper)
    WStroke.Color=Color3.fromRGB(255,60,60)
    WStroke.Thickness=1.5
    self.Wrapper=Wrapper

    local Main=Instance.new("Frame",Wrapper)
    Main.Size=UDim2.new(1,0,1,0)
    Main.BackgroundColor3=Color3.fromRGB(12,8,8)
    Main.BorderSizePixel=0; Main.ClipsDescendants=true
    Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12)
    self.Main=Main

    local TopBar=Instance.new("Frame",Main)
    TopBar.Size=UDim2.new(1,0,0,36)
    TopBar.BackgroundColor3=Color3.fromRGB(20,8,8)
    TopBar.BorderSizePixel=0

    local TL=Instance.new("TextLabel",TopBar)
    TL.Size=UDim2.new(1,-96,1,0); TL.Position=UDim2.new(0,11,0,0)
    TL.BackgroundTransparency=1; TL.Text="🎯  NEXUS  FORTLINE"
    TL.TextColor3=Color3.fromRGB(255,80,80)
    TL.Font=Enum.Font.GothamBold; TL.TextSize=12
    TL.TextXAlignment=Enum.TextXAlignment.Left

    local PanicBtn=Instance.new("TextButton",TopBar)
    PanicBtn.Size=UDim2.new(0,24,0,22); PanicBtn.Position=UDim2.new(1,-90,0.5,-11)
    PanicBtn.BackgroundColor3=Color3.fromRGB(140,20,20); PanicBtn.Text="❌"
    PanicBtn.TextColor3=Color3.fromRGB(255,255,255); PanicBtn.Font=Enum.Font.GothamBold
    PanicBtn.TextSize=11; PanicBtn.BorderSizePixel=0
    Instance.new("UICorner",PanicBtn).CornerRadius=UDim.new(0,5)
    Core:Add(PanicBtn.MouseButton1Click:Connect(function()
        Config.Aimbot.Enabled=false; Config.Triggerbot.Enabled=false
        Config.SilentAim.Enabled=false; Config.Weapon.RapidFire=false
        Config.ESP.Enabled=false; Config.KillFeedMonitor=false
        ShowToast("PANIC — Semua OFF",false)
    end))

    local HideBtn=Instance.new("TextButton",TopBar)
    HideBtn.Size=UDim2.new(0,24,0,22); HideBtn.Position=UDim2.new(1,-62,0.5,-11)
    HideBtn.BackgroundColor3=Color3.fromRGB(80,20,20); HideBtn.Text="👁"
    HideBtn.TextColor3=Color3.fromRGB(255,180,180); HideBtn.Font=Enum.Font.GothamBold
    HideBtn.TextSize=11; HideBtn.BorderSizePixel=0
    Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(0,5)

    local MinBtn=Instance.new("TextButton",TopBar)
    MinBtn.Size=UDim2.new(0,24,0,22); MinBtn.Position=UDim2.new(1,-34,0.5,-11)
    MinBtn.BackgroundColor3=Color3.fromRGB(50,20,20); MinBtn.Text="—"
    MinBtn.TextColor3=Color3.fromRGB(200,200,200); MinBtn.Font=Enum.Font.GothamBold
    MinBtn.TextSize=12; MinBtn.BorderSizePixel=0
    Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,5)

    local TabBar=Instance.new("ScrollingFrame",Main)
    TabBar.Size=UDim2.new(1,0,0,26); TabBar.Position=UDim2.new(0,0,0,36)
    TabBar.BackgroundColor3=Color3.fromRGB(16,6,6); TabBar.BorderSizePixel=0
    TabBar.ScrollBarThickness=2; TabBar.CanvasSize=UDim2.new(0,0,0,0)
    TabBar.ScrollingDirection=Enum.ScrollingDirection.X
    TabBar.ScrollBarImageColor3=Color3.fromRGB(255,60,60)
    local TLayout=Instance.new("UIListLayout",TabBar)
    TLayout.FillDirection=Enum.FillDirection.Horizontal; TLayout.Padding=UDim.new(0,2)
    TLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    local tabPad=Instance.new("UIPadding",TabBar)
    tabPad.PaddingLeft=UDim.new(0,4)
    TLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabBar.CanvasSize=UDim2.new(0,TLayout.AbsoluteContentSize.X+8,0,0)
    end)
    self.TabBar=TabBar

    local Content=Instance.new("Frame",Main)
    Content.Name="Content"; Content.Size=UDim2.new(1,0,1,-62)
    Content.Position=UDim2.new(0,0,0,62); Content.BackgroundTransparency=1
    self.Content=Content

    local Pill=Instance.new("TextButton",Screen)
    Pill.Size=UDim2.new(0,110,0,24); Pill.Position=Wrapper.Position
    Pill.BackgroundColor3=Color3.fromRGB(80,10,10); Pill.Text="🎯 FORTLINE"
    Pill.TextColor3=Color3.fromRGB(255,100,100); Pill.Font=Enum.Font.GothamBold
    Pill.TextSize=10; Pill.BorderSizePixel=0; Pill.Visible=false
    Instance.new("UICorner",Pill).CornerRadius=UDim.new(0,12)
    local pillStroke=Instance.new("UIStroke",Pill)
    pillStroke.Color=Color3.fromRGB(255,60,60)
    pillStroke.Thickness=1
    self.Pill=Pill

    Core:Add(HideBtn.MouseButton1Click:Connect(function()
        Pill.Position=UDim2.new(
            Wrapper.Position.X.Scale,Wrapper.Position.X.Offset,
            Wrapper.Position.Y.Scale,Wrapper.Position.Y.Offset
        )
        Wrapper.Visible=false; Pill.Visible=true
    end))
    Core:Add(Pill.MouseButton1Click:Connect(function()
        Wrapper.Position=Pill.Position
        Wrapper.Visible=true; Pill.Visible=false
    end))

    local drag,ds,sp=false,nil,nil
    Core:Add(TopBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=Wrapper.Position
        end
    end))
    Core:Add(UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-ds
            Wrapper.Position=UDim2.new(
                sp.X.Scale,sp.X.Offset+d.X,
                sp.Y.Scale,sp.Y.Offset+d.Y
            )
        end
    end))
    Core:Add(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=false
        end
    end))

    local mini=false
    Core:Add(MinBtn.MouseButton1Click:Connect(function()
        mini=not mini
        Content.Visible=not mini; TabBar.Visible=not mini
        Wrapper.Size=mini and UDim2.new(0,255,0,36) or UDim2.new(0,255,0,420)
        MinBtn.Text=mini and "+" or "—"
    end))
end

function UI:AddTab(name)
    local page=Instance.new("ScrollingFrame",self.Content)
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1
    page.BorderSizePixel=0; page.ScrollBarThickness=4
    page.ScrollBarImageColor3=Color3.fromRGB(255,60,60)
    page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false; page.ScrollingEnabled=true
    local layout=Instance.new("UIListLayout",page)
    layout.Padding=UDim.new(0,4); layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local pad=Instance.new("UIPadding",page)
    pad.PaddingTop=UDim.new(0,6); pad.PaddingLeft=UDim.new(0,5)
    pad.PaddingRight=UDim.new(0,5); pad.PaddingBottom=UDim.new(0,10)
    Core:Add(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
    end))
    local function refresh()
        task.wait()
        page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
    end
    local btn=Instance.new("TextButton",self.TabBar)
    btn.Size=UDim2.new(0,42,0,20)
    btn.BackgroundColor3=Color3.fromRGB(28,10,10)
    btn.Text=name; btn.TextColor3=Color3.fromRGB(180,80,80)
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=9; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    local entry={page=page,btn=btn}; table.insert(self._tabPages,entry)
    local function activate()
        for _,t in ipairs(self._tabPages) do
            t.page.Visible=false
            t.btn.BackgroundColor3=Color3.fromRGB(28,10,10)
            t.btn.TextColor3=Color3.fromRGB(180,80,80)
        end
        page.Visible=true
        btn.BackgroundColor3=Color3.fromRGB(200,40,40)
        btn.TextColor3=Color3.fromRGB(255,255,255)
        task.defer(refresh)
    end
    Core:Add(btn.MouseButton1Click:Connect(activate))
    if #self._tabPages==1 then activate() end
    return page,refresh
end

function UI:Section(parent,text)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,16); f.BackgroundTransparency=1
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text="── "..text.." ──"
    l.TextColor3=Color3.fromRGB(255,80,80)
    l.Font=Enum.Font.GothamBold; l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Center
end

function UI:Toggle(parent,label,callback,col)
    local color=col or Color3.fromRGB(200,40,40); local state=false
    local card=Instance.new("Frame",parent)
    card.Size=UDim2.new(1,0,0,26)
    card.BackgroundColor3=Color3.fromRGB(22,10,10); card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,-48,1,0); lbl.Position=UDim2.new(0,9,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(235,200,200)
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pill=Instance.new("TextButton",card)
    pill.Size=UDim2.new(0,32,0,15); pill.Position=UDim2.new(1,-40,0.5,-7)
    pill.BackgroundColor3=Color3.fromRGB(50,20,20)
    pill.Text=""; pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,11,0,11); knob.Position=UDim2.new(0,2,0.5,-5)
    knob.BackgroundColor3=Color3.fromRGB(150,80,80); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    Core:Add(pill.MouseButton1Click:Connect(function()
        state=not state
        if state then
            pill.BackgroundColor3=color
            knob.Position=UDim2.new(1,-13,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(255,255,255)
        else
            pill.BackgroundColor3=Color3.fromRGB(50,20,20)
            knob.Position=UDim2.new(0,2,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(150,80,80)
        end
        ShowToast(label,state); pcall(callback,state)
    end))
end

function UI:MakeSlider(parent,labelText,initVal,minVal,maxVal,onChange)
    local fc=Instance.new("Frame",parent)
    fc.Size=UDim2.new(1,0,0,42)
    fc.BackgroundColor3=Color3.fromRGB(22,10,10); fc.BorderSizePixel=0
    Instance.new("UICorner",fc).CornerRadius=UDim.new(0,6)
    local fl=Instance.new("TextLabel",fc)
    fl.Size=UDim2.new(1,-10,0,18); fl.Position=UDim2.new(0,9,0,3)
    fl.BackgroundTransparency=1; fl.Text=labelText..": "..initVal
    fl.TextColor3=Color3.fromRGB(220,180,180); fl.Font=Enum.Font.GothamSemibold
    fl.TextSize=11; fl.TextXAlignment=Enum.TextXAlignment.Left
    local tr=Instance.new("Frame",fc)
    tr.Size=UDim2.new(1,-18,0,6); tr.Position=UDim2.new(0,9,0,28)
    tr.BackgroundColor3=Color3.fromRGB(50,20,20); tr.BorderSizePixel=0
    Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local ratio=math.clamp((initVal-minVal)/(maxVal-minVal),0,1)
    local fi=Instance.new("Frame",tr)
    fi.Size=UDim2.new(ratio,0,1,0)
    fi.BackgroundColor3=Color3.fromRGB(200,40,40); fi.BorderSizePixel=0
    Instance.new("UICorner",fi).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("TextButton",tr)
    kn.Size=UDim2.new(0,14,0,14); kn.AnchorPoint=Vector2.new(0.5,0.5)
    kn.Position=UDim2.new(ratio,0,0.5,0)
    kn.BackgroundColor3=Color3.fromRGB(255,255,255); kn.Text=""; kn.BorderSizePixel=0
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local ds=false
    Core:Add(kn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true end
    end))
    Core:Add(UserInputService.InputChanged:Connect(function(i)
        if not ds then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            local tp=tr.AbsolutePosition; local ts=tr.AbsoluteSize
            local rx=math.clamp((i.Position.X-tp.X)/ts.X,0,1)
            local val=math.floor(minVal+(maxVal-minVal)*rx)
            fi.Size=UDim2.new(rx,0,1,0); kn.Position=UDim2.new(rx,0,0.5,0)
            fl.Text=labelText..": "..val; pcall(onChange,val)
        end
    end))
    Core:Add(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then ds=false end
    end))
end

-- ============================================================================
-- [12] BOOTSTRAP
-- ============================================================================
UI:Build()

-- Tab AIM
do
    local p,r=UI:AddTab("Aim")
    UI:Section(p,"AIMBOT")
    UI:Toggle(p,"Aktifkan Aimbot",function(v)
        Config.Aimbot.Enabled=v
        FOVCircle.Visible=v and Config.Aimbot.FOVVisible
    end,Color3.fromRGB(255,60,60))
    UI:Toggle(p,"Silent Aim",function(v) Config.SilentAim.Enabled=v end,Color3.fromRGB(255,120,40))
    UI:Toggle(p,"Triggerbot",function(v) Config.Triggerbot.Enabled=v end,Color3.fromRGB(255,80,80))
    UI:Toggle(p,"FOV Circle",function(v)
        Config.Aimbot.FOVVisible=v
        FOVCircle.Visible=v and Config.Aimbot.Enabled
    end)
    UI:Toggle(p,"Wall Check",function(v) Config.Aimbot.WallCheck=v end)
    UI:Toggle(p,"Team Check",function(v) Config.Aimbot.TeamCheck=v end)
    UI:MakeSlider(p,"FOV Radius",Config.Aimbot.FOVRadius,30,500,function(v)
        Config.Aimbot.FOVRadius=v; FOVCircle.Radius=v
    end)
    UI:MakeSlider(p,"Smoothness (x10)",math.floor(Config.Aimbot.Smoothness*10),1,10,function(v)
        Config.Aimbot.Smoothness=v/10
    end)
    UI:MakeSlider(p,"Trigger (px)",Config.Triggerbot.Threshold,5,100,function(v)
        Config.Triggerbot.Threshold=v
    end)
    task.defer(r)
end

-- Tab GUN
do
    local p,r=UI:AddTab("Gun")
    UI:Section(p,"WEAPON MODS")
    UI:Toggle(p,"Rapid Fire",function(v)
        Config.Weapon.RapidFire=v; if v then StartRapidFire() end
    end,Color3.fromRGB(255,60,60))
    UI:Toggle(p,"Auto Reload",function(v)
        Config.Weapon.AutoReload=v; if v then StartAutoReload() end
    end,Color3.fromRGB(255,180,40))
    UI:Toggle(p,"No Reload Cancel",function(v)
        Config.Weapon.NoReload=v; if v then StartNoReload() end
    end,Color3.fromRGB(200,100,255))
    UI:MakeSlider(p,"Rapid Delay (ms)",math.floor(Config.Weapon.RapidDelay*1000),10,500,function(v)
        Config.Weapon.RapidDelay=v/1000
    end)
    task.defer(r)
end

-- Tab ESP
do
    local p,r=UI:AddTab("ESP")
    UI:Section(p,"MASTER")
    UI:Toggle(p,"Aktifkan ESP",function(v) Config.ESP.Enabled=v end,Color3.fromRGB(30,210,80))
    UI:Section(p,"VISUAL")
    UI:Toggle(p,"Box ESP",function(v) Config.ESP.ShowBox=v end)
    UI:Toggle(p,"Name + Weapon",function(v) Config.ESP.ShowName=v end)
    UI:Toggle(p,"Health Bar",function(v) Config.ESP.ShowHealth=v end)
    UI:Toggle(p,"Distance",function(v) Config.ESP.ShowDistance=v end)
    UI:Toggle(p,"Snap Line",function(v) Config.ESP.ShowSnapLine=v end)
    task.defer(r)
end

-- Tab MISC
do
    local p,r=UI:AddTab("Misc")
    UI:Section(p,"GAME")
    UI:Toggle(p,"Kill Feed Monitor",function(v) Config.KillFeedMonitor=v end,Color3.fromRGB(255,200,50))
    UI:Toggle(p,"Auto Respawn",function(v) Config.AutoRespawn=v end,Color3.fromRGB(100,200,255))
    UI:Section(p,"REMOTE STATUS")
    local loaded=0; for _,v in pairs(R) do if v then loaded=loaded+1 end end
    local sCard=Instance.new("Frame",p)
    sCard.Size=UDim2.new(1,0,0,30)
    sCard.BackgroundColor3=Color3.fromRGB(14,20,14); sCard.BorderSizePixel=0
    Instance.new("UICorner",sCard).CornerRadius=UDim.new(0,6)
    local sStroke=Instance.new("UIStroke",sCard)
    sStroke.Color=Color3.fromRGB(40,130,40); sStroke.Thickness=1
    local sL=Instance.new("TextLabel",sCard)
    sL.Size=UDim2.new(1,-14,1,-8); sL.Position=UDim2.new(0,7,0,4)
    sL.BackgroundTransparency=1
    sL.Text=string.format("✅ Remote: %d | WeaponNet: %s",
        loaded, WeaponNet and "OK" or "❌")
    sL.TextColor3=Color3.fromRGB(120,200,100); sL.Font=Enum.Font.Gotham
    sL.TextSize=10; sL.TextXAlignment=Enum.TextXAlignment.Left
    task.defer(r)
end

-- ============================================================================
print("✅ NEXUS Fortline Suite — Loaded (Fixed)")
print("🎯 Aimbot + Silent Aim + Triggerbot")
print("🔫 Rapid Fire + Auto Reload + No Reload")
print("👁 ESP + Kill Feed + Auto Respawn")
-- ============================================================================
