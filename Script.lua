-- ============================================
-- RIVALS CHEAT SCRIPT
-- Ausführen in einem Executor (z.B. Solara)
-- ============================================

-- Services
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

-- Hauptrahmen
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0, 20, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 170, 255)
Stroke.Thickness = 2
Stroke.Parent = MainFrame

-- Titel
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Title.BorderSizePixel = 0
Title.Text = "RIVALS CHEAT | RShift = Menü"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- ScrollFrame für Buttons
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
-- TOGGLE BUTTON FUNKTION
-- ============================================
local function CreateToggle(name, key, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Button.BorderSizePixel = 0
    Button.Text = name .. " [" .. key .. "]: OFF"
    Button.TextColor3 = Color3.fromRGB(255, 70, 70)
    Button.Font = Enum.Font.GothamSemibold
    Button.TextSize = 13
    Button.Parent = Scroll

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Button

    local state = false

    Button.MouseButton1Click:Connect(function()
        state = not state
        Button.Text = name .. " [" .. key .. "]: " .. (state and "ON" or "OFF")
        Button.TextColor3 = state and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 70, 70)
        callback(state)
    end)

    return Button
end

-- ============================================
-- Aimbot Logik
-- ============================================
local function GetClosestPlayer()
    local closest = nil
    local shortestDist = Settings.AimbotFOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
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

local function AimbotLoop()
    RunService.RenderStepped:Connect(function()
        if Settings.Aimbot and UserInputService:IsKeyDown(Settings.AimbotKey) then
            local target = GetClosestPlayer()
            if target and target.Character then
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                local head = target.Character:FindFirstChild("Head")
                if hrp and head then
                    local lookAt = head.Position
                    local cam = workspace.CurrentCamera
                    cam.CFrame = cam.CFrame:Lerp(
                        CFrame.new(cam.CFrame.Position, lookAt),
                        Settings.AimbotSmoothness
                    )
                end
            end
        end
    end)
end
AimbotLoop()

-- ============================================
-- ESP Logik
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

local function RemoveESP(player)
    if ESPDrawings[player] then
        ESPDrawings[player].box:Remove()
        ESPDrawings[player] = nil
    end
end

local function ESPUpdate()
    RunService.RenderStepped:Connect(function()
        if not Settings.ESP then
            for _, data in pairs(ESPDrawings) do
                data.box.Visible = false
            end
            return
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                CreateESP(player)
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local cam = workspace.CurrentCamera

                if hrp and humanoid and humanoid.Health > 0 then
                    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local head = player.Character:FindFirstChild("Head")
                        if head then
                            local headPos = cam:WorldToViewportPoint(head.Position)
                            local height = math.abs(pos.Y - headPos.Y) * 2
                            local width = height / 2
                            ESPDrawings[player].box.Size = Vector2.new(width, height)
                            ESPDrawings[player].box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                            ESPDrawings[player].box.Visible = true
                            ESPDrawings[player].box.Color = Settings.ESPColor
                        end
                    else
                        ESPDrawings[player].box.Visible = false
                    end
                else
                    if ESPDrawings[player] then
                        ESPDrawings[player].box.Visible = false
                    end
                end
            end
        end
    end)
end
ESPUpdate()

Players.PlayerRemoving:Connect(function(p)
    if ESPDrawings[p] then
        ESPDrawings[p].box:Remove()
        ESPDrawings[p] = nil
    end
end)

-- ============================================
-- HITBOX EXPANDER
-- ============================================
local function ApplyHitbox(player)
    if not Settings.HitboxExpander then return end
    if player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
            hrp.Transparency = 0.6
        end
    end
end

local function ResetHitbox(player)
    if player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
        end
    end
end

RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Settings.HitboxExpander then
                ApplyHitbox(player)
            else
                ResetHitbox(player)
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
            else
                if hum.WalkSpeed == Settings.WalkSpeedValue then
                    hum.WalkSpeed = 16
                end
            end
        end
    end
end)

-- ============================================
-- MENÜ BUTTONS
-- ============================================
CreateToggle("Aimbot (Halte Q)", "Q", function(state) Settings.Aimbot = state end)
CreateToggle("ESP Boxes", "ESP", function(state) Settings.ESP = state end)
CreateToggle("Hitbox Expander", "HIT", function(state)
    Settings.HitboxExpander = state
    if not state then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ResetHitbox(p) end
        end
    end
end)
CreateToggle("Speed Hack", "SPD", function(state)
    Settings.WalkSpeed = state
    if not state then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end
end)

-- ============================================
-- MENÜ TOGGLE (RShift)
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.MenuKey then
        Settings.MenuOpen = not Settings.MenuOpen
        MainFrame.Visible = Settings.MenuOpen
    end
end)

-- Canvas Size anpassen
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
    local c = Instance.new("UICorner", notif)
    c.CornerRadius = UDim.new(0, 6)
    task.delay(2, function()
        TweenService:Create(notif, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        task.wait(0.5)
        notif:Destroy()
    end)
end

Notify("✅ Rivals Cheat geladen! RShift = Menü")
