```lua
-- NEXUS PvS Duel - GUI First Build
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local CoreGui=game:GetService("CoreGui")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local LocalPlayer=Players.LocalPlayer
local Camera=workspace.CurrentCamera

-- SafeGUI
local SafeGUI
pcall(function() local _=CoreGui.Name; SafeGUI=CoreGui end)
if not SafeGUI then SafeGUI=LocalPlayer:WaitForChild("PlayerGui") end

-- Hapus instance lama
if getgenv().NexPvS then pcall(function() getgenv().NexPvS:Destroy() end) end
local Conns={}
getgenv().NexPvS={Destroy=function()
    for _,c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    pcall(function() SafeGUI:FindFirstChild("NexPvSDuelUI"):Destroy() end)
    pcall(function() SafeGUI:FindFirstChild("NexToast"):Destroy() end)
end}
local function AddConn(c) table.insert(Conns,c); return c end

-- Config
local Config={
    SilentAim=false, RapidFire=false, RapidDelay=0.15,
    AutoKnife=false, KnifeDelay=0.08,
    AutoThrow=false, ThrowDelay=0.3,
    AutoSpin=false,  SpinDelay=1.5,
    KillFeed=false,  ScoreHUD=false,
    ESPEnabled=false,ShowBox=false,ShowName=false,ShowHP=false,ShowDist=false,
    Speed=false,     SpeedVal=60,
    Noclip=false,    InfJump=false,
}

-- Remotes (boleh nil)
local Rem=ReplicatedStorage:FindFirstChild("Remotes")
local REvt=ReplicatedStorage:FindFirstChild("RemoteEvents")
local function GR(p,...) local o=p; for _,n in ipairs({...}) do if not o then return nil end; o=o:FindFirstChild(n) end; return o end
local R={
    ShootGun   =GR(Rem,"Weapons","ShootGun"),
    KnifeStab  =GR(Rem,"Weapons","KnifeStab"),
    KnifeThrow =GR(Rem,"Weapons","KnifeThrow"),
    RequestSpin=GR(Rem,"Wheel","RequestSpin"),
    RedeemCode =GR(Rem,"Data","RedeemCode"),
    VoteForMap =GR(Rem,"Round","VoteForMap"),
    ReplicaSet =GR(REvt,"ReplicaSet"),
    ReplicaIns =GR(REvt,"ReplicaTableInsert"),
}

-- Util
local function Fire(r,...) if r then pcall(function() r:FireServer(...) end) end end
local function Inv(r,...) if not r then return nil end; local ok,v=pcall(function() return r:InvokeServer(...) end); return ok and v or nil end
local function HW(mn,mx) task.wait(math.max(0.05,mn+math.random()*(mx-mn))) end
local function GetTool() local c=LocalPlayer.Character; return c and c:FindFirstChildOfClass("Tool") end
local function GetHRP() local c=LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function GetNearest(rad)
    local myH=GetHRP(); if not myH then return nil end
    local best,bd=nil,rad or 9999
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LocalPlayer then continue end
        local c=pl.Character; local h=c and c:FindFirstChild("HumanoidRootPart"); local hm=c and c:FindFirstChildOfClass("Humanoid")
        if h and hm and hm.Health>0 then
            local d=(h.Position-myH.Position).Magnitude
            if d<bd then bd=d; best={pl=pl,hrp=h,char=c,hum=hm} end
        end
    end
    return best
end

-- Toast
local function Toast(msg,on)
    pcall(function()
        local ex=SafeGUI:FindFirstChild("NexToast"); if ex then ex:Destroy() end
        local sg=Instance.new("ScreenGui",SafeGUI); sg.Name="NexToast"; sg.ResetOnSpawn=false; sg.DisplayOrder=9999
        local f=Instance.new("Frame",sg); f.Size=UDim2.new(0,200,0,26); f.Position=UDim2.new(0.5,-100,0.88,0)
        f.BackgroundColor3=on and Color3.fromRGB(10,50,20) or Color3.fromRGB(60,10,10); f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,13)
        Instance.new("UIStroke",f).Color=on and Color3.fromRGB(40,200,60) or Color3.fromRGB(200,50,50)
        local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
        l.Text=(on and "[ON] " or "[OFF] ")..msg; l.TextColor3=Color3.fromRGB(255,255,255); l.Font=Enum.Font.GothamBold; l.TextSize=11
        task.delay(2,function()
            for i=1,10 do pcall(function() f.BackgroundTransparency=i/10; l.TextTransparency=i/10 end); task.wait(0.04) end
            pcall(function() sg:Destroy() end)
        end)
    end)
end

-- FPS+Ping
local fpD=Drawing.new("Text"); fpD.Size=13; fpD.Center=true; fpD.Outline=true; fpD.Visible=true; fpD.ZIndex=11
table.insert(Conns,function() pcall(function() fpD:Remove() end) end)
local fa,fc,fd,fp=0,0,0,0
AddConn(RunService.RenderStepped:Connect(function(dt)
    fa=fa+dt; fc=fc+1; if fa>=0.5 then fd=math.floor(fc/fa); fa=0; fc=0 end
    pcall(function() fp=math.floor(LocalPlayer.NetworkPing*1000) end)
    local col=(fd>=50 and fp<=80) and Color3.fromRGB(80,255,80) or (fd>=30 and fp<=150) and Color3.fromRGB(255,220,50) or Color3.fromRGB(255,60,60)
    fpD.Color=col; fpD.Text=("FPS: %d  |  Ping: %dms"):format(fd,fp); fpD.Position=Vector2.new(Camera.ViewportSize.X/2,14)
end))

-- ======================== FEATURES ========================

-- Silent Aim
pcall(function()
    local mt=getrawmetatable(game); local old=mt.__namecall; setreadonly(mt,false)
    mt.__namecall=newcclosure(function(self,...)
        if Config.SilentAim and getnamecallmethod()=="FireServer" then
            local ok2,nm=pcall(function() return self:GetFullName() end)
            if ok2 and nm:find("ShootGun") then
                local a={...}
                if a[3] and type(a[3])=="table" then
                    local t=GetNearest(600)
                    if t then local hd=t.char:FindFirstChild("Head"); if hd then a[3].HitPosition=hd.Position end end
                    return old(self,table.unpack(a))
                end
            end
        end
        return old(self,...)
    end)
    setreadonly(mt,true)
    table.insert(Conns,function() pcall(function() local mt2=getrawmetatable(game); setreadonly(mt2,false); mt2.__namecall=old; setreadonly(mt2,true) end) end)
end)

-- Rapid Fire
local rfN=0
local function StartRF()
    task.spawn(function()
        while Config.RapidFire do
            local tool=GetTool(); local hrp=GetHRP(); local t=GetNearest(300)
            if tool and hrp and t then
                local hd=t.char:FindFirstChild("Head") or t.hrp
                Fire(R.ShootGun,tick(),tool,{HitPosition=hd.Position,Origin=hrp.Position+Vector3.new(0,1.5,0)})
                rfN=rfN+1
            end
            HW(Config.RapidDelay,Config.RapidDelay+0.05)
        end
    end)
end

-- Auto Knife Stab
local akN=0
local function StartKnife()
    task.spawn(function()
        while Config.AutoKnife do
            local tool=GetTool(); local hrp=GetHRP(); local t=GetNearest(25)
            if tool and hrp and t then
                pcall(function() hrp.CFrame=t.hrp.CFrame*CFrame.new(0,0,-3) end)
                task.wait(0.05)
                Fire(R.KnifeStab,tool,tick()); akN=akN+1
            end
            HW(Config.KnifeDelay,Config.KnifeDelay+0.03)
        end
    end)
end

-- Auto Throw
local atN=0
local function StartThrow()
    task.spawn(function()
        while Config.AutoThrow do
            local tool=GetTool(); local t=GetNearest(150)
            if tool and t then
                local hd=t.char:FindFirstChild("Head") or t.hrp
                Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,hd.Position)
                task.wait(0.05)
                Fire(R.KnifeThrow,tool,tick()); atN=atN+1
            end
            HW(Config.ThrowDelay,Config.ThrowDelay+0.1)
        end
    end)
end

-- Auto Spin
local spN=0
local spinT=0
AddConn(RunService.Heartbeat:Connect(function(dt)
    if not Config.AutoSpin then return end
    spinT=spinT+dt; if spinT<Config.SpinDelay then return end; spinT=0
    task.spawn(function() local r=Inv(R.RequestSpin); if r then spN=spN+1; Toast("Spin #"..spN,true) end end)
end))

-- Speed
AddConn(RunService.Heartbeat:Connect(function()
    if not Config.Speed then return end
    local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=Config.SpeedVal end
end))
table.insert(Conns,function()
    local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=16 end
end)

-- Noclip
local nParts={}
local function CacheNoclip() nParts={}; local c=LocalPlayer.Character; if not c then return end; for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then table.insert(nParts,p) end end end
CacheNoclip()
AddConn(LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); CacheNoclip() end))
AddConn(RunService.Stepped:Connect(function()
    if not Config.Noclip then return end
    for _,p in ipairs(nParts) do pcall(function() if p.CanCollide then p.CanCollide=false end end) end
end))

-- Inf Jump
local ijC
local function SetIJ(on)
    if ijC then ijC:Disconnect(); ijC=nil end
    if on then ijC=UserInputService.JumpRequest:Connect(function()
        local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end) end
end
table.insert(Conns,function() if ijC then ijC:Disconnect() end end)

-- Kill Feed
local kfFrame
local kfCounts={}
if R.ReplicaIns then
    AddConn(R.ReplicaIns.OnClientEvent:Connect(function(id,path,data)
        if not Config.KillFeed then return end
        pcall(function()
            if type(path)=="table" and path[5]=="Kills" and type(data)=="table" then
                local killer=tostring(path[4] or "?")
                local victim=tostring(data.KilledWho or "?")
                local wep=tostring(data.KillType or "?")
                if not kfFrame or not kfFrame.Parent then
                    local sg=Instance.new("ScreenGui",SafeGUI); sg.Name="NexKF"; sg.ResetOnSpawn=false; sg.DisplayOrder=994
                    local fr=Instance.new("Frame",sg); fr.Size=UDim2.new(0,220,0,180); fr.Position=UDim2.new(1,-230,0.4,0); fr.Backgrparency=1
                    Instance.new("UIListLayout",fr).VerticalAlignment=Enum.VerticalAlignment.Bottom
                    kfFrame=fr
                end
                local e=Instance.new("Frame",kfFrame); e.Size=UDim2.new(1,0,0,22); e.BackgroundColor3=Color3.fromRGB(15,8,8); e.BackgroundTransparency=0.3; e.BorderSizePixel=0
                Instance.new("UICorner",e).CornerRadius=UDim.new(0,5)
                local lb=Instance.new("TextLabel",e); lb.Size=UDim2.new(1,-8,1,0); lb.Position=UDim2.new(0,4,0,0); lb.BackgroundTransparency=1
                local mine=killer==LocalPlayer.Name or victim==LocalPlayer.Name
                lb.Text=killer.." > "..victim.." ["..wep.."]"
                lb.TextColor3=mine and Color3.fromRGB(80,255,80) or Color3.fromRGB(255,200,100)
                lb.Font=Enum.Font.GothamBold; lb.TextSize=9; lb.TextXAlignment=Enum.TextXAlignment.Left
                local frames={}; for _,c in ipairs(kfFrame:GetChildren()) do if c:IsA("Frame") then table.insert(frames,c) end end
                if #frames>8 then frames[1]:Destroy() end
                task.delay(4,function() pcall(function() e:Destroy() end) end)
            end
        end)
    end))
end

-- Score
local scores={Blue=0,Red=0}
if R.ReplicaSet then
    AddConn(R.ReplicaSet.OnClientEvent:Connect(function(id,path,val)
        pcall(function()
            if type(path)=="table" and path[5]=="Score" then
                local team=tostring(path[4] or "")
                if team=="Blue" or team=="Red" then scores[team]=val or 0 end
            end
        end)
    end))
end
local scGUI
local function BuildScoreHUD(on)
    if scGUI then scGUI:Destroy(); scGUI=nil end
    if not on then return end
    local sg=Instance.new("ScreenGui",SafeGUI); sg.Name="NexScore"; sg.ResetOnSpawn=false; sg.DisplayOrder=990; scGUI=sg
    local f=Instance.new("Frame",sg); f.Size=UDim2.new(0,160,0,44); f.Position=UDim2.new(0.5,-80,0,46); f.BackgroundColor3=Color3.fromRGB(8,8,18); f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",f).Color=Color3.fromRGB(80,80,200)
    local lb=Instance.new("TextLabel",f); lb.Size=UDim2.new(1,0,1,0); lb.BackgroundTransparency=1; lb.Font=Enum.Font.GothamBold; lb.TextSize=18; lb.TextXAlignment=Enum.TextXAlignment.Center
    AddConn(RunService.Heartbeat:Connect(function()
        pcall(function()
            lb.Text=("Blue %d - %d Red"):format(scores.Blue,scores.Red)
            lb.TextColor3=scores.Blue>scores.Red and Color3.fromRGB(80,150,255) or scores.Red>scores.Blue and Color3.fromRGB(255,80,80) or Color3.fromRGB(255,255,255)
        end)
    end))
end

-- ESP
local ESPCache={}
local function MakeESP(pl)
    if pl==LocalPlayer or ESPCache[pl] then return end
    local c={}
    local ec=Color3.fromRGB(255,60,60)
    local function nL(t) local l=Drawing.new("Line"); l.Color=ec; l.Thickness=t; l.Visible=false; l.ZIndex=4; return l end
    c.BT=nL(1.5); c.BB=nL(1.5); c.BL=nL(1.5); c.BR=nL(1.5)
    c.TX=Drawing.new("Text"); c.TX.Size=12; c.TX.Center=true; c.TX.Outline=true; c.TX.Color=ec; c.TX.Visible=false; c.TX.ZIndex=5
    c.HB=Drawing.new("Line"); c.HB.Thickness=3; c.HB.Color=Color3.new(0,0,0); c.HB.Visible=false
    c.HF=Drawing.new("Line"); c.HF.Thickness=1.8; c.HF.Visible=false
    c.DT=Drawing.new("Text"); c.DT.Size=10; c.DT.Center=true; c.DT.Outline=true; c.DT.Color=Color3.fromRGB(255,230,80); c.DT.Visible=false; c.DT.ZIndex=5
    local hl=Instance.new("Highlight"); hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.FillTransparency=0.75; hl.FillColor=ec; hl.OutlineColor=ec; hl.Enabled=false; hl.Parent=CoreGui
    if pl.Character then hl.Adornee=pl.Character end
    c._cc=pl.CharacterAdded:Connect(function(ch) hl.Adornee=ch end); c.HL=hl
    ESPCache[pl]=c
end
local function KillESP(pl)
    local c=ESPCache[pl]; if not c then return end
    pcall(function() c._cc:Disconnect() end); pcall(function() c.HL:Destroy() end)
    for _,k in ipairs({"BT","BB","BL","BR","TX","HB","HF","DT"}) do pcall(function() c[k]:Remove() end) end
    ESPCache[pl]=nil
end
local function HideE(c) c.HL.Enabled=false; for _,k in ipairs({"BT","BB","BL","BR","TX","HB","HF","DT"}) do c[k].Visible=false end end
for _,p in ipairs(Players:GetPlayers()) do MakeESP(p) end
AddConn(Players.PlayerAdded:Connect(MakeESP)); AddConn(Players.PlayerRemoving:Connect(KillESP))
table.insert(Conns,function() local s={}; for p in pairs(ESPCache) do table.insert(s,p) end; for _,p in ipairs(s) do KillESP(p) end end)
AddConn(RunService.RenderStepped:Connect(function()
    for pl,c in pairs(ESPCache) do
        if not Config.ESPEnabled then HideE(c); continue end
        local char=pl.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not(char and hum and hrp and hum.Health>0) then HideE(c); continue end
        local dist=(Camera.CFrame.Position-hrp.Position).Magnitude
        if dist>600 then HideE(c); continue end
        c.HL.Enabled=true
        local pos,onS=Camera:WorldToViewportPoint(hrp.Position)
        if not onS then for _,k in ipairs({"BT","BB","BL","BR","TX","HB","HF","DT"}) do c[k].Visible=false end; continue end
        local tV=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,3.2,0))
        local bV=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3.2,0))
        local h=math.abs(tV.Y-bV.Y); local w=h*0.45; local cx=pos.X; local lx=cx-w/2; local rx=cx+w/2
        if Config.ShowBox then
            c.BT.From=Vector2.new(lx,tV.Y); c.BT.To=Vector2.new(rx,tV.Y); c.BT.Visible=true
            c.BB.From=Vector2.new(lx,bV.Y); c.BB.To=Vector2.new(rx,bV.Y); c.BB.Visible=true
            c.BL.From=Vector2.new(lx,tV.Y); c.BL.To=Vector2.new(lx,bV.Y); c.BL.Visible=true
            c.BR.From=Vector2.new(rx,tV.Y); c.BR.To=Vector2.new(rx,bV.Y); c.BR.Visible=true
        else c.BT.Visible=false; c.BB.Visible=false; c.BL.Visible=false; c.BR.Visible=false end
        if Config.ShowName then c.TX.Text=pl.Name; c.TX.Position=Vector2.new(cx,tV.Y-16); c.TX.Visible=true else c.TX.Visible=false end
        if Config.ShowDist then c.DT.Text=("%.0fm"):format(dist); c.DT.Position=Vector2.new(cx,bV.Y+3); c.DT.Visible=true else c.DT.Visible=false end
        if Config.ShowHP then
            local hp=hum.Health/math.max(hum.MaxHealth,1); local bx=lx-6
            c.HB.From=Vector2.new(bx,tV.Y); c.HB.To=Vector2.new(bx,bV.Y); c.HB.Visible=true
            c.HF.From=Vector2.new(bx,bV.Y); c.HF.To=Vector2.new(bx,bV.Y-h*hp); c.HF.Color=Color3.new(1-hp,hp,0); c.HF.Visible=true
        else c.HB.Visible=false; c.HF.Visible=false end
    end
end))

-- ======================== UI ========================
local PRI=Color3.fromRGB(255,80,80)
local BG=Color3.fromRGB(12,6,6)
local TOP=Color3.fromRGB(20,8,8)
local CARD=Color3.fromRGB(18,8,8)

local Screen=Instance.new("ScreenGui",SafeGUI)
Screen.Name="NexPvSDuelUI"; Screen.ResetOnSpawn=false; Screen.DisplayOrder=999

local Wrap=Instance.new("Frame",Screen)
Wrap.Size=UDim2.new(0,255,0,470); Wrap.Position=UDim2.new(0.04,0,0.05,0); Wrap.BackgroundTransparency=1
Instance.new("UICorner",Wrap).CornerRadius=UDim.new(0,12)
Instance.new("UIStroke",Wrap).Color=PRI

local Main=Instance.new("Frame",Wrap)
Main.Size=UDim2.new(1,0,1,0); Main.BackgroundColor3=BG; Main.BorderSizePixel=0; Main.ClipsDescendants=true
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12)

local TopBar=Instance.new("Frame",Main)
TopBar.Size=UDim2.new(1,0,0,36); TopBar.BackgroundColor3=TOP; TopBar.BorderSizePixel=0

local TitleL=Instance.new("TextLabel",TopBar)
TitleL.Size=UDim2.new(1,-96,1,0); TitleL.Position=UDim2.new(0,11,0,0); TitleL.BackgroundTransparency=1
TitleL.Text="NEXUS - PvS DUEL"; TitleL.TextColor3=PRI; TitleL.Font=Enum.Font.GothamBold; TitleL.TextSize=13; TitleL.TextXAlignment=Enum.TextXAlignment.Left

local function TopBtn(txt,px,col)
    local b=Instance.new("TextButton",TopBar)
    b.Size=UDim2.new(0,24,0,22); b.Position=UDim2.new(1,px,0.5,-11)
    b.BackgroundColor3=col; b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5); return b
end
local PanicBtn=TopBtn("X",-90,Color3.fromRGB(140,20,20))
local HideBtn=TopBtn("H",-62,Color3.fromRGB(60,15,15))
local MinBtn=TopBtn("-",-34,Color3.fromRGB(40,12,12))

AddConn(PanicBtn.MouseButton1Click:Connect(function()
    Config.SilentAim=false; Config.RapidFire=false; Config.AutoKnife=false
    Config.AutoThrow=false; Config.AutoSpin=false; Config.ESPEnabled=false
    Config.Speed=false; Config.Noclip=false; Config.InfJump=false
    Config.KillFeed=false; Config.ScoreHUD=false; BuildScoreHUD(false)
    local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=16 end; SetIJ(false); Toast("ALL OFF",false)
end))

local TabBar=Instance.new("ScrollingFrame",Main)
TabBar.Size=UDim2.new(1,0,0,26); TabBar.Position=UDim2.new(0,0,0,36)
TabBar.BackgroundColor3=Color3.fromRGB(16,6,6); TabBar.BorderSizePixel=0
TabBar.ScrollBarThickness=2; TabBar.CanvasSize=UDim2.new(0,0,0,0); TabBar.ScrollingDirection=Enum.ScrollingDirection.X
TabBar.ScrollBarImageColor3=PRI
local TBL=Instance.new("UIListLayout",TabBar)
TBL.FillDirection=Enum.FillDirection.Horizontal; TBL.Padding=UDim.new(0,2); TBL.VerticalAlignment=Enum.VerticalAlignment.Center
Instance.new("UIPadding",TabBar).PaddingLeft=UDim.new(0,4)
TBL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TabBar.CanvasSize=UDim2.new(0,TBL.AbsoluteContentSize.X+8,0,0) end)

local ContentFrame=Instance.new("Frame",Main)
ContentFrame.Size=UDim2.new(1,0,1,-62); ContentFrame.Position=UDim2.new(0,0,0,62); ContentFrame.BackgroundTransparency=1

local Pill=Instance.new("TextButton",Screen)
Pill.Size=UDim2.new(0,110,0,24); Pill.Position=Wrap.Position; Pill.BackgroundColor3=Color3.fromRGB(40,8,8)
Pill.Text="PvS DUEL"; Pill.TextColor3=PRI; Pill.Font=Enum.Font.GothamBold; Pill.TextSize=10; Pill.BorderSizePixel=0; Pill.Visible=false
Instance.new("UICorner",Pill).CornerRadius=UDim.new(0,12); Instance.new("UIStroke",Pill).Color=PRI

AddConn(HideBtn.MouseButton1Click:Connect(function()
    Pill.Position=UDim2.new(Wrap.Position.X.Scale,Wrap.Position.X.Offset,Wrap.Position.Y.Scale,Wrap.Position.Y.Offset)
    Wrap.Visible=false; Pill.Visible=true
end))
AddConn(Pill.MouseButton1Click:Connect(function() Wrap.Position=Pill.Position; Wrap.Visible=true; Pill.Visible=false end))

local drag,ds,sp=false,nil,nil
AddConn(TopBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; ds=i.Position; sp=Wrap.Position end
end))
AddConn(UserInputService.InputChanged:Connect(function(i)
    if not drag then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-ds; Wrap.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
end))
AddConn(UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
end))

local mini=false
AddConn(MinBtn.MouseButton1Click:Connect(function()
    mini=not mini; ContentFrame.Visible=not mini; TabBar.Visible=not mini
    Wrap.Size=mini and UDim2.new(0,255,0,36) or UDim2.new(0,255,0,470); MinBtn.Text=mini and "+" or "-"
end))

-- Tab + Widget helpers
local tabs={}
local function NewTab(name)
    local pg=Instance.new("ScrollingFrame",ContentFrame)
    pg.Size=UDim2.new(1,0,1,0); pg.BackgroundTransparency=1; pg.BorderSizePixel=0
    pg.ScrollBarThickness=4; pg.ScrollBarImageColor3=PRI; pg.CanvasSize=UDim2.new(0,0,0,0); pg.Visible=false; pg.ScrollingEnabled=true
    local ly=Instance.new("UIListLayout",pg); ly.Padding=UDim.new(0,4); ly.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local pd=Instance.new("UIPadding",pg); pd.PaddingTop=UDim.new(0,6); pd.PaddingLeft=UDim.new(0,5); pd.PaddingRight=UDim.new(0,5); pd.PaddingBottom=UDim.new(0,10)
    AddConn(ly:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() pg.CanvasSize=UDim2.new(0,0,0,ly.AbsoluteContentSize.Y+20) end))
    local function ref() task.wait(); pg.CanvasSize=UDim2.new(0,0,0,ly.AbsoluteContentSize.Y+20) end
    local tb=Instance.new("TextButton",TabBar); tb.Size=UDim2.new(0,44,0,20); tb.BackgroundColor3=Color3.fromRGB(28,8,8)
    tb.Text=name; tb.TextColor3=Color3.fromRGB(180,60,60); tb.Font=Enum.Font.GothamSemibold; tb.TextSize=9; tb.BorderSizePixel=0
    Instance.new("UICorner",tb).CornerRadius=UDim.new(0,5)
    local ent={pg=pg,tb=tb}; table.insert(tabs,ent)
    local function act()
        for _,t in ipairs(tabs) do t.pg.Visible=false; t.tb.BackgroundColor3=Color3.fromRGB(28,8,8); t.tb.TextColor3=Color3.fromRGB(180,60,60) end
        pg.Visible=true; tb.BackgroundColor3=PRI; tb.TextColor3=Color3.fromRGB(255,255,255); task.defer(ref)
    end
    AddConn(tb.MouseButton1Click:Connect(act)); if #tabs==1 then act() end
    return pg,ref
end

local function Sec(p,t)
    local f=Instance.new("Frame",p); f.Size=UDim2.new(1,0,0,16); f.BackgroundTransparency=1
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text="-- "..t.." --"; l.TextColor3=PRI; l.Font=Enum.Font.GothamBold; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Center
end

local function Tog(p,lbl,cb,col)
    local color=col or PRI; local state=false
    local card=Instance.new("Frame",p); card.Size=UDim2.new(1,0,0,26); card.BackgroundColor3=CARD; card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,6)
    local lb=Instance.new("TextLabel",card); lb.Size=UDim2.new(1,-48,1,0); lb.Position=UDim2.new(0,9,0,0); lb.BackgroundTransparency=1
    lb.Text=lbl; lb.TextColor3=Color3.fromRGB(235,200,200); lb.Font=Enum.Font.GothamSemibold; lb.TextSize=11; lb.TextXAlignment=Enum.TextXAlignment.Left
    local pill=Instance.new("TextButton",card); pill.Size=UDim2.new(0,32,0,15); pill.Position=UDim2.new(1,-40,0.5,-7)
    pill.BackgroundColor3=Color3.fromRGB(45,15,15); pill.Text=""; pill.BorderSizePixel=0; Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",pill); knob.Size=UDim2.new(0,11,0,11); knob.Position=UDim2.new(0,2,0.5,-5); knob.BackgroundColor3=Color3.fromRGB(150,60,60); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    AddConn(pill.MouseButton1Click:Connect(function()
        state=not state
        if state then pill.BackgroundColor3=color; knob.Position=UDim2.new(1,-13,0.5,-5); knob.BackgroundColor3=Color3.fromRGB(255,255,255)
        else pill.BackgroundColor3=Color3.fromRGB(45,15,15); knob.Position=UDim2.new(0,2,0.5,-5); knob.BackgroundColor3=Color3.fromRGB(150,60,60) end
        Toast(lbl,state); pcall(cb,state)
    end))
end

local function Sld(p,lbl,ini,mn,mx,cb)
    local fc=Instance.new("Frame",p); fc.Size=UDim2.new(1,0,0,42); fc.BackgroundColor3=CARD; fc.BorderSizePixel=0
    Instance.new("UICorner",fc).CornerRadius=UDim.new(0,6)
    local fl=Instance.new("TextLabel",fc); fl.Size=UDim2.new(1,-10,0,18); fl.Position=UDim2.new(0,9,0,3); fl.BackgroundTransparency=1
    fl.Text=lbl..": "..ini; fl.TextColor3=Color3.fromRGB(220,170,170); fl.Font=Enum.Font.GothamSemibold; fl.TextSize=11; fl.TextXAlignment=Enum.TextXAlignment.Left
    local tr=Instance.new("Frame",fc); tr.Size=UDim2.new(1,-18,0,6); tr.Position=UDim2.new(0,9,0,28); tr.BackgroundColor3=Color3.fromRGB(45,15,15); tr.BorderSizePixel=0
    Instance.new("UICorner",tr).CornerRadius=UDim.new(1,0)
    local ra=math.clamp((ini-mn)/(mx-mn),0,1)
    local fi=Instance.new("Frame",tr); fi.Size=UDim2.new(ra,0,1,0); fi.BackgroundColor3=PRI; fi.BorderSizePixel=0; Instance.new("UICorner",fi).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("TextButton",tr); kn.Size=UDim2.new(0,14,0,14); kn.AnchorPoint=Vector2.new(0.5,0.5); kn.Position=UDim2.new(ra,0,0.5,0)
    kn.BackgroundColor3=Color3.fromRGB(255,255,255); kn.Text=""; kn.BorderSizePixel=0; Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local ds2=false
    AddConn(kn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then ds2=true end end))
    AddConn(UserInputService.InputChanged:Connect(function(i)
        if not ds2 then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local tp=tr.AbsolutePosition; local ts=tr.AbsoluteSize
            local rx=math.clamp((i.Position.X-tp.X)/ts.X,0,1)
            local v=math.floor(mn+(mx-mn)*rx); fi.Size=UDim2.new(rx,0,1,0); kn.Position=UDim2.new(rx,0,0.5,0); fl.Text=lbl..": "..v; pcall(cb,v)
        end
    end))
    AddConn(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then ds2=false end end))
end

local function ActBtn(p,lbl,col,cb)
    local b=Instance.new("TextButton",p); b.Size=UDim2.new(1,0,0,28); b.BackgroundColor3=col or PRI
    b.Text=lbl; b.TextColor3=Color3.fromRGB(255,255,255); b.Font=Enum.Font.GothamBold; b.TextSize=11; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    AddConn(b.MouseButton1Click:Connect(function() local oc=b.BackgroundColor3; b.BackgroundColor3=Color3.fromRGB(255,255,255); task.delay(0.12,function() b.BackgroundColor3=oc end); pcall(cb) end))
end

local function StatCard(p,txt)
    local f=Instance.new("Frame",p); f.Size=UDim2.new(1,0,0,26); f.BackgroundColor3=Color3.fromRGB(10,6,6); f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",f).Color=Color3.fromRGB(80,20,20)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-10,1,-6); l.Position=UDim2.new(0,5,0,3); l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=Color3.fromRGB(255,150,100); l.Font=Enum.Font.GothamBold; l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end

-- ======== TAB GUN ========
do
    local p,r=NewTab("Gun")
    Sec(p,"SILENT AIM")
    Tog(p,"Silent Aim",function(v) Config.SilentAim=v end,Color3.fromRGB(255,80,80))
    Sec(p,"RAPID FIRE")
    Tog(p,"Rapid Fire",function(v) Config.RapidFire=v; if v then StartRF() end end,Color3.fromRGB(255,120,30))
    Sld(p,"Delay ms",math.floor(Config.RapidDelay*1000),50,500,function(v) Config.RapidDelay=v/1000 end)
    Sld(p,"Range stud",300,50,600,function(v) Config.RapidFire_Range=v end)
    local sl=StatCard(p,"RF shots: 0 | Target: none")
    AddConn(RunService.Heartbeat:Connect(function()
        pcall(function()
            local t=GetNearest(300); sl.Text=("RF shots: %d | Target: %s"):format(rfN,t and t.pl.Name or "none")
        end)
    end))
    task.defer(r)
end

-- ======== TAB KNIFE ========
do
    local p,r=NewTab("Knife")
    Sec(p,"AUTO STAB")
    Tog(p,"Auto Knife Stab",function(v) Config.AutoKnife=v; if v then StartKnife() end end,Color3.fromRGB(200,50,255))
    Sld(p,"Stab Delay ms",math.floor(Config.KnifeDelay*1000),50,500,function(v) Config.KnifeDelay=v/1000 end)
    Sec(p,"AUTO THROW")
    Tog(p,"Auto Knife Throw",function(v) Config.AutoThrow=v; if v then StartThrow() end end,Color3.fromRGB(255,150,200))
    Sld(p,"Throw Delay ms",math.floor(Config.ThrowDelay*1000),100,1000,function(v) Config.ThrowDelay=v/1000 end)
    local sl=StatCard(p,"Stabs: 0 | Throws: 0")
    AddConn(RunService.Heartbeat:Connect(function() pcall(function() sl.Text=("Stabs: %d | Throws: %d"):format(akN,atN) end) end))
    task.defer(r)
end

-- ======== TAB ESP ========
do
    local p,r=NewTab("ESP")
    Sec(p,"PLAYER ESP")
    Tog(p,"Aktifkan ESP",function(v) Config.ESPEnabled=v end,Color3.fromRGB(30,210,80))
    Tog(p,"Box",function(v) Config.ShowBox=v end)
    Tog(p,"Name",function(v) Config.ShowName=v end)
    Tog(p,"Health Bar",function(v) Config.ShowHP=v end)
    Tog(p,"Distance",function(v) Config.ShowDist=v end)
    task.defer(r)
end

-- ======== TAB GAME ========
do
    local p,r=NewTab("Game")
    Sec(p,"SCORE + KILLFEED")
    Tog(p,"Score HUD",function(v) Config.ScoreHUD=v; BuildScoreHUD(v) end,Color3.fromRGB(80,150,255))
    Tog(p,"Kill Feed",function(v) Config.KillFeed=v end,Color3.fromRGB(255,180,50))
    Sec(p,"AUTO SPIN")
    Tog(p,"Auto Spin Wheel",function(v) Config.AutoSpin=v end,Color3.fromRGB(255,220,50))
    Sld(p,"Spin Delay s",math.floor(Config.SpinDelay),1,10,function(v) Config.SpinDelay=v end)
    local sl=StatCard(p,"Total spins: 0")
    AddConn(RunService.Heartbeat:Connect(function() pcall(function() sl.Text="Total spins: "..spN end) end))
    Sec(p,"REDEEM CODE")
    local cf=Instance.new("Frame",p); cf.Size=UDim2.new(1,0,0,32); cf.BackgroundColor3=Color3.fromRGB(18,8,8); cf.BorderSizePixel=0
    Instance.new("UICorner",cf).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",cf).Color=Color3.fromRGB(100,30,30)
    local cb=Instance.new("TextBox",cf); cb.Size=UDim2.new(0.68,0,1,-6); cb.Position=UDim2.new(0,4,0,3); cb.BackgroundTransparency=1
    cb.Text=""; cb.PlaceholderText="Masukkan kode..."; cb.TextColor3=Color3.fromRGB(255,200,200); cb.PlaceholderColor3=Color3.fromRGB(120,80,80)
    cb.Font=Enum.Font.Gotham; cb.TextSize=11; cb.TextXAlignment=Enum.TextXAlignment.Left; cb.ClearTextOnFocus=false
    local rb=Instance.new("TextButton",cf); rb.Size=UDim2.new(0.3,0,1,-6); rb.Position=UDim2.new(0.69,0,0,3)
    rb.BackgroundColor3=Color3.fromRGB(100,20,20); rb.Text="Redeem"; rb.TextColor3=Color3.fromRGB(255,255,255)
    rb.Font=Enum.Font.GothamBold; rb.TextSize=10; rb.BorderSizePixel=0; Instance.new("UICorner",rb).CornerRadius=UDim.new(0,5)
    AddConn(rb.MouseButton1Click:Connect(function()
        if cb.Text and #cb.Text>0 then
            local res=Inv(R.RedeemCode,cb.Text)
            Toast(res and "Berhasil!" or "Gagal/Invalid",not not res)
        end
    end))
    task.defer(r)
end

-- ======== TAB MOVE ========
do
    local p,r=NewTab("Move")
    Sec(p,"MOVEMENT")
    Tog(p,"Speed Hack",function(v) Config.Speed=v; if not v then local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16 end end end,PRI)
    Sld(p,"Speed Value",Config.SpeedVal,16,200,function(v) Config.SpeedVal=v end)
    Tog(p,"Noclip",function(v) Config.Noclip=v end,PRI)
    Tog(p,"Infinite Jump",function(v) Config.InfJump=v; SetIJ(v) end,PRI)
    task.defer(r)
end

-- ======== TAB INFO ========
do
    local p,r=NewTab("Info")
    Sec(p,"REMOTE STATUS")
    local loaded=0; for _,v in pairs(R) do if v then loaded=loaded+1 end end
    local f=Instance.new("Frame",p); f.Size=UDim2.new(1,0,0,80); f.BackgroundColor3=Color3.fromRGB(10,6,6); f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",f).Color=Color3.fromRGB(80,20,20)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-14,1,-8); l.Position=UDim2.new(0,7,0,4); l.BackgroundTransparency=1
    l.Text=("Remote: %d loaded\nShootGun:%s KnifeStab:%s KnifeThrow:%s\nRequestSpin:%s RedeemCode:%s"):format(
        loaded, R.ShootGun and "OK" or "NO", R.KnifeStab and "OK" or "NO",
        R.KnifeThrow and "OK" or "NO", R.RequestSpin and "OK" or "NO", R.RedeemCode and "OK" or "NO")
    l.TextColor3=Color3.fromRGB(220,150,150); l.Font=Enum.Font.Code; l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
    task.defer(r)
end

print("[NEXUS] PvS Duel - LOADED!")
```
