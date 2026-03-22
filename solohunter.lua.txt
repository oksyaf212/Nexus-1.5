--[[
    NEXUS Solo Hunter Suite
    Game: Solo Hunter (RPG Dungeon)
    Platform: Delta Executor Android
]]

local ENV_KEY="NexusSoloHunter"
if getgenv()[ENV_KEY] then pcall(function() getgenv()[ENV_KEY]:Destroy() end) end

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local CoreGui=game:GetService("CoreGui")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local LocalPlayer=Players.LocalPlayer
local SafeGUI=(pcall(function() return CoreGui.Name end)) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local Camera=Workspace.CurrentCamera

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

local RS=ReplicatedStorage
local RemoteServices=RS:FindFirstChild("RemoteServices")
local function GetR(parent,...)
    local obj=parent
    for _,name in ipairs({...}) do
        if not obj then return nil end
        obj=obj:FindFirstChild(name)
    end
    return obj
end

local R={}
R.UseWeapon=GetR(RemoteServices,"CombatService","RF","UseWeapon")
R.CancelAtk=GetR(RemoteServices,"CombatService","RF","CancelAttacks")
R.CollectDrop=GetR(RemoteServices,"DropsService","RF","CollectDrop")
R.DropCreated=GetR(RemoteServices,"DropsService","RE","DropCreatedSignal")
R.DropRemoved=GetR(RemoteServices,"DropsService","RE","DropRemovedSignal")
R.OpenChest=GetR(RemoteServices,"BossDropsService","RF","OpenChest")
R.ClaimChests=GetR(RemoteServices,"BossDropsService","RF","ClaimAvailableChests")
R.SpawnChest=GetR(RemoteServices,"BossDropsService","RE","SpawnChest")
R.RequestQuest=GetR(RemoteServices,"QuestsV2Service","RF","RequestQuest")
R.GetQuests=GetR(RemoteServices,"QuestsV2Service","RF","GetActiveQuests")
R.TurnIn=GetR(RemoteServices,"QuestsV2Service","RF","TurnInQuest")
R.QuestDone=GetR(RemoteServices,"QuestsV2Service","RE","QuestReadyToTurnIn")
R.AssignQuests=GetR(RemoteServices,"QuestsService","RF","AssignQuests")
R.UseHeal=GetR(RemoteServices,"HealingService","RF","UseHeal")
R.UseMana=GetR(RemoteServices,"HealingService","RF","UseMana")
R.SellAll=GetR(RemoteServices,"InventoryService","RF","SellAllLootMaterial")

local Config={
    AutoAttack={Enabled=false,MinDelay=0.12,MaxDelay=0.22,SkipAnim=true,Range=50},
    AutoCollect={Enabled=false,Range=150},
    AutoQuest={Enabled=false,Delay=2.0},
    AutoHeal={Enabled=false,HPThreshold=50},
    AutoSell={Enabled=false,Interval=60},
    ESP={Enabled=false,ShowBox=false,ShowName=false,ShowHealth=false,ShowDistance=false,MaxDist=500},
    Speed={Enabled=false,Value=60},
}

local function ShowToast(msg,isOn)
    pcall(function()
        local ex=SafeGUI:FindFirstChild("SHToast"); if ex then ex:Destroy() end
        local sg=Instance.new("ScreenGui",SafeGUI)
        sg.Name="SHToast"; sg.ResetOnSpawn=false; sg.DisplayOrder=9999; Core:Add(sg)
        local f=Instance.new("Frame",sg)
        f.Size=UDim2.new(0,220,0,28); f.Position=UDim2.new(0.5,-110,0.85,0)
        f.BackgroundColor3=isOn and Color3.fromRGB(10,50,20) or Color3.fromRGB(60,10,10)
        f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,14)
        local fs=Instance.new("UIStroke",f); fs.Color=isOn and Color3.fromRGB(40,200,60) or Color3.fromRGB(200,50,50); fs.Thickness=1
        local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=(isOn and "✅ " or "❌ ")..msg; l.TextColor3=Color3.fromRGB(255,255,255)
        l.Font=Enum.Font.GothamBold; l.TextSize=11
        task.delay(2,function()
            for i=1,10 do pcall(function() f.BackgroundTransparency=i/10; l.TextTransparency=i/10 end); task.wait(0.04) end
            pcall(function() sg:Destroy() end)
        end)
    end)
end

local function Invoke(remote,...) if not remote then return nil end; local ok,r=pcall(function() return remote:InvokeServer(...) end); return ok and r or nil end
local function Fire(remote,...) if not remote then return end; pcall(function() remote:FireServer(...) end) end
local function HumanWait(mn,mx) task.wait(math.max(0.05,mn+(math.random()*(mx-mn))+(math.random(-5,5)/1000))) end

local function GetNearestMonster(radius)
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local nearest,minDist=nil,radius or math.huge
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj~=LocalPlayer.Character then
            local hum=obj:FindFirstChildOfClass("Humanoid"); local hrp=obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health>0 then
                local isPlayer=false
                for _,pl in ipairs(Players:GetPlayers()) do if pl.Character==obj then isPlayer=true; break end end
                if not isPlayer then
                    local dist=(hrp.Position-myHRP.Position).Magnitude
                    if dist<minDist then minDist=dist; nearest=obj end
                end
            end
        end
    end
    return nearest,minDist
end

-- FPS+Ping
local _fpsDraw=Drawing.new("Text"); _fpsDraw.Size=13; _fpsDraw.Center=true; _fpsDraw.Outline=true; _fpsDraw.Visible=true; _fpsDraw.ZIndex=11
Core:Add(function() pcall(function() _fpsDraw:Remove() end) end)
local _fa,_fc,_fd,_ping=0,0,0,0
Core:Add(RunService.RenderStepped:Connect(function(dt)
    _fa=_fa+dt; _fc=_fc+1
    if _fa>=0.5 then _fd=math.floor(_fc/_fa); _fa=0; _fc=0 end
    pcall(function() _ping=math.floor(LocalPlayer.NetworkPing*1000) end)
    local col=(_fd>=50 and _ping<=80) and Color3.fromRGB(80,255,80) or (_fd>=30 and _ping<=150) and Color3.fromRGB(255,220,50) or Color3.fromRGB(255,60,60)
    _fpsDraw.Color=col; _fpsDraw.Text=string.format("FPS: %d  |  Ping: %dms",_fd,_ping); _fpsDraw.Position=Vector2.new(Camera.ViewportSize.X/2,14)
end))

-- Auto Attack
local _atkCount=0
local function StartAutoAttack()
    task.spawn(function()
        while Config.AutoAttack.Enabled do
            local char=LocalPlayer.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid")
            if not(hrp and hum and hum.Health>0) then task.wait(0.5); continue end
            local target,dist=GetNearestMonster(Config.AutoAttack.Range)
            if not target then task.wait(0.3); continue end
            local tHRP=target:FindFirstChild("HumanoidRootPart"); if not tHRP then task.wait(0.1); continue end
            hrp.CFrame=tHRP.CFrame*CFrame.new(0,0,-3); task.wait(0.05)
            Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,tHRP.Position); task.wait(0.05)
            Invoke(R.UseWeapon,0,{},1.0); _atkCount=_atkCount+1
            if Config.AutoAttack.SkipAnim then task.wait(0.03); Invoke(R.CancelAtk,LocalPlayer) end
            HumanWait(Config.AutoAttack.MinDelay,Config.AutoAttack.MaxDelay)
        end
    end)
end

-- Auto Collect
local _pendingDrops={}; local _pendingChests={}
if R.DropCreated then Core:Add(R.DropCreated.OnClientEvent:Connect(function(data) if data then table.insert(_pendingDrops,data) end end)) end
if R.DropRemoved then Core:Add(R.DropRemoved.OnClientEvent:Connect(function(id) for i,d in ipairs(_pendingDrops) do if (d.id or d)==id then table.remove(_pendingDrops,i); break end end end)) end
if R.SpawnChest then Core:Add(R.SpawnChest.OnClientEvent:Connect(function(data) if data then table.insert(_pendingChests,data) end end)) end

local _collectConn
local function StartAutoCollect()
    if _collectConn then _collectConn:Disconnect(); _collectConn=nil end
    local t=0
    _collectConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.AutoCollect.Enabled then _collectConn:Disconnect(); _collectConn=nil; return end
        t=t+dt; if t<0.5 then return end; t=0
        task.spawn(function()
            local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
            local snap={table.unpack(_pendingDrops)}
            for _,drop in ipairs(snap) do
                local id=drop.id or drop
                if drop.position or drop.Position then
                    local pos=drop.position or drop.Position
                    if (pos-myHRP.Position).Magnitude<=Config.AutoCollect.Range then myHRP.CFrame=CFrame.new(pos+Vector3.new(0,3,0)); task.wait(0.05) end
                end
                Invoke(R.CollectDrop,id); task.wait(0.05)
            end
            Invoke(R.ClaimChests)
            for _,chest in ipairs({table.unpack(_pendingChests)}) do Invoke(R.OpenChest,chest); task.wait(0.1) end
        end)
    end)
end
Core:Add(function() if _collectConn then _collectConn:Disconnect() end end)

-- Auto Quest
local _questConn; local _questCount=0
if R.QuestDone then
    Core:Add(R.QuestDone.OnClientEvent:Connect(function(qid)
        if Config.AutoQuest.Enabled then task.spawn(function() task.wait(0.5); Invoke(R.TurnIn,qid); _questCount=_questCount+1; ShowToast("Quest #".._questCount.." done!",true) end) end
    end))
end
local function StartAutoQuest()
    if _questConn then _questConn:Disconnect(); _questConn=nil end
    local t=0
    _questConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.AutoQuest.Enabled then _questConn:Disconnect(); _questConn=nil; return end
        t=t+dt; if t<Config.AutoQuest.Delay then return end; t=0
        task.spawn(function()
            local active=Invoke(R.GetQuests)
            if active then for _,q in pairs(active) do if q.completed or q.readyToTurnIn then Invoke(R.TurnIn,q.id or q); _questCount=_questCount+1; task.wait(0.3) end end
            else Invoke(R.RequestQuest); task.wait(0.5); Invoke(R.AssignQuests) end
        end)
    end)
end
Core:Add(function() if _questConn then _questConn:Disconnect() end end)

-- Auto Heal
local _healConn
local function StartAutoHeal()
    if _healConn then _healConn:Disconnect(); _healConn=nil end
    local t=0
    _healConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.AutoHeal.Enabled then _healConn:Disconnect(); _healConn=nil; return end
        t=t+dt; if t<0.5 then return end; t=0
        task.spawn(function()
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if not hum then return end
            if (hum.Health/math.max(hum.MaxHealth,1))*100<Config.AutoHeal.HPThreshold then Invoke(R.UseHeal); Invoke(R.UseMana) end
        end)
    end)
end
Core:Add(function() if _healConn then _healConn:Disconnect() end end)

-- Auto Sell
local _sellConn
local function StartAutoSell()
    if _sellConn then _sellConn:Disconnect(); _sellConn=nil end
    local t=0
    _sellConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.AutoSell.Enabled then _sellConn:Disconnect(); _sellConn=nil; return end
        t=t+dt; if t<Config.AutoSell.Interval then return end; t=0
        task.spawn(function() local r=Invoke(R.SellAll); if r then ShowToast("Sold!",true) end end)
    end)
end
Core:Add(function() if _sellConn then _sellConn:Disconnect() end end)

-- Speed
local _speedConn
local function StartSpeed()
    if _speedConn then _speedConn:Disconnect(); _speedConn=nil end
    _speedConn=RunService.Heartbeat:Connect(function()
        if not Config.Speed.Enabled then
            _speedConn:Disconnect(); _speedConn=nil
            local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16 end; return
        end
        local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=Config.Speed.Value end
    end)
end
Core:Add(function() if _speedConn then _speedConn:Disconnect() end; local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16 end end)
Core:Add(LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); if Config.Speed.Enabled then StartSpeed() end; if Config.AutoAttack.Enabled then StartAutoAttack() end end))

-- ESP
local ESPCache={}
local function CreateESP(player)
    if player==LocalPlayer or ESPCache[player] then return end
    local c={}; local ec=Color3.fromRGB(255,50,50)
    local function nL(t) local l=Drawing.new("Line"); l.Color=ec; l.Thickness=t; l.Visible=false; l.ZIndex=4; return l end
    c.BoxT=nL(1.5); c.BoxB=nL(1.5); c.BoxL=nL(1.5); c.BoxR=nL(1.5)
    local txt=Drawing.new("Text"); txt.Size=12; txt.Center=true; txt.Outline=true; txt.Color=ec; txt.Visible=false; txt.ZIndex=5; c.Text=txt
    local hpBg=Drawing.new("Line"); hpBg.Thickness=3; hpBg.Color=Color3.new(0,0,0); hpBg.Visible=false; c.HpBg=hpBg
    local hpFg=Drawing.new("Line"); hpFg.Thickness=1.8; hpFg.Visible=false; c.HpFg=hpFg
    local dTxt=Drawing.new("Text"); dTxt.Size=10; dTxt.Center=true; dTxt.Outline=true; dTxt.Color=Color3.fromRGB(255,230,80); dTxt.Visible=false; dTxt.ZIndex=5; c.DistText=dTxt
    local hl=Instance.new("Highlight"); hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency=0.75; hl.FillColor=ec; hl.OutlineColor=ec; hl.Enabled=false; hl.Parent=CoreGui
    if player.Character then hl.Adornee=player.Character end
    c._charConn=player.CharacterAdded:Connect(function(ch) hl.Adornee=ch end); c.Highlight=hl; ESPCache[player]=c
end
local function RemoveESP(player)
    local c=ESPCache[player]; if not c then return end
    if c._charConn then pcall(function() c._charConn:Disconnect() end) end
    pcall(function() c.Highlight:Destroy() end)
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","DistText"}) do pcall(function() c[k]:Remove() end) end
    ESPCache[player]=nil
end
local function HideESP(c) c.Highlight.Enabled=false; for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","DistText"}) do c[k].Visible=false end end
for _,p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Core:Add(Players.PlayerAdded:Connect(CreateESP)); Core:Add(Players.PlayerRemoving:Connect(RemoveESP))
Core:Add(function() local s={}; for p in pairs(ESPCache) do table.insert(s,p) end; for _,p in ipairs(s) do RemoveESP(p) end end)
Core:Add(RunService.RenderStepped:Connect(function()
    for player,c in pairs(ESPCache) do
        if not Config.ESP.Enabled then HideESP(c); continue end
        local char=player.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not(char and hum and hrp and hum.Health>0) then HideESP(c); continue end
        local dist=(Camera.CFrame.Position-hrp.Position).Magnitude
        if dist>Config.ESP.MaxDist then HideESP(c); continue end
        c.Highlight.Enabled=true
        local pos,onScreen=Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","DistText"}) do c[k].Visible=false end; continue end
        local tV=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3.2,0)); local bV=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3.2,0))
        local h=math.abs(tV.Y-bV.Y); local w=h*0.45; local cx=pos.X; local lx=cx-w/2; local rx=cx+w/2
        if Config.ESP.ShowBox then
            c.BoxT.From=Vector2.new(lx,tV.Y); c.BoxT.To=Vector2.new(rx,tV.Y); c.BoxT.Visible=true
            c.BoxB.From=Vector2.new(lx,bV.Y); c.BoxB.To=Vector2.new(rx,bV.Y); c.BoxB.Visible=true
            c.BoxL.From=Vector2.new(lx,tV.Y); c.BoxL.To=Vector2.new(lx,bV.Y); c.BoxL.Visible=true
            c.BoxR.From=Vector2.new(rx,tV.Y); c.BoxR.To=Vector2.new(rx,bV.Y); c.BoxR.Visible=true
        else c.BoxT.Visible=false; c.BoxB.Visible=false; c.BoxL.Visible=false; c.BoxR.Visible=false end
        if Config.ESP.ShowName then c.Text.Text=player.Name; c.Text.Position=Vector2.new(cx,tV.Y-16); c.Text.Visible=true else c.Text.Visible=false end
        if Config.ESP.ShowDistance then c.DistText.Text=string.format("[%.0fm]",dist); c.DistText.Position=Vector2.new(cx,bV.Y+3); c.DistText.Visible=true else c.DistText.Visible=false end
        if Config.ESP.ShowHealth then
            local hp=hum.Health/math.max(hum.MaxHealth,1); local bx=lx-6
            c.HpBg.From=Vector2.new(bx,tV.Y); c.HpBg.To=Vector2.new(bx,bV.Y); c.HpBg.Visible=true
            c.HpFg.From=Vector2.new(bx,bV.Y); c.HpFg.To=Vector2.new(bx,bV.Y-h*hp); c.HpFg.Color=Color3.new(1-hp,hp,0); c.HpFg.Visible=true
        else c.HpBg.Visible=false; c.HpFg.Visible=false end
    end
end))

-- UI
local UI={_tabPages={}}
local THEME={primary=Color3.fromRGB(180,100,255),bg=Color3.fromRGB(10,6,16),topbar=Color3.fromRGB(16,8,24),card=Color3.fromRGB(16,10,24)}

function UI:Build()
    local Screen=Instance.new("ScreenGui",SafeGUI); Screen.Name="SoloHunterUI"; Screen.ResetOnSpawn=false; Screen.DisplayOrder=999; Core:Add(Screen)
    local Wrapper=Instance.new("Frame",Screen); Wrapper.Size=UDim2.new(0,255,0,460); Wrapper.Position=UDim2.new(0.04,0,0.06,0); Wrapper.BackgroundTransparency=1
    Instance.new("UICorner",Wrapper).CornerRadius=UDim.new(0,12)
    local WS=Instance.new("UIStroke",Wrapper); WS.Color=THEME.primary; WS.Thickness=1.5; self.Wrapper=Wrapper
    local Main=Instance.new("Frame",Wrapper); Main.Size=UDim2.new(1,0,1,0); Main.BackgroundColor3=THEME.bg; Main.BorderSizePixel=0; Main.ClipsDescendants=true
    Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12); self.Main=Main
    local TopBar=Instance.new("Frame",Main); TopBar.Size=UDim2.new(1,0,0,36); TopBar.BackgroundColor3=THEME.topbar; TopBar.BorderSizePixel=0
    local TL=Instance.new("TextLabel",TopBar); TL.Size=UDim2.new(1,-96,1,0); TL.Position=UDim2.new(0,11,0,0); TL.BackgroundTransparency=1; TL.Text="⚔️  SOLO HUNTER"; TL.TextColor3=THEME.primary; TL.Font=Enum.Font.GothamBold; TL.TextSize=13; TL.TextXAlignment=Enum.TextXAlignment.Left
    local PanicBtn=Instance.new("TextButton",TopBar); PanicBtn.Size=UDim2.new(0,24,0,22); PanicBtn.Position=UDim2.new(1,-90,0.5,-11); PanicBtn.BackgroundColor3=Color3.fromRGB(140,20,20); PanicBtn.Text="❌"; PanicBtn.TextColor3=Color3.fromRGB(255,255,255); PanicBtn.Font=Enum.Font.GothamBold; PanicBtn.TextSize=11; PanicBtn.BorderSizePixel=0; Instance.new("UICorner",PanicBtn).CornerRadius=UDim.new(0,5)
    Core:Add(PanicBtn.MouseButton1Click:Connect(function() Config.AutoAttack.Enabled=false; Config.AutoCollect.Enabled=false; Config.AutoQuest.Enabled=false; Config.AutoHeal.Enabled=false; Config.AutoSell.Enabled=false; Config.ESP.Enabled=false; Config.Speed.Enabled=false; ShowToast("PANIC OFF",false) end))
    local HideBtn=Instance.new("TextButton",TopBar); HideBtn.Size=UDim2.new(0,24,0,22); HideBtn.Position=UDim2.new(1,-62,0.5,-11); HideBtn.BackgroundColor3=Color3.fromRGB(40,20,60); HideBtn.Text="👁"; HideBtn.TextColor3=Color3.fromRGB(200,150,255); HideBtn.Font=Enum.Font.GothamBold; HideBtn.TextSize=11; HideBtn.BorderSizePixel=0; Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(0,5)
    local MinBtn=Instance.new("TextButton",TopBar); MinBtn.Size=UDim2.new(0,24,0,22); MinBtn.Position=UDim2.new(1,-34,0.5,-11); MinBtn.BackgroundColor3=Color3.fromRGB(30,15,45); MinBtn.Text="—"; MinBtn.TextColor3=Color3.fromRGB(200,200,200); MinBtn.Font=Enum.Font.GothamBold; MinBtn.TextSize=12; MinBtn.BorderSizePixel=0; Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,5)
    local TabBar=Instance.new("ScrollingFrame",Main); TabBar.Size=UDim2.new(1,0,0,26); TabBar.Position=UDim2.new(0,0,0,36); TabBar.BackgroundColor3=Color3.fromRGB(14,8,20); TabBar.BorderSizePixel=0; TabBar.ScrollBarThickness=2; TabBar.CanvasSize=UDim2.new(0,0,0,0); TabBar.ScrollingDirection=Enum.ScrollingDirection.X; TabBar.ScrollBarImageColor3=THEME.primary
    local TLayout=Instance.new("UIListLayout",TabBar); TLayout.FillDirection=Enum.FillDirection.Horizontal; TLayout.Padding=UDim.new(0,2); TLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    local tabPad=Instance.new("UIPadding",TabBar); tabPad.PaddingLeft=UDim.new(0,4)
    TLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TabBar.CanvasSize=UDim2.new(0,TLayout.AbsoluteContentSize.X+8,0,0) end)
    self.TabBar=TabBar
    local Content=Instance.new("Frame",Main); Content.Name="Content"; Content.Size=UDim2.new(1,0,1,-62); Content.Position=UDim2.new(0,0,0,62); Content.BackgroundTransparency=1; self.Content=Content
    local Pill=Instance.new("TextButton",Screen); Pill.Size=UDim2.new(0,115,0,24); Pill.Position=Wrapper.Position; Pill.BackgroundColor3=Color3.fromRGB(25,10,40); Pill.Text="⚔️ SOLO HUNTER"; Pill.TextColor3=THEME.primary; Pill.Font=Enum.Font.GothamBold; Pill.TextSize=10; Pill.BorderSizePixel=0; Pill.Visible=false
    Instance.new("UICorner",Pill).CornerRadius=UDim.new(0,12); local PS=Instance.new("UIStroke",Pill); PS.Color=THEME.primary; PS.Thickness=1; self.Pill=Pill
    Core:Add(HideBtn.MouseButton1Click:Connect(function() Pill.Position=UDim2.new(Wrapper.Position.X.Scale,Wrapper.Position.X.Offset,Wrapper.Position.Y.Scale,Wrapper.Position.Y.Offset); Wrapper.Visible=false; Pill.Visible=true end))
    Core:Add(Pill.MouseButton1Click:Connect(function() Wrapper.Position=Pill.Position; Wrapper.Visible=true; Pill.Visible=false end))
    local drag,ds,sp=false,nil,nil
    Core:Add(TopBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; ds=i.Position; sp=Wrapper.Position end end))
    Core:Add(UserInputService.InputChanged:Connect(function(i) if not drag then return end; if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then local d=i.Position-ds; Wrapper.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end))
    Core:Add(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end))
    local mini=false
    Core:Add(MinBtn.MouseButton1Click:Connect(function() mini=not mini; Content.Visible=not mini; TabBar.Visible=not mini; Wrapper.Size=mini and UDim2.new(0,255,0,36) or UDim2.new(0,255,0,460); MinBtn.Text=mini and "+" or "—" end))
end

function UI:AddTab(name)
    local page=Instance.new("ScrollingFrame",self.Content); page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1; page.BorderSizePixel=0; page.ScrollBarThickness=4; page.ScrollBarImageColor3=THEME.primary; page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false; page.ScrollingEnabled=true
    local layout=Instance.new("UIListLayout",page); layout.Padding=UDim.new(0,4); layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local pad=Instance.new("UIPadding",page); pad.PaddingTop=UDim.new(0,6); pad.PaddingLeft=UDim.new(0,5); pad.PaddingRight=UDim.new(0,5); pad.PaddingBottom=UDim.new(0,10)
    Core:Add(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20) end))
    local function refresh() task.wait(); page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20) end
    local btn=Instance.new("TextButton",self.TabBar); btn.Size=UDim2.new(0,42,0,20); btn.BackgroundColor3=Color3.fromRGB(22,12,34); btn.Text=name; btn.TextColor3=Color3.fromRGB(140,80,200); btn.Font=Enum.Font.GothamSemibold; btn.TextSize=9; btn.BorderSizePixel=0; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    local entry={page=page,btn=btn}; table.insert(self._tabPages,entry)
    local function activate() for _,t in ipairs(self._tabPages) do t.page.Visible=false; t.btn.BackgroundColor3=Color3.fromRGB(22,12,34); t.btn.TextColor3=Color3.fromRGB(140,80,200) end; page.Visible=true; btn.BackgroundColor3=THEME.primary; btn.TextColor3=Color3.fromRGB(255,255,255); task.defer(refresh) end
    Core:Add(btn.MouseButton1Click:Connect(activate)); if #self._tabPages==1 then activate() end; return page,refresh
end

function UI:Section(parent,text) local f=Instance.new("Frame",parent); f.Size=UDim2.new(1,0,0,16); f.BackgroundTransparency=1; local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Text="── "..text.." ──"; l.TextColor3=THEME.primary; l.Font=Enum.Font.GothamBold; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Center end

function UI:Toggle(parent,label,callback,col)
    local color=col or THEME.primary; local state=false
    local card=Instance.new("Frame",parent); card.Size=UDim2.new(1,0,0,26); card.BackgroundColor3=THEME.card; card.BorderSizePixel=0; Instance.new("UICorner",card).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",card); lbl.Size=UDim2.new(1,-48,1,0); lbl.Position=UDim2.new(0,9,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(210,185,240); lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pill=Instance.new("TextButton",card); pill.Size=UDim2.new(0,32,0,15); pill.Position=UDim2.new(1,-40,0.5,-7); pill.BackgroundColor3=Color3.fromRGB(35,20,50); pill.Text=""; pill.BorderSizePixel=0; Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",pill); knob.Size=UDim2.new(0,11,0,11); knob.Position=UDim2.new(0,2,0.5,-5); knob.BackgroundColor3=Color3.fromRGB(120,80,160); knob.BorderSizePixel=0; Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    Core:Add(pill.MouseButton1Click:Connect(function() state=not state; if state then pill.BackgroundColor3=color; knob.Position=UDim2.new(1,-13,0.5,-5); knob.BackgroundColor3=Color3.fromRGB(255,255,255) else pill.BackgroundColor3=Color3.fromRGB(35,20,50); knob.Position=UDim2.new(0,2,0.5,-5); knob.BackgroundColor3=Color3.fromRGB(120,80,160) end; ShowToast(label,state); pcall(callback,state) end))
end

function UI:MakeSlider(parent,labelText,initVal,minVal,maxVal,onChange)
    local fc=Instance.new("Frame",parent); fc.Size=UDim2.new(1,0,0,42); fc.BackgroundColor3=THEME.card; fc.BorderSizePixel=0; Instance.new("UICorner",fc).CornerRadius=UDim.new(0,6)
    local fl=Instance.new("TextLabel",fc); fl.Size=UDim2.new(1,-10,0,18); fl.Position=UDim2.new(0,9,0,3); fl.BackgroundTransparency=1; fl.Text=labelText..": "..initVal; fl.TextColor3=Color3.fromRGB(190,160,220); fl.Font=Enum.Font.GothamSemibold; fl.TextSize=11; fl.TextXAlignment=Enum.TextXAlignment.Left
    local tr=Instance.new("Frame",fc); tr.Size=UDim2.new(1,-18,0,6); tr.Position=UDim2.new(0,9,0,28); tr.BackgroundColor3=Color3.fromRGB(35,20,50); tr.BorderSizePixel=0; Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local ratio=math.clamp((initVal-minVal)/(maxVal-minVal),0,1)
    local fi=Instance.new("Frame",tr); fi.Size=UDim2.new(ratio,0,1,0); fi.BackgroundColor3=THEME.primary; fi.BorderSizePixel=0; Instance.new("UICorner",fi).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("TextButton",tr); kn.Size=UDim2.new(0,14,0,14); kn.AnchorPoint=Vector2.new(0.5,0.5); kn.Position=UDim2.new(ratio,0,0.5,0); kn.BackgroundColor3=Color3.fromRGB(255,255,255); kn.Text=""; kn.BorderSizePixel=0; Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local ds=false
    Core:Add(kn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true end end))
    Core:Add(UserInputService.InputChanged:Connect(function(i) if not ds then return end; if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then local tp=tr.AbsolutePosition; local ts=tr.AbsoluteSize; local rx=math.clamp((i.Position.X-tp.X)/ts.X,0,1); local val=math.floor(minVal+(maxVal-minVal)*rx); fi.Size=UDim2.new(rx,0,1,0); kn.Position=UDim2.new(rx,0,0.5,0); fl.Text=labelText..": "..val; pcall(onChange,val) end end))
    Core:Add(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then ds=false end end))
end

function UI:ActionBtn(parent,label,col,cb)
    local btn=Instance.new("TextButton",parent); btn.Size=UDim2.new(1,0,0,28); btn.BackgroundColor3=col or THEME.primary; btn.Text=label; btn.TextColor3=Color3.fromRGB(255,255,255); btn.Font=Enum.Font.GothamBold; btn.TextSize=11; btn.BorderSizePixel=0; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    Core:Add(btn.MouseButton1Click:Connect(function() local oc=btn.BackgroundColor3; btn.BackgroundColor3=Color3.fromRGB(255,255,255); task.delay(0.12,function() btn.BackgroundColor3=oc end); pcall(cb) end))
end

-- BUILD UI
UI:Build()

do local p,r=UI:AddTab("Atk")
    UI:Section(p,"AUTO ATTACK")
    UI:Toggle(p,"⚔️ Auto Attack",function(v) Config.AutoAttack.Enabled=v; if v then StartAutoAttack() end end,Color3.fromRGB(220,50,255))
    UI:Toggle(p,"⚡ Skip Animasi",function(v) Config.AutoAttack.SkipAnim=v end,Color3.fromRGB(180,80,255))
    UI:MakeSlider(p,"Min Delay ms",math.floor(Config.AutoAttack.MinDelay*1000),50,500,function(v) Config.AutoAttack.MinDelay=v/1000 end)
    UI:MakeSlider(p,"Max Delay ms",math.floor(Config.AutoAttack.MaxDelay*1000),100,800,function(v) Config.AutoAttack.MaxDelay=v/1000 end)
    UI:MakeSlider(p,"Range stud",Config.AutoAttack.Range,10,500,function(v) Config.AutoAttack.Range=v end)
    local statsCard=Instance.new("Frame",p); statsCard.Size=UDim2.new(1,0,0,28); statsCard.BackgroundColor3=Color3.fromRGB(10,6,18); statsCard.BorderSizePixel=0; Instance.new("UICorner",statsCard).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",statsCard).Color=Color3.fromRGB(80,40,160)
    local statsLbl=Instance.new("TextLabel",statsCard); statsLbl.Size=UDim2.new(1,-10,1,-6); statsLbl.Position=UDim2.new(0,5,0,3); statsLbl.BackgroundTransparency=1; statsLbl.Text="⚔️ Count: 0"; statsLbl.TextColor3=Color3.fromRGB(180,140,255); statsLbl.Font=Enum.Font.GothamBold; statsLbl.TextSize=11; statsLbl.TextXAlignment=Enum.TextXAlignment.Left
    Core:Add(RunService.Heartbeat:Connect(function() pcall(function() local t,d=GetNearestMonster(Config.AutoAttack.Range); statsLbl.Text=string.format("⚔️ Count: %d | %s",_atkCount,t and string.format("%s %.0fm",t.Name,d or 0) or "no target") end) end))
    task.defer(r) end

do local p,r=UI:AddTab("Farm")
    UI:Section(p,"AUTO COLLECT"); UI:Toggle(p,"Auto Collect",function(v) Config.AutoCollect.Enabled=v; if v then StartAutoCollect() end end,Color3.fromRGB(255,180,50))
    UI:MakeSlider(p,"Collect Range",Config.AutoCollect.Range,50,500,function(v) Config.AutoCollect.Range=v end)
    UI:Section(p,"AUTO QUEST"); UI:Toggle(p,"Auto Quest",function(v) Config.AutoQuest.Enabled=v; if v then StartAutoQuest() end end,Color3.fromRGB(80,200,255))
    UI:Section(p,"AUTO HEAL"); UI:Toggle(p,"Auto Heal+Mana",function(v) Config.AutoHeal.Enabled=v; if v then StartAutoHeal() end end,Color3.fromRGB(80,220,80))
    UI:MakeSlider(p,"HP %",Config.AutoHeal.HPThreshold,10,90,function(v) Config.AutoHeal.HPThreshold=v end)
    UI:Section(p,"AUTO SELL"); UI:Toggle(p,"Auto Sell",function(v) Config.AutoSell.Enabled=v; if v then StartAutoSell() end end,Color3.fromRGB(255,200,50))
    UI:ActionBtn(p,"💰 Jual Sekarang",Color3.fromRGB(140,90,10),function() local r2=Invoke(R.SellAll); ShowToast(r2 and "Sold!" or "Gagal",not not r2) end)
    local qCard=Instance.new("Frame",p); qCard.Size=UDim2.new(1,0,0,26); qCard.BackgroundColor3=Color3.fromRGB(10,6,18); qCard.BorderSizePixel=0; Instance.new("UICorner",qCard).CornerRadius=UDim.new(0,6)
    local qLbl=Instance.new("TextLabel",qCard); qLbl.Size=UDim2.new(1,-10,1,-6); qLbl.Position=UDim2.new(0,5,0,3); qLbl.BackgroundTransparency=1; qLbl.Text="📋 Quest: 0"; qLbl.TextColor3=Color3.fromRGB(100,200,255); qLbl.Font=Enum.Font.GothamBold; qLbl.TextSize=11; qLbl.TextXAlignment=Enum.TextXAlignment.Left
    Core:Add(RunService.Heartbeat:Connect(function() pcall(function() qLbl.Text="📋 Quest completed: ".._questCount end) end))
    task.defer(r) end

do local p,r=UI:AddTab("ESP")
    UI:Section(p,"PLAYER ESP"); UI:Toggle(p,"Aktifkan ESP",function(v) Config.ESP.Enabled=v end,Color3.fromRGB(30,210,80))
    UI:Toggle(p,"Box ESP",function(v) Config.ESP.ShowBox=v end); UI:Toggle(p,"Name Tag",function(v) Config.ESP.ShowName=v end)
    UI:Toggle(p,"Health Bar",function(v) Config.ESP.ShowHealth=v end); UI:Toggle(p,"Distance",function(v) Config.ESP.ShowDistance=v end)
    task.defer(r) end

do local p,r=UI:AddTab("Move")
    UI:Section(p,"SPEED"); UI:Toggle(p,"Speed Hack",function(v) Config.Speed.Enabled=v; if v then StartSpeed() end end,THEME.primary)
    UI:MakeSlider(p,"Speed",Config.Speed.Value,16,200,function(v) Config.Speed.Value=v; if Config.Speed.Enabled then local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=v end end end)
    task.defer(r) end

print("✅ NEXUS Solo Hunter Loaded!")
print("⚔️ UseWeapon(0,{},1.0) + CancelAttacks")
print("🌾 Auto Farm + Quest + Heal + Sell")
