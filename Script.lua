--[[
    RIVALS CHEAT SCRIPT
    Features: Aimbot, ESP, Silent Aim, No Recoil, Teleport, Godmode
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚙️ EINSTELLUNGEN
local Config = {
    Aimbot = true,
    AimbotSmoothness = 0.15,
    AimbotFOV = 120,
    SilentAim = true,
    ESP = true,
    ESPColor = Color3.fromRGB(0, 255, 0),
    NoRecoil = true,
    InfiniteAmmo = true,
    WalkSpeed = 60,
    JumpPower = 120,
    Godmode = true,
}

-- ============================================================
-- 🎯 AIMBOT
-- ============================================================
local function getClosestPlayer()
    local closest = nil
    local shortest = Config.AimbotFOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            if head and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = head
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if Config.Aimbot then
        local target = getClosestPlayer()
        if target then
            local newCF = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, Config.AimbotSmoothness)
        end
    end
end)

-- ============================================================
-- 🔫 SILENT AIM
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not Config.SilentAim then return end
    local target = getClosestPlayer()
    if target then
        -- Hook: falls Waffe Raycast nutzt
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        setreadonly(mt, false)
        mt.__index = newproxy(true)
        getmetatable(mt.__index).__index = function(t, k)
            if k == "Hit" or k == "Target" then return target end
            return oldIndex(t, k)
        end
        setreadonly(mt, true)
    end
end)

-- ============================================================
-- 👁️ ESP (Box + Name + Health)
-- ============================================================
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "RIVALS_ESP"

local function createESP(player)
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Color = Config.ESPColor
    box.Filled = false
    box.Visible = false

    local name = Drawing.new("Text")
    name.Size = 16
    name.Center = true
    name.Outline = true
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Visible = false

    local healthBar = Drawing.new("Line")
    healthBar.Thickness = 4
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false

    RunService.RenderStepped:Connect(function()
        if not Config.ESP or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            box.Visible = false; name.Visible = false; healthBar.Visible = false
            return
        end
        local root = player.Character.HumanoidRootPart
        local head = player.Character:FindFirstChild("Head")
        local hum = player.Character:FindFirstChild("Humanoid")
        if not head or not hum or hum.Health <= 0 then
            box.Visible = false; name.Visible = false; healthBar.Visible = false
            return
        end

        local hrpPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position)

        if onScreen then
            local height = math.abs(headPos.Y - hrpPos.Y) * 2
            local width = height / 2

            box.Size = Vector2.new(width, height)
            box.Position = Vector2.new(hrpPos.X - width/2, hrpPos.Y - height/2)
            box.Visible = true

            name.Text = player.Name .. " [" .. math.floor(hum.Health) .. "]"
            name.Position = Vector2.new(hrpPos.X, hrpPos.Y - height/2 - 20)
            name.Visible = true

            local hpRatio = hum.Health / hum.MaxHealth
            healthBar.From = Vector2.new(box.Position.X - 6, box.Position.Y)
            healthBar.To = Vector2.new(box.Position.X - 6, box.Position.Y + height * hpRatio)
            healthBar.Color = Color3.fromRGB(255 * (1 - hpRatio), 255 * hpRatio, 0)
            healthBar.Visible = true
        else
            box.Visible = false; name.Visible = false; healthBar.Visible = false
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createESP(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createESP(p) end end)

-- ============================================================
-- 🏃 SPEED / JUMP / GODMODE
-- ============================================================
local function applyMovement()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        hum.WalkSpeed = Config.WalkSpeed
        hum.JumpPower = Config.JumpPower
        hum.UseJumpPower = true
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    applyMovement()
end)

if LocalPlayer.Character then applyMovement() end

-- Godmode
RunService.Stepped:Connect(function()
    if Config.Godmode and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
    end
end)

-- ============================================================
-- 🔫 NO RECOIL / INFINITE AMMO (Fallback)
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not Config.NoRecoil then return end
    local char = LocalPlayer.Character
    if char then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local equipped = char:FindFirstChildOfClass("Tool")
        if equipped then
            -- Versuch, Recoil-Eigenschaften zu nullen
            pcall(function()
                for _, v in pairs(equipped:GetDescendants()) do
                    if v:IsA("NumberValue") then
                        if v.Name:lower():find("recoil") then v.Value = 0 end
                        if v.Name:lower():find("ammo") then v.Value = 9999 end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- 🚀 TELEPORT ZUM GEGNER (Taste "T")
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then
        local target = getClosestPlayer()
        if target and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 0, 3)
        end
    end
end)

-- ============================================================
-- 💬 INFO
-- ============================================================
print("✅ RIVALS Cheat geladen!")
print("Features: Aimbot, SilentAim, ESP, Godmode, Speed, Teleport (T)")
