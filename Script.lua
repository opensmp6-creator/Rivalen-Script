-- 🚀 NEXUS-MATRIX // Rivals Ultimate God-Bundle (Luau Exploit Script)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Konfiguration & Toggles
local Config = {
    FlyEnabled = true,
    FlySpeed = 75,
    ESPEnabled = true,
    AimbotEnabled = true,
    FOV = 120
}

-- 1. FLIGHT ENGINE (Fly)
local CoreGui = game:GetService("CoreGui")
local BV, BG

local function toggleFly(state)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = character.HumanoidRootPart

    if state then
        BV = Instance.new("BodyVelocity", rootPart)
        BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BV.Velocity = Vector3.new(0, 0, 0)
        
        BG = Instance.new("BodyGyro", rootPart)
        BG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        BG.CFrame = rootPart.CFrame

        RunService.RenderStepped:Connect(function()
            if not Config.FlyEnabled then return end
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            BV.Velocity = moveDir * Config.FlySpeed
            BG.CFrame = Camera.CFrame
        end)
    else
        if BV then BV:Destroy() end
        if BG then BG:Destroy() end
    end
end

-- 2. FULL PLAYER ESP
local function updateESP()
    if not Config.ESPEnabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not player.Character:FindFirstChild("NexusHighlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "NexusHighlight"
                hl.Adornee = player.Character
                hl.FillColor = Color3.fromRGB(255, 0, 128)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.Parent = player.Character
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    updateESP()
end)

-- 3. SILENT AIM / AIMBOT ASSIST
RunService.RenderStepped:Connect(function()
    if not Config.AimbotEnabled then return end
    local closestTarget = nil
    local shortestDist = Config.FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local headPos, onScreen = Camera:WorldToScreenPoint(player.Character.Head.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(headPos.X, headPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestTarget = player.Character.Head
                    end
                end
            end
        end
    end

    if closestTarget and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestTarget.Position)
    end
end)

print("⚡ [NEXUS-MATRIX] Rivals Hybrid Exploit geladen! Flugsteuerung mit W,A,S,D & Space aktiv.")
