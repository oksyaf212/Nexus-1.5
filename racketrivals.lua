--[[
    ============================================================================
    PROJECT   : NEXUS — Racket Rivals Suite
    GAME      : Racket Rivals (Badminton)
    PLATFORM  : Delta Executor Android
    AUTHOR    : Claude Sonnet 4.6
    FITUR:
    ├── Auto Aim Bola (hook ReplicateCamLook → arahkan ke bola)
    ├── Ball ESP (posisi shuttlecock realtime)
    ├── Score Monitor HUD (skor semua court)
    ├── Rally Counter HUD (rally count realtime)
    ├── Serve Alert (notifikasi saat serve)
    ├── ESP Player (lihat semua player)
    ├── Auto Ability (spam AbilityRemote)
    └── FPS + Ping otomatis aktif
    ============================================================================
]]

local ENV_KEY="NexusRacket"
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
local Remotes=RS:FindFirstChild("Remotes")
local Actions=RS:FindFirstChild("Actions")
local Values =RS:FindFirstChild("Values")

local function GetR(parent,name)
    if not parent then return nil end
    return parent:FindFirstChild(name)
end

local R={}
R.ReplicateCamLook = GetR(Remotes,"ReplicateCamLook")
    or GetR(Remotes,"ReplicateMouse")
    or GetR(Remotes,"ReplicateMouseAsync")
R.AbilityRemote    = GetR(Remotes,"AbilityRemote")
R.PrivateAbility   = GetR(Remotes,"PrivateAbilityRemote")
R.Action           = GetR(Actions,"Action")
R.Set              = GetR(Values,"Set")

-- ============================================================================
-- [4] CONFIG
-- ============================================================================
local Config={
    AutoAim={
        Enabled=false,
        -- Arahkan kamera ke bola saat ada dalam jangkauan
        Range=100,            -- radius deteksi bola (stud)
        Smoothness=0.3,       -- kelancaran aim (0.1=smooth, 1.0=instant)
        OnlyWhenSwinging=true,-- hanya aim saat animasi swing
    },
    BallESP={
        Enabled=false,
        ShowTrail=false,      -- trail prediksi arah bola
        TrailLength=10,       -- panjang trail
    },
    ScoreHUD={
        Enabled=false,
    },
    RallyHUD={
        Enabled=false,
    },
    ServeAlert={
        Enabled=false,
    },
    ESP={
        Enabled=false,
        ShowBox=false,
        ShowName=false,
        ShowHealth=false,
        ShowDistance=false,
    },
    AutoAbility={
        Enabled=false,
        AbilityName="Freeze",  -- nama ability
        Delay=0.5,             -- delay antar spam
    },
}

-- ============================================================================
-- [5] STATE — data dari Set remote
-- ============================================================================
local State={
    -- Score per court [courtId] = {team1, team2}
    Scores={},
    -- Rally count per court
    RallyCounts={},
    -- Ball locked per court
    BallLocked={},
    -- Serve player per court
    ServePlayers={},
    -- Ball positions (dari Action aa0cd20cfc595859)
    BallPositions={},
    -- My court number
    MyCourt=nil,
}

-- ============================================================================
-- [6] UTILITY
-- ============================================================================
local function ShowToast(msg,isOn)
    pcall(function()
        local existing=SafeGUI:FindFirstChild("RacketToast")
        if existing then existing:Destroy() end
        local sg=Instance.new("ScreenGui",SafeGUI)
        sg.Name="RacketToast"; sg.ResetOnSpawn=false; sg.DisplayOrder=9999
        Core:Add(sg)
        local f=Instance.new("Frame",sg)
        f.Size=UDim2.new(0,240,0,30); f.Position=UDim2.new(0.5,-120,0.85,0)
        f.BackgroundColor3=isOn and Color3.fromRGB(10,50,20) or Color3.fromRGB(60,10,10)
        f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,15)
        local fs=Instance.new("UIStroke",f)
        fs.Color=isOn and Color3.fromRGB(40,220,80) or Color3.fromRGB(220,50,50)
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

local function ShowAlert(msg,color,dur)
    pcall(function()
        local existing=SafeGUI:FindFirstChild("RacketAlert")
        if existing then existing:Destroy() end
        local sg=Instance.new("ScreenGui",SafeGUI)
        sg.Name="RacketAlert"; sg.ResetOnSpawn=false; sg.DisplayOrder=9998
        Core:Add(sg)
        local f=Instance.new("Frame",sg)
        f.Size=UDim2.new(0,260,0,36); f.Position=UDim2.new(0.5,-130,0.08,0)
        f.BackgroundColor3=Color3.fromRGB(8,16,8); f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,18)
        local fs=Instance.new("UIStroke",f)
        fs.Color=color or Color3.fromRGB(100,255,100); fs.Thickness=1.5
        local l=Instance.new("TextLabel",f)
        l.Size=UDim2.new(1,-10,1,0); l.Position=UDim2.new(0,5,0,0)
        l.BackgroundTransparency=1; l.Text=msg
        l.TextColor3=color or Color3.fromRGB(100,255,100)
        l.Font=Enum.Font.GothamBold; l.TextSize=12
        local d=dur or 2.5
        task.delay(d,function()
            for i=1,10 do
                pcall(function() f.BackgroundTransparency=i/10; l.TextTransparency=i/10 end)
                task.wait(0.04)
            end
            pcall(function() sg:Destroy() end)
        end)
    end)
end

-- ============================================================================
-- [7] LISTEN SET REMOTE — ambil data game
-- ============================================================================
if R.Set then
    Core:Add(R.Set.OnClientEvent:Connect(function(key,value)
        pcall(function()
            if not key then return end

            -- Score per court
            local scoreMatch=tostring(key):match("ROUND_SCORE_(%d+)")
            if scoreMatch then
                local courtId=tonumber(scoreMatch)
                if type(value)=="table" then
                    State.Scores[courtId]={value[1] or 0,value[2] or 0}
                end
                return
            end

            -- Rally count per court
            local rallyMatch=tostring(key):match("ROUND_RALLY_HIT_COUNT_(%d+)")
            if rallyMatch then
                local courtId=tonumber(rallyMatch)
                State.RallyCounts[courtId]=value or 0
                return
            end

            -- Ball locked per court (serve moment)
            local ballLockMatch=tostring(key):match("ROUND_BALL_LOCKED_(%d+)")
            if ballLockMatch then
                local courtId=tonumber(ballLockMatch)
                local wasLocked=State.BallLocked[courtId]
                State.BallLocked[courtId]=value
                -- Deteksi serve baru
                if value==true and not wasLocked then
                    -- Serve alert
                    local servePlayer=State.ServePlayers[courtId]
                    if Config.ServeAlert.Enabled then
                        local playerName=servePlayer and servePlayer.Name or "?"
                        -- Cek apakah serve ini di court kita
                        if courtId==State.MyCourt then
                            ShowAlert("🏸 SERVE! Court "..courtId.." — "..playerName,
                                Color3.fromRGB(255,220,80),2)
                        end
                    end
                end
                return
            end

            -- Serve player per court
            local serveMatch=tostring(key):match("ROUND_SERVE_PLAYER_(%d+)")
            if serveMatch then
                local courtId=tonumber(serveMatch)
                if typeof(value)=="Instance" and value:IsA("Player") then
                    State.ServePlayers[courtId]=value
                    -- Detect my court
                    if value==LocalPlayer then
                        State.MyCourt=courtId
                    end
                else
                    State.ServePlayers[courtId]=nil
                end
                return
            end
        end)
    end))
end

-- ============================================================================
-- [8] LISTEN ACTION REMOTE — posisi bola
-- ============================================================================
-- Action aa0cd20cfc595859 = posisi bola/shuttlecock
-- Format: CFrame(posisi bola), bool, string, "Swing"
if R.Action then
    Core:Add(R.Action.OnClientEvent:Connect(function(actionId,...)
        pcall(function()
            if tostring(actionId)=="aa0cd20cfc595859" then
                local args={...}
                -- args[1] = CFrame posisi bola
                -- args[2] = bool
                -- args[3] = string (Default)
                -- args[4] = "Swing"
                if args[1] and typeof(args[1])=="CFrame" then
                    local ballPos=args[1].Position
                    -- Simpan posisi bola (index 1 = terbaru)
                    table.insert(State.BallPositions,1,{
                        pos=ballPos,
                        time=tick()
                    })
                    -- Batasi history
                    if #State.BallPositions>20 then
                        table.remove(State.BallPositions)
                    end
                end
            end

            -- Detect my court dari action yang melibatkan LocalPlayer
            if tostring(actionId)=="efa5dfa502bd5abd" then
                local args={...}
                if args[1]==LocalPlayer then
                    -- Ini court saya, tapi perlu cari court number dari Set data
                end
            end
        end)
    end))
end

-- ============================================================================
-- [9] CARI BOLA DI WORKSPACE
-- ============================================================================
local _ballKeywords={"shuttle","ball","birdie","racket","puck","orb","projectile"}

local function FindBalls()
    local balls={}
    local myHRP=LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("SpecialMesh") then
            local nameLower=obj.Name:lower()
            for _,kw in ipairs(_ballKeywords) do
                if nameLower:find(kw) then
                    table.insert(balls,obj)
                    break
                end
            end
        end
    end

    -- Juga cari dari posisi history bola (lebih akurat)
    if #State.BallPositions>0 then
        local latest=State.BallPositions[1]
        if tick()-latest.time<0.5 then -- data masih fresh
            -- Cari BasePart di sekitar posisi bola terakhir
            if myHRP then
                for _,obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and not obj.Anchored then
                        local dist=(obj.Position-latest.pos).Magnitude
                        if dist<3 then -- dalam radius 3 stud dari posisi bola
                            local alreadyAdded=false
                            for _,b in ipairs(balls) do
                                if b==obj then alreadyAdded=true; break end
                            end
                            if not alreadyAdded then
                                table.insert(balls,obj)
                            end
                        end
                    end
                end
            end
        end
    end

    return balls
end

local function GetNearestBall()
    local myHRP=LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    -- Prioritas: gunakan data dari Action remote (paling akurat)
    if #State.BallPositions>0 then
        local latest=State.BallPositions[1]
        if tick()-latest.time<1 then
            return {Position=latest.pos}
        end
    end

    -- Fallback: cari di workspace
    local balls=FindBalls()
    local nearest,minDist=nil,math.huge
    for _,ball in ipairs(balls) do
        local dist=(ball.Position-myHRP.Position).Magnitude
        if dist<minDist then minDist=dist; nearest=ball end
    end
    return nearest
end

-- ============================================================================
-- [10] AUTO AIM — Hook ReplicateCamLook
-- ============================================================================
--[[
    ReplicateCamLook:FireServer(x, y, z, timestamp)
    x, y, z = Camera.CFrame.LookVector (arah kamera)
    timestamp = tick()

    Cara kerja Auto Aim:
    1. Deteksi posisi bola terdekat
    2. Hitung LookVector dari posisi kamera ke bola
    3. Ganti x,y,z dengan LookVector yang sudah diarahkan ke bola
    4. Server terima arah yang sudah dimodifikasi
    Server pikir kamera kamu sudah mengarah ke bola
]]

local _autoAimHooked=false
local _lastBallDirection=nil

local function InitAutoAim()
    if _autoAimHooked then return end
    _autoAimHooked=true
    pcall(function()
        local mt=getrawmetatable(game)
        local old=mt.__namecall
        setreadonly(mt,false)
        mt.__namecall=newcclosure(function(self,...)
            local method=getnamecallmethod()
            if Config.AutoAim.Enabled and method=="FireServer" then
                local ok,name=pcall(function() return self:GetFullName() end)
                if ok and (name:find("ReplicateCamLook")
                        or name:find("ReplicateMouse")) then
                    local args={...}
                    -- args: x, y, z, timestamp
                    -- Cari bola terdekat
                    local ball=GetNearestBall()
                    if ball then
                        local camPos=Camera.CFrame.Position
                        local ballPos=ball.Position
                        local dist=(ballPos-camPos).Magnitude
                        -- Hanya aim jika bola dalam range
                        if dist<=Config.AutoAim.Range then
                            -- Hitung look vector ke bola
                            local lookDir=(ballPos-camPos).Unit
                            -- Smooth lerp dengan direction sebelumnya
                            if _lastBallDirection then
                                lookDir=_lastBallDirection:Lerp(lookDir,Config.AutoAim.Smoothness)
                            end
                            _lastBallDirection=lookDir
                            -- Ganti argumen arah
                            args[1]=lookDir.X
                            args[2]=lookDir.Y
                            args[3]=lookDir.Z
                            -- args[4] = timestamp tetap
                            return old(self,table.unpack(args))
                        end
                    end
                    _lastBallDirection=nil
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
pcall(InitAutoAim)

-- ============================================================================
-- [11] AUTO ABILITY
-- ============================================================================
local _abilityConn
local function StartAutoAbility()
    if _abilityConn then _abilityConn:Disconnect(); _abilityConn=nil end
    local t=0
    _abilityConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.AutoAbility.Enabled then
            _abilityConn:Disconnect(); _abilityConn=nil; return
        end
        t=t+dt; if t<Config.AutoAbility.Delay then return end; t=0
        if not R.AbilityRemote then return end
        local ball=GetNearestBall()
        if not ball then return end
        pcall(function()
            -- Format dari spy: UUID + nama ability + V3 posisi
            local uuid=game:GetService("HttpService"):GenerateGUID(false)
            local ballPos=ball.Position
            R.AbilityRemote:FireServer(uuid,Config.AutoAbility.AbilityName,ballPos)
        end)
    end)
end
Core:Add(function() if _abilityConn then _abilityConn:Disconnect() end end)

-- ============================================================================
-- [12] BALL ESP
-- ============================================================================
local _ballDots={}
local _ballTrail={}
local _trailLines={}

Core:Add(RunService.RenderStepped:Connect(function()
    -- Cleanup dots lama
    for _,d in ipairs(_ballDots) do pcall(function() d:Remove() end) end
    _ballDots={}

    if not Config.BallESP.Enabled then
        for _,l in ipairs(_trailLines) do pcall(function() l:Remove() end) end
        _trailLines={}
        return
    end

    -- Tampilkan posisi bola dari history
    if #State.BallPositions>0 then
        local latest=State.BallPositions[1]
        if tick()-latest.time<1.5 then
            local sp,on=Camera:WorldToViewportPoint(latest.pos)
            if on then
                -- Dot bola
                local dot=Drawing.new("Circle")
                dot.Position=Vector2.new(sp.X,sp.Y)
                dot.Radius=8; dot.Filled=true
                dot.Color=Color3.fromRGB(255,255,50)
                dot.Transparency=0; dot.Visible=true; dot.ZIndex=10
                table.insert(_ballDots,dot)

                -- Label
                local lbl=Drawing.new("Text")
                lbl.Text="🏸 BOLA"
                lbl.Position=Vector2.new(sp.X,sp.Y-18)
                lbl.Size=12; lbl.Center=true; lbl.Outline=true
                lbl.Color=Color3.fromRGB(255,255,50)
                lbl.Visible=true; lbl.ZIndex=10
                table.insert(_ballDots,lbl)
            end
        end
    end

    -- Trail dari history posisi
    if Config.BallESP.ShowTrail and #State.BallPositions>1 then
        local trailLen=math.min(Config.BallESP.TrailLength,#State.BallPositions)
        -- Hapus trail lama
        for _,l in ipairs(_trailLines) do pcall(function() l:Remove() end) end
        _trailLines={}
        for i=1,trailLen-1 do
            local p1=State.BallPositions[i].pos
            local p2=State.BallPositions[i+1].pos
            if tick()-State.BallPositions[i+1].time<3 then
                local sp1,on1=Camera:WorldToViewportPoint(p1)
                local sp2,on2=Camera:WorldToViewportPoint(p2)
                if on1 and on2 then
                    local line=Drawing.new("Line")
                    line.From=Vector2.new(sp1.X,sp1.Y)
                    line.To=Vector2.new(sp2.X,sp2.Y)
                    line.Thickness=math.max(1,3-(i*0.3))
                    local alpha=1-(i/trailLen)
                    line.Color=Color3.fromRGB(255,math.floor(220*alpha),0)
                    line.Visible=true; line.ZIndex=9
                    table.insert(_trailLines,line)
                end
            end
        end
    end
end))
Core:Add(function()
    for _,d in ipairs(_ballDots) do pcall(function() d:Remove() end) end
    for _,l in ipairs(_trailLines) do pcall(function() l:Remove() end) end
end)

-- ============================================================================
-- [13] SCORE + RALLY HUD
-- ============================================================================
local _scoreGui
local function BuildScoreHUD()
    if _scoreGui then _scoreGui:Destroy(); _scoreGui=nil end
    if not Config.ScoreHUD.Enabled and not Config.RallyHUD.Enabled then return end

    local sg=Instance.new("ScreenGui",SafeGUI)
    sg.Name="RacketScoreHUD"; sg.ResetOnSpawn=false; sg.DisplayOrder=990
    Core:Add(sg); _scoreGui=sg

    local frame=Instance.new("Frame",sg)
    frame.Size=UDim2.new(0,200,0,180)
    frame.Position=UDim2.new(1,-210,0.3,0)
    frame.BackgroundColor3=Color3.fromRGB(6,10,6)
    frame.BorderSizePixel=0; frame.BackgroundTransparency=0.2
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
    local fStroke=Instance.new("UIStroke",frame)
    fStroke.Color=Color3.fromRGB(100,255,100); fStroke.Thickness=1

    local title=Instance.new("TextLabel",frame)
    title.Size=UDim2.new(1,0,0,22); title.BackgroundTransparency=1
    title.Text="🎾 SCORE MONITOR"
    title.TextColor3=Color3.fromRGB(100,255,100)
    title.Font=Enum.Font.GothamBold; title.TextSize=11

    local scrollFrame=Instance.new("ScrollingFrame",frame)
    scrollFrame.Size=UDim2.new(1,-4,1,-24)
    scrollFrame.Position=UDim2.new(0,2,0,24)
    scrollFrame.BackgroundTransparency=1; scrollFrame.BorderSizePixel=0
    scrollFrame.ScrollBarThickness=3
    scrollFrame.ScrollBarImageColor3=Color3.fromRGB(100,255,100)
    scrollFrame.CanvasSize=UDim2.new(0,0,0,0)
    local layout=Instance.new("UIListLayout",scrollFrame)
    layout.Padding=UDim.new(0,2)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+4)
    end)

    -- Update setiap 0.5 detik
    Core:Add(RunService.Heartbeat:Connect(function()
        -- Hapus semua label lama
        for _,child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end

        -- Score per court
        if Config.ScoreHUD.Enabled then
            for courtId=1,8 do
                local score=State.Scores[courtId]
                if score then
                    local lbl=Instance.new("TextLabel",scrollFrame)
                    lbl.Size=UDim2.new(1,0,0,18)
                    lbl.BackgroundTransparency=1
                    local isMyCourt=courtId==State.MyCourt
                    lbl.Text=string.format("%sCourt %d: %d - %d",
                        isMyCourt and "⭐" or "  ",
                        courtId,score[1],score[2])
                    lbl.TextColor3=isMyCourt
                        and Color3.fromRGB(255,220,50)
                        or  Color3.fromRGB(180,230,180)
                    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10
                    lbl.TextXAlignment=Enum.TextXAlignment.Left
                    Instance.new("UIPadding",lbl).PaddingLeft=UDim.new(0,6)
                end
            end
        end

        -- Rally per court
        if Config.RallyHUD.Enabled then
            local divider=Instance.new("TextLabel",scrollFrame)
            divider.Size=UDim2.new(1,0,0,14); divider.BackgroundTransparency=1
            divider.Text="── RALLY ──"
            divider.TextColor3=Color3.fromRGB(80,180,80)
            divider.Font=Enum.Font.GothamBold; divider.TextSize=9
            divider.TextXAlignment=Enum.TextXAlignment.Center

            for courtId=1,8 do
                local rally=State.RallyCounts[courtId]
                if rally and rally>0 then
                    local lbl=Instance.new("TextLabel",scrollFrame)
                    lbl.Size=UDim2.new(1,0,0,18); lbl.BackgroundTransparency=1
                    local isMyCourt=courtId==State.MyCourt
                    -- Warna berdasarkan rally count
                    local col=rally>=20
                        and Color3.fromRGB(255,80,80)
                        or rally>=10
                        and Color3.fromRGB(255,180,50)
                        or Color3.fromRGB(150,220,150)
                    lbl.Text=string.format("%sCourt %d: %d hit",
                        isMyCourt and "⭐" or "  ",courtId,rally)
                    lbl.TextColor3=col
                    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10
                    lbl.TextXAlignment=Enum.TextXAlignment.Left
                    Instance.new("UIPadding",lbl).PaddingLeft=UDim.new(0,6)
                end
            end
        end
    end))
end

-- ============================================================================
-- [14] ESP PLAYER
-- ============================================================================
local ESPCache={}

local function CreateESP(player)
    if player==LocalPlayer or ESPCache[player] then return end
    local c={}
    local function nL(t)
        local l=Drawing.new("Line"); l.Color=Color3.fromRGB(100,255,100)
        l.Thickness=t; l.Visible=false; l.ZIndex=4; return l
    end
    c.BoxT=nL(1.5); c.BoxB=nL(1.5); c.BoxL=nL(1.5); c.BoxR=nL(1.5)
    local txt=Drawing.new("Text"); txt.Size=12; txt.Center=true
    txt.Outline=true; txt.Color=Color3.fromRGB(100,255,100)
    txt.Visible=false; txt.ZIndex=5; c.Text=txt
    local hpBg=Drawing.new("Line"); hpBg.Thickness=3
    hpBg.Color=Color3.new(0,0,0); hpBg.Visible=false; c.HpBg=hpBg
    local hpFg=Drawing.new("Line"); hpFg.Thickness=1.8
    hpFg.Visible=false; c.HpFg=hpFg
    local dTxt=Drawing.new("Text"); dTxt.Size=10; dTxt.Center=true
    dTxt.Outline=true; dTxt.Color=Color3.fromRGB(255,230,80)
    dTxt.Visible=false; dTxt.ZIndex=5; c.DistText=dTxt
    local hl=Instance.new("Highlight")
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency=0.75; hl.OutlineTransparency=0.0
    hl.FillColor=Color3.fromRGB(100,255,100)
    hl.OutlineColor=Color3.fromRGB(100,255,100)
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
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","DistText"}) do
        pcall(function() c[k]:Remove() end)
    end
    ESPCache[player]=nil
end

local function HideESP(c)
    c.Highlight.Enabled=false
    for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","DistText"}) do
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
        if dist>500 then HideESP(c); continue end
        c.Highlight.Enabled=true
        local pos,onScreen=Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            for _,k in ipairs({"BoxT","BoxB","BoxL","BoxR","Text","HpBg","HpFg","DistText"}) do
                c[k].Visible=false
            end
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
        if Config.ESP.ShowName then
            c.Text.Text=player.Name
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
    end
end))

-- ============================================================================
-- [15] FPS + PING
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
-- [16] UI
-- ============================================================================
local UI={_tabPages={}}

local THEME={
    primary=Color3.fromRGB(80,220,80),
    bg=Color3.fromRGB(6,12,6),
    topbar=Color3.fromRGB(8,18,8),
    card=Color3.fromRGB(10,18,10),
}

function UI:Build()
    local Screen=Instance.new("ScreenGui",SafeGUI)
    Screen.Name="RacketUI"; Screen.ResetOnSpawn=false; Screen.DisplayOrder=999
    Core:Add(Screen)

    local Wrapper=Instance.new("Frame",Screen)
    Wrapper.Size=UDim2.new(0,255,0,440)
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
    TopBar.BackgroundColor3=THEME.topbar; TopBar.BorderSizePixel=0

    local TL=Instance.new("TextLabel",TopBar)
    TL.Size=UDim2.new(1,-96,1,0); TL.Position=UDim2.new(0,11,0,0)
    TL.BackgroundTransparency=1; TL.Text="🎾  NEXUS  RACKET"
    TL.TextColor3=THEME.primary
    TL.Font=Enum.Font.GothamBold; TL.TextSize=13
    TL.TextXAlignment=Enum.TextXAlignment.Left

    local PanicBtn=Instance.new("TextButton",TopBar)
    PanicBtn.Size=UDim2.new(0,24,0,22); PanicBtn.Position=UDim2.new(1,-90,0.5,-11)
    PanicBtn.BackgroundColor3=Color3.fromRGB(140,20,20); PanicBtn.Text="❌"
    PanicBtn.TextColor3=Color3.fromRGB(255,255,255); PanicBtn.Font=Enum.Font.GothamBold
    PanicBtn.TextSize=11; PanicBtn.BorderSizePixel=0
    Instance.new("UICorner",PanicBtn).CornerRadius=UDim.new(0,5)
    Core:Add(PanicBtn.MouseButton1Click:Connect(function()
        Config.AutoAim.Enabled=false; Config.BallESP.Enabled=false
        Config.ESP.Enabled=false; Config.AutoAbility.Enabled=false
        Config.ScoreHUD.Enabled=false; Config.RallyHUD.Enabled=false
        ShowToast("PANIC — Semua OFF",false)
    end))

    local HideBtn=Instance.new("TextButton",TopBar)
    HideBtn.Size=UDim2.new(0,24,0,22); HideBtn.Position=UDim2.new(1,-62,0.5,-11)
    HideBtn.BackgroundColor3=Color3.fromRGB(20,50,20); HideBtn.Text="👁"
    HideBtn.TextColor3=Color3.fromRGB(150,255,150); HideBtn.Font=Enum.Font.GothamBold
    HideBtn.TextSize=11; HideBtn.BorderSizePixel=0
    Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(0,5)

    local MinBtn=Instance.new("TextButton",TopBar)
    MinBtn.Size=UDim2.new(0,24,0,22); MinBtn.Position=UDim2.new(1,-34,0.5,-11)
    MinBtn.BackgroundColor3=Color3.fromRGB(18,40,18); MinBtn.Text="—"
    MinBtn.TextColor3=Color3.fromRGB(200,200,200); MinBtn.Font=Enum.Font.GothamBold
    MinBtn.TextSize=12; MinBtn.BorderSizePixel=0
    Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,5)

    local TabBar=Instance.new("ScrollingFrame",Main)
    TabBar.Size=UDim2.new(1,0,0,26); TabBar.Position=UDim2.new(0,0,0,36)
    TabBar.BackgroundColor3=Color3.fromRGB(6,14,6); TabBar.BorderSizePixel=0
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
    Pill.Size=UDim2.new(0,105,0,24); Pill.Position=Wrapper.Position
    Pill.BackgroundColor3=Color3.fromRGB(8,22,8); Pill.Text="🎾 RACKET"
    Pill.TextColor3=THEME.primary; Pill.Font=Enum.Font.GothamBold
    Pill.TextSize=10; Pill.BorderSizePixel=0; Pill.Visible=false
    Instance.new("UICorner",Pill).CornerRadius=UDim.new(0,12)
    local PS=Instance.new("UIStroke",Pill); PS.Color=THEME.primary; PS.Thickness=1
    self.Pill=Pill

    Core:Add(HideBtn.MouseButton1Click:Connect(function()
        Pill.Position=UDim2.new(
            Wrapper.Position.X.Scale,Wrapper.Position.X.Offset,
            Wrapper.Position.Y.Scale,Wrapper.Position.Y.Offset)
        Wrapper.Visible=false; Pill.Visible=true
    end))
    Core:Add(Pill.MouseButton1Click:Connect(function()
        Wrapper.Position=Pill.Position; Wrapper.Visible=true; Pill.Visible=false
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
            Wrapper.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end))
    Core:Add(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end))

    local mini=false
    Core:Add(MinBtn.MouseButton1Click:Connect(function()
        mini=not mini; Content.Visible=not mini; TabBar.Visible=not mini
        Wrapper.Size=mini and UDim2.new(0,255,0,36) or UDim2.new(0,255,0,440)
        MinBtn.Text=mini and "+" or "—"
    end))
end

function UI:AddTab(name)
    local page=Instance.new("ScrollingFrame",self.Content)
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1
    page.BorderSizePixel=0; page.ScrollBarThickness=4
    page.ScrollBarImageColor3=THEME.primary
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
        task.wait(); page.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
    end
    local btn=Instance.new("TextButton",self.TabBar)
    btn.Size=UDim2.new(0,42,0,20)
    btn.BackgroundColor3=Color3.fromRGB(14,26,14)
    btn.Text=name; btn.TextColor3=Color3.fromRGB(80,160,80)
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=9; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    local entry={page=page,btn=btn}; table.insert(self._tabPages,entry)
    local function activate()
        for _,t in ipairs(self._tabPages) do
            t.page.Visible=false
            t.btn.BackgroundColor3=Color3.fromRGB(14,26,14)
            t.btn.TextColor3=Color3.fromRGB(80,160,80)
        end
        page.Visible=true
        btn.BackgroundColor3=THEME.primary
        btn.TextColor3=Color3.fromRGB(0,0,0)
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
    lbl.TextColor3=Color3.fromRGB(180,230,180)
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pill=Instance.new("TextButton",card)
    pill.Size=UDim2.new(0,32,0,15); pill.Position=UDim2.new(1,-40,0.5,-7)
    pill.BackgroundColor3=Color3.fromRGB(25,40,25)
    pill.Text=""; pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,11,0,11); knob.Position=UDim2.new(0,2,0.5,-5)
    knob.BackgroundColor3=Color3.fromRGB(80,120,80); knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    Core:Add(pill.MouseButton1Click:Connect(function()
        state=not state
        if state then
            pill.BackgroundColor3=color
            knob.Position=UDim2.new(1,-13,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(255,255,255)
        else
            pill.BackgroundColor3=Color3.fromRGB(25,40,25)
            knob.Position=UDim2.new(0,2,0.5,-5)
            knob.BackgroundColor3=Color3.fromRGB(80,120,80)
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
    fl.TextColor3=Color3.fromRGB(160,220,160); fl.Font=Enum.Font.GothamSemibold
    fl.TextSize=11; fl.TextXAlignment=Enum.TextXAlignment.Left
    local tr=Instance.new("Frame",fc)
    tr.Size=UDim2.new(1,-18,0,6); tr.Position=UDim2.new(0,9,0,28)
    tr.BackgroundColor3=Color3.fromRGB(20,40,20); tr.BorderSizePixel=0
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
-- [17] BOOTSTRAP
-- ============================================================================
UI:Build()

-- Tab AIM
do
    local p,r=UI:AddTab("Aim")

    -- Info card
    local ic=Instance.new("Frame",p)
    ic.Size=UDim2.new(1,0,0,44); ic.BackgroundColor3=Color3.fromRGB(6,18,6); ic.BorderSizePixel=0
    Instance.new("UICorner",ic).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",ic).Color=Color3.fromRGB(40,180,40)
    local il=Instance.new("TextLabel",ic)
    il.Size=UDim2.new(1,-10,1,-6); il.Position=UDim2.new(0,5,0,3); il.BackgroundTransparency=1
    il.Text="🎾 Hook ReplicateCamLook → arahkan\nke posisi bola sebelum hit"
    il.TextColor3=Color3.fromRGB(100,220,100); il.Font=Enum.Font.Gotham
    il.TextSize=10; il.TextXAlignment=Enum.TextXAlignment.Left; il.TextWrapped=true

    UI:Section(p,"AUTO AIM BOLA")
    UI:Toggle(p,"Auto Aim ke Bola",function(v)
        Config.AutoAim.Enabled=v
    end,Color3.fromRGB(100,255,100))
    UI:MakeSlider(p,"Range (stud)",Config.AutoAim.Range,20,300,function(v)
        Config.AutoAim.Range=v
    end)
    UI:MakeSlider(p,"Smoothness (x10)",math.floor(Config.AutoAim.Smoothness*10),1,10,function(v)
        Config.AutoAim.Smoothness=v/10
    end)

    -- Status bola realtime
    local ballCard=Instance.new("Frame",p)
    ballCard.Size=UDim2.new(1,0,0,30); ballCard.BackgroundColor3=Color3.fromRGB(8,16,8); ballCard.BorderSizePixel=0
    Instance.new("UICorner",ballCard).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",ballCard).Color=Color3.fromRGB(40,150,40)
    local ballLabel=Instance.new("TextLabel",ballCard)
    ballLabel.Size=UDim2.new(1,-10,1,-6); ballLabel.Position=UDim2.new(0,5,0,3)
    ballLabel.BackgroundTransparency=1; ballLabel.Text="🏸 Bola: menunggu data..."
    ballLabel.TextColor3=Color3.fromRGB(100,220,100); ballLabel.Font=Enum.Font.Gotham
    ballLabel.TextSize=10; ballLabel.TextXAlignment=Enum.TextXAlignment.Left

    Core:Add(RunService.Heartbeat:Connect(function()
        pcall(function()
            if #State.BallPositions>0 then
                local latest=State.BallPositions[1]
                local age=tick()-latest.time
                if age<2 then
                    local myHRP=LocalPlayer.Character
                        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local dist=myHRP and (myHRP.Position-latest.pos).Magnitude or 0
                    ballLabel.Text=string.format(
                        "🏸 Bola: %.1f stud | %.2fs lalu",dist,age)
                    ballLabel.TextColor3=age<0.5
                        and Color3.fromRGB(100,255,100)
                        or  Color3.fromRGB(200,200,100)
                else
                    ballLabel.Text="🏸 Bola: data expired"
                    ballLabel.TextColor3=Color3.fromRGB(150,150,150)
                end
            else
                ballLabel.Text="🏸 Bola: belum terdeteksi"
                ballLabel.TextColor3=Color3.fromRGB(150,150,150)
            end
        end)
    end))

    task.defer(r)
end

-- Tab BALL
do
    local p,r=UI:AddTab("Ball")
    UI:Section(p,"BALL ESP")
    UI:Toggle(p,"Ball ESP (Tampilkan Posisi)",function(v)
        Config.BallESP.Enabled=v
    end,Color3.fromRGB(255,220,50))
    UI:Toggle(p,"Trail Bola (Jejak Arah)",function(v)
        Config.BallESP.ShowTrail=v
    end,Color3.fromRGB(255,150,30))
    UI:MakeSlider(p,"Panjang Trail",Config.BallESP.TrailLength,3,20,function(v)
        Config.BallESP.TrailLength=v
    end)

    UI:Section(p,"SERVE ALERT")
    UI:Toggle(p,"Notifikasi Serve",function(v)
        Config.ServeAlert.Enabled=v
    end,Color3.fromRGB(100,200,255))
    task.defer(r)
end

-- Tab HUD
do
    local p,r=UI:AddTab("HUD")
    UI:Section(p,"SCORE MONITOR")
    UI:Toggle(p,"Score Monitor (Skor Court)",function(v)
        Config.ScoreHUD.Enabled=v
        BuildScoreHUD()
    end,Color3.fromRGB(100,255,100))

    UI:Section(p,"RALLY COUNTER")
    UI:Toggle(p,"Rally Counter (Hit Count)",function(v)
        Config.RallyHUD.Enabled=v
        BuildScoreHUD()
    end,Color3.fromRGB(255,200,50))

    -- Info court saya
    local courtCard=Instance.new("Frame",p)
    courtCard.Size=UDim2.new(1,0,0,28); courtCard.BackgroundColor3=Color3.fromRGB(8,16,8); courtCard.BorderSizePixel=0
    Instance.new("UICorner",courtCard).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",courtCard).Color=Color3.fromRGB(40,150,40)
    local courtLabel=Instance.new("TextLabel",courtCard)
    courtLabel.Size=UDim2.new(1,-10,1,-6); courtLabel.Position=UDim2.new(0,5,0,3)
    courtLabel.BackgroundTransparency=1; courtLabel.Text="⭐ Court saya: menunggu..."
    courtLabel.TextColor3=Color3.fromRGB(255,220,80); courtLabel.Font=Enum.Font.GothamBold
    courtLabel.TextSize=11; courtLabel.TextXAlignment=Enum.TextXAlignment.Left
    Core:Add(RunService.Heartbeat:Connect(function()
        pcall(function()
            if State.MyCourt then
                local score=State.Scores[State.MyCourt]
                local rally=State.RallyCounts[State.MyCourt] or 0
                if score then
                    courtLabel.Text=string.format(
                        "⭐ Court %d: %d-%d | Rally: %d",
                        State.MyCourt,score[1],score[2],rally)
                else
                    courtLabel.Text="⭐ Court "..State.MyCourt
                end
            else
                courtLabel.Text="⭐ Court: belum terdeteksi"
            end
        end)
    end))

    task.defer(r)
end

-- Tab ESP
do
    local p,r=UI:AddTab("ESP")
    UI:Section(p,"PLAYER ESP")
    UI:Toggle(p,"Aktifkan ESP",function(v) Config.ESP.Enabled=v end,THEME.primary)
    UI:Toggle(p,"Box ESP",function(v) Config.ESP.ShowBox=v end)
    UI:Toggle(p,"Name Tag",function(v) Config.ESP.ShowName=v end)
    UI:Toggle(p,"Health Bar",function(v) Config.ESP.ShowHealth=v end)
    UI:Toggle(p,"Distance",function(v) Config.ESP.ShowDistance=v end)
    task.defer(r)
end

-- Tab ABILITY
do
    local p,r=UI:AddTab("Skill")
    UI:Section(p,"AUTO ABILITY")

    local ic=Instance.new("Frame",p)
    ic.Size=UDim2.new(1,0,0,30); ic.BackgroundColor3=Color3.fromRGB(6,18,6); ic.BorderSizePixel=0
    Instance.new("UICorner",ic).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",ic).Color=Color3.fromRGB(40,180,40)
    local il=Instance.new("TextLabel",ic)
    il.Size=UDim2.new(1,-10,1,-6); il.Position=UDim2.new(0,5,0,3); il.BackgroundTransparency=1
    il.Text="Spam ability ke posisi bola otomatis"
    il.TextColor3=Color3.fromRGB(100,220,100); il.Font=Enum.Font.Gotham
    il.TextSize=10; il.TextXAlignment=Enum.TextXAlignment.Left

    UI:Toggle(p,"Auto Ability",function(v)
        Config.AutoAbility.Enabled=v; if v then StartAutoAbility() end
    end,Color3.fromRGB(200,100,255))
    UI:MakeSlider(p,"Delay (x10ms)",math.floor(Config.AutoAbility.Delay*100),5,200,function(v)
        Config.AutoAbility.Delay=v/100
    end)

    -- Pilih ability
    local abilityNames={
        "Freeze","Phase","Overload","Slow","Pull",
        "Blind","Void","Bomb","Time","Default"
    }
    local abilityRow=Instance.new("Frame",p)
    abilityRow.Size=UDim2.new(1,0,0,80); abilityRow.BackgroundColor3=THEME.card; abilityRow.BorderSizePixel=0
    Instance.new("UICorner",abilityRow).CornerRadius=UDim.new(0,6)
    local aTitle=Instance.new("TextLabel",abilityRow)
    aTitle.Size=UDim2.new(1,0,0,18); aTitle.BackgroundTransparency=1
    aTitle.Text="Pilih Ability:"; aTitle.TextColor3=Color3.fromRGB(160,220,160)
    aTitle.Font=Enum.Font.GothamBold; aTitle.TextSize=10; aTitle.Position=UDim2.new(0,6,0,2)
    aTitle.TextXAlignment=Enum.TextXAlignment.Left
    local aScrollRow=Instance.new("ScrollingFrame",abilityRow)
    aScrollRow.Size=UDim2.new(1,-4,1,-20); aScrollRow.Position=UDim2.new(0,2,0,18)
    aScrollRow.BackgroundTransparency=1; aScrollRow.BorderSizePixel=0
    aScrollRow.ScrollBarThickness=3; aScrollRow.ScrollBarImageColor3=THEME.primary
    aScrollRow.CanvasSize=UDim2.new(0,0,0,0); aScrollRow.ScrollingDirection=Enum.ScrollingDirection.X
    local aLayout=Instance.new("UIListLayout",aScrollRow)
    aLayout.FillDirection=Enum.FillDirection.Horizontal; aLayout.Padding=UDim.new(0,3)
    aLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    aLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        aScrollRow.CanvasSize=UDim2.new(0,aLayout.AbsoluteContentSize.X+6,0,0)
    end)
    local aBtns={}
    for _,abilName in ipairs(abilityNames) do
        local b=Instance.new("TextButton",aScrollRow)
        b.Size=UDim2.new(0,58,0,26)
        b.BackgroundColor3=abilName==Config.AutoAbility.AbilityName
            and THEME.primary or Color3.fromRGB(20,40,20)
        b.Text=abilName; b.TextColor3=Color3.fromRGB(200,255,200)
        b.Font=Enum.Font.GothamBold; b.TextSize=9; b.BorderSizePixel=0
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        table.insert(aBtns,{btn=b,name=abilName})
        Core:Add(b.MouseButton1Click:Connect(function()
            Config.AutoAbility.AbilityName=abilName
            for _,e in ipairs(aBtns) do
                e.btn.BackgroundColor3=e.name==abilName
                    and THEME.primary or Color3.fromRGB(20,40,20)
            end
            ShowToast("Ability: "..abilName,true)
        end))
    end
    task.defer(r)
end

-- ============================================================================
print("✅ NEXUS Racket Rivals — Loaded")
print("🎾 Auto Aim: hook ReplicateCamLook")
print("🏸 Ball ESP dari Action remote data")
print("📊 Score + Rally Monitor realtime")
-- ============================================================================
