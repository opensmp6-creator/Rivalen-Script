--[[
    RIVALS CHEAT SCRIPT
    Features: ESP, Aimbot, Killaura, Speed, Fly, Godmode (semi), NoClip, AutoReload
    Loadstring:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DEINNAME/Rivals/main/script.lua"))()
--]]

-- ============ SERVICES ============
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local Camera            = workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer

-- ============ CONFIG ============
local Config = {
    ESP = {
        Enabled = true,
        BoxColor = Color3.fromRGB(0, 255, 0),
        NameColor = Color3.fromRGB(255, 255, 255),
        HealthColor = Color3.fromRGB(0, 255, 0),
        TracerColor = Color3.fromRGB(255, 0, 0),
        ShowTracer = true,
        ShowHealth = true,
        ShowName = true,
        MaxDistance = 1500,
    },
    Aimbot = {
        Enabled = true,
        Key = Enum.UserInputType.MouseButton2,   -- RMB
        Smoothness = 0.25,
        FOV = 120,
        MaxDistance = 800,
        WallCheck = true,
        TeamCheck = true,
    },
    Killaura = {
        Enabled = true,
        Range = 25,          -- Studs
        Key = Enum.KeyCode.X, -- Toggle-Hotkey
    },
    Speed = {
        Enabled = true,
        Value = 30,           -- Standard ist ~16
    },
    Fly = {
        Enabled = false,
        Speed = 50,
        Key = Enum.KeyCode.F,
    },
    JumpPower = 70,
    NoClip = false,
    AutoReload = true,
}

-- ============ STATE ============
local ESPObjects = {}
local FlyBV, FlyBG = nil, nil
local OriginalWalkSpeed, OriginalJumpPower

-- ============ HELPERS ============
local function isAlive(plr)
    local char = plr and plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getRoot(plr)
    local char = plr and plr.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
end

-- ============ ESP ============
local function createESP(plr)
    if plr == LocalPlayer then return end
    if ESPObjects[plr] then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RivalsESP"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = nil -- set später

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Config.ESP.NameColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Text = plr.Name
    nameLabel.Parent = billboard

    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBg"
    healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Size = UDim2.new(1, 0, 0.15, 0)
    healthBar.Position = UDim2.new(0, 0, 0.55, 0)
    healthBar.Parent = billboard

    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.BackgroundColor3 = Config.ESP.HealthColor
    healthFill.BorderSizePixel = 0
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.Parent = healthBar

    -- Line Drawing (Tracer)
    local tracer = Instance.new("LineHandleAdornment") -- fallback falls Drawing nicht vorhanden
    tracer.Name = "Tracer"

    ESPObjects[plr] = {
        Billboard = billboard,
        NameLabel = nameLabel,
        HealthFill = healthFill,
    }

    billboard.Parent = plr.Character
        and plr.Character:FindFirstChild("HumanoidRootPart")
        or workspace
end

local function removeESP(plr)
    local data = ESPObjects[plr]
    if data and data.Billboard then data.Billboard:Destroy() end
    ESPObjects[plr] = nil
end

-- ============ AIMBOT ============
local HeadAimFactor = Vector3.new(0, 0.5, 0)

local function getClosestTarget()
    local closest, closestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and plr.Team == LocalPlayer.Team and plr.Team then continue end
        if not isAlive(plr) then continue end

        local head = plr.Character:FindFirstChild("Head")
        local root = getRoot(plr)
        if not head or not root then continue end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > Config.Aimbot.MaxDistance then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if onScreen then
            local aimDist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
            if aimDist < Config.Aimbot.FOV and aimDist < closestDist then
                if Config.Aimbot.WallCheck then
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {LocalPlayer.Character, plr.Character}
                    local result = workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position), params)
                    if result then continue end
                end
                closest = plr
                closestDist = aimDist
            end
        end
    end
    return closest
end

local aimActive = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Config.Aimbot.Key and Config.Aimbot.Enabled then
        aimActive = true
    end
end)
UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Config.Aimbot.Key then
        aimActive = false
    end
end)

-- Aimbot Loop
RunService.RenderStepped:Connect(function()
    if not aimActive or not Config.Aimbot.Enabled then return end
    local target = getClosestTarget()
    if not target then return end
    local head = target.Character and target.Character:FindFirstChild("Head")
    if not head then return end

    local targetPos = head.Position + HeadAimFactor
    local currentCF = Camera.CFrame
    local desired = CFrame.new(currentCF.Position, targetPos)
    Camera.CFrame = currentCF:Lerp(desired, Config.Aimbot.Smoothness)
end)

-- ============ KILLAURA ============
local killauraActive = true

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.Killaura.Key then
        Config.Killaura.Enabled = not Config.Killaura.Enabled
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if not Config.Killaura.Enabled then continue end
        local root = getRoot(LocalPlayer)
        if not root then continue end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            if not isAlive(plr) then continue end
            local tRoot = getRoot(plr)
            if not tRoot then continue end
            if (root.Position - tRoot.Position).Magnitude <= Config.Killaura.Range then
                -- Fire alle Tools / Remotes via Click simulieren
                if mousemoverel then
                    mousemoverel(0, 0)
                end
                -- standard hit-fire
                pcall(function()
                    for _, t in ipairs(LocalPlayer.Character:GetChildren()) do
                        if t:IsA("Tool") then
                            t:Activate()
                        end
                    end
                end)
                -- Roblox VirtualUser Fallback
                if VirtualUser then
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton1(Vector2.new())
                    end)
                end
                break
            end
        end
    end
end)

-- ============ SPEED / JUMP ============
local function applySpeed()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    OriginalWalkSpeed = OriginalWalkSpeed or hum.WalkSpeed
    hum.WalkSpeed = Config.Speed.Enabled and Config.Speed.Value or OriginalWalkSpeed
    hum.JumpPower = Config.JumpPower
    hum.UseJumpPower = true
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    applySpeed()
end)
if LocalPlayer.Character then
    applySpeed()
end

-- ============ FLY ============
local function enableFly()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    FlyBV = Instance.new("BodyVelocity")
    FlyBV.Velocity = Vector3.zero
    FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    FlyBV.Parent = root

    FlyBG = Instance.new("BodyGyro")
    FlyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    FlyBG.P = 1e4
    FlyBG.Parent = root

    Config.Fly.Enabled = true
end

local function disableFly()
    if FlyBV then FlyBV:Destroy() end
    if FlyBG then FlyBG:Destroy() end
    FlyBV, FlyBG = nil, nil
    Config.Fly.Enabled = false
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.Fly.Key then
        if Config.Fly.Enabled then disableFly() else enableFly() end
    end
end)

RunService.RenderStepped:Connect(function()
    if not Config.Fly.Enabled or not FlyBV then return end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local vel = Vector3.zero
    local camCF = Camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel += camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel -= camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel -= camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel += camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.new(0, 1, 0) end
    FlyBV.Velocity = vel.Magnitude > 0 and vel.Unit * Config.Fly.Speed or Vector3.zero
    root.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
end)

-- ============ NOCLIP ============
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.N then
        Config.NoClip = not Config.NoClip
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not Config.NoClip
                end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if not Config.NoClip then return end
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- ============ AUTORELOAD ============
task.spawn(function()
    while task.wait(0.2) do
        if not Config.AutoReload then continue end
        local char = LocalPlayer.Character
        if not char then continue end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo")
                if ammo and ammo.Value == 0 then
                    pcall(function() tool:Activate() end)
                end
            end
        end
    end
end)

-- ============ ESP LOOP ============
local function updateESP()
    for plr, data in pairs(ESPObjects) do
        local char = plr.Character
        local root = getRoot(plr)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if config_esp_disabled or not char or not root or not hum then
            data.Billboard.Enabled = false
            continue
        end
        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        data.Billboard.Enabled = Config.ESP.Enabled and dist <= Config.ESP.MaxDistance
        data.Billboard.Adornee = char:FindFirstChild("Head") or root
        if hum then
            data.HealthFill.Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 1, 0)
        end
    end
end

-- ============ PLAYER CONNECTIONS ============
local function onCharacter(plr, char)
    if plr == LocalPlayer then
        task.wait(0.3)
        applySpeed()
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char) onCharacter(plr, char) end)
    if plr.Character then createESP(plr) end
end)
Players.PlayerRemoving:Connect(removeESP)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        createESP(plr)
        plr.CharacterAdded:Connect(function() task.wait(0.3) createESP(plr) end)
    end
end

-- ============ MAIN LOOP ============
RunService.RenderStepped:Connect(updateESP)

-- ============ CLEANUP ============
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applySpeed()
end)

print("[Rivals Cheat] geladen – ESP aktiv, Aimbot = RMB, Killaura = X toggeln, Fly = F, NoClip = N")
