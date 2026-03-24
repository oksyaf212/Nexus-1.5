-- ============================================
-- VIOLENCE DISTRICT — MOD SCRIPT
-- Berdasarkan data spy yang tersedia
-- ============================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")
local lp         = Players.LocalPlayer

if lp.PlayerGui:FindFirstChild("VDHub") then
    lp.PlayerGui:FindFirstChild("VDHub"):Destroy()
end

-- ============================================
-- REMOTE REFERENCES
-- ============================================
local Remotes = RS:WaitForChild("Remotes")

local R = {
    -- Generator
    RepairEvent    = Remotes.Generator.RepairEvent,
    RepairAnim     = Remotes.Generator.RepairAnim,
    BreakGenEvent  = Remotes.Generator.BreakGenEvent,
    SkillCheckResult = Remotes.Generator.SkillCheckResultEvent,
    SkillCheckFail   = Remotes.Generator.SkillCheckFailEvent,

    -- Healing
    HealEvent      = Remotes.Healing.HealEvent,
    HealAnim       = Remotes.Healing.HealAnim,
    HealSkillCheck = Remotes.Healing.SkillCheckResultEvent,
    HealSkillFail  = Remotes.Healing.SkillCheckFailEvent,
    Reset          = Remotes.Healing.Reset,

    -- Movement
    VaultEvent     = Remotes.Window.VaultEvent,
    VaultComplete  = Remotes.Window.VaultCompleteEvent,
    FastVault      = Remotes.Window.fastvault,
    PalletDrop     = Remotes.Pallet.PalletDropEvent,
    PalletSlide    = Remotes.Pallet.PalletSlideEvent,
    PalletComplete = Remotes.Pallet.PalletSlideCompleteEvent,

    -- Attack
    BasicAttack    = Remotes.Attacks.BasicAttack,
    AfterAttack    = Remotes.Attacks.AfterAttack,
    AttackEvent    = Remotes.AttackEvent,

    -- Character
    UpdateLook     = Remotes.Game.UpdateCharacterLook,
    Teleport       = Remotes.Mechanics.Teleportcharacter,
    Crouch         = Remotes.Mechanics.Crouch,

    -- Killer
    ActivatePower  = Remotes.Killers.Killer.ActivatePower,
    Instinct       = Remotes.Killers.Instinct,
    ShowPlayers    = Remotes.Killers.Killer.ShowPlayers,
}

local function FR(remote, ...)
    if not remote then return false end
    local ok = pcall(function() remote:FireServer(...) end)
    return ok
end

local function INV(remote, ...)
    if not remote then return nil end
    local ok, res = pcall(function() return remote:InvokeServer(...) end)
    return ok and res or nil
end

local function GetChar() return lp.Character end
local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function GetHRP()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ============================================
-- FEATURE STATE
-- ============================================
local State = {
    GodMode       = false,
    Invisible     = false,
    AutoRepair    = false,
    AutoSkillCheck = false,
    AutoHeal      = false,
    FastVault     = false,
    SpeedHack     = false,
    ESP           = false,
    NoClip        = false,
}

local Loops     = {}
local Conns     = {}
local origTrans = {}

local function KL(k)
    if Loops[k] then pcall(task.cancel, Loops[k]); Loops[k]=nil end
end
local function KC(k)
    if Conns[k] then pcall(function() Conns[k]:Disconnect() end); Conns[k]=nil end
end

-- ============================================
-- GOD MODE
-- ============================================
local function GodON()
    Loops.God = RunService.Heartbeat:Connect(function()
        local h = GetHum()
        if not h then return end
        h.MaxHealth = math.huge
        h.Health    = math.huge
        if h:GetState() == Enum.HumanoidStateType.Dead then
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
    lp.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if not State.GodMode then return end
        local h = c:WaitForChild("Humanoid",5)
        if h then h.MaxHealth=math.huge; h.Health=math.huge end
    end)
end
local function GodOFF()
    KL("God")
    local h = GetHum()
    if h then h.MaxHealth=100; h.Health=100 end
end

-- ============================================
-- INVISIBLE (Transparency = 1, terlihat semua client)
-- ============================================
local function SetTransp(char, val)
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
            if val == 1 then
                if origTrans[obj] == nil then origTrans[obj] = obj.Transparency end
                obj.Transparency = 1
            else
                obj.Transparency = origTrans[obj] or 0
            end
        elseif obj:IsA("Decal") then
            if val == 1 then
                if origTrans[obj] == nil then origTrans[obj] = obj.Transparency end
                obj.Transparency = 1
            else
                obj.Transparency = origTrans[obj] or 0
            end
        end
    end
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            local h = acc:FindFirstChild("Handle")
            if h then
                if val == 1 then
                    if origTrans[h] == nil then origTrans[h] = h.Transparency end
                    h.Transparency = 1
                else
                    h.Transparency = origTrans[h] or 0
                end
            end
        end
    end
end

local function InvisON()
    local c = GetChar()
    if c then SetTransp(c, 1) end
    Loops.Invis = RunService.Heartbeat:Connect(function()
        local ch = GetChar()
        if not ch then return end
        for _, obj in ipairs(ch:GetDescendants()) do
            if obj:IsA("BasePart")
            and obj.Name ~= "HumanoidRootPart"
            and obj.Transparency ~= 1 then
                if origTrans[obj] == nil then origTrans[obj] = obj.Transparency end
                obj.Transparency = 1
            end
        end
    end)
    lp.CharacterAdded:Connect(function(nc)
        task.wait(0.5)
        if not State.Invisible then return end
        table.clear(origTrans)
        SetTransp(nc, 1)
    end)
end
local function InvisOFF()
    KL("Invis")
    local c = GetChar()
    if c then SetTransp(c, 0) end
    table.clear(origTrans)
end

-- ============================================
-- AUTO REPAIR GENERATOR
-- Scan semua generator di workspace dan repair
-- Format dari spy: RepairEvent:FireServer(Part, true)
-- ============================================
local function AutoRepairON()
    Loops.Repair = task.spawn(function()
        while State.AutoRepair do
            local hrp = GetHRP()
            if hrp then
                -- Cari semua GeneratorPoint di workspace
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if not State.AutoRepair then break end
                    if obj:IsA("BasePart") and
                       (obj.Name:find("Generator",1,true) or
                        obj.Name:find("Gen",1,true)) then
                        local dist = (hrp.Position - obj.Position).Magnitude
                        if dist < 10 then
                            -- Format tepat dari spy log:
                            -- RepairEvent:FireServer(generatorPart, true)
                            FR(R.RepairEvent, obj, true)
                            -- Kirim animasi juga agar tidak terdeteksi aneh
                            FR(R.RepairAnim, obj, true)
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end
local function AutoRepairOFF()
    KL("Repair")
    -- Kirim stop repair ke server
    local hrp = GetHRP()
    if hrp then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:find("Generator",1,true) then
                local dist = (hrp.Position - obj.Position).Magnitude
                if dist < 10 then
                    FR(R.RepairEvent, obj, false)
                    FR(R.RepairAnim, obj, false)
                end
            end
        end
    end
end

-- ============================================
-- AUTO SKILL CHECK
-- Hook SkillCheckEvent → langsung kirim result true
-- ============================================
local function SkillON()
    -- Generator skill check
    if R.SkillCheckResult then
        Conns.GenSkill = Remotes.Generator.SkillCheckEvent.OnClientEvent:Connect(function(...)
            task.wait(0.05) -- delay kecil agar natural
            FR(R.SkillCheckResult, true)
        end)
    end
    -- Heal skill check
    if R.HealSkillCheck then
        Conns.HealSkill = Remotes.Healing.SkillCheckEvent.OnClientEvent:Connect(function(...)
            task.wait(0.05)
            FR(R.HealSkillCheck, true)
        end)
    end
end
local function SkillOFF()
    KC("GenSkill"); KC("HealSkill")
end

-- ============================================
-- AUTO HEAL
-- Cari player yang terluka di sekitar dan heal
-- ============================================
local function AutoHealON()
    Loops.Heal = task.spawn(function()
        while State.AutoHeal do
            local hrp = GetHRP()
            if hrp then
                for _, p in ipairs(Players:GetPlayers()) do
                    if not State.AutoHeal then break end
                    if p ~= lp and p.Character then
                        local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
                        local pHum = p.Character:FindFirstChildOfClass("Humanoid")
                        if pHRP and pHum and pHum.Health < pHum.MaxHealth then
                            local dist = (hrp.Position - pHRP.Position).Magnitude
                            if dist < 8 then
                                FR(R.HealEvent, p.Character, true)
                                FR(R.HealAnim, p.Character, true)
                            end
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end
local function AutoHealOFF() KL("Heal") end

-- ============================================
-- SPEED HACK
-- ============================================
local function SpeedON()
    local h = GetHum()
    if h then h.WalkSpeed = 32 end
    Loops.Speed = RunService.Heartbeat:Connect(function()
        local hum = GetHum()
        if hum and hum.WalkSpeed < 32 then hum.WalkSpeed = 32 end
    end)
    lp.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if not State.SpeedHack then return end
        local hum = c:WaitForChild("Humanoid",5)
        if hum then hum.WalkSpeed = 32 end
    end)
end
local function SpeedOFF()
    KL("Speed")
    local h = GetHum()
    if h then h.WalkSpeed = 16 end
end

-- ============================================
-- NO CLIP
-- ============================================
local function NoClipON()
    Loops.NoClip = RunService.Stepped:Connect(function()
        local c = GetChar()
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end
local function NoClipOFF()
    KC("NoClip")
    local c = GetChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

-- ============================================
-- ESP — Highlight semua player
-- ============================================
local espConns = {}
local function ClearESP()
    for _, c in ipairs(espConns) do
        pcall(function() c:Disconnect() end)
    end
    espConns = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("ESP_HL")
            if hl then hl:Destroy() end
        end
    end
end

local function AddESP(p)
    if p == lp then return end
    local function apply(char)
        if not char then return end
        task.wait(0.5)
        local hl = Instance.new("Highlight", char)
        hl.Name            = "ESP_HL"
        hl.FillColor       = Color3.fromRGB(255, 50, 50)
        hl.OutlineColor    = Color3.new(1,1,1)
        hl.FillTransparency    = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode       = Enum.HighlightDepthMode.AlwaysOnTop
    end
    apply(p.Character)
    local c = p.CharacterAdded:Connect(apply)
    table.insert(espConns, c)
end

local function ESPON()
    for _, p in ipairs(Players:GetPlayers()) do AddESP(p) end
    local c = Players.PlayerAdded:Connect(AddESP)
    table.insert(espConns, c)
end
local function ESPOFF() ClearESP() end

-- ============================================
-- GUI
-- ============================================
local sg = Instance.new("ScreenGui")
sg.Name="VDHub"; sg.ResetOnSpawn=false; sg.Parent=lp.PlayerGui

local mf = Instance.new("Frame",sg)
mf.Size=UDim2.new(0,220,0,390)
mf.Position=UDim2.new(0,10,0.5,-195)
mf.BackgroundColor3=Color3.fromRGB(10,10,20)
mf.BorderSizePixel=0; mf.Active=true
Instance.new("UICorner",mf).CornerRadius=UDim.new(0,8)

local ac=Instance.new("Frame",mf)
ac.Size=UDim2.new(1,0,0,2)
ac.BackgroundColor3=Color3.fromRGB(200,50,50)
ac.BorderSizePixel=0

local ttl=Instance.new("TextLabel",mf)
ttl.Size=UDim2.new(1,0,0,30)
ttl.Position=UDim2.new(0,0,0,2)
ttl.BackgroundTransparency=1
ttl.Text="⚔️  VIOLENCE DISTRICT"
ttl.TextColor3=Color3.fromRGB(200,50,50)
ttl.Font=Enum.Font.GothamBold
ttl.TextSize=12

local drg,ds,do_=false,nil,nil
ttl.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then
        drg=true;ds=i.Position;do_=mf.Position end end)
ttl.InputChanged:Connect(function(i)
    if not drg then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement
    or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-ds
        mf.Position=UDim2.new(do_.X.Scale,do_.X.Offset+d.X,
                               do_.Y.Scale,do_.Y.Offset+d.Y)
    end end)
ttl.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then drg=false end end)

local sc=Instance.new("ScrollingFrame",mf)
sc.Size=UDim2.new(1,0,1,-34)
sc.Position=UDim2.new(0,0,0,34)
sc.BackgroundTransparency=1
sc.BorderSizePixel=0
sc.ScrollBarThickness=3
sc.CanvasSize=UDim2.new(0,0,0,0)

local ll=Instance.new("UIListLayout",sc)
ll.Padding=UDim.new(0,5)
ll.SortOrder=Enum.SortOrder.LayoutOrder
local pp=Instance.new("UIPadding",sc)
pp.PaddingLeft=UDim.new(0,6);pp.PaddingRight=UDim.new(0,6)
pp.PaddingTop=UDim.new(0,6);pp.PaddingBottom=UDim.new(0,6)

ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sc.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+12)
end)

local W=Color3.new(1,1,1)
local GR=Color3.fromRGB(100,100,140)
local ord=0

local function Sec(txt,col)
    ord=ord+1
    local f=Instance.new("Frame",sc)
    f.Size=UDim2.new(1,0,0,18); f.BackgroundColor3=Color3.fromRGB(25,10,10)
    f.BorderSizePixel=0; f.LayoutOrder=ord
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-8,1,0); l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1; l.Text=txt
    l.TextColor3=col or Color3.fromRGB(200,50,50)
    l.Font=Enum.Font.GothamBold; l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=2
end

local function MkTog(lbl,col,onEN,onDIS)
    ord=ord+1
    local on=false
    local f=Instance.new("Frame",sc)
    f.Size=UDim2.new(1,0,0,36); f.BackgroundColor3=Color3.fromRGB(18,18,32)
    f.BorderSizePixel=0; f.LayoutOrder=ord
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)

    local s=Instance.new("Frame",f)
    s.Size=UDim2.new(0,3,1,-8); s.Position=UDim2.new(0,0,0,4)
    s.BackgroundColor3=col; s.BorderSizePixel=0
    Instance.new("UICorner",s).CornerRadius=UDim.new(0,2)

    local lb=Instance.new("TextLabel",f)
    lb.Size=UDim2.new(1,-56,1,0); lb.Position=UDim2.new(0,10,0,0)
    lb.BackgroundTransparency=1; lb.Text=lbl; lb.TextColor3=W
    lb.Font=Enum.Font.GothamBold; lb.TextSize=11
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.ZIndex=2

    local ind=Instance.new("TextLabel",f)
    ind.Size=UDim2.new(0,38,0,20); ind.Position=UDim2.new(1,-44,0.5,-10)
    ind.BackgroundColor3=Color3.fromRGB(28,28,48); ind.BorderSizePixel=0
    ind.Text="OFF"; ind.TextColor3=GR
    ind.Font=Enum.Font.GothamBold; ind.TextSize=10; ind.ZIndex=3
    Instance.new("UICorner",ind).CornerRadius=UDim.new(0,5)

    local hit=Instance.new("TextButton",f)
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1
    hit.Text=""; hit.AutoButtonColor=false; hit.ZIndex=4

    hit.MouseButton1Click:Connect(function()
        on=not on
        ind.Text=on and"ON"or"OFF"
        ind.TextColor3=on and W or GR
        ind.BackgroundColor3=on and col or Color3.fromRGB(28,28,48)
        f.BackgroundColor3=on and Color3.fromRGB(14,26,16) or Color3.fromRGB(18,18,32)
        if on then task.spawn(function() pcall(onEN) end)
        else       task.spawn(function() pcall(onDIS) end) end
    end)
end

-- ISI GUI
Sec("— SURVIVAL —", Color3.fromRGB(200,50,50))
MkTog("☠️ God Mode",    Color3.fromRGB(255,80,80),
    function() State.GodMode=true;  GodON()   end,
    function() State.GodMode=false; GodOFF()  end)
MkTog("👻 Invisible",   Color3.fromRGB(80,180,255),
    function() State.Invisible=true;  InvisON()  end,
    function() State.Invisible=false; InvisOFF() end)
MkTog("🏃 Speed x2",    Color3.fromRGB(80,220,120),
    function() State.SpeedHack=true;  SpeedON()  end,
    function() State.SpeedHack=false; SpeedOFF() end)
MkTog("👁️ ESP Players", Color3.fromRGB(255,200,50),
    function() State.ESP=true;  ESPON()  end,
    function() State.ESP=false; ESPOFF() end)
MkTog("🔮 No Clip",     Color3.fromRGB(180,100,255),
    function() State.NoClip=true;  NoClipON()  end,
    function() State.NoClip=false; NoClipOFF() end)

Sec("— GAMEPLAY —", Color3.fromRGB(200,50,50))
MkTog("⚡ Auto Repair Gen",   Color3.fromRGB(255,160,30),
    function() State.AutoRepair=true;  AutoRepairON()  end,
    function() State.AutoRepair=false; AutoRepairOFF() end)
MkTog("✅ Auto Skill Check",  Color3.fromRGB(80,220,120),
    function() State.AutoSkillCheck=true;  SkillON()  end,
    function() State.AutoSkillCheck=false; SkillOFF() end)
MkTog("💊 Auto Heal Teammate",Color3.fromRGB(100,220,180),
    function() State.AutoHeal=true;  AutoHealON()  end,
    function() State.AutoHeal=false; AutoHealOFF() end)

print("✅ Violence District Hub loaded")
print("  God Mode, Invisible, Speed, ESP, NoClip")
print("  Auto Repair, Auto SkillCheck, Auto Heal")
