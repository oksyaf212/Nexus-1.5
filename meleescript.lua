--[[
    ============================================================================
    PROJECT   : NEXUS — Melee Suite
    GAME      : Knife/Melee Game (ByteNet)
    PLATFORM  : Delta Executor Android
    AUTHOR    : Claude Sonnet 4.6
    FITUR:
    ├── ESP (Box/Name/HP/Distance/Weapon/SnapLine)
    ├── Aimbot (kamera lock ke kepala)
    ├── Speed Hack
    ├── Noclip
    ├── Infinite Jump
    ├── Kill Feed Monitor
    ├── Weapon ESP (senjata musuh realtime)
    └── Kill Counter
    ============================================================================
]]

local ENV_KEY="NexusMelee"
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
local Remote=RS:FindFirstChild("Remote")
local GameService=Remote and Remote:FindFirstChild("GameService")
local EntityService=Remote and Remote:FindFirstChild("EntityService")
local CombatService=Remote and Remote:FindFirstChild("CombatService")

local function GetR(parent,...)
    local obj=parent
    for _,name in ipairs({...}) do
        if not obj then return nil end
        obj=obj:FindFirstChild(name)
    end
    return obj
end

local R={}
R.Killed        = GetR(GameService,"Killed")
R.Killed2       = GetR(GameService,"GameClient","Killed")
R.SetSimpleWeapon= GetR(CombatService,"SetSimpleWeapon")
R.SlotSwitched  = GetR(CombatService,"SlotSwitched")
R.BeDamaged     = GetR(EntityService,"BeDamaged")
R.Died          = GetR(EntityService,"Died")
R.Spawned       = GetR(EntityService,"Spawned")
R.Respawn       = GetR(GameService,"Respawn")

-- ============================================================================
-- [4] CONFIG
-- ============================================================================
local Config={
    ESP={
        Enabled=false,
        ShowBox=false,
        ShowName=false,
        ShowHealth=false,
        ShowDistance=false,
        ShowSnapLine=false,
        ShowWeapon=false,
        MaxDistance=99999,
        EnemyColor=Color3.fromRGB(255,50,50),
        TeamColor=Color3.fromRGB(30,220,80),
    },
    Aimbot={
        Enabled=false,
        FOVRadius=150,
        Smoothness=0.06,
        TargetPart="Head",
        TeamCheck=true,
        WallCheck=false,
        FOVVisible=true,
    },
    Mods={
        Speed=false,
        SpeedValue=60,
        Noclip=false,
        InfJump=false,
    },
    KillFeed=false,
    AutoRespawn=false,
}

-- Weapon cache — simpan senjata per player dari event
local _weaponCache={}

-- Kill stats
local _killStats={kills=0,deaths=0}

-- ============================================================================
-- [5] UTILITY
-- ============================================================================
local function ShowToast(msg,isOn)
    pcall(function()
        local existing=SafeGUI:FindFirstChild("MeleeToast")
        if existing then existing:Destroy() end
        local sg=Instance.new("ScreenGui",SafeGUI)
        sg.Name="MeleeToast"; sg.ResetOnSpawn=false; sg.DisplayOrder=9999
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
    local r=Workspace:Raycast(Camera.CFrame.Position,tPos-Camera.CFrame.Position,RayParams)
    return not r or r.Instance:IsDescendantOf(tChar)
end

-- ============================================================================
-- [6] REMOTE EVENTS LISTENER
-- ============================================================================

-- Listen SetSimpleWeapon → cache senjata per player
if R.SetSimpleWeapon then
    Core:Add(R.SetSimpleWeapon.OnClientEvent:Connect(function(playerOrId,slot,data)
        pcall(function()
            -- Cari player dari argumen
            local targetPlayer=nil
            if typeof(playerOrId)=="Instance" and playerOrId:IsA("Player") then
                targetPlayer=playerOrId
            elseif type(playerOrId)=="number" then
                for _,pl in ipairs(Players:GetPlayers()) do
                    if pl.UserId==playerOrId then targetPlayer=pl; break end
                end
            end
            if targetPlayer and type(data)=="table" and data.Name then
                _weaponCache[targetPlayer]=data.Name
            end
        end)
    end))
end

-- Listen SlotSwitched → update weapon cache
if R.SlotSwitched then
    Core:Add(R.SlotSwitched.OnClientEvent:Connect(function(playerOrId,slot,data)
        pcall(function()
            if type(data)=="table" and data.Name then
                local targetPlayer=nil
                if typeof(playerOrId)=="Instance" and playerOrId:IsA("Player") then
                    targetPlayer=playerOrId
                elseif type(playerOrId)=="number" then
                    for _,pl in ipairs(Players:GetPlayers()) do
                        if pl.UserId==playerOrId then targetPlayer=pl; break end
                    end
                end
                if targetPlayer then _weaponCache[targetPlayer]=data.Name end
            end
        end)
    end))
end

-- Kill Feed + Kill Counter
local _killFeedFrame
local function ShowKillFeed(msg,color)
    pcall(function()
        if not _killFeedFrame or not _killFeedFrame.Parent then
            local sg=Instance.new("ScreenGui",SafeGUI)
            sg.Name="MeleeKillFeed"; sg.ResetOnSpawn=false; sg.DisplayOrder=998
            Core:Add(sg)
            local frame=Instance.new("Frame",sg)
            frame.Size=UDim2.new(0,240,0,200)
            frame.Position=UDim2.new(1,-250,0.4,-100)
            frame.BackgroundTransparency=1
            local layout=Instance.new("UIListLayout",frame)
            layout.Padding=UDim.new(0,3)
            layout.VerticalAlignment=Enum.VerticalAlignment.Bottom
            _killFeedFrame=frame
        end
        local entry=Instance.new("Frame",_killFeedFrame)
        entry.Size=UDim2.new(1,0,0,24)
        entry.BackgroundColor3=Color3.fromRGB(0,0,0)
        entry.BackgroundTransparency=0.35; entry.BorderSizePixel=0
        Instance.new("UICorner",entry).CornerRadius=UDim.new(0,5)
        local l=Instance.new("TextLabel",entry)
        l.Size=UDim2.new(1,-8,1,0); l.Position=UDim2.new(0,4,0,0)
        l.BackgroundTransparency=1; l.Text=msg
        l.TextColor3=color or Color3.fromRGB(255,255,255)
        l.Font=Enum.Font.GothamBold; l.TextSize=10
        l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
        task.delay(5,function()
            for i=1,10 do
                pcall(function()
                    entry.BackgroundTransparency=0.35+(i*0.065)
                    l.TextTransparency=i/10
                end)
                task.wait(0.06)
            end
            pcall(function() entry:Destroy() end)
        end)
    end)
end

local function ListenKilled(remote)
    if not remote then return end
    Core:Add(remote.OnClientEvent:Connect(function(killer,victim,timestamp,data)
        pcall(function()
            local killerName=typeof(killer)=="Instance" and killer.Name or tostring(killer)
            local victimName=typeof(victim)=="Instance" and victim.Name or tostring(victim)
            local weapon=""
            if type(data)=="table" and data.Weapon then
                weapon=" ["..tostring(data.Weapon).."]"
            end

            -- Update stats
            if typeof(killer)=="Instance" and killer==LocalPlayer then
                _killStats.kills=_killStats.kills+1
            end
            if typeof(victim)=="Instance" and victim==LocalPlayer then
                _killStats.deaths=_killStats.deaths+1
            end

            if not Config.KillFeed then return end

            -- Tentukan warna
            local col=Color3.fromRGB(200,200,200)
            if typeof(killer)=="Instance" and killer==LocalPlayer then
                col=Color3.fromRGB(80,255,80)   -- kamu bunuh
            elseif typeof(victim)=="Instance" and victim==LocalPlayer then
                col=Color3.fromRGB(255,80,80)   -- kamu mati
            end

            ShowKillFeed("⚔️ "..killerName.." → "..victimName..weapon,col)
        end)
    end))
end

ListenKilled(R.Killed)
ListenKilled(R.Killed2)

-- Auto Respawn
if R.Died then
    Core:Add(R.Died.OnClientEvent:Connect(function()
        if Config.AutoRespawn and R.Respawn then
            task.wait(0.5)
            pcall(function() R.Respawn:FireServer() end)
        end
    end))
end

-- ============================================================================
-- [7] ESP MODULE
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

    local wtxt=Drawing.new("Text"); wtxt.Size=10; wtxt.Center=true
    wtxt.Outline=true; wtxt.Color=Color3.fromRGB(255,200,50)
    wtxt.Visible=false; wtxt.ZIndex=5; c.WeaponText=wtxt

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
    hl.FillTransparency=0.75; hl.OutlineTransparency=0.0
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
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","WeaponText","HpBg","HpFg","DistText","SnapLine"}) do
        pcall(function() c[k]:Remove() end)
    end
    ESPCache[player]=nil
end

local function HideESP(c)
    c.Highlight.Enabled=false
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","WeaponText","HpBg","HpFg","DistText","SnapLine"}) do
        c[k].Visible=false
    end
end

for _,p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Core:Add(Players.PlayerAdded:Connect(CreateESP))
Core:Add(Players.PlayerRemoving:Connect(function(p)
    _weaponCache[p]=nil
    RemoveESP(p)
end))
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

        -- Update warna
        c.Highlight.FillColor=col; c.Highlight.OutlineColor=col
        c.BoxT.Color=col; c.BoxB.Color=col; c.BoxL.Color=col; c.BoxR.Color=col
        c.Text.Color=col; c.SnapLine.Color=col
        c.Highlight.Enabled=true

        local pos,onScreen=Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","WeaponText","HpBg","HpFg","DistText","SnapLine"}) do
                c[k].Visible=false
            end
            continue
        end

        local tV=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3.2,0))
        local bV=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3.2,0))
        local h=math.abs(tV.Y-bV.Y); local w=h*0.5
        local cx=pos.X; local lx=cx-w/2; local rx=cx+w/2

        -- Box
        if Config.ESP.ShowBox then
            c.BoxT.From=Vector2.new(lx,tV.Y); c.BoxT.To=Vector2.new(rx,tV.Y); c.BoxT.Visible=true
            c.BoxB.From=Vector2.new(lx,bV.Y); c.BoxB.To=Vector2.new(rx,bV.Y); c.BoxB.Visible=true
            c.BoxL.From=Vector2.new(lx,tV.Y); c.BoxL.To=Vector2.new(lx,bV.Y); c.BoxL.Visible=true
            c.BoxR.From=Vector2.new(rx,tV.Y); c.BoxR.To=Vector2.new(rx,bV.Y); c.BoxR.Visible=true
        else c.BoxT.Visible=false; c.BoxB.Visible=false; c.BoxL.Visible=false; c.BoxR.Visible=false end

        -- Name
        if Config.ESP.ShowName then
            c.Text.Text=player.Name
            c.Text.Position=Vector2.new(cx,tV.Y-16); c.Text.Visible=true
        else c.Text.Visible=false end

        -- Weapon ESP
        if Config.ESP.ShowWeapon then
            local wn=_weaponCache[player] or "?"
            c.WeaponText.Text="🔪 "..wn
            c.WeaponText.Position=Vector2.new(cx,tV.Y-28); c.WeaponText.Visible=true
        else c.WeaponText.Visible=false end

        -- Distance
        if Config.ESP.ShowDistance then
            c.DistText.Text=string.format("[%.0fm]",dist)
            c.DistText.Position=Vector2.new(cx,bV.Y+3); c.DistText.Visible=true
        else c.DistText.Visible=false end

        -- HP Bar
        if Config.ESP.ShowHealth then
            local hp=hum.Health/math.max(hum.MaxHealth,1); local bx=lx-6
            c.HpBg.From=Vector2.new(bx,tV.Y); c.HpBg.To=Vector2.new(bx,bV.Y); c.HpBg.Visible=true
            c.HpFg.From=Vector2.new(bx,bV.Y); c.HpFg.To=Vector2.new(bx,bV.Y-h*hp)
            c.HpFg.Color=Color3.new(1-hp,hp,0); c.HpFg.Visible=true
        else c.HpBg.Visible=false; c.HpFg.Visible=false end

        -- Snap Line
        if Config.ESP.ShowSnapLine then
            c.SnapLine.From=Vector2.new(vp.X/2,vp.Y)
            c.SnapLine.To=Vector2.new(cx,bV.Y); c.SnapLine.Visible=true
        else c.SnapLine.Visible=false end
    end
end))

-- ============================================================================
-- [8] AIMBOT
-- ============================================================================
local FOVCircle=Drawing.new("Circle")
FOVCircle.Radius=Config.Aimbot.FOVRadius; FOVCircle.Visible=false
FOVCircle.Color=Color3.fromRGB(255,100,30); FOVCircle.Thickness=1.5
FOVCircle.NumSides=64; FOVCircle.Filled=false
Core:Add(function() pcall(function() FOVCircle:Remove() end) end)

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

Core:Add(RunService.RenderStepped:Connect(function()
    if FOVCircle.Visible then
        FOVCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        FOVCircle.Radius=Config.Aimbot.FOVRadius
    end
    local result=GetBestTarget()
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
end))

-- ============================================================================
-- [9] PHYSICS MODS
-- ============================================================================

-- Speed Hack
local _speedConn
local function StartSpeed()
    if _speedConn then _speedConn:Disconnect(); _speedConn=nil end
    _speedConn=RunService.Heartbeat:Connect(function()
        if not Config.Mods.Speed then
            _speedConn:Disconnect(); _speedConn=nil
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed=16 end
            return
        end
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=Config.Mods.SpeedValue end
    end)
end
Core:Add(function()
    if _speedConn then _speedConn:Disconnect() end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed=16 end
end)

-- Noclip
Core:Add(RunService.Stepped:Connect(function()
    if not Config.Mods.Noclip then return end
    local char=LocalPlayer.Character; if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
    end
end))

-- Infinite Jump
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
Core:Add(function() if _ijConn then _ijConn:Disconnect() end end)

-- Re-apply saat respawn
Core:Add(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Config.Mods.Speed then StartSpeed() end
    if Config.Mods.InfJump then SetInfJump(true) end
end))

-- ============================================================================
-- [10] FPS + PING — otomatis aktif
-- ============================================================================
local _fpsDraw=Drawing.new("Text")
_fpsDraw.Size=13; _fpsDraw.Center=true
_fpsDraw.Outline=true; _fpsDraw.Visible=true; _fpsDraw.ZIndex=11
Core:Add(function() pcall(function() _fpsDraw:Remove() end) end)

-- Kill Counter HUD
local _kcDraw=Drawing.new("Text")
_kcDraw.Size=12; _kcDraw.Center=false
_kcDraw.Outline=true; _kcDraw.Visible=true; _kcDraw.ZIndex=11
_kcDraw.Color=Color3.fromRGB(255,200,80)
Core:Add(function() pcall(function() _kcDraw:Remove() end) end)

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

    -- Kill counter pojok kiri atas
    _kcDraw.Text=string.format("⚔️ K: %d  💀 D: %d  KD: %.1f",
        _killStats.kills,
        _killStats.deaths,
        _killStats.deaths==0 and _killStats.kills or _killStats.kills/_killStats.deaths
    )
    _kcDraw.Position=Vector2.new(8,36)
end))

-- ============================================================================
-- [11] UI
-- ============================================================================
local UI={_tabPages={}}

-- Warna tema orange/coklat untuk game melee
local THEME={
    primary=Color3.fromRGB(220,120,20),
    bg=Color3.fromRGB(14,10,6),
    topbar=Color3.fromRGB(22,14,6),
    card=Color3.fromRGB(20,14,8),
}

function UI:Build()
    local Screen=Instance.new("ScreenGui",SafeGUI)
    Screen.Name="MeleeUI"; Screen.ResetOnSpawn=false; Screen.DisplayOrder=999
    Core:Add(Screen)

    local Wrapper=Instance.new("Frame",Screen)
    Wrapper.Size=UDim2.new(0,255,0,430)
    Wrapper.Position=UDim2.new(0.04,0,0.08,0)
    Wrapper.BackgroundTransparency=1
    Instance.new("UICorner",Wrapper).CornerRadius=UDim.new(0,12)
    local WStroke=Instance.new("UIStroke",Wrapper)
    WStroke.Color=THEME.primary; WStroke.Thickness=1.5
    self.Wrapper=Wrapper

    local Main=Instance.new("Frame",Wrapper)
    Main.Size=UDim2.new(1,0,1,0)
    Main.BackgroundColor3=THEME.bg
    Main.BorderSizePixel=0; Main.ClipsDescendants=true
    Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12)
    self.Main=Main

    local TopBar=Instance.new("Frame",Main)
    TopBar.Size=UDim2.new(1,0,0,36)
    TopBar.BackgroundColor3=THEME.topbar
    TopBar.BorderSizePixel=0

    local TL=Instance.new("TextLabel",TopBar)
    TL.Size=UDim2.new(1,-96,1,0); TL.Position=UDim2.new(0,11,0,0)
    TL.BackgroundTransparency=1; TL.Text="🔪  NEXUS  MELEE"
    TL.TextColor3=THEME.primary
    TL.Font=Enum.Font.GothamBold; TL.TextSize=13
    TL.TextXAlignment=Enum.TextXAlignment.Left

    -- Panic Button
    local PanicBtn=Instance.new("TextButton",TopBar)
    PanicBtn.Size=UDim2.new(0,24,0,22); PanicBtn.Position=UDim2.new(1,-90,0.5,-11)
    PanicBtn.BackgroundColor3=Color3.fromRGB(140,20,20); PanicBtn.Text="❌"
    PanicBtn.TextColor3=Color3.fromRGB(255,255,255); PanicBtn.Font=Enum.Font.GothamBold
    PanicBtn.TextSize=11; PanicBtn.BorderSizePixel=0
    Instance.new("UICorner",PanicBtn).CornerRadius=UDim.new(0,5)
    Core:Add(PanicBtn.MouseButton1Click:Connect(function()
        Config.ESP.Enabled=false; Config.Aimbot.Enabled=false
        Config.Mods.Speed=false; Config.Mods.Noclip=false
        Config.Mods.InfJump=false; Config.KillFeed=false
        ShowToast("PANIC — Semua OFF",false)
    end))

    local HideBtn=Instance.new("TextButton",TopBar)
    HideBtn.Size=UDim2.new(0,24,0,22); HideBtn.Position=UDim2.new(1,-62,0.5,-11)
    HideBtn.BackgroundColor3=Color3.fromRGB(60,35,8); HideBtn.Text="👁"
    HideBtn.TextColor3=Color3.fromRGB(255,200,100); HideBtn.Font=Enum.Font.GothamBold
    HideBtn.TextSize=11; HideBtn.BorderSizePixel=0
    Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(0,5)

    local MinBtn=Instance.new("TextButton",TopBar)
    MinBtn.Size=UDim2.new(0,24,0,22); MinBtn.Position=UDim2.new(1,-34,0.5,-11)
    MinBtn.BackgroundColor3=Color3.fromRGB(45,28,6); MinBtn.Text="—"
    MinBtn.TextColor3=Color3.fromRGB(200,200,200); MinBtn.Font=Enum.Font.GothamBold
    MinBtn.TextSize=12; MinBtn.BorderSizePixel=0
    Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,5)

    local TabBar=Instance.new("ScrollingFrame",Main)
    TabBar.Size=UDim2.new(1,0,0,26); TabBar.Position=UDim2.new(0,0,0,36)
    TabBar.BackgroundColor3=Color3.fromRGB(18,12,4); TabBar.BorderSizePixel=0
    TabBar.ScrollBarThickness=2; TabBar.CanvasSize=UDim2.new(0,0,0,0)
    TabBar.ScrollingDirection=Enum.ScrollingDirection.X
    TabBar.ScrollBarImageColor3=THEME.primary
    local TLayout=Instance.new("UIListLayout",TabBar)
    TLayout.FillDirection=Enum.FillDirection.Horizontal; TLayout.Padding=UDim.new(0,2)
    TLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    local tabPad=Instance.new("UIPadding",TabBar); tabPad.PaddingLeft=UDim.new(0,4)
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
    Pill.BackgroundColor3=Color3.fromRGB(40,22,4); Pill.Text="🔪 MELEE"
    Pill.TextColor3=THEME.primary; Pill.Font=Enum.Font.GothamBold
    Pill.TextSize=10; Pill.BorderSizePixel=0; Pill.Visible=false
    Instance.new("UICorner",Pill).CornerRadius=UDim.new(0,12)
    local pillStroke=Instance.new("UIStroke",Pill)
    pillStroke.Color=THEME.primary; pillStroke.Thickness=1
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
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end))

    local mini=false
    Core:Add(MinBtn.MouseButton1Click:Connect(function()
        mini=not mini
        Content.Visible=not mini; TabBar.Visible=not mini
        Wrapper.Size=mini and UDim2.new(0,255,0,36) or UDim2.new(0,255,0,430)
        MinBtn.Text=mini and "+" or "—"
    end))
end

function UI:AddTab(name)
    local page=Instance.new("ScrollingFrame",self.Content)
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1
    page.BorderSizePixel=0; page.ScrollBarThickness=4
    page.ScrollBarImageColor3=THEME.primary
    page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false
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
    btn.Size=UDim2.new(0,42,0,20)
    btn.BackgroundColor3=Color3.fromRGB(28,18,6)
    btn.Text=name; btn.TextColor3=Color3.fromRGB(180,110,40)
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=9; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    local entry={page=page,btn=btn}; table.insert(self._tabPages,entry)
    local function activate()
        for _,t in ipairs(self._tabPages) do
            t.page.Visible=false
            t.btn.BackgroundColor3=Color3.fromRGB(28,18,6)
            t.btn.TextColor3=Color3.fromRGB(180,110,40)
        end
        page.Visible=true
        btn.BackgroundColor3=THEME.primary
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
    l.TextColor3=THEME.primary
    l.Font=Enum.Font.GothamBold; l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Center
end

function UI:Toggle(parent,label,callback,col)
    local color=col or THEME.primary; local state=false
    local card=Instance.new("Frame",parent)
    card.Size=UDim2.new(1,0,0,26)
    card.BackgroundColor3=THEME.card; card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,-48,1,0); lbl.Position=UDim2.new(0,9,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(235,210,170)
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pill=Instance.new("TextButton",card)
    pill.Size=UDim2.new(0,32,0,15); pill.Position=UDim2.new(1,-40,0.5,-7)
    pill.BackgroundColor3=Color3.fromRGB(45,28,8)
    pill.Text=""; pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,11,0,11); knob.Position=UDim2.new(0,2,0.5,-5)
    knob.BackgroundColor3=Color3.fromRGB(150,100,40); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    Core:Add(pill.MouseButton1Click:Connect(function()
        state=not state
        if state then
            pill.BackgroundColor3=color
            knob.Position=UDim2.new(1,-13,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(255,255,255)
        else
            pill.BackgroundColor3=Color3.fromRGB(45,28,8)
            knob.Position=UDim2.new(0,2,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(150,100,40)
        end
        ShowToast(label,state); pcall(callback,state)
    end))
end

function UI:MakeSlider(parent,labelText,initVal,minVal,maxVal,onChange)
    local fc=Instance.new("Frame",parent)
    fc.Size=UDim2.new(1,0,0,42)
    fc.BackgroundColor3=THEME.card; fc.BorderSizePixel=0
    Instance.new("UICorner",fc).CornerRadius=UDim.new(0,6)
    local fl=Instance.new("TextLabel",fc)
    fl.Size=UDim2.new(1,-10,0,18); fl.Position=UDim2.new(0,9,0,3)
    fl.BackgroundTransparency=1; fl.Text=labelText..": "..initVal
    fl.TextColor3=Color3.fromRGB(220,185,130); fl.Font=Enum.Font.GothamSemibold
    fl.TextSize=11; fl.TextXAlignment=Enum.TextXAlignment.Left
    local tr=Instance.new("Frame",fc)
    tr.Size=UDim2.new(1,-18,0,6); tr.Position=UDim2.new(0,9,0,28)
    tr.BackgroundColor3=Color3.fromRGB(45,28,8); tr.BorderSizePixel=0
    Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local ratio=math.clamp((initVal-minVal)/(maxVal-minVal),0,1)
    local fi=Instance.new("Frame",tr)
    fi.Size=UDim2.new(ratio,0,1,0)
    fi.BackgroundColor3=THEME.primary; fi.BorderSizePixel=0
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

-- Tab ESP
do
    local p,r=UI:AddTab("ESP")
    UI:Section(p,"MASTER")
    UI:Toggle(p,"⚡ Aktifkan ESP",function(v) Config.ESP.Enabled=v end,Color3.fromRGB(30,210,80))
    UI:Section(p,"VISUAL — pilih sendiri")
    UI:Toggle(p,"Box ESP",function(v) Config.ESP.ShowBox=v end)
    UI:Toggle(p,"Name Tag",function(v) Config.ESP.ShowName=v end)
    UI:Toggle(p,"Health Bar",function(v) Config.ESP.ShowHealth=v end)
    UI:Toggle(p,"Distance",function(v) Config.ESP.ShowDistance=v end)
    UI:Toggle(p,"Snap Line",function(v) Config.ESP.ShowSnapLine=v end)
    UI:Toggle(p,"🔪 Weapon ESP",function(v) Config.ESP.ShowWeapon=v end,Color3.fromRGB(255,200,50))
    task.defer(r)
end

-- Tab AIM
do
    local p,r=UI:AddTab("Aim")
    UI:Section(p,"AIMBOT")
    UI:Toggle(p,"Aktifkan Aimbot",function(v)
        Config.Aimbot.Enabled=v
        FOVCircle.Visible=v and Config.Aimbot.FOVVisible
    end,THEME.primary)
    UI:Toggle(p,"FOV Circle",function(v)
        Config.Aimbot.FOVVisible=v
        FOVCircle.Visible=v and Config.Aimbot.Enabled
    end)
    UI:Toggle(p,"Wall Check",function(v) Config.Aimbot.WallCheck=v end)
    UI:Toggle(p,"Team Check",function(v) Config.Aimbot.TeamCheck=v end)
    UI:MakeSlider(p,"FOV Radius",Config.Aimbot.FOVRadius,30,500,function(v)
        Config.Aimbot.FOVRadius=v; FOVCircle.Radius=v
    end)
    UI:MakeSlider(p,"Smoothness (x100)",math.floor(Config.Aimbot.Smoothness*100),1,30,function(v)
        Config.Aimbot.Smoothness=v/100
    end)
    task.defer(r)
end

-- Tab MOVE
do
    local p,r=UI:AddTab("Move")
    UI:Section(p,"MOVEMENT")
    UI:Toggle(p,"Speed Hack",function(v)
        Config.Mods.Speed=v; if v then StartSpeed() end
    end,THEME.primary)
    UI:MakeSlider(p,"Speed Value",Config.Mods.SpeedValue,16,200,function(v)
        Config.Mods.SpeedValue=v
        if Config.Mods.Speed then
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed=v end
        end
    end)
    UI:Toggle(p,"Noclip (Tembus Dinding)",function(v) Config.Mods.Noclip=v end,THEME.primary)
    UI:Toggle(p,"Infinite Jump",function(v)
        Config.Mods.InfJump=v; SetInfJump(v)
    end,THEME.primary)
    task.defer(r)
end

-- Tab MISC
do
    local p,r=UI:AddTab("Misc")
    UI:Section(p,"GAME")
    UI:Toggle(p,"Kill Feed Monitor",function(v) Config.KillFeed=v end,Color3.fromRGB(255,200,50))
    UI:Toggle(p,"Auto Respawn",function(v) Config.AutoRespawn=v end,Color3.fromRGB(100,200,255))

    UI:Section(p,"KILL STATS")
    local statsCard=Instance.new("Frame",p)
    statsCard.Size=UDim2.new(1,0,0,44)
    statsCard.BackgroundColor3=Color3.fromRGB(18,12,4); statsCard.BorderSizePixel=0
    Instance.new("UICorner",statsCard).CornerRadius=UDim.new(0,6)
    local sStroke=Instance.new("UIStroke",statsCard)
    sStroke.Color=THEME.primary; sStroke.Thickness=1
    local statsLabel=Instance.new("TextLabel",statsCard)
    statsLabel.Size=UDim2.new(1,-10,1,-8); statsLabel.Position=UDim2.new(0,5,0,4)
    statsLabel.BackgroundTransparency=1
    statsLabel.Text="⚔️ Kills: 0  |  💀 Deaths: 0  |  KD: 0.0"
    statsLabel.TextColor3=Color3.fromRGB(255,200,80); statsLabel.Font=Enum.Font.GothamBold
    statsLabel.TextSize=11; statsLabel.TextXAlignment=Enum.TextXAlignment.Left

    -- Update stats realtime
    Core:Add(RunService.Heartbeat:Connect(function()
        pcall(function()
            local kd=_killStats.deaths==0
                and tostring(_killStats.kills)
                or string.format("%.1f",_killStats.kills/_killStats.deaths)
            statsLabel.Text=string.format(
                "⚔️ Kills: %d  |  💀 Deaths: %d  |  KD: %s",
                _killStats.kills,_killStats.deaths,kd
            )
        end)
    end))

    -- Reset button
    local resetBtn=Instance.new("TextButton",p)
    resetBtn.Size=UDim2.new(1,0,0,26)
    resetBtn.BackgroundColor3=Color3.fromRGB(80,40,8)
    resetBtn.Text="🔄  Reset Kill Stats"
    resetBtn.TextColor3=Color3.fromRGB(255,220,150)
    resetBtn.Font=Enum.Font.GothamBold; resetBtn.TextSize=11
    resetBtn.BorderSizePixel=0
    Instance.new("UICorner",resetBtn).CornerRadius=UDim.new(0,6)
    Core:Add(resetBtn.MouseButton1Click:Connect(function()
        _killStats.kills=0; _killStats.deaths=0
        ShowToast("Stats direset!",true)
    end))

    UI:Section(p,"WEAPON TRACKER")
    local wCard=Instance.new("Frame",p)
    wCard.Size=UDim2.new(1,0,0,26)
    wCard.BackgroundColor3=Color3.fromRGB(18,12,4); wCard.BorderSizePixel=0
    Instance.new("UICorner",wCard).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",wCard).Color=Color3.fromRGB(255,200,50)
    local wLabel=Instance.new("TextLabel",wCard)
    wLabel.Size=UDim2.new(1,-10,1,-6); wLabel.Position=UDim2.new(0,5,0,3)
    wLabel.BackgroundTransparency=1
    wLabel.Text="🔪 Weapon cache: 0 player"
    wLabel.TextColor3=Color3.fromRGB(255,200,80); wLabel.Font=Enum.Font.Gotham
    wLabel.TextSize=10; wLabel.TextXAlignment=Enum.TextXAlignment.Left
    Core:Add(RunService.Heartbeat:Connect(function()
        local count=0
        for _ in pairs(_weaponCache) do count=count+1 end
        pcall(function()
            wLabel.Text="🔪 Weapon cache: "..count.." player"
        end)
    end))

    task.defer(r)
end

-- ============================================================================
print("✅ NEXUS Melee Suite — Loaded")
print("👁 ESP + Weapon ESP + Kill Feed")
print("🎯 Aimbot (kamera)")
print("🏃 Speed + Noclip + InfJump")
print("📊 Kill Counter realtime")
-- ============================================================================
