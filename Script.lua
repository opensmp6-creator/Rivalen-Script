-- ============================================
-- RIVALS CHEAT SCRIPT - EXTENDED
-- Killaura + Teleport + Aimbot + ESP
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- SETTINGS
-- ============================================
local Settings = {
    Aimbot = false,
    AimbotKey = Enum.KeyCode.Q,
    AimbotFOV = 150,
    AimbotSmoothness = 0.15,

    Killaura = false,
    KillauraRange = 15,
    KillauraSpeed = 0.1,

    TeleportKey = Enum.KeyCode.T,
    TeleportToCursor = true, -- true = zum Mauszeiger, false = zum nächsten Gegner

    ESP = false,
    ESPColor = Color3.fromRGB(255, 0, 0),

    HitboxExpander = false,
    HitboxSize = 5,

    WalkSpeed = false,
    WalkSpeedValue = 50,

    MenuKey = Enum.KeyCode.RightShift,
    MenuOpen = true,
}

-- ============================================
-- GUI ERSTELLEN
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RivalsCheat"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 480)
MainFrame.Position = UDim2.new(0, 20, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 170, 255)
Stroke.Thickness = 2
Stroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Title.BorderSizePixel = 0
Title.Text = "RIVALS CHEAT v2 | RShift = Menü"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -50)
Scroll.Position = UDim2.new(0, 5, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 5
Scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = Scroll

-- ============================================
-- TOGGLE BUTTON
-- ============================================
local function CreateToggle(name, key, default, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Button.BorderSizePixel = 0
    Button.TextColor3 = Color3.fromRGB(255, 70, 70)
    Button.Font = Enum.Font.GothamSemibold
    Button.TextSize = 13
    Button.Parent = Scroll
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)

    local state = default or false
    Button.Text = name .. " [" .. key .. "]: " .. (state and "ON" or "OFF")
    Button.TextColor3 = state and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 70, 70)

    Button.MouseButton1Click:Connect(function()
        state = not state
        Button.Text = name .. " [" .. key .. "]: " .. (state and "ON" or "OFF")
        Button.TextColor3 = state and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 70, 70)
        callback(state)
    end)

    return Button
end

local function CreateButton(name, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    Button.BorderSizePixel = 0
    Button.Text = name
    Button.TextColor3 = Color3.fromRGB(0, 170, 255)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 13
    Button.Parent = Scroll
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
    Button.MouseButton1Click:Connect(callback)
    return Button
end

-- ============================================
-- AIMBOT
-- ============================================
local function GetClosestPlayer()
    local closest, shortestDist = nil, Settings.AimbotFOV
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if Settings.Aimbot and UserInputService:IsKeyDown(Settings.AimbotKey) then
        local target = GetClosestPlayer()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                local cam = workspace.CurrentCamera
                cam.CFrame = cam.CFrame:Lerp(
                    CFrame.new(cam.CFrame.Position, head.Position),
                    Settings.AimbotSmoothness
                )
            end
        end
    end
end)

-- ============================================
-- KILLAURA
-- ============================================
-- Nutzt RemoteEvents um Schaden zu machen
local function GetDamageRemote()
    -- Sucht nach gängigen Rivals RemoteEvent Namen
    local remotes = game:GetService("ReplicatedStorage"):GetDescendants()
    for _, obj in pairs(remotes) do
        if obj:IsA("RemoteEvent") then
            local n = obj.Name:lower()
            if n:find("damage") or n:find("hit") or n:find("attack") or n:find("slash") then
                return obj
            end
        end
    end
    return nil
end

local function KillauraAttack()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local myPos = hrp.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local ehrp = player.Character:FindFirstChild("HumanoidRootPart")
            local ehum = player.Character:FindFirstChildOfClass("Humanoid")
            if ehrp and ehum and ehum.Health > 0 then
                local dist = (ehrp.Position - myPos).Magnitude
                if dist <= Settings.KillauraRange then
                    -- Methode 1: Tool aktivieren (falls Schwert ausgerüstet)
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end

                    -- Methode 2: RemoteEvent feuern (falls gefunden)
                    local remote = GetDamageRemote()
                    if remote then
                        pcall(function()
                            remote:FireServer(player.Character, "Hit")
                        end)
                    end

                    -- Methode 3: Direkter Schaden (falls Server es erlaubt)
                    pcall(function()
                        ehum:TakeDamage(5)
                    end)
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(Settings.KillauraSpeed) do
        if Settings.Killaura then
            pcall(KillauraAttack)
        end
    end
end)

-- ============================================
-- TELEPORT (T)
-- ============================================
local function TeleportToCursor()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local mouse = LocalPlayer:GetMouse()
    if mouse.Hit then
        hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
    end
end

local function TeleportToNearestEnemy()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local closest, dist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local ehrp = player.Character:FindFirstChild("HumanoidRootPart")
            local ehum = player.Character:FindFirstChildOfClass("Humanoid")
            if ehrp and ehum and ehum.Health > 0 then
                local d = (ehrp.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = ehrp
                end
            end
        end
    end
    if closest then
        hrp.CFrame = closest.CFrame * CFrame.new(0, 0, 3)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Settings.TeleportKey then
        if Settings.TeleportToCursor then
            TeleportToCursor()
        else
            TeleportToNearestEnemy()
        end
    end
end)

-- ============================================
-- ESP
-- ============================================
local ESPDrawings = {}

local function CreateESP(player)
    if ESPDrawings[player] then return end
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Color = Settings.ESPColor
    box.Filled = false
    box.Visible = false
    ESPDrawings[player] = {box = box}
end

RunService.RenderStepped:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateESP(player)
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            local cam = workspace.CurrentCamera

            if Settings.ESP and hrp and head and hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                local headPos = cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    local height = math.abs(pos.Y - headPos.Y) * 2
                    local width = height / 2
                    ESPDrawings[player].box.Size = Vector2.new(width, height)
                    ESPDrawings[player].box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                    ESPDrawings[player].box.Color = Settings.ESPColor
                    ESPDrawings[player].box.Visible = true
                else
                    ESPDrawings[player].box.Visible = false
                end
            elseif ESPDrawings[player] then
                ESPDrawings[player].box.Visible = false
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if ESPDrawings[p] then
        ESPDrawings[p].box:Remove()
        ESPDrawings[p] = nil
    end
end)

-- ============================================
-- HITBOX EXPANDER
-- ============================================
RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if Settings.HitboxExpander then
                    hrp.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    hrp.Transparency = 0.6
                else
                    if hrp.Size == Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize) then
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 1
                    end
                end
            end
        end
    end
end)

-- ============================================
-- WALKSPEED
-- ============================================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Settings.WalkSpeed then
                hum.WalkSpeed = Settings.WalkSpeedValue
            elseif hum.WalkSpeed == Settings.WalkSpeedValue then
                hum.WalkSpeed = 16
            end
        end
    end
end)

-- ============================================
-- MENÜ BUTTONS
-- ============================================
CreateToggle("Aimbot (Halte Q)", "Q", false, function(s) Settings.Aimbot = s end)
CreateToggle("Killaura", "KA", false, function(s) Settings.Killaura = s end)
CreateButton("Teleport-Modus: " .. (Settings.TeleportToCursor and "Mauszeiger" or "Gegner"), function(self)
    Settings.TeleportToCursor = not Settings.TeleportToCursor
    self.Text = "Teleport-Modus: " .. (Settings.TeleportToCursor and "Mauszeiger" or "Gegner")
end)
CreateToggle("ESP Boxes", "ESP", false, function(s) Settings.ESP = s end)
CreateToggle("Hitbox Expander", "HIT", false, function(s) Settings.HitboxExpander = s end)
CreateToggle("Speed Hack", "SPD", false, function(s) Settings.WalkSpeed = s end)

-- ============================================
-- MENÜ TOGGLE (RShift)
-- ============================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Settings.MenuKey then
        Settings.MenuOpen = not Settings.MenuOpen
        MainFrame.Visible = Settings.MenuOpen
    end
end)

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

-- Notification
local function Notify(text)
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0, 300, 0, 40)
    notif.Position = UDim2.new(0.5, -150, 0, 50)
    notif.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    notif.Text = text
    notif.TextColor3 = Color3.fromRGB(0, 255, 100)
    notif.Font = Enum.Font.GothamBold
    notif.TextSize = 14
    notif.Parent = ScreenGui
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 6)
    task.delay(2, function()
        TweenService:Create(notif, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        task.wait(0.5)
        notif:Destroy()
    end)
end

Notify("✅ Rivals Cheat v2 geladen!  RShift=Menü  |  T=Teleport")
