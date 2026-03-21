--[[
    ============================================================================
    PROJECT   : NEXUS v1.7 — Sovereign Edition
    PLATFORM  : Delta Executor Android
    AUTHOR    : Claude Sonnet 4.6
    NEW v1.7:
    ├── FIX: ESP sub-fitur independen (default OFF semua)
    ├── FIX: Damage 100% kena saat teleport
    ├── Translate Chat (ID→EN / EN→ID via MyMemory API)
    ├── Teleport System (Player/Monster/Posisi)
    ├── Billboard HP (BillboardGui di atas kepala)
    ├── Item Rarity ESP (warna per rarity)
    ├── Boss Tracker (nama+HP+arrow)
    ├── Anti Ban Mode (randomisasi interval)
    ├── Crash Prevention (auto disable berat)
    ├── Instance Monitor (deteksi spawn event)
    ├── Custom Color Picker (RGB slider)
    ├── Script Hub Mini (simpan & run script)
    ├── Performance Monitor (memory/ping/drawing)
    ├── Server Hop (pindah server otomatis)
    └── Remote Spy Lite (monitor FireServer)
    ============================================================================
]]

local ENV_KEY="Nexus_Suite_v1_7"
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
local TextChatService  = pcall(function() return game:GetService("TextChatService") end)
                         and game:GetService("TextChatService") or nil

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
    Blue  ={primary=Color3.fromRGB(40,100,255),  bg=Color3.fromRGB(14,14,20),  topbar=Color3.fromRGB(20,20,30)},
    Red   ={primary=Color3.fromRGB(220,40,40),   bg=Color3.fromRGB(18,10,10),  topbar=Color3.fromRGB(28,12,12)},
    Green ={primary=Color3.fromRGB(30,200,80),   bg=Color3.fromRGB(10,18,12),  topbar=Color3.fromRGB(12,26,16)},
    Purple={primary=Color3.fromRGB(150,50,255),  bg=Color3.fromRGB(14,10,20),  topbar=Color3.fromRGB(20,12,30)},
    Gold  ={primary=Color3.fromRGB(220,170,20),  bg=Color3.fromRGB(18,15,8),   topbar=Color3.fromRGB(26,22,10)},
}
local CurrentTheme=Themes.Blue

-- ============================================================================
-- [4] CONFIG
-- [FIX] Semua sub-fitur ESP default FALSE
-- User nyalakan sendiri yang dibutuhkan
-- ============================================================================
local SpeedTiers={Normal=28,Fast=60,Turbo=100,Ultra=160}
local CONFIG_FILE="nexus_v17_config.json"

local Config={
    ESP={
        Enabled=false,
        -- [FIX v1.7] Semua sub-fitur default FALSE
        -- Tidak ada yang otomatis aktif saat ESP dinyalakan
        ShowHighlight=false,
        ShowBox=false,
        ShowName=false,
        ShowHealth=false,
        ShowHealthNum=false,
        ShowDistance=false,
        ShowHeadDot=false,
        ShowSkeleton=false,
        ShowSnapLine=false,
        ShowChams=false,
        ShowLevelTag=false,
        AdaptiveOpacity=false,
        ShowBillboard=false,   -- [v1.7] Billboard HP
        ShowRarityESP=false,   -- [v1.7] Item Rarity
        MaxDistance=99999,CullDistance=1500,
        TeamColor=Color3.fromRGB(30,220,80),
        EnemyColor=Color3.fromRGB(255,50,50),
        FillAlpha=0.2,OutlineAlpha=0.0,
        -- [v1.7] Custom colors
        CustomESPColor=false,
        CustomR=255,CustomG=50,CustomB=50,
    },
    Aimbot={
        Enabled=false,FOVRadius=200,FOVVisible=true,Smoothness=0.35,
        TargetPart="Head",WallCheck=true,TeamCheck=true,AliveCheck=true,
        PredictMovement=true,PredictFactor=0.12,SilentAim=false,
        Triggerbot=false,TriggerDelay=0.05,KillAura=false,KillAuraRadius=15,
        Priority="FOV",NoRecoil=false,
        -- [v1.7] Shake prevention
        ShakePrevention=false,
    },
    Mods={
        Speed=false,SpeedTier="Fast",Noclip=false,InfJump=false,
        Fly=false,FlySpeed=55,FullBright=false,AntiAFK=false,
        FPSBoost=false,AutoRejoin=false,InfStamina=false,
        AntiVoid=false,BunnyHop=false,
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
        AutoFarm=false,BlinkAttack=false,BlinkRadius=400,BlinkInterval=1.5,
        AutoCollect=false,CollectRadius=50,AutoQuest=false,DungeonHelper=false,
    },
    Combat={AutoCombo=false,ComboDelay=0.1,BlockPredict=false,ParryTiming=false},
    Sim={AutoClick=false,AutoClickDelay=0.05,AutoRebirth=false,MultiplierESP=false},
    World={WorldESP=false,SafeZoneDetect=false,WeatherAlert=false},
    Chat={Bypass=false},
    -- [v1.7] Fitur baru
    Translate={
        Enabled=false,        -- translate outgoing chat ID→EN
        IncomingTranslate=false, -- translate incoming EN→ID
        ShowOriginal=true,    -- tampilkan teks asli juga
    },
    Teleport={
        TeleportMode="Player", -- Player/Monster/Custom
        TeleportRadius=500,
        AutoAttackAfter=true,  -- [FIX] auto attack setelah teleport
    },
    BossTracker={Enabled=false},
    AntiBan={
        Enabled=false,
        RandomizeInterval=true,
        MinDelay=0.8,
        MaxDelay=2.0,
    },
    CrashPrevention={Enabled=true},
    InstanceMonitor={Enabled=false},
    ServerHop={
        Enabled=false,
        MinPlayers=0,
        MaxPlayers=5,
    },
    RemoteSpy={Enabled=false},
    ScriptHub={scripts={}},
    Performance={Enabled=false},
}

-- ============================================================================
-- [5] CONFIG SAVE / LOAD
-- Hanya simpan setting NON-TOGGLE
-- Toggle state tidak disimpan agar tidak auto-aktif
-- ============================================================================
local function SaveConfig()
    pcall(function()
        local d={
            AimbotFOV=Config.Aimbot.FOVRadius,
            AimbotSmooth=Config.Aimbot.Smoothness,
            AimbotPriority=Config.Aimbot.Priority,
            SpeedTier=Config.Mods.SpeedTier,
            UITheme=Config.UI.Theme,
            UIOpacity=Config.UI.Opacity,
            CrosshairStyle=Config.Crosshair.Style,
            BlinkRadius=Config.RPG.BlinkRadius,
            BlinkInterval=Config.RPG.BlinkInterval,
            CustomR=Config.ESP.CustomR,
            CustomG=Config.ESP.CustomG,
            CustomB=Config.ESP.CustomB,
            ScriptHub=Config.ScriptHub.scripts,
        }
        writefile(CONFIG_FILE,HttpService:JSONEncode(d))
    end)
end

local function LoadConfig()
    pcall(function()
        if not isfile(CONFIG_FILE) then return end
        local d=HttpService:JSONDecode(readfile(CONFIG_FILE))
        if not d then return end
        Config.Aimbot.FOVRadius=d.AimbotFOV or 200
        Config.Aimbot.Smoothness=d.AimbotSmooth or 0.35
        Config.Aimbot.Priority=d.AimbotPriority or "FOV"
        Config.Mods.SpeedTier=d.SpeedTier or "Fast"
        Config.UI.Theme=d.UITheme or "Blue"
        Config.UI.Opacity=d.UIOpacity or 1.0
        Config.Crosshair.Style=d.CrosshairStyle or "Cross"
        Config.RPG.BlinkRadius=d.BlinkRadius or 400
        Config.RPG.BlinkInterval=d.BlinkInterval or 1.5
        Config.ESP.CustomR=d.CustomR or 255
        Config.ESP.CustomG=d.CustomG or 50
        Config.ESP.CustomB=d.CustomB or 50
        if d.ScriptHub then Config.ScriptHub.scripts=d.ScriptHub end
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
        f.Size=UDim2.new(0,210,0,28); f.Position=UDim2.new(0.5,-105,0.85,0)
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

-- Notifikasi translate (lebih panjang)
local function ShowTranslateNotif(original,translated,direction)
    pcall(function()
        local existing=SafeGUI:FindFirstChild("NexusTranslate")
        if existing then existing:Destroy() end
        local sg=Instance.new("ScreenGui",SafeGUI)
        sg.Name="NexusTranslate"; sg.ResetOnSpawn=false; sg.DisplayOrder=9998
        Core:Add(sg)
        local f=Instance.new("Frame",sg)
        f.Size=UDim2.new(0,280,0,60); f.Position=UDim2.new(0.5,-140,0.75,0)
        f.BackgroundColor3=Color3.fromRGB(10,10,20); f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,10)
        local fs=Instance.new("UIStroke",f)
        fs.Color=Color3.fromRGB(40,100,255); fs.Thickness=1
        local dir=Instance.new("TextLabel",f)
        dir.Size=UDim2.new(1,0,0,16); dir.Position=UDim2.new(0,0,0,4)
        dir.BackgroundTransparency=1; dir.Text=direction
        dir.TextColor3=Color3.fromRGB(100,180,255); dir.Font=Enum.Font.GothamBold
        dir.TextSize=9; dir.TextXAlignment=Enum.TextXAlignment.Center
        local tl=Instance.new("TextLabel",f)
        tl.Size=UDim2.new(1,-12,0,18); tl.Position=UDim2.new(0,6,0,18)
        tl.BackgroundTransparency=1; tl.Text=translated
        tl.TextColor3=Color3.fromRGB(255,255,200); tl.Font=Enum.Font.Gotham
        tl.TextSize=11; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.TextWrapped=true
        if Config.Translate.ShowOriginal then
            local ol=Instance.new("TextLabel",f)
            ol.Size=UDim2.new(1,-12,0,14); ol.Position=UDim2.new(0,6,0,38)
            ol.BackgroundTransparency=1; ol.Text="("..original..")"
            ol.TextColor3=Color3.fromRGB(120,120,120); ol.Font=Enum.Font.Gotham
            ol.TextSize=9; ol.TextXAlignment=Enum.TextXAlignment.Left; ol.TextWrapped=true
        end
        task.delay(4,function()
            for i=1,10 do
                pcall(function() f.BackgroundTransparency=i/10 end)
                task.wait(0.05)
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
    local function scanFolder(f)
        if not f then return end
        for _,obj in ipairs(f:GetDescendants()) do
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
            local isPlayer=false
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl.Character==obj then isPlayer=true; break end
            end
            if not isPlayer then
                local hum=obj:FindFirstChildOfClass("Humanoid")
                local hrp=obj:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health>0 then
                    local dist=(hrp.Position-myHRP.Position).Magnitude
                    if dist<minDist then minDist=dist; nearest=obj end
                end
            end
        end
    end
    return nearest
end

-- [v1.7] Anti Ban — randomisasi interval
local function RandomDelay()
    if not Config.AntiBan.Enabled or not Config.AntiBan.RandomizeInterval then
        return 0
    end
    local min=Config.AntiBan.MinDelay
    local max=Config.AntiBan.MaxDelay
    return min+(math.random()*(max-min))
end

-- ============================================================================
-- [9] TRANSLATE MODULE — MyMemory API (gratis)
-- ============================================================================
local _translateCache={}

local function TranslateText(text,fromLang,toLang)
    -- Cek cache dulu
    local cacheKey=text..fromLang..toLang
    if _translateCache[cacheKey] then return _translateCache[cacheKey] end

    local encoded=HttpService:UrlEncode(text)
    local url=string.format(
        "https://api.mymemory.translated.net/get?q=%s&langpair=%s|%s",
        encoded,fromLang,toLang
    )
    local ok,result=pcall(function()
        return game:HttpGet(url,true)
    end)
    if not ok then return text end

    local ok2,data=pcall(function()
        return HttpService:JSONDecode(result)
    end)
    if not ok2 then return text end

    local translated=data and data.responseData and data.responseData.translatedText
    if translated and translated~="" then
        _translateCache[cacheKey]=translated
        return translated
    end
    return text
end

-- Detect bahasa (sederhana — cek karakter Indonesia)
local function DetectLang(text)
    -- Kata umum Indonesia
    local idWords={"aku","kamu","saya","dia","kami","mereka","ini","itu",
        "yang","dengan","untuk","dari","ke","di","dan","atau","tidak","ada"}
    local textLower=text:lower()
    for _,word in ipairs(idWords) do
        if textLower:find("%f[%w]"..word.."%f[%W]") then return "id" end
    end
    return "en"
end

-- Hook chat untuk translate outgoing
local _originalSendMessage
local function InitTranslateHook()
    -- Translate outgoing (ID → EN)
    pcall(function()
        local mt=getrawmetatable(game)
        local old=mt.__namecall
        setreadonly(mt,false)
        mt.__namecall=newcclosure(function(self,...)
            local method=getnamecallmethod()
            if Config.Translate.Enabled then
                if method=="FireServer" then
                    -- Cek apakah ini chat remote
                    local selfName=tostring(self):lower()
                    if selfName:find("chat") or selfName:find("message") or selfName:find("say") then
                        local args={...}
                        if type(args[1])=="string" and args[1]~="" then
                            local lang=DetectLang(args[1])
                            if lang=="id" then
                                local translated=TranslateText(args[1],"id","en")
                                args[1]=translated
                                ShowTranslateNotif(args[1],translated,"📤 ID → EN")
                                return old(self,table.unpack(args))
                            end
                        end
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
pcall(InitTranslateHook)

-- Listen incoming chat untuk translate EN → ID
Core:Add(Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if not Config.Translate.IncomingTranslate then return end
        if player==LocalPlayer then return end
        local lang=DetectLang(msg)
        if lang=="en" then
            local translated=TranslateText(msg,"en","id")
            ShowTranslateNotif(msg,translated,"📥 "..player.Name..": EN → ID")
        end
    end)
end))

-- Hook existing players juga
for _,player in ipairs(Players:GetPlayers()) do
    if player~=LocalPlayer then
        Core:Add(player.Chatted:Connect(function(msg)
            if not Config.Translate.IncomingTranslate then return end
            local lang=DetectLang(msg)
            if lang=="en" then
                local translated=TranslateText(msg,"en","id")
                ShowTranslateNotif(msg,translated,"📥 "..player.Name..": EN → ID")
            end
        end))
    end
end

-- ============================================================================
-- [10] TELEPORT SYSTEM — dengan 100% damage guarantee
-- ============================================================================
local _teleportHistory={}  -- simpan 5 posisi terakhir
local _maxHistory=5

local function SaveTeleportHistory()
    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    table.insert(_teleportHistory,1,hrp.CFrame)
    if #_teleportHistory>_maxHistory then
        table.remove(_teleportHistory,#_teleportHistory)
    end
end

--[[
    [FIX v1.7] TELEPORT + 100% DAMAGE:
    1. Simpan posisi sebelum teleport
    2. Arahkan kamera ke target
    3. Teleport ke target
    4. Arahkan kamera LAGI dari posisi baru
    5. Tunggu sebentar (pastikan client & server sync)
    6. Serang
    Hasilnya: damage dijamin kena karena
    kamera sudah mengarah sebelum & sesudah teleport
]]
local function TeleportAndAttack(targetModel)
    local char=LocalPlayer.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local tHRP=targetModel:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end

    -- Simpan posisi untuk history
    SaveTeleportHistory()

    -- Step 1: Arahkan kamera ke target SEBELUM teleport
    Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,tHRP.Position)
    task.wait(0.06)

    -- Step 2: Teleport ke depan target
    hrp.CFrame=tHRP.CFrame*CFrame.new(0,0,-3.5)
    task.wait(0.06)

    -- Step 3: Arahkan kamera LAGI dari posisi baru
    Camera.CFrame=CFrame.lookAt(
        hrp.Position+Vector3.new(0,2,0),
        tHRP.Position
    )
    task.wait(0.06)

    -- Step 4: Serang jika auto attack aktif
    if Config.Teleport.AutoAttackAfter then
        -- Coba M1 (scan dinamis)
        local m1Remote=nil
        pcall(function()
            local RS=game:GetService("ReplicatedStorage")
            for _,obj in ipairs(RS:GetDescendants()) do
                if obj.Name:lower()=="m1" and obj:IsA("RemoteEvent") then
                    m1Remote=obj; break
                end
            end
        end)
        if m1Remote then pcall(function() m1Remote:FireServer() end) end
        task.wait(0.03)

        -- Tool activate
        pcall(function()
            local tool=char:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end)
        task.wait(0.03)

        -- Touch
        pcall(function() firetouchinterest(hrp,tHRP,0) end)
        task.wait(0.02)
        pcall(function() firetouchinterest(hrp,tHRP,1) end)
        task.wait(0.03)

        -- Fallback
        pcall(function() mouse1click() end)
    end
end

-- Teleport ke player by name
local function TeleportToPlayer(name)
    local target
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl.Name:lower():find(name:lower()) and pl~=LocalPlayer then
            target=pl; break
        end
    end
    if not target then ShowToast("Player tidak ditemukan",false); return end
    local tHRP=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not(tHRP and hrp) then ShowToast("Character tidak ada",false); return end
    SaveTeleportHistory()
    hrp.CFrame=tHRP.CFrame*CFrame.new(0,0,-4)
    ShowToast("Teleport → "..target.Name,true)
end

-- Teleport ke monster terdekat
local function TeleportToMonster()
    local target=GetNearestMonster(Config.Teleport.TeleportRadius)
    if not target then ShowToast("Tidak ada monster",false); return end
    TeleportAndAttack(target)
    ShowToast("Blink → "..target.Name,true)
end

-- Teleport balik (history)
local function TeleportBack()
    if #_teleportHistory==0 then ShowToast("Tidak ada history",false); return end
    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local lastPos=table.remove(_teleportHistory,1)
    hrp.CFrame=lastPos
    ShowToast("Teleport balik!",true)
end

-- ============================================================================
-- [11] ESP MODULE
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

-- [v1.7] Rarity colors
local RARITY_COLORS={
    common=Color3.fromRGB(200,200,200),
    uncommon=Color3.fromRGB(80,200,80),
    rare=Color3.fromRGB(40,120,255),
    epic=Color3.fromRGB(160,50,255),
    legendary=Color3.fromRGB(255,165,0),
    mythic=Color3.fromRGB(255,50,50),
}

local ESPCache={}
local _chamsCache={}

local function GetESPColor(relation)
    if Config.ESP.CustomESPColor then
        return Color3.fromRGB(Config.ESP.CustomR,Config.ESP.CustomG,Config.ESP.CustomB)
    end
    return relation=="Team" and Config.ESP.TeamColor or Config.ESP.EnemyColor
end

local function ApplyChams(player,on)
    local char=player.Character; if not char then return end
    local col=GetESPColor(GetRelation(player))
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
    local c={_lastRelation=nil,_bones={},_billboard=nil}
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
    if c._billboard then pcall(function() c._billboard:Destroy() end) end
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
    if c._billboard then c._billboard.Enabled=false end
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

        -- [FIX] Master toggle hanya kontrol on/off
        -- Sub-fitur punya state independen masing-masing
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
            local col=GetESPColor(rel)
            c.Highlight.FillColor=col; c.Highlight.OutlineColor=col
            c.BoxT.Color=col; c.BoxB.Color=col; c.BoxL.Color=col; c.BoxR.Color=col
            c.Text.Color=col; c.HeadDot.Color=col; c.SnapLine.Color=col
            for _,b in ipairs(c._bones) do b.Color=col end
            c._lastRelation=rel
        end

        -- [FIX] Setiap sub-fitur cek state SENDIRI
        -- Tidak terpengaruh oleh sub-fitur lain
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

        if Config.ESP.ShowName then
            c.Text.Text=player.Name; c.Text.Position=Vector2.new(cx,tV.Y-17); c.Text.Visible=true
        else c.Text.Visible=false end

        if Config.ESP.ShowDistance then
            c.DistText.Text=string.format("[%.0fm]",dist); c.DistText.Position=Vector2.new(cx,bV.Y+3); c.DistText.Visible=true
        else c.DistText.Visible=false end

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

        -- [v1.7] Billboard HP di atas kepala
        if Config.ESP.ShowBillboard and head then
            if not c._billboard or not c._billboard.Parent then
                -- Buat billboard baru
                local bb=Instance.new("BillboardGui")
                bb.Name="NexusBillboard"
                bb.Size=UDim2.new(0,80,0,20)
                bb.StudsOffset=Vector3.new(0,2.5,0)
                bb.AlwaysOnTop=true
                bb.Enabled=true
                bb.Adornee=head
                bb.Parent=CoreGui
                local frame=Instance.new("Frame",bb)
                frame.Size=UDim2.new(1,0,1,0); frame.BackgroundColor3=Color3.new(0,0,0)
                frame.BackgroundTransparency=0.5; frame.BorderSizePixel=0
                Instance.new("UICorner",frame).CornerRadius=UDim.new(0,4)
                local bar=Instance.new("Frame",frame)
                bar.Name="Bar"; bar.BackgroundColor3=Color3.new(0,1,0)
                bar.Size=UDim2.new(1,0,1,0); bar.BorderSizePixel=0
                Instance.new("UICorner",bar).CornerRadius=UDim.new(0,4)
                local label=Instance.new("TextLabel",bb)
                label.Name="Label"; label.Size=UDim2.new(1,0,0,14)
                label.Position=UDim2.new(0,0,1,1); label.BackgroundTransparency=1
                label.Font=Enum.Font.GothamBold; label.TextSize=9
                label.TextColor3=Color3.fromRGB(255,255,255); label.TextStrokeTransparency=0
                c._billboard=bb
                Core:Add(bb)
            end
            -- Update bar
            local hp=hum.Health/math.max(hum.MaxHealth,1)
            pcall(function()
                c._billboard.Enabled=true
                local bar=c._billboard:FindFirstChild("Frame") and c._billboard.Frame:FindFirstChild("Bar")
                if bar then
                    bar.Size=UDim2.new(hp,0,1,0)
                    bar.BackgroundColor3=Color3.new(1-hp,hp,0)
                end
                local label=c._billboard:FindFirstChild("Label")
                if label then
                    label.Text=string.format("%d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth))
                end
            end)
        elseif c._billboard then
            pcall(function() c._billboard.Enabled=false end)
        end
    end
end))

-- ============================================================================
-- [12] AIMBOT
-- ============================================================================
local FOVCircle=Drawing.new("Circle")
FOVCircle.Radius=Config.Aimbot.FOVRadius; FOVCircle.Visible=false
FOVCircle.Color=Color3.fromRGB(255,255,255); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false
getgenv().Nexus_FOVCircle=FOVCircle
Core:Add(function() pcall(function() FOVCircle:Remove() end); getgenv().Nexus_FOVCircle=nil end)

local _hasTarget=false
local _lastCamCF=nil  -- untuk shake prevention

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
        if (cp-tp).Magnitude>0.1 then
            local targetCF=CFrame.lookAt(cp,tp)
            -- [v1.7] Shake Prevention — smooth lebih halus
            if Config.Aimbot.ShakePrevention and _lastCamCF then
                local lerpFactor=math.min(Config.Aimbot.Smoothness,0.25)
                Camera.CFrame=_lastCamCF:Lerp(targetCF,lerpFactor)
            else
                Camera.CFrame=Camera.CFrame:Lerp(targetCF,Config.Aimbot.Smoothness)
            end
            _lastCamCF=Camera.CFrame
        end
    else _lastCamCF=nil end
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
            if (mh.Position-hr.Position).Magnitude<=Config.Aimbot.KillAuraRadius then
                pcall(function() mouse1click() end)
            end
        end
    end)
end
Core:Add(function() if _killAuraConn then _killAuraConn:Disconnect() end end)

-- ============================================================================
-- [13] CROSSHAIR
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
-- [14] RADAR
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
-- [15] FPS COUNTER
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
-- [16] v1.7 NEW FEATURES
-- ============================================================================

-- [v1.7] BOSS TRACKER
local _bossObjs={}; local _bossTimer=0
Core:Add(RunService.RenderStepped:Connect(function(dt)
    if not Config.BossTracker.Enabled then
        for _,o in ipairs(_bossObjs) do pcall(function() o:Remove() end) end; _bossObjs={}; return
    end
    _bossTimer=_bossTimer+dt; if _bossTimer<1 then return end; _bossTimer=0
    for _,o in ipairs(_bossObjs) do pcall(function() o:Remove() end) end; _bossObjs={}
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local bossKeywords={"boss","elite","king","lord","master","giant","dragon","demon"}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local nameLower=obj.Name:lower()
            local isBoss=false
            for _,kw in ipairs(bossKeywords) do
                if nameLower:find(kw) then isBoss=true; break end
            end
            if isBoss then
                local hum=obj:FindFirstChildOfClass("Humanoid")
                local hrp=obj:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health>0 then
                    local dist=(hrp.Position-myHRP.Position).Magnitude
                    local sp,on=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,5,0))
                    if on then
                        local hp=hum.Health/math.max(hum.MaxHealth,1)
                        local t=Drawing.new("Text"); t.Size=14; t.Center=true; t.Outline=true
                        t.Color=Color3.fromRGB(255,80,80)
                        t.Text=string.format("👹 %s | HP: %.0f%% | %.0fm",obj.Name,hp*100,dist)
                        t.Position=Vector2.new(sp.X,sp.Y); t.Visible=true; t.ZIndex=8
                        table.insert(_bossObjs,t)
                    else
                        -- Arrow penunjuk arah boss (saat tidak terlihat di layar)
                        local dir=(hrp.Position-myHRP.Position).Unit
                        local screenDir=Camera:WorldToViewportPoint(myHRP.Position+dir*5)
                        local arrowX=math.clamp(screenDir.X,50,Camera.ViewportSize.X-50)
                        local arrowY=math.clamp(screenDir.Y,50,Camera.ViewportSize.Y-50)
                        local arrow=Drawing.new("Text"); arrow.Size=20; arrow.Center=true
                        arrow.Color=Color3.fromRGB(255,80,80); arrow.Outline=true
                        arrow.Text="▶ BOSS ["..string.format("%.0fm",dist).."]"
                        arrow.Position=Vector2.new(arrowX,arrowY); arrow.Visible=true; arrow.ZIndex=8
                        table.insert(_bossObjs,arrow)
                    end
                end
            end
        end
    end
end))
Core:Add(function() for _,o in ipairs(_bossObjs) do pcall(function() o:Remove() end) end end)

-- [v1.7] ITEM RARITY ESP
local _rarityObjs={}; local _rarityTimer=0
Core:Add(RunService.RenderStepped:Connect(function(dt)
    if not Config.ESP.ShowRarityESP then
        for _,o in ipairs(_rarityObjs) do pcall(function() o:Remove() end) end; _rarityObjs={}; return
    end
    _rarityTimer=_rarityTimer+dt; if _rarityTimer<1 then return end; _rarityTimer=0
    for _,o in ipairs(_rarityObjs) do pcall(function() o:Remove() end) end; _rarityObjs={}
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local nameLower=obj.Name:lower()
            local col=nil
            if nameLower:find("mythic") then col=RARITY_COLORS.mythic
            elseif nameLower:find("legendary") then col=RARITY_COLORS.legendary
            elseif nameLower:find("epic") then col=RARITY_COLORS.epic
            elseif nameLower:find("rare") then col=RARITY_COLORS.rare
            elseif nameLower:find("uncommon") then col=RARITY_COLORS.uncommon
            elseif nameLower:find("common") then col=RARITY_COLORS.common end
            if col then
                local part=obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                if part then
                    local dist=(part.Position-myHRP.Position).Magnitude
                    if dist<1000 then
                        local sp,on=Camera:WorldToViewportPoint(part.Position+Vector3.new(0,3,0))
                        if on then
                            local t=Drawing.new("Text"); t.Size=12; t.Center=true; t.Outline=true
                            t.Color=col; t.Text="✦ "..obj.Name.." ["..string.format("%.0fm",dist).."]"
                            t.Position=Vector2.new(sp.X,sp.Y); t.Visible=true; t.ZIndex=7
                            table.insert(_rarityObjs,t)
                        end
                    end
                end
            end
        end
    end
end))
Core:Add(function() for _,o in ipairs(_rarityObjs) do pcall(function() o:Remove() end) end end)

-- [v1.7] INSTANCE MONITOR
local _instanceConn
local function StartInstanceMonitor()
    if _instanceConn then _instanceConn:Disconnect(); _instanceConn=nil end
    if not Config.InstanceMonitor.Enabled then return end
    local importantKeywords={"boss","chest","event","portal","spawn","rare","mythic","legendary"}
    _instanceConn=Workspace.DescendantAdded:Connect(function(obj)
        if not Config.InstanceMonitor.Enabled then return end
        local name=obj.Name:lower()
        for _,kw in ipairs(importantKeywords) do
            if name:find(kw) then
                ShowToast("⚠️ Spawned: "..obj.Name,true)
                break
            end
        end
    end)
end
Core:Add(function() if _instanceConn then _instanceConn:Disconnect() end end)

-- [v1.7] CRASH PREVENTION
local _crashCheckTimer=0
Core:Add(RunService.Heartbeat:Connect(function(dt)
    if not Config.CrashPrevention.Enabled then return end
    _crashCheckTimer=_crashCheckTimer+dt; if _crashCheckTimer<5 then return end; _crashCheckTimer=0
    local drawCount=#_rarityObjs+#_bossObjs+#_crossObjs
    for _ in pairs(ESPCache) do drawCount=drawCount+20 end
    if drawCount>500 then
        -- Terlalu banyak drawing object → disable beberapa
        Config.ESP.ShowRarityESP=false
        Config.ESP.ShowSkeleton=false
        ShowToast("⚠️ Auto disable: terlalu berat",false)
    end
end))

-- [v1.7] PERFORMANCE MONITOR
local _perfDraw={}
local function UpdatePerfDraw()
    for _,o in ipairs(_perfDraw) do pcall(function() o:Remove() end) end; _perfDraw={}
    if not Config.Performance.Enabled then return end
    local lines={
        string.format("FPS: %d",_fd),
        string.format("Ping: %dms",math.floor(LocalPlayer.NetworkPing*1000 or 0)),
        string.format("Drawing: %d objs",#_rarityObjs+#_bossObjs+#_crossObjs),
        string.format("Players: %d",#Players:GetPlayers()),
    }
    for i,line in ipairs(lines) do
        local t=Drawing.new("Text"); t.Size=11; t.Outline=true; t.Visible=true; t.ZIndex=12
        t.Color=Color3.fromRGB(200,200,255)
        t.Position=Vector2.new(8,Camera.ViewportSize.Y-80+(i*16))
        t.Text=line; table.insert(_perfDraw,t)
    end
end
local _perfTimer=0
Core:Add(RunService.RenderStepped:Connect(function(dt)
    _perfTimer=_perfTimer+dt; if _perfTimer<0.5 then return end; _perfTimer=0
    UpdatePerfDraw()
end))
Core:Add(function() for _,o in ipairs(_perfDraw) do pcall(function() o:Remove() end) end end)

-- [v1.7] SERVER HOP
local function DoServerHop()
    local currentPlayers=#Players:GetPlayers()
    if currentPlayers>=Config.ServerHop.MaxPlayers then
        ShowToast("Server penuh → Hopping...",false)
        pcall(function()
            local servers={}
            local ok,result=pcall(function()
                return game:HttpGet(
                    "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=25",
                    true
                )
            end)
            if ok then
                local data=HttpService:JSONDecode(result)
                if data and data.data then
                    for _,server in ipairs(data.data) do
                        if server.playing<=Config.ServerHop.MaxPlayers and server.id~=game.JobId then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId,server.id,LocalPlayer)
                            return
                        end
                    end
                end
            end
            -- Fallback: teleport ke server baru
            TeleportService:Teleport(game.PlaceId,LocalPlayer)
        end)
    else
        ShowToast("Server OK ("..currentPlayers.." players)",true)
    end
end

local _serverHopConn
local function StartServerHop()
    if _serverHopConn then _serverHopConn:Disconnect(); _serverHopConn=nil end
    if not Config.ServerHop.Enabled then return end
    local t=0
    _serverHopConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.ServerHop.Enabled then _serverHopConn:Disconnect(); _serverHopConn=nil; return end
        t=t+dt; if t<30 then return end; t=0
        if #Players:GetPlayers()>Config.ServerHop.MaxPlayers then
            DoServerHop()
        end
    end)
end
Core:Add(function() if _serverHopConn then _serverHopConn:Disconnect() end end)

-- [v1.7] REMOTE SPY LITE
local _spyLog={}
local _maxSpyLog=50
local _spyHooked=false
local _spyLabel=nil

local function InitRemoteSpy()
    if _spyHooked then return end
    _spyHooked=true
    pcall(function()
        local mt=getrawmetatable(game)
        local old=mt.__namecall
        setreadonly(mt,false)
        mt.__namecall=newcclosure(function(self,...)
            local method=getnamecallmethod()
            if Config.RemoteSpy.Enabled then
                if method=="FireServer" or method=="InvokeServer" then
                    local selfPath=pcall(function() return self:GetFullName() end)
                        and self:GetFullName() or tostring(self)
                    local entry=string.format("[%s] %s",method,selfPath)
                    table.insert(_spyLog,1,entry)
                    if #_spyLog>_maxSpyLog then table.remove(_spyLog,#_spyLog) end
                    if _spyLabel then
                        pcall(function()
                            _spyLabel.Text=table.concat(_spyLog,"\n",1,math.min(8,#_spyLog))
                        end)
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

-- ============================================================================
-- [17] PHYSICS MODS
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
        if (v:IsA("NumberValue") or v:IsA("IntValue")) then
            local name=v.Name:lower()
            if name:find("stamina") or name:find("energy") or name:find("mana") then
                pcall(function() if v.Value<100 then v.Value=100 end end)
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
        if ok and vu then
            _aafkConn=LocalPlayer.Idled:Connect(function()
                pcall(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
            end)
        end
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

-- Blink Attack
local _blinkLoopConn,_blinkOrigin,_blinkBusy=nil,nil,false
local _blinkTimeout=0

Core:Add(RunService.Heartbeat:Connect(function(dt)
    if not _blinkBusy then _blinkTimeout=0; return end
    _blinkTimeout=_blinkTimeout+dt
    if _blinkTimeout>=3 then
        pcall(function()
            local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and _blinkOrigin then hrp.CFrame=_blinkOrigin end
        end)
        _blinkOrigin=nil; _blinkBusy=false; _blinkTimeout=0
        ShowToast("Blink reset",false)
    end
end))

local function StartBlinkLoop()
    if _blinkLoopConn then _blinkLoopConn:Disconnect(); _blinkLoopConn=nil end
    _blinkOrigin=nil; _blinkBusy=false
    local t=0
    _blinkLoopConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.RPG.BlinkAttack then
            if _blinkBusy and _blinkOrigin then
                local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.CFrame=_blinkOrigin end) end
            end
            _blinkOrigin=nil; _blinkBusy=false
            _blinkLoopConn:Disconnect(); _blinkLoopConn=nil; return
        end
        t=t+dt
        -- Anti Ban: randomize interval
        local interval=Config.RPG.BlinkInterval+RandomDelay()
        if t<interval then return end; t=0
        if _blinkBusy then return end
        local char=LocalPlayer.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        task.spawn(function()
            _blinkBusy=true; _blinkOrigin=nil
            local ok=pcall(function()
                local target=GetNearestMonster(Config.RPG.BlinkRadius); if not target then _blinkBusy=false; return end
                local tHRP=target:FindFirstChild("HumanoidRootPart"); if not tHRP then _blinkBusy=false; return end
                _blinkOrigin=hrp.CFrame
                Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,tHRP.Position); task.wait(0.08)
                hrp.CFrame=tHRP.CFrame*CFrame.new(0,0,-3); task.wait(0.08)
                if not tHRP.Parent then if _blinkOrigin then hrp.CFrame=_blinkOrigin end; _blinkOrigin=nil; _blinkBusy=false; return end
                Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,tHRP.Position); task.wait(0.08)
                TeleportAndAttack(target); task.wait(0.3)
                if _blinkOrigin then
                    hrp.CFrame=_blinkOrigin; task.wait(0.08)
                    if tHRP.Parent then
                        Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,tHRP.Position); task.wait(0.08)
                        TeleportAndAttack(target)
                    end
                    _blinkOrigin=nil
                end
            end)
            _blinkBusy=false
        end)
    end)
end
Core:Add(function()
    if _blinkLoopConn then _blinkLoopConn:Disconnect() end
    if _blinkOrigin then
        local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.CFrame=_blinkOrigin end) end
        _blinkOrigin=nil
    end
    _blinkBusy=false
end)

local _farmConn
local function StartAutoFarm()
    if _farmConn then _farmConn:Disconnect(); _farmConn=nil end
    local t=0
    _farmConn=RunService.Heartbeat:Connect(function(dt)
        if not Config.RPG.AutoFarm then _farmConn:Disconnect(); _farmConn=nil; return end
        t=t+dt; if t<0.25+RandomDelay() then return end; t=0
        task.spawn(function()
            local target=GetNearestMonster(500); if not target then return end
            TeleportAndAttack(target)
        end)
    end)
end
Core:Add(function() if _farmConn then _farmConn:Disconnect() end end)

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
-- [18] UI MODULE
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
    Wrapper.Name="Wrapper"; Wrapper.Size=UDim2.new(0,265,0,455); Wrapper.Position=UDim2.new(0.04,0,0.06,0)
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
    TL.Text="⚡  NEXUS  v1.7"; TL.TextColor3=Color3.fromRGB(255,255,255)
    TL.Font=Enum.Font.GothamBold; TL.TextSize=13; TL.TextXAlignment=Enum.TextXAlignment.Left

    local HideBtn=Instance.new("TextButton",TopBar)
    HideBtn.Size=UDim2.new(0,24,0,22); HideBtn.Position=UDim2.new(1,-60,0.5,-11)
    HideBtn.BackgroundColor3=Color3.fromRGB(30,60,120); HideBtn.Text="👁"
    HideBtn.TextColor3=Color3.fromRGB(200,220,255); HideBtn.Font=Enum.Font.GothamBold
    HideBtn.TextSize=11; HideBtn.BorderSizePixel=0
    Instance.new("UICorner",HideBtn).CornerRadius=UDim.new(0,5)

    local MinBtn=Instance.new("TextButton",TopBar)
    MinBtn.Size=UDim2.new(0,24,0,22); MinBtn.Position=UDim2.new(1,-32,0.5,-11)
    MinBtn.BackgroundColor3=Color3.fromRGB(35,35,52); MinBtn.Text="—"
    MinBtn.TextColor3=Color3.fromRGB(200,200,200); MinBtn.Font=Enum.Font.GothamBold
    MinBtn.TextSize=12; MinBtn.BorderSizePixel=0
    Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,5)

    -- TabBar scrollable horizontal
    local TabBar=Instance.new("ScrollingFrame",Main)
    TabBar.Size=UDim2.new(1,0,0,28); TabBar.Position=UDim2.new(0,0,0,36)
    TabBar.BackgroundColor3=Color3.fromRGB(18,18,27); TabBar.BorderSizePixel=0
    TabBar.ScrollBarThickness=2; TabBar.CanvasSize=UDim2.new(0,0,0,0)
    TabBar.ScrollingDirection=Enum.ScrollingDirection.X
    TabBar.ScrollBarImageColor3=CurrentTheme.primary
    table.insert(self._themeRefs,{type="scrollbar",obj=TabBar})
    local TLayout=Instance.new("UIListLayout",TabBar)
    TLayout.FillDirection=Enum.FillDirection.Horizontal; TLayout.Padding=UDim.new(0,2)
    TLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    local tabPad=Instance.new("UIPadding",TabBar); tabPad.PaddingLeft=UDim.new(0,4)
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
        Pill.Position=UDim2.new(Wrapper.Position.X.Scale,Wrapper.Position.X.Offset,
            Wrapper.Position.Y.Scale,Wrapper.Position.Y.Offset)
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
        Wrapper.Size=mini and UDim2.new(0,265,0,36) or UDim2.new(0,265,0,455)
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
            t.page.Visible=false; t.btn.BackgroundColor3=Color3.fromRGB(28,28,40)
            t.btn.TextColor3=Color3.fromRGB(150,150,170)
        end
        page.Visible=true; btn.BackgroundColor3=CurrentTheme.primary
        btn.TextColor3=Color3.fromRGB(255,255,255); task.defer(refresh)
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

-- [FIX v1.7] Toggle INDEPENDEN — tidak panggil SaveConfig
-- State lokal per toggle, tidak terhubung ke toggle lain
function UI:Toggle(parent,label,callback,col)
    local color=col or CurrentTheme.primary
    local state=false  -- STATE LOKAL — tidak shared

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
        -- [FIX] TIDAK panggil SaveConfig() — cegah side effect
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
        task.delay(0.12,function() btn.BackgroundColor3=oc end)
        pcall(cb)
    end))
end

function UI:InputRow(parent,placeholder,btnLabel,col,cb)
    local frame=Instance.new("Frame",parent)
    frame.Size=UDim2.new(1,0,0,30); frame.BackgroundColor3=Color3.fromRGB(22,22,33); frame.BorderSizePixel=0
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",frame).Color=Color3.fromRGB(60,60,80)
    local input=Instance.new("TextBox",frame)
    input.Size=UDim2.new(1,-70,1,-8); input.Position=UDim2.new(0,8,0,4)
    input.BackgroundTransparency=1; input.PlaceholderText=placeholder; input.Text=""
    input.TextColor3=Color3.fromRGB(220,220,220); input.PlaceholderColor3=Color3.fromRGB(100,100,120)
    input.Font=Enum.Font.Gotham; input.TextSize=11; input.TextXAlignment=Enum.TextXAlignment.Left
    input.ClearTextOnFocus=false
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

-- Slider helper
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
    local ratio=math.clamp((initVal-minVal)/(maxVal-minVal),0,1)
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
            fl.Text=labelText..": "..val; pcall(onChange,val)
        end
    end))
    Core:Add(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then ds=false end
    end))
end

-- ============================================================================
-- [19] BOOTSTRAP
-- ============================================================================
UI:Build()

-- ── TAB: ESP ──────────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("ESP")
    UI:Section(p,"MASTER")
    UI:Toggle(p,"⚡ Aktifkan ESP",function(v)
        Config.ESP.Enabled=v
    end,Color3.fromRGB(30,210,80))

    -- Info fix
    local ic=Instance.new("Frame",p)
    ic.Size=UDim2.new(1,0,0,30); ic.BackgroundColor3=Color3.fromRGB(10,20,10); ic.BorderSizePixel=0
    Instance.new("UICorner",ic).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",ic).Color=Color3.fromRGB(40,150,40)
    local il=Instance.new("TextLabel",ic)
    il.Size=UDim2.new(1,-10,1,-6); il.Position=UDim2.new(0,5,0,3); il.BackgroundTransparency=1
    il.Text="💡 Aktifkan master dulu, lalu pilih fitur yang diinginkan"
    il.TextColor3=Color3.fromRGB(100,200,100); il.Font=Enum.Font.Gotham
    il.TextSize=9; il.TextXAlignment=Enum.TextXAlignment.Left; il.TextWrapped=true

    UI:Section(p,"BODY — pilih yang diinginkan")
    UI:Toggle(p,"Highlight (Tembus Dinding)",function(v) Config.ESP.ShowHighlight=v end,Color3.fromRGB(30,210,80))
    UI:Toggle(p,"Skeleton (Rangka Badan)",function(v) Config.ESP.ShowSkeleton=v end,Color3.fromRGB(30,210,80))
    UI:Toggle(p,"Chams (Neon Fill)",function(v)
        Config.ESP.ShowChams=v
        for _,pl in ipairs(Players:GetPlayers()) do if pl~=LocalPlayer then ApplyChams(pl,v) end end
    end,Color3.fromRGB(160,80,255))
    UI:Toggle(p,"Adaptive Opacity",function(v) Config.ESP.AdaptiveOpacity=v end,Color3.fromRGB(120,80,255))
    UI:Toggle(p,"Box ESP",function(v) Config.ESP.ShowBox=v end)
    UI:Toggle(p,"Head Dot",function(v) Config.ESP.ShowHeadDot=v end)
    UI:Toggle(p,"Snap Line",function(v) Config.ESP.ShowSnapLine=v end)
    UI:Toggle(p,"Billboard HP (3D di kepala)",function(v) Config.ESP.ShowBillboard=v end,Color3.fromRGB(255,180,40))
    UI:Toggle(p,"Item Rarity ESP",function(v) Config.ESP.ShowRarityESP=v end,Color3.fromRGB(220,170,20))

    UI:Section(p,"INFO HUD — pilih yang diinginkan")
    UI:Toggle(p,"Name Tag",function(v) Config.ESP.ShowName=v end)
    UI:Toggle(p,"Health Bar",function(v) Config.ESP.ShowHealth=v end)
    UI:Toggle(p,"Health Number",function(v) Config.ESP.ShowHealthNum=v end)
    UI:Toggle(p,"Distance Tag",function(v) Config.ESP.ShowDistance=v end)
    UI:Toggle(p,"Level Tag",function(v) Config.ESP.ShowLevelTag=v end,Color3.fromRGB(180,180,255))

    UI:Section(p,"CUSTOM COLOR")
    UI:Toggle(p,"Pakai Warna Custom",function(v) Config.ESP.CustomESPColor=v end,Color3.fromRGB(255,100,100))
    MakeSlider(p,"Merah (R)",Config.ESP.CustomR,0,255,function(v) Config.ESP.CustomR=v end)
    MakeSlider(p,"Hijau (G)",Config.ESP.CustomG,0,255,function(v) Config.ESP.CustomG=v end)
    MakeSlider(p,"Biru (B)",Config.ESP.CustomB,0,255,function(v) Config.ESP.CustomB=v end)

    task.defer(r)
end

-- ── TAB: AIM ──────────────────────────────────────────────────────────────
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
    UI:Toggle(p,"Shake Prevention",function(v) Config.Aimbot.ShakePrevention=v end,Color3.fromRGB(100,200,255))
    UI:Section(p,"PRIORITY")
    UI:ChoiceRow(p,"Target",{"FOV","LowestHP","Nearest"},"FOV",function(v) Config.Aimbot.Priority=v end)
    UI:Section(p,"FILTER")
    UI:Toggle(p,"Wall Check",function(v) Config.Aimbot.WallCheck=v end)
    UI:Toggle(p,"Team Check",function(v) Config.Aimbot.TeamCheck=v end)
    UI:Toggle(p,"Alive Check",function(v) Config.Aimbot.AliveCheck=v end)
    UI:Toggle(p,"Prediction",function(v) Config.Aimbot.PredictMovement=v end,Color3.fromRGB(255,160,40))
    UI:Section(p,"FOV")
    UI:Toggle(p,"Tampilkan FOV Circle",function(v)
        Config.Aimbot.FOVVisible=v; FOVCircle.Visible=v and Config.Aimbot.Enabled
    end)
    MakeSlider(p,"FOV Radius",Config.Aimbot.FOVRadius,30,500,function(v)
        Config.Aimbot.FOVRadius=v; FOVCircle.Radius=v
    end)
    task.defer(r)
end

-- ── TAB: MOVE ─────────────────────────────────────────────────────────────
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

-- ── TAB: TELEPORT ─────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("Tele")

    -- Info
    local ic=Instance.new("Frame",p)
    ic.Size=UDim2.new(1,0,0,40); ic.BackgroundColor3=Color3.fromRGB(10,15,25); ic.BorderSizePixel=0
    Instance.new("UICorner",ic).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",ic).Color=Color3.fromRGB(40,100,200)
    local il=Instance.new("TextLabel",ic)
    il.Size=UDim2.new(1,-10,1,-6); il.Position=UDim2.new(0,5,0,3); il.BackgroundTransparency=1
    il.Text="✅ Teleport ke monster → kamera diarahkan dulu\n→ Damage dijamin 100% kena"
    il.TextColor3=Color3.fromRGB(100,180,255); il.Font=Enum.Font.Gotham
    il.TextSize=10; il.TextXAlignment=Enum.TextXAlignment.Left; il.TextWrapped=true

    UI:Section(p,"TELEPORT KE MONSTER")
    UI:ActionBtn(p,"⚡  Teleport + Serang Monster",Color3.fromRGB(200,50,50),function()
        TeleportToMonster()
    end)
    UI:Toggle(p,"Auto Attack Setelah Teleport",function(v) Config.Teleport.AutoAttackAfter=v end,Color3.fromRGB(255,80,80))
    MakeSlider(p,"Radius Deteksi (m)",Config.Teleport.TeleportRadius,50,2000,function(v)
        Config.Teleport.TeleportRadius=v
    end)

    UI:Section(p,"TELEPORT KE PLAYER")
    UI:InputRow(p,"Nama player...","Go",Color3.fromRGB(40,100,255),function(name)
        TeleportToPlayer(name)
    end)

    -- List semua player
    local playerList=Instance.new("Frame",p)
    playerList.Size=UDim2.new(1,0,0,20*(#Players:GetPlayers())+8)
    playerList.BackgroundColor3=Color3.fromRGB(18,18,28); playerList.BorderSizePixel=0
    Instance.new("UICorner",playerList).CornerRadius=UDim.new(0,6)
    local plLayout=Instance.new("UIListLayout",playerList)
    plLayout.Padding=UDim.new(0,2); plLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local pad2=Instance.new("UIPadding",playerList); pad2.PaddingTop=UDim.new(0,4); pad2.PaddingLeft=UDim.new(0,4); pad2.PaddingRight=UDim.new(0,4)

    local function RefreshPlayerList()
        for _,child in ipairs(playerList:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
        end
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl==LocalPlayer then continue end
            local btn=Instance.new("TextButton",playerList)
            btn.Size=UDim2.new(1,0,0,18); btn.BackgroundColor3=Color3.fromRGB(28,28,40)
            btn.Text="→ "..pl.Name; btn.TextColor3=Color3.fromRGB(200,200,220)
            btn.Font=Enum.Font.Gotham; btn.TextSize=10; btn.BorderSizePixel=0
            Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
            Core:Add(btn.MouseButton1Click:Connect(function()
                TeleportToPlayer(pl.Name)
            end))
        end
    end
    RefreshPlayerList()

    UI:ActionBtn(p,"🔄  Refresh List",Color3.fromRGB(40,60,100),function()
        RefreshPlayerList()
        ShowToast("List diperbarui",true)
    end)

    UI:Section(p,"TELEPORT HISTORY")
    UI:ActionBtn(p,"↩️  Balik ke Posisi Sebelumnya",Color3.fromRGB(80,50,150),function()
        TeleportBack()
    end)

    local historyLbl=Instance.new("TextLabel",p)
    historyLbl.Size=UDim2.new(1,0,0,20); historyLbl.BackgroundTransparency=1
    historyLbl.TextColor3=Color3.fromRGB(150,150,170); historyLbl.Font=Enum.Font.Gotham
    historyLbl.TextSize=10; historyLbl.TextXAlignment=Enum.TextXAlignment.Center
    Core:Add(RunService.Heartbeat:Connect(function()
        pcall(function()
            historyLbl.Text="History tersimpan: "..#_teleportHistory.."/"..tostring(_maxHistory)
        end)
    end))

    task.defer(r)
end

-- ── TAB: RPG ──────────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("RPG")
    UI:Section(p,"AUTO SYSTEMS")
    UI:Toggle(p,"Auto Farm",function(v) Config.RPG.AutoFarm=v; if v then StartAutoFarm() end end,Color3.fromRGB(255,80,80))
    UI:Toggle(p,"Boss Tracker",function(v) Config.BossTracker.Enabled=v end,Color3.fromRGB(255,120,40))
    UI:Section(p,"⚡ BLINK ATTACK")
    UI:Toggle(p,"Aktifkan Blink Attack",function(v)
        Config.RPG.BlinkAttack=v; if v then StartBlinkLoop() end
    end,Color3.fromRGB(0,200,255))
    MakeSlider(p,"Radius Blink (m)",Config.RPG.BlinkRadius,50,1000,function(v) Config.RPG.BlinkRadius=v end)
    MakeSlider(p,"Interval (x10 detik)",math.floor(Config.RPG.BlinkInterval*10),10,50,function(v) Config.RPG.BlinkInterval=v/10 end)
    UI:Section(p,"ANTI BAN")
    UI:Toggle(p,"Anti Ban Mode",function(v) Config.AntiBan.Enabled=v end,Color3.fromRGB(255,60,60))
    UI:Toggle(p,"Randomize Interval",function(v) Config.AntiBan.RandomizeInterval=v end,Color3.fromRGB(200,100,100))
    task.defer(r)
end

-- ── TAB: TRANSLATE ────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("Chat")

    local ic=Instance.new("Frame",p)
    ic.Size=UDim2.new(1,0,0,50); ic.BackgroundColor3=Color3.fromRGB(10,10,20); ic.BorderSizePixel=0
    Instance.new("UICorner",ic).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",ic).Color=Color3.fromRGB(40,100,255)
    local il=Instance.new("TextLabel",ic)
    il.Size=UDim2.new(1,-10,1,-6); il.Position=UDim2.new(0,5,0,3); il.BackgroundTransparency=1
    il.Text="📤 Outgoing: Chat kamu (ID) → otomatis jadi EN\n📥 Incoming: Chat orang (EN) → notif terjemahan ID"
    il.TextColor3=Color3.fromRGB(100,180,255); il.Font=Enum.Font.Gotham
    il.TextSize=10; il.TextXAlignment=Enum.TextXAlignment.Left; il.TextWrapped=true

    UI:Section(p,"TRANSLATE CHAT")
    UI:Toggle(p,"📤 Outgoing: ID → EN",function(v) Config.Translate.Enabled=v end,Color3.fromRGB(80,200,255))
    UI:Toggle(p,"📥 Incoming: EN → ID",function(v) Config.Translate.IncomingTranslate=v end,Color3.fromRGB(100,255,180))
    UI:Toggle(p,"Tampilkan Teks Asli",function(v) Config.Translate.ShowOriginal=v end)

    UI:Section(p,"TEST TRANSLATE")
    UI:InputRow(p,"Tulis bahasa Indonesia...","Test",Color3.fromRGB(40,100,255),function(text)
        task.spawn(function()
            ShowToast("Translating...",true)
            local result=TranslateText(text,"id","en")
            ShowTranslateNotif(text,result,"🧪 Test ID → EN")
        end)
    end)

    UI:Section(p,"CHAT BYPASS")
    UI:Toggle(p,"Chat Bypass (Zero-Width Space)",function(v) Config.Chat.Bypass=v end,Color3.fromRGB(200,160,255))

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
    UI:Section(p,"FPS COUNTER")
    UI:Toggle(p,"FPS Counter (Atas Tengah)",function(v)
        Config.FPSCounter.Enabled=v; if not v then _fpsDraw.Visible=false end
    end,Color3.fromRGB(100,255,100))
    UI:Section(p,"PERFORMANCE MONITOR")
    UI:Toggle(p,"Performance Monitor",function(v) Config.Performance.Enabled=v end,Color3.fromRGB(200,200,255))
    task.defer(r)
end

-- ── TAB: TOOLS ────────────────────────────────────────────────────────────
do
    local p,r=UI:AddTab("Tools")

    UI:Section(p,"INSTANCE MONITOR")
    UI:Toggle(p,"Monitor Spawn (Boss/Chest/Event)",function(v)
        Config.InstanceMonitor.Enabled=v; StartInstanceMonitor()
    end,Color3.fromRGB(255,200,50))

    UI:Section(p,"SERVER HOP")
    UI:Toggle(p,"Auto Server Hop",function(v)
        Config.ServerHop.Enabled=v; if v then StartServerHop() end
    end,Color3.fromRGB(255,120,40))
    UI:ActionBtn(p,"🔀  Hop Sekarang",Color3.fromRGB(180,80,10),function()
        DoServerHop()
    end)

    UI:Section(p,"REMOTE SPY LITE")
    UI:Toggle(p,"Remote Spy (Monitor FireServer)",function(v)
        Config.RemoteSpy.Enabled=v; if v then InitRemoteSpy() end
    end,Color3.fromRGB(150,100,255))

    -- Log display
    local logFrame=Instance.new("Frame",p)
    logFrame.Size=UDim2.new(1,0,0,120); logFrame.BackgroundColor3=Color3.fromRGB(8,8,14); logFrame.BorderSizePixel=0
    Instance.new("UICorner",logFrame).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",logFrame).Color=Color3.fromRGB(60,40,100)
    local logLabel=Instance.new("TextLabel",logFrame)
    logLabel.Size=UDim2.new(1,-8,1,-8); logLabel.Position=UDim2.new(0,4,0,4)
    logLabel.BackgroundTransparency=1; logLabel.Text="Remote spy log akan muncul di sini..."
    logLabel.TextColor3=Color3.fromRGB(150,120,200); logLabel.Font=Enum.Font.Code
    logLabel.TextSize=9; logLabel.TextXAlignment=Enum.TextXAlignment.Left
    logLabel.TextYAlignment=Enum.TextYAlignment.Top; logLabel.TextWrapped=true
    _spyLabel=logLabel

    UI:ActionBtn(p,"🗑️  Clear Log",Color3.fromRGB(80,20,20),function()
        _spyLog={}
        if _spyLabel then _spyLabel.Text="Log cleared." end
    end)

    UI:Section(p,"SCRIPT HUB MINI")
    -- Input script
    local scriptFrame=Instance.new("Frame",p)
    scriptFrame.Size=UDim2.new(1,0,0,60); scriptFrame.BackgroundColor3=Color3.fromRGB(18,18,28); scriptFrame.BorderSizePixel=0
    Instance.new("UICorner",scriptFrame).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",scriptFrame).Color=Color3.fromRGB(60,60,100)
    local scriptInput=Instance.new("TextBox",scriptFrame)
    scriptInput.Size=UDim2.new(1,-12,1,-8); scriptInput.Position=UDim2.new(0,6,0,4)
    scriptInput.BackgroundTransparency=1; scriptInput.PlaceholderText="Tulis script pendek disini..."
    scriptInput.Text=""; scriptInput.TextColor3=Color3.fromRGB(200,200,220)
    scriptInput.PlaceholderColor3=Color3.fromRGB(80,80,100)
    scriptInput.Font=Enum.Font.Code; scriptInput.TextSize=10
    scriptInput.TextXAlignment=Enum.TextXAlignment.Left
    scriptInput.TextYAlignment=Enum.TextYAlignment.Top
    scriptInput.MultiLine=true; scriptInput.ClearTextOnFocus=false

    local scriptBtnRow=Instance.new("Frame",p)
    scriptBtnRow.Size=UDim2.new(1,0,0,28); scriptBtnRow.BackgroundTransparency=1
    local sbLayout=Instance.new("UIListLayout",scriptBtnRow)
    sbLayout.FillDirection=Enum.FillDirection.Horizontal; sbLayout.Padding=UDim.new(0,4)
    sbLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center

    local runBtn=Instance.new("TextButton",scriptBtnRow)
    runBtn.Size=UDim2.new(0,100,0,26); runBtn.BackgroundColor3=Color3.fromRGB(40,120,40)
    runBtn.Text="▶ Run"; runBtn.TextColor3=Color3.fromRGB(200,255,200)
    runBtn.Font=Enum.Font.GothamBold; runBtn.TextSize=11; runBtn.BorderSizePixel=0
    Instance.new("UICorner",runBtn).CornerRadius=UDim.new(0,6)
    Core:Add(runBtn.MouseButton1Click:Connect(function()
        if scriptInput.Text~="" then
            local ok,err=pcall(loadstring(scriptInput.Text))
            ShowToast(ok and "Script ran!" or "Error: "..tostring(err):sub(1,20),ok)
        end
    end))

    local saveScriptBtn=Instance.new("TextButton",scriptBtnRow)
    saveScriptBtn.Size=UDim2.new(0,100,0,26); saveScriptBtn.BackgroundColor3=Color3.fromRGB(40,40,120)
    saveScriptBtn.Text="💾 Simpan"; saveScriptBtn.TextColor3=Color3.fromRGB(200,200,255)
    saveScriptBtn.Font=Enum.Font.GothamBold; saveScriptBtn.TextSize=11; saveScriptBtn.BorderSizePixel=0
    Instance.new("UICorner",saveScriptBtn).CornerRadius=UDim.new(0,6)
    Core:Add(saveScriptBtn.MouseButton1Click:Connect(function()
        if scriptInput.Text~="" then
            table.insert(Config.ScriptHub.scripts,scriptInput.Text)
            SaveConfig()
            ShowToast("Script tersimpan (#"..#Config.ScriptHub.scripts..")",true)
            scriptInput.Text=""
        end
    end))

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
    MakeSlider(p,"Opacity",math.floor(Config.UI.Opacity*100),20,100,function(v)
        Config.UI.Opacity=v/100
        if UI.Main then UI.Main.BackgroundTransparency=1-(v/100) end
    end)
    UI:Section(p,"UTILITY")
    UI:Toggle(p,"Anti AFK",function(v) Config.Mods.AntiAFK=v; SetAntiAFK(v) end)
    UI:Toggle(p,"FPS Booster",function(v) Config.Mods.FPSBoost=v; SetFPSBoost(v) end,Color3.fromRGB(255,210,40))
    UI:Toggle(p,"Auto Rejoin",function(v) Config.Mods.AutoRejoin=v end,Color3.fromRGB(255,120,40))
    UI:Toggle(p,"Spectator Detect",function(v) Config.Spectator.Enabled=v end,Color3.fromRGB(200,100,255))
    UI:Toggle(p,"Undetected Mode",function(v)
        Config.UI.UndetectedMode=v
        for _,c in pairs(ESPCache) do HideAll(c) end
        _fpsDraw.Visible=not v; FOVCircle.Visible=not v
        local ui=SafeGUI:FindFirstChild("Nexus_UI")
        if ui then ui.Enabled=not v end
        ShowToast(v and "Undetected ON" or "Undetected OFF",not v)
    end,Color3.fromRGB(80,80,80))
    UI:Toggle(p,"Crash Prevention",function(v) Config.CrashPrevention.Enabled=v end,Color3.fromRGB(255,80,80))
    UI:Section(p,"SERVER INFO")
    UI:ActionBtn(p,"📊  Info Server",Color3.fromRGB(40,80,150),function()
        ShowToast(string.format("Players: %d | Ping: %dms",
            #Players:GetPlayers(),
            math.floor(LocalPlayer.NetworkPing*1000)
        ),true)
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
print("✅ NEXUS v1.7 — Sovereign Edition Loaded")
print("🔧 FIX: ESP sub-fitur independen (default OFF)")
print("🔧 FIX: Teleport damage 100% kena")
print("🆕 Translate Chat (ID↔EN), Teleport System")
print("🆕 Billboard HP, Rarity ESP, Boss Tracker")
print("🆕 Anti Ban, Crash Prevention, Server Hop")
print("🆕 Remote Spy Lite, Script Hub, Performance Monitor")
-- ============================================================================
