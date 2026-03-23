-- NEXUS PvS Duel Suite
-- Platform: Delta Executor Android

local ENV_KEY="NexusPvSDuel"
if getgenv()[ENV_KEY] then pcall(function() getgenv()[ENV_KEY]:Destroy() end) end

local ok,err=pcall(function()

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local CoreGui=game:GetService("CoreGui")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local LocalPlayer=Players.LocalPlayer
local Camera=Workspace.CurrentCamera

local SafeGUI
do
    local ok2=pcall(function() local _=CoreGui.Name end)
    SafeGUI=ok2 and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
end

-- Maid
local Maid={}; Maid.__index=Maid
function Maid.new() return setmetatable({_j={}},Maid) end
function Maid:Add(j) table.insert(self._j,j); return j end
function Maid:Destroy()
    for _,j in ipairs(self._j) do
        if typeof(j)=="RBXScriptConnection" then pcall(function() j:Disconnect() end)
        elseif type(j)=="function" then pcall(j)
        elseif typeof(j)=="Instance" then pcall(function() j:Destroy() end) end
    end
    self._j={}
end
local Core=Maid.new()
getgenv()[ENV_KEY]=Core

-- Remotes
local Rem=ReplicatedStorage:FindFirstChild("Remotes")
local R={}
R.ShootGun     = Rem and Rem:FindFirstChild("Weapons") and Rem.Weapons:FindFirstChild("ShootGun")
R.KnifeStab    = Rem and Rem:FindFirstChild("Weapons") and Rem.Weapons:FindFirstChild("KnifeStab")
R.KnifeThrow   = Rem and Rem:FindFirstChild("Weapons") and Rem.Weapons:FindFirstChild("KnifeThrow")
R.VoteForMap   = Rem and Rem:FindFirstChild("Round")   and Rem.Round:FindFirstChild("VoteForMap")
R.RedeemCode   = Rem and Rem:FindFirstChild("Data")    and Rem.Data:FindFirstChild("RedeemCode")
R.RequestSpin  = Rem and Rem:FindFirstChild("Wheel")   and Rem.Wheel:FindFirstChild("RequestSpin")
R.PurchaseBox  = Rem and Rem:FindFirstChild("Shop")    and Rem.Shop:FindFirstChild("PurchaseBox")
R.EquipItem    = Rem and Rem:FindFirstChild("Data")    and Rem.Data:FindFirstChild("EquipItem")
R.MakeKillEff  = Rem and Rem:FindFirstChild("Round")   and Rem.Round:FindFirstChild("MakeKillEffect")

local REvt=ReplicatedStorage:FindFirstChild("RemoteEvents")
R.ReplicaTableInsert = REvt and REvt:FindFirstChild("ReplicaTableInsert")
R.ReplicaSet         = REvt and REvt:FindFirstChild("ReplicaSet")

-- Config
local Config={
    SilentAim   ={Enabled=false},
    RapidFire   ={Enabled=false, Delay=0.15, Range=200},
    AutoKnife   ={Enabled=false, Delay=0.08, Range=20},
    AutoThrow   ={Enabled=false, Delay=0.3,  Range=100},
    AutoSpin    ={Enabled=false, Delay=1.5},
    KillFeed    ={Enabled=false},
    ScoreHUD    ={Enabled=false},
    ESP         ={Enabled=false, ShowBox=false, ShowName=false,
                  ShowHP=false, ShowDist=false, MaxDist=600},
    Speed       ={Enabled=false, Value=60},
    Noclip      ={Enabled=false},
    InfJump     ={Enabled=false},
}

-- Utility
local function Fire(remote,...) if remote then pcall(function() remote:FireServer(...) end) end end
local function Invoke(remote,...) if not remote then return nil end; local ok2,r=pcall(function() return remote:InvokeServer(...) end); return ok2 and r or nil end
local function HWait(mn,mx) task.wait(math.max(0.05,mn+(math.random()*(mx-mn)))) end

local function GetRoot()
    local c=LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetTool()
    local c=LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Tool")
end

local function GetNearest(radius,checkPlayer)
    local myHRP=GetRoot(); if not myHRP then return nil end
    local nearest,minDist=nil,radius or math.huge
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LocalPlayer then continue end
        local char=pl.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health>0 then
            local dist=(hrp.Position-myHRP.Position).Magnitude
            if dist<minDist then minDist=dist; nearest={player=pl,hrp=hrp,char=char,hum=hum,dist=dist} end
        end
    end
    return nearest
end

-- Toast
local function Toast(msg,isOn)
    pcall(function()
        local ex=SafeGUI:FindFirstChild("NexToast"); if ex then ex:Destroy() end
        local sg=Instance.new("ScreenGui",SafeGUI)
        sg.Name="NexToast"; sg.ResetOnSpawn=false; sg.DisplayOrder=9999; Core:Add(sg)
        local f=Instance.new("Frame",sg)
        f.Size=UDim2.new(0,200,0,26); f.Position=UDim2.new(0.5,-100,0.88,0)
        f.BackgroundColor3=isOn and Color3.fromRGB(10,50,20) or Color3.fromRGB(60,10,10)
        f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,13)
        local s=Instance.new("UIStroke",f)
        s.Color=isOn and Color3.fromRGB(40,200,60) or Color3.fromRGB(200,50,50); s.Thickness=1
        local l=Instance.new("TextLabel",f)
        l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=(isOn and "[ON] " or "[OFF] ")..msg
        l.TextColor3=Color3.fromRGB(255,255,255); l.Font=Enum.Font.GothamBold; l.TextSize=11
        task.delay(2,function()
            for i=1,10 do pcall(function() f.BackgroundTransparency=i/10; l.TextTransparency=i/10 end); task.wait(0.04) end
            pcall(function() sg:Destroy() end)
        end)
    end)
end

-- FPS + Ping
local fpsDraw=Drawing.new("Text")
fpsDraw.Size=13; fpsDraw.Center=true; fpsDraw.Outline=true; fpsDraw.Visible=true; fpsDraw.ZIndex=11
Core:Add(function() pcall(function() fpsDraw:Remove() end) end)
local fa,fc,fd,fp=0,0,0,0
Core:Add(RunService.RenderStepped:Connect(function(dt)
    fa=fa+dt; fc=fc+1
    if fa>=0.5 then fd=math.floor(fc/fa); fa=0; fc=0 end
    pcall(function() fp=math.floor(LocalPlayer.NetworkPing*1000) end)
    local col=(fd>=50 and fp<=80) and Color3.fromRGB(80,255,80)
        or (fd>=30 and fp<=150) and Color3.fromRGB(255,220,50)
        or Color3.fromRGB(255,60,60)
    fpsDraw.Color=col
    fpsDraw.Text=string.format("FPS: %d  |  Ping: %dms",fd,fp)
    fpsDraw.Position=Vector2.new(Camera.ViewportSize.X/2,14)
end))

-- ============================================================
-- SILENT AIM
-- Hook ShootGun FireServer -> ganti HitPosition ke kepala musuh
-- ============================================================
local oldNC
local ncHooked=false
local function InitSilentAim()
    if ncHooked then return end; ncHooked=true
    pcall(function()
        local mt=getrawmetatable(game)
        oldNC=mt.__namecall
        setreadonly(mt,false)
        mt.__namecall=newcclosure(function(self,...)
            local method=getnamecallmethod()
            if Config.SilentAim.Enabled and method=="FireServer" then
                local ok2,name=pcall(function() return self:GetFullName() end)
                if ok2 and name:find("ShootGun") then
                    local args={...}
                    -- args: timestamp, tool, {HitPosition, Origin}
                    if args[3] and type(args[3])=="table" then
                        local target=GetNearest(600)
                        if target then
                            local head=target.char:FindFirstChild("Head")
                            if head then
                                args[3].HitPosition=head.Position
                            end
                        end
                        return oldNC(self,table.unpack(args))
                    end
                end
            end
            return oldNC(self,...)
        end)
        setreadonly(mt,true)
        Core:Add(function()
            pcall(function()
                local mt=getrawmetatable(game)
                setreadonly(mt,false)
                mt.__namecall=oldNC
                setreadonly(mt,true)
            end)
        end)
    end)
end
pcall(InitSilentAim)

-- ============================================================
-- RAPID FIRE
-- Spam ShootGun ke musuh terdekat
-- ============================================================
local rfConn
local rfCount=0
local function StartRapidFire()
    task.spawn(function()
        while Config.RapidFire.Enabled do
            local tool=GetTool()
            local myHRP=GetRoot()
            local target=GetNearest(Config.RapidFire.Range)
            if tool and myHRP and target then
                local head=target.char:FindFirstChild("Head") or target.hrp
                local origin=myHRP.Position+Vector3.new(0,1.5,0)
                local hitPos=head.Position
                Fire(R.ShootGun, tick(), tool, {HitPosition=hitPos, Origin=origin})
                rfCount=rfCount+1
            end
            HWait(Config.RapidFire.Delay, Config.RapidFire.Delay+0.05)
        end
    end)
end

-- ============================================================
-- AUTO KNIFE STAB
-- Spam KnifeStab + teleport ke musuh
-- ============================================================
local akCount=0
local function StartAutoKnife()
    task.spawn(function()
        while Config.AutoKnife.Enabled do
            local tool=GetTool()
            local myHRP=GetRoot()
            local target=GetNearest(Config.AutoKnife.Range)
            if tool and myHRP and target then
                -- Teleport dekat musuh
                myHRP.CFrame=target.hrp.CFrame*CFrame.new(0,0,-3)
                task.wait(0.05)
                Fire(R.KnifeStab, tool, tick())
                akCount=akCount+1
            end
            HWait(Config.AutoKnife.Delay, Config.AutoKnife.Delay+0.03)
        end
    end)
end

-- ============================================================
-- AUTO KNIFE THROW
-- Lempar pisau ke musuh terdekat
-- ============================================================
local atCount=0
local function StartAutoThrow()
    task.spawn(function()
        while Config.AutoThrow.Enabled do
            local tool=GetTool()
            local myHRP=GetRoot()
            local target=GetNearest(Config.AutoThrow.Range)
            if tool and myHRP and target then
                -- Arahkan kamera ke target
                local head=target.char:FindFirstChild("Head") or target.hrp
                Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position, head.Position)
                task.wait(0.05)
                Fire(R.KnifeThrow, tool, tick())
                atCount=atCount+1
            end
            HWait(Config.AutoThrow.Delay, Config.AutoThrow.Delay+0.1)
        end
    end)
end

-- ============================================================
-- AUTO SPIN WHEEL
-- ============================================================
local spinCount=0
local spinConn
local function StartAutoSpin()
    if spinConn then spinConn:Disconnect(); spinConn=nil end
    local t=0
    spinConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.AutoSpin.Enabled then spinConn:Disconnect(); spinConn=nil; return end
        t=t+dt; if t<Config.AutoSpin.Delay then return end; t=0
        task.spawn(function()
            local r=Invoke(R.RequestSpin)
            if r then spinCount=spinCount+1; Toast("Spin #"..spinCount,true) end
        end)
    end)
end
Core:Add(function() if spinConn then spinConn:Disconnect() end end)

-- ============================================================
-- SPEED HACK
-- ============================================================
local speedConn
local function StartSpeed()
    if speedConn then speedConn:Disconnect(); speedConn=nil end
    speedConn=RunService.Heartbeat:Connect(function()
        if not Config.Speed.Enabled then
            speedConn:Disconnect(); speedConn=nil
            local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=16 end; return
        end
        local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed=Config.Speed.Value end
    end)
end
Core:Add(function()
    if speedConn then speedConn:Disconnect() end
    local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=16 end
end)

-- ============================================================
-- NOCLIP
-- ============================================================
local noclipParts={}
local noclipConn
local function CacheParts()
    noclipParts={}
    local c=LocalPlayer.Character; if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(noclipParts,p) end
    end
end
Core:Add(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5); CacheParts()
    if Config.Speed.Enabled then StartSpeed() end
end))
CacheParts()
Core:Add(RunService.Stepped:Connect(function()
    if not Config.Noclip.Enabled then return end
    for _,p in ipairs(noclipParts) do
        pcall(function() if p.CanCollide then p.CanCollide=false end end)
    end
end))

-- ============================================================
-- INFINITE JUMP
-- ============================================================
local ijConn
local function SetInfJump(on)
    if ijConn then ijConn:Disconnect(); ijConn=nil end
    if on then
        ijConn=UserInputService.JumpRequest:Connect(function()
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end
Core:Add(function() if ijConn then ijConn:Disconnect() end end)

-- ============================================================
-- KILL FEED
-- ============================================================
local killFeedGui
local function ShowKillFeedEntry(killer,victim,weapon,isMine)
    pcall(function()
        if not killFeedGui or not killFeedGui.Parent then
            local sg=Instance.new("ScreenGui",SafeGUI)
            sg.Name="NexKillFeed"; sg.ResetOnSpawn=false; sg.DisplayOrder=995; Core:Add(sg)
            local frame=Instance.new("Frame",sg)
            frame.Size=UDim2.new(0,230,0,200); frame.Position=UDim2.new(1,-240,0.35,0)
            frame.BackgroundTransparency=1
            local layout=Instance.new("UIListLayout",frame)
            layout.Padding=UDim.new(0,3); layout.VerticalAlignment=Enum.VerticalAlignment.Bottom
            killFeedGui=frame
        end
        local entry=Instance.new("Frame",killFeedGui)
        entry.Size=UDim2.new(1,0,0,22)
        entry.BackgroundColor3=isMine and Color3.fromRGB(10,40,10) or Color3.fromRGB(20,15,8)
        entry.BackgroundTransparency=0.3; entry.BorderSizePixel=0
        Instance.new("UICorner",entry).CornerRadius=UDim.new(0,5)
        local l=Instance.new("TextLabel",entry)
        l.Size=UDim2.new(1,-8,1,0); l.Position=UDim2.new(0,4,0,0)
        l.BackgroundTransparency=1
        l.Text=killer.." > "..victim.." ["..weapon.."]"
        l.TextColor3=isMine and Color3.fromRGB(80,255,80) or Color3.fromRGB(255,200,100)
        l.Font=Enum.Font.GothamBold; l.TextSize=9
        l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
        -- Remove lama
        local frames={}
        for _,c in ipairs(killFeedGui:GetChildren()) do
            if c:IsA("Frame") then table.insert(frames,c) end
        end
        if #frames>10 then frames[1]:Destroy() end
        task.delay(4,function()
            for i=1,10 do
                pcall(function() entry.BackgroundTransparency=0.3+(i*0.07); l.TextTransparency=i/10 end)
                task.wait(0.05)
            end
            pcall(function() entry:Destroy() end)
        end)
    end)
end

-- Listen ReplicaTableInsert untuk kill feed
if R.ReplicaTableInsert then
    Core:Add(R.ReplicaTableInsert.OnClientEvent:Connect(function(id,path,data)
        if not Config.KillFeed.Enabled then return end
        pcall(function()
            if type(path)=="table" and path[5]=="Kills" and type(data)=="table" then
                local killer=tostring(path[4] or "?")
                local victim=tostring(data.KilledWho or "?")
                local weapon=tostring(data.KillType or "?")
                local isMine=killer==LocalPlayer.Name or victim==LocalPlayer.Name
                ShowKillFeedEntry(killer,victim,weapon,isMine)
            end
        end)
    end))
end

-- ============================================================
-- SCORE HUD
-- ============================================================
local scoreGui
local _scores={Blue=0,Red=0}
if R.ReplicaSet then
    Core:Add(R.ReplicaSet.OnClientEvent:Connect(function(id,path,value)
        pcall(function()
            if type(path)=="table" and path[5]=="Score" then
                local team=tostring(path[4] or "")
                if team=="Blue" or team=="Red" then
                    _scores[team]=value or 0
                end
            end
        end)
    end))
end

local function BuildScoreHUD()
    if scoreGui then scoreGui:Destroy(); scoreGui=nil end
    if not Config.ScoreHUD.Enabled then return end
    local sg=Instance.new("ScreenGui",SafeGUI)
    sg.Name="NexScore"; sg.ResetOnSpawn=false; sg.DisplayOrder=990; Core:Add(sg); scoreGui=sg
    local f=Instance.new("Frame",sg)
    f.Size=UDim2.new(0,160,0,50); f.Position=UDim2.new(0.5,-80,0,50)
    f.BackgroundColor3=Color3.fromRGB(8,8,18); f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",f).Color=Color3.fromRGB(80,80,200)
    local lbl=Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(1,-10,1,-8); lbl.Position=UDim2.new(0,5,0,4)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=16
    lbl.TextXAlignment=Enum.TextXAlignment.Center
    Core:Add(RunService.Heartbeat:Connect(function()
        pcall(function()
            lbl.Text=string.format("Blue %d  -  %d Red",_scores.Blue,_scores.Red)
            lbl.TextColor3=_scores.Blue>_scores.Red
                and Color3.fromRGB(80,150,255)
                or _scores.Red>_scores.Blue
                and Color3.fromRGB(255,80,80)
                or Color3.fromRGB(255,255,255)
        end)
    end))
end

-- ============================================================
-- ESP
-- ============================================================
local ESPCache={}
local function CreateESP(player)
    if player==LocalPlayer or ESPCache[player] then return end
    local c={}
    local function nL(t) local l=Drawing.new("Line"); l.Color=Color3.fromRGB(255,50,50); l.Thickness=t; l.Visible=false; l.ZIndex=4; return l end
    c.BoxT=nL(1.5); c.BoxB=nL(1.5); c.BoxL=nL(1.5); c.BoxR=nL(1.5)
    local tx=Drawing.new("Text"); tx.Size=12; tx.Center=true; tx.Outline=true; tx.Color=Color3.fromRGB(255,80,80); tx.Visible=false; tx.ZIndex=5; c.Text=tx
    local hb=Drawing.new("Line"); hb.Thickness=3; hb.Color=Color3.new(0,0,0); hb.Visible=false; c.HpBg=hb
    local hf=Drawing.new("Line"); hf.Thickness=1.8; hf.Visible=false; c.HpFg=hf
    local dt=Drawing.new("Text"); dt.Size=10; dt.Center=true; dt.Outline=true; dt.Color=Color3.fromRGB(255,230,80); dt.Visible=false; dt.ZIndex=5; c.Dist=dt
    local hl=Instance.new("Highlight"); hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency=0.75; hl.FillColor=Color3.fromRGB(255,50,50); hl.OutlineColor=Color3.fromRGB(255,50,50); hl.Enabled=false; hl.Parent=CoreGui
    if player.Character then hl.Adornee=player.Character end
    c._cc=player.CharacterAdded:Connect(function(ch) hl.Adornee=ch end); c.HL=hl
    ESPCache[player]=c
end
local function RemoveESP(player)
    local c=ESPCache[player]; if not c then return end
    pcall(function() c._cc:Disconnect() end); pcall(function() c.HL:Destroy() end)
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","Dist"}) do pcall(function() c[k]:Remove() end) end
    ESPCache[player]=nil
end
local function HideESP(c)
    c.HL.Enabled=false
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","Dist"}) do c[k].Visible=false end
end
for _,p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Core:Add(Players.PlayerAdded:Connect(CreateESP))
Core:Add(Players.PlayerRemoving:Connect(RemoveESP))
Core:Add(function()
    local s={}; for p in pairs(ESPCache) do table.insert(s,p) end
    for _,p in ipairs(s) do RemoveESP(p) end
end)
Core:Add(RunService.RenderStepped:Connect(function()
    for player,c in pairs(ESPCache) do
        if not Config.ESP.Enabled then HideESP(c); continue end
        local char=player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not(char and hum and hrp and hum.Health>0) then HideESP(c); continue end
        local dist=(Camera.CFrame.Position-hrp.Position).Magnitude
        if dist>Config.ESP.MaxDist then HideESP(c); continue end
        c.HL.Enabled=true
        local pos,onScreen=Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","Dist"}) do c[k].Visible=false end; continue end
        local tV=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3.2,0))
        local bV=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3.2,0))
        local h=math.abs(tV.Y-bV.Y); local w=h*0.45; local cx=pos.X; local lx=cx-w/2; local rx=cx+w/2
        if Config.ESP.ShowBox then
            c.BoxT.From=Vector2.new(lx,tV.Y); c.BoxT.To=Vector2.new(rx,tV.Y); c.BoxT.Visible=true
            c.BoxB.From=Vector2.new(lx,bV.Y); c.BoxB.To=Vector2.new(rx,bV.Y); c.BoxB.Visible=true
            c.BoxL.From=Vector2.new(lx,tV.Y); c.BoxL.To=Vector2.new(lx,bV.Y); c.BoxL.Visible=true
            c.BoxR.From=Vector2.new(rx,tV.Y); c.BoxR.To=Vector2.new(rx,bV.Y); c.BoxR.Visible=true
        else c.BoxT.Visible=false; c.BoxB.Visible=false; c.BoxL.Visible=false; c.BoxR.Visible=false end
        if Config.ESP.ShowName then c.Text.Text=player.Name; c.Text.Position=Vector2.new(cx,tV.Y-16); c.Text.Visible=true else c.Text.Visible=false end
        if Config.ESP.ShowDist then c.Dist.Text=string.format("%.0fm",dist); c.Dist.Position=Vector2.new(cx,bV.Y+3); c.Dist.Visible=true else c.Dist.Visible=false end
        if Config.ESP.ShowHP then
            local hp=hum.Health/math.max(hum.MaxHealth,1); local bx=lx-6
            c.HpBg.From=Vector2.new(bx,tV.Y); c.HpBg.To=Vector2.new(bx,bV.Y); c.HpBg.Visible=true
            c.HpFg.From=Vector2.new(bx,bV.Y); c.HpFg.To=Vector2.new(bx,bV.Y-h*hp); c.HpFg.Color=Color3.new(1-hp,hp,0); c.HpFg.Visible=true
        else c.HpBg.Visible=false; c.HpFg.Visible=false end
    end
end))

-- ============================================================
-- UI
-- ============================================================
local THEME={
    pri=Color3.fromRGB(255,80,80),
    bg=Color3.fromRGB(12,6,6),
    top=Color3.fromRGB(20,8,8),
    card=Color3.fromRGB(18,8,8),
}

local Screen=Instance.new("ScreenGui",SafeGUI)
Screen.Name="NexPvSDuelUI"; Screen.ResetOnSpawn=false; Screen.DisplayOrder=999; Core:Add(Screen)

local Wrap=Instance.new("Frame",Screen)
Wrap.Size=UDim2.new(0,255,0,470); Wrap.Position=UDim2.new(0.04,0,0.05,0); Wrap.BackgroundTransparency=1
Instance.new("UICorner",Wrap).CornerRadius=UDim.new(0,12)
local WS=Instance.new("UIStroke",Wrap); WS.Color=THEME.pri; WS.Thickness=1.5

local Main=Instance.new("Frame",Wrap)
Main.Size=UDim2.new(1,0,1,0); Main.BackgroundColor3=THEME.bg; Main.BorderSizePixel=0; Main.ClipsDescendants=true
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12)

local TopBar=Instance.new("Frame",Main)
TopBar.Size=UDim2.new(1,0,0,36); TopBar.BackgroundColor3=THEME.top; TopBar.BorderSizePixel=0

local TL=Instance.new("TextLabel",TopBar)
TL.Size=UDim2.new(1,-96,1,0); TL.Position=UDim2.new(0,11,0,0); TL.BackgroundTransparency=1
TL.Text="NEXUS - PvS DUEL"; TL.TextColor3=THEME.pri; TL.Font=Enum.Font.GothamBold; TL.TextSize=13; TL.TextXAlignment=Enum.TextXAlignment.Left

-- Tombol topbar
local function MakeTopBtn(txt,posX,col)
    local b=Instance.new("TextButton",TopBar)
    b.Size=UDim2.new(0,24,0,22); b.Position=UDim2.new(1,posX,0.5,-11)
    b.BackgroundColor3=col; b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5); return b
end
local PanicBtn=MakeTopBtn("X",-90,Color3.fromRGB(140,20,20))
local HideBtn =MakeTopBtn("H",-62,Color3.fromRGB(60,15,15))
local MinBtn  =MakeTopBtn("-",-34,Color3.fromRGB(40,12,12))

Core:Add(PanicBtn.MouseButton1Click:Connect(function()
    Config.SilentAim.Enabled=false; Config.RapidFire.Enabled=false
    Config.AutoKnife.Enabled=false; Config.AutoThrow.Enabled=false
    Config.AutoSpin.Enabled=false; Config.ESP.Enabled=false
    Config.Speed.Enabled=false; Config.Noclip.Enabled=false
    Config.InfJump.Enabled=false; Config.KillFeed.Enabled=false
    Config.ScoreHUD.Enabled=false
    Toast("ALL OFF",false)
end))

-- TabBar
local TabBar=Instance.new("ScrollingFrame",Main)
TabBar.Size=UDim2.new(1,0,0,26); TabBar.Position=UDim2.new(0,0,0,36)
TabBar.BackgroundColor3=Color3.fromRGB(16,6,6); TabBar.BorderSizePixel=0
TabBar.ScrollBarThickness=2; TabBar.CanvasSize=UDim2.new(0,0,0,0)
TabBar.ScrollingDirection=Enum.ScrollingDirection.X
TabBar.ScrollBarImageColor3=THEME.pri
local TL2=Instance.new("UIListLayout",TabBar)
TL2.FillDirection=Enum.FillDirection.Horizontal; TL2.Padding=UDim.new(0,2); TL2.VerticalAlignment=Enum.VerticalAlignment.Center
Instance.new("UIPadding",TabBar).PaddingLeft=UDim.new(0,4)
TL2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabBar.CanvasSize=UDim2.new(0,TL2.AbsoluteContentSize.X+8,0,0)
end)

local Content=Instance.new("Frame",Main)
Content.Size=UDim2.new(1,0,1,-62); Content.Position=UDim2.new(0,0,0,62); Content.BackgroundTransparency=1

-- Pill
local Pill=Instance.new("TextButton",Screen)
Pill.Size=UDim2.new(0,110,0,24); Pill.Position=Wrap.Position
Pill.BackgroundColor3=Color3.fromRGB(40,8,8); Pill.Text="PvS DUEL"
Pill.TextColor3=THEME.pri; Pill.Font=Enum.Font.GothamBold; Pill.TextSize=10
Pill.BorderSizePixel=0; Pill.Visible=false
Instance.new("UICorner",Pill).CornerRadius=UDim.new(0,12)
Instance.new("UIStroke",Pill).Color=THEME.pri

Core:Add(HideBtn.MouseButton1Click:Connect(function()
    Pill.Position=UDim2.new(Wrap.Position.X.Scale,Wrap.Position.X.Offset,Wrap.Position.Y.Scale,Wrap.Position.Y.Offset)
    Wrap.Visible=false; Pill.Visible=true
end))
Core:Add(Pill.MouseButton1Click:Connect(function()
    Wrap.Position=Pill.Position; Wrap.Visible=true; Pill.Visible=false
end))

-- Drag
local drag,ds,sp=false,nil,nil
Core:Add(TopBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag=true; ds=i.Position; sp=Wrap.Position
    end
end))
Core:Add(UserInputService.InputChanged:Connect(function(i)
    if not drag then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-ds
        Wrap.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
end))
Core:Add(UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
end))

local mini=false
Core:Add(MinBtn.MouseButton1Click:Connect(function()
    mini=not mini; Content.Visible=not mini; TabBar.Visible=not mini
    Wrap.Size=mini and UDim2.new(0,255,0,36) or UDim2.new(0,255,0,470)
    MinBtn.Text=mini and "+" or "-"
end))

-- Tab system
local tabPages={}
local function AddTab(name)
    local page=Instance.new("ScrollingFrame",Content)
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=4; page.ScrollBarImageColor3=THEME.pri
    page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false; page.ScrollingEnabled=true
    local layout=Instance.new("UIListLayout",page)
    layout.Padding=UDim.new(0,4); layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local pad=Instance.new("UIPadding",page)
    pad.PaddingTop=UDim.new(0,6); pad.PaddingLeft=UDim.new(0,5); pad.PaddingRight=UDim.new(0,5); pad.PaddingBottom=UDim.new(0,10)
    Core:Add(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
    end))
    local function refresh() task.wait(); page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20) end
    local btn=Instance.new("TextButton",TabBar)
    btn.Size=UDim2.new(0,44,0,20); btn.BackgroundColor3=Color3.fromRGB(28,8,8)
    btn.Text=name; btn.TextColor3=Color3.fromRGB(180,60,60)
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=9; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    local entry={page=page,btn=btn}; table.insert(tabPages,entry)
    local function activate()
        for _,t in ipairs(tabPages) do t.page.Visible=false; t.btn.BackgroundColor3=Color3.fromRGB(28,8,8); t.btn.TextColor3=Color3.fromRGB(180,60,60) end
        page.Visible=true; btn.BackgroundColor3=THEME.pri; btn.TextColor3=Color3.fromRGB(255,255,255)
        task.defer(refresh)
    end
    Core:Add(btn.MouseButton1Click:Connect(activate))
    if #tabPages==1 then activate() end
    return page,refresh
end

local function Section(parent,text)
    local f=Instance.new("Frame",parent); f.Size=UDim2.new(1,0,0,16); f.BackgroundTransparency=1
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text="-- "..text.." --"; l.TextColor3=THEME.pri; l.Font=Enum.Font.GothamBold; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Center
end

local function Toggle(parent,label,callback,col)
    local color=col or THEME.pri; local state=false
    local card=Instance.new("Frame",parent); card.Size=UDim2.new(1,0,0,26); card.BackgroundColor3=THEME.card; card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",card); lbl.Size=UDim2.new(1,-48,1,0); lbl.Position=UDim2.new(0,9,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(235,200,200)
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pill=Instance.new("TextButton",card); pill.Size=UDim2.new(0,32,0,15); pill.Position=UDim2.new(1,-40,0.5,-7)
    pill.BackgroundColor3=Color3.fromRGB(45,15,15); pill.Text=""; pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",pill); knob.Size=UDim2.new(0,11,0,11); knob.Position=UDim2.new(0,2,0.5,-5)
    knob.BackgroundColor3=Color3.fromRGB(150,60,60); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    Core:Add(pill.MouseButton1Click:Connect(function()
        state=not state
        if state then pill.BackgroundColor3=color; knob.Position=UDim2.new(1,-13,0.5,-5); knob.BackgroundColor3=Color3.fromRGB(255,255,255)
        else pill.BackgroundColor3=Color3.fromRGB(45,15,15); knob.Position=UDim2.new(0,2,0.5,-5); knob.BackgroundColor3=Color3.fromRGB(150,60,60) end
        Toast(label,state); pcall(callback,state)
    end))
end

local function MakeSlider(parent,labelText,initVal,minVal,maxVal,onChange)
    local fc=Instance.new("Frame",parent); fc.Size=UDim2.new(1,0,0,42); fc.BackgroundColor3=THEME.card; fc.BorderSizePixel=0
    Instance.new("UICorner",fc).CornerRadius=UDim.new(0,6)
    local fl=Instance.new("TextLabel",fc); fl.Size=UDim2.new(1,-10,0,18); fl.Position=UDim2.new(0,9,0,3)
    fl.BackgroundTransparency=1; fl.Text=labelText..": "..initVal; fl.TextColor3=Color3.fromRGB(220,170,170)
    fl.Font=Enum.Font.GothamSemibold; fl.TextSize=11; fl.TextXAlignment=Enum.TextXAlignment.Left
    local tr=Instance.new("Frame",fc); tr.Size=UDim2.new(1,-18,0,6); tr.Position=UDim2.new(0,9,0,28)
    tr.BackgroundColor3=Color3.fromRGB(45,15,15); tr.BorderSizePixel=0; Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local ratio=math.clamp((initVal-minVal)/(maxVal-minVal),0,1)
    local fi=Instance.new("Frame",tr); fi.Size=UDim2.new(ratio,0,1,0); fi.BackgroundColor3=THEME.pri; fi.BorderSizePixel=0
    Instance.new("UICorner",fi).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("TextButton",tr); kn.Size=UDim2.new(0,14,0,14); kn.AnchorPoint=Vector2.new(0.5,0.5)
    kn.Position=UDim2.new(ratio,0,0.5,0); kn.BackgroundColor3=Color3.fromRGB(255,255,255); kn.Text=""; kn.BorderSizePixel=0
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local ds2=false
    Core:Add(kn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then ds2=true end end))
    Core:Add(UserInputService.InputChanged:Connect(function(i)
        if not ds2 then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local tp=tr.AbsolutePosition; local ts=tr.AbsoluteSize
            local rx=math.clamp((i.Position.X-tp.X)/ts.X,0,1)
            local val=math.floor(minVal+(maxVal-minVal)*rx)
            fi.Size=UDim2.new(rx,0,1,0); kn.Position=UDim2.new(rx,0,0.5,0)
            fl.Text=labelText..": "..val; pcall(onChange,val)
        end
    end))
    Core:Add(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then ds2=false end end))
end

local function ActionBtn(parent,label,col,cb)
    local btn=Instance.new("TextButton",parent); btn.Size=UDim2.new(1,0,0,28); btn.BackgroundColor3=col or THEME.pri
    btn.Text=label; btn.TextColor3=Color3.fromRGB(255,255,255); btn.Font=Enum.Font.GothamBold; btn.TextSize=11; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    Core:Add(btn.MouseButton1Click:Connect(function()
        local oc=btn.BackgroundColor3; btn.BackgroundColor3=Color3.fromRGB(255,255,255)
        task.delay(0.12,function() btn.BackgroundColor3=oc end); pcall(cb)
    end))
end

local function InfoCard(parent,text)
    local f=Instance.new("Frame",parent); f.Size=UDim2.new(1,0,0,32); f.BackgroundColor3=Color3.fromRGB(10,6,6); f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",f).Color=Color3.fromRGB(100,30,30)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-10,1,-6); l.Position=UDim2.new(0,5,0,3)
    l.BackgroundTransparency=1; l.Text=text; l.TextColor3=Color3.fromRGB(220,150,150); l.Font=Enum.Font.Gotham; l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
end

-- ============================================================
-- BUILD TABS
-- ============================================================

-- TAB: GUN
do
    local p,r=AddTab("Gun")
    Section(p,"SILENT AIM")
    InfoCard(p,"Hook ShootGun -> HitPosition ke kepala musuh")
    Toggle(p,"Silent Aim",function(v) Config.SilentAim.Enabled=v end,Color3.fromRGB(255,80,80))

    Section(p,"RAPID FIRE")
    InfoCard(p,"Spam tembak ke musuh terdekat otomatis")
    Toggle(p,"Rapid Fire",function(v) Config.RapidFire.Enabled=v; if v then StartRapidFire() end end,Color3.fromRGB(255,120,30))
    MakeSlider(p,"Delay ms",math.floor(Config.RapidFire.Delay*1000),50,500,function(v) Config.RapidFire.Delay=v/1000 end)
    MakeSlider(p,"Range stud",Config.RapidFire.Range,50,600,function(v) Config.RapidFire.Range=v end)

    -- Realtime target
    local tc=Instance.new("Frame",p); tc.Size=UDim2.new(1,0,0,26); tc.BackgroundColor3=Color3.fromRGB(10,6,6); tc.BorderSizePixel=0
    Instance.new("UICorner",tc).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",tc).Color=Color3.fromRGB(100,30,30)
    local tl=Instance.new("TextLabel",tc); tl.Size=UDim2.new(1,-10,1,-6); tl.Position=UDim2.new(0,5,0,3)
    tl.BackgroundTransparency=1; tl.Text="Target: none | Shots: 0"; tl.TextColor3=Color3.fromRGB(255,150,100)
    tl.Font=Enum.Font.GothamBold; tl.TextSize=10; tl.TextXAlignment=Enum.TextXAlignment.Left
    Core:Add(RunService.Heartbeat:Connect(function()
        pcall(function()
            local t=GetNearest(Config.RapidFire.Range)
            tl.Text=string.format("Target: %s | RF: %d",t and t.player.Name or "none",rfCount)
        end)
    end))
    task.defer(r)
end

-- TAB: KNIFE
do
    local p,r=AddTab("Knife")
    Section(p,"AUTO STAB")
    InfoCard(p,"Teleport + KnifeStab spam ke musuh terdekat")
    Toggle(p,"Auto Knife Stab",function(v) Config.AutoKnife.Enabled=v; if v then StartAutoKnife() end end,Color3.fromRGB(200,50,255))
    MakeSlider(p,"Delay ms",math.floor(Config.AutoKnife.Delay*1000),50,500,function(v) Config.AutoKnife.Delay=v/1000 end)
    MakeSlider(p,"Range stud",Config.AutoKnife.Range,5,100,function(v) Config.AutoKnife.Range=v end)

    Section(p,"AUTO THROW")
    InfoCard(p,"Lempar pisau otomatis ke musuh terdekat")
    Toggle(p,"Auto Knife Throw",function(v) Config.AutoThrow.Enabled=v; if v then StartAutoThrow() end end,Color3.fromRGB(255,150,200))
    MakeSlider(p,"Throw Delay ms",math.floor(Config.AutoThrow.Delay*1000),100,1000,function(v) Config.AutoThrow.Delay=v/1000 end)
    MakeSlider(p,"Throw Range stud",Config.AutoThrow.Range,20,200,function(v) Config.AutoThrow.Range=v end)

    -- Stats
    local sc=Instance.new("Frame",p); sc.Size=UDim2.new(1,0,0,26); sc.BackgroundColor3=Color3.fromRGB(10,6,6); sc.BorderSizePixel=0
    Instance.new("UICorner",sc).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",sc).Color=Color3.fromRGB(100,30,100)
    local sl=Instance.new("TextLabel",sc); sl.Size=UDim2.new(1,-10,1,-6); sl.Position=UDim2.new(0,5,0,3)
    sl.BackgroundTransparency=1; sl.Text="Stabs: 0 | Throws: 0"; sl.TextColor3=Color3.fromRGB(220,150,255)
    sl.Font=Enum.Font.GothamBold; sl.TextSize=10; sl.TextXAlignment=Enum.TextXAlignment.Left
    Core:Add(RunService.Heartbeat:Connect(function()
        pcall(function() sl.Text=string.format("Stabs: %d | Throws: %d",akCount,atCount) end)
    end))
    task.defer(r)
end

-- TAB: ESP
do
    local p,r=AddTab("ESP")
    Section(p,"PLAYER ESP")
    Toggle(p,"Aktifkan ESP",function(v) Config.ESP.Enabled=v end,Color3.fromRGB(30,210,80))
    Toggle(p,"Box ESP",function(v) Config.ESP.ShowBox=v end)
    Toggle(p,"Name Tag",function(v) Config.ESP.ShowName=v end)
    Toggle(p,"Health Bar",function(v) Config.ESP.ShowHP=v end)
    Toggle(p,"Distance",function(v) Config.ESP.ShowDist=v end)
    task.defer(r)
end

-- TAB: GAME
do
    local p,r=AddTab("Game")
    Section(p,"SCORE + KILLFEED")
    Toggle(p,"Score HUD (Blue/Red)",function(v) Config.ScoreHUD.Enabled=v; BuildScoreHUD() end,Color3.fromRGB(80,150,255))
    Toggle(p,"Kill Feed",function(v) Config.KillFeed.Enabled=v end,Color3.fromRGB(255,180,50))

    Section(p,"AUTO SPIN WHEEL")
    Toggle(p,"Auto Spin",function(v) Config.AutoSpin.Enabled=v; if v then StartAutoSpin() end end,Color3.fromRGB(255,220,50))
    MakeSlider(p,"Spin Delay s",math.floor(Config.AutoSpin.Delay),1,10,function(v) Config.AutoSpin.Delay=v end)
    local spinLbl_=Instance.new("Frame",p); spinLbl_.Size=UDim2.new(1,0,0,26); spinLbl_.BackgroundColor3=Color3.fromRGB(10,6,6); spinLbl_.BorderSizePixel=0
    Instance.new("UICorner",spinLbl_).CornerRadius=UDim.new(0,6)
    local spinTxt=Instance.new("TextLabel",spinLbl_); spinTxt.Size=UDim2.new(1,-10,1,-6); spinTxt.Position=UDim2.new(0,5,0,3)
    spinTxt.BackgroundTransparency=1; spinTxt.Text="Total spins: 0"; spinTxt.TextColor3=Color3.fromRGB(255,220,100)
    spinTxt.Font=Enum.Font.GothamBold; spinTxt.TextSize=11; spinTxt.TextXAlignment=Enum.TextXAlignment.Left
    Core:Add(RunService.Heartbeat:Connect(function() pcall(function() spinTxt.Text="Total spins: "..spinCount end) end))

    Section(p,"REDEEM CODE")
    local codeInput=Instance.new("Frame",p); codeInput.Size=UDim2.new(1,0,0,32); codeInput.BackgroundColor3=Color3.fromRGB(18,8,8); codeInput.BorderSizePixel=0
    Instance.new("UICorner",codeInput).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",codeInput).Color=Color3.fromRGB(100,30,30)
    local codeBox=Instance.new("TextBox",codeInput); codeBox.Size=UDim2.new(0.7,0,1,-6); codeBox.Position=UDim2.new(0,4,0,3)
    codeBox.BackgroundTransparency=1; codeBox.Text=""; codeBox.PlaceholderText="Masukkan kode..."
    codeBox.TextColor3=Color3.fromRGB(255,200,200); codeBox.PlaceholderColor3=Color3.fromRGB(120,80,80)
    codeBox.Font=Enum.Font.Gotham; codeBox.TextSize=11; codeBox.TextXAlignment=Enum.TextXAlignment.Left; codeBox.ClearTextOnFocus=false
    local redeemBtn=Instance.new("TextButton",codeInput); redeemBtn.Size=UDim2.new(0.28,0,1,-6); redeemBtn.Position=UDim2.new(0.72,0,0,3)
    redeemBtn.BackgroundColor3=Color3.fromRGB(100,20,20); redeemBtn.Text="Redeem"; redeemBtn.TextColor3=Color3.fromRGB(255,255,255)
    redeemBtn.Font=Enum.Font.GothamBold; redeemBtn.TextSize=10; redeemBtn.BorderSizePixel=0
    Instance.new("UICorner",redeemBtn).CornerRadius=UDim.new(0,5)
    Core:Add(redeemBtn.MouseButton1Click:Connect(function()
        local code=codeBox.Text
        if code and #code>0 then
            local result=Invoke(R.RedeemCode,code)
            Toast(result and "Berhasil!" or "Gagal/Invalid",not not result)
        end
    end))

    task.defer(r)
end

-- TAB: MOVE
do
    local p,r=AddTab("Move")
    Section(p,"MOVEMENT")
    Toggle(p,"Speed Hack",function(v) Config.Speed.Enabled=v; if v then StartSpeed() end end,THEME.pri)
    MakeSlider(p,"Speed Value",Config.Speed.Value,16,200,function(v)
        Config.Speed.Value=v
        if Config.Speed.Enabled then
            local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=v end
        end
    end)
    Toggle(p,"Noclip",function(v) Config.Noclip.Enabled=v end,THEME.pri)
    Toggle(p,"Infinite Jump",function(v) Config.InfJump.Enabled=v; SetInfJump(v) end,THEME.pri)
    task.defer(r)
end

-- TAB: INFO
do
    local p,r=AddTab("Info")
    Section(p,"REMOTE STATUS")
    local loaded=0; for _,v in pairs(R) do if v then loaded=loaded+1 end end
    local ic=Instance.new("Frame",p); ic.Size=UDim2.new(1,0,0,80); ic.BackgroundColor3=Color3.fromRGB(10,6,6); ic.BorderSizePixel=0
    Instance.new("UICorner",ic).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",ic).Color=Color3.fromRGB(100,30,30)
    local il=Instance.new("TextLabel",ic); il.Size=UDim2.new(1,-14,1,-8); il.Position=UDim2.new(0,7,0,4)
    il.BackgroundTransparency=1
    il.Text=string.format("Remote: %d loaded\nShootGun: %s | KnifeStab: %s\nKnifeThrow: %s | Spin: %s\nRedeemCode: %s | VoteMap: %s",
        loaded,
        R.ShootGun and "OK" or "NO",
        R.KnifeStab and "OK" or "NO",
        R.KnifeThrow and "OK" or "NO",
        R.RequestSpin and "OK" or "NO",
        R.RedeemCode and "OK" or "NO",
        R.VoteForMap and "OK" or "NO"
    )
    il.TextColor3=Color3.fromRGB(220,150,150); il.Font=Enum.Font.Code; il.TextSize=10
    il.TextXAlignment=Enum.TextXAlignment.Left; il.TextWrapped=true
    task.defer(r)
end

print("[NEXUS] PvS Duel Suite - LOADED!")
print("[NEXUS] Remote loaded: " .. (function() local n=0; for _,v in pairs(R) do if v then n=n+1 end end; return n end)())

end)

-- Error handler
if not ok then
    pcall(function()
        local sg=Instance.new("ScreenGui")
        sg.Name="NexError"; sg.DisplayOrder=99999
        local p2=pcall(function() sg.Parent=game:GetService("CoreGui") end)
        if not p2 then sg.Parent=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
        local f=Instance.new("Frame",sg); f.Size=UDim2.new(0,360,0,80); f.Position=UDim2.new(0.5,-180,0.5,-40)
        f.BackgroundColor3=Color3.fromRGB(80,10,10); f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
        local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-10,1,-10); l.Position=UDim2.new(0,5,0,5)
        l.BackgroundTransparency=1; l.Text="NEXUS ERROR:\n"..tostring(err)
        l.TextColor3=Color3.fromRGB(255,180,180); l.Font=Enum.Font.Gotham; l.TextSize=10
        l.TextWrapped=true; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextYAlignment=Enum.TextYAlignment.Top
        task.delay(10,function() pcall(function() sg:Destroy() end) end)
    end)
    warn("[NEXUS] Error: "..tostring(err))
end
