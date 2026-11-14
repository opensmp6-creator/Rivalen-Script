--[[
    RIVALS CHEAT SCRIPT  v2.0
    Repo: https://github.com/opensmp6-creator/Rivalen-Script
    Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/opensmp6-creator/Rivalen-Script/main/Script.lua", true))()

    Hotkeys:
      RMB  = Aimbot (halten)
      X    = Killaura toggle
      F    = Fly toggle
      N    = NoClip toggle
      K    = GUI toggle
--]]

--============================================================
-- SERVICES
--============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local RS               = game:GetService("ReplicatedStorage")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer

local HAS_DRAWING = pcall(function() return Drawing.new("Line") end)

--============================================================
-- CONFIG
--============================================================
local Config = {
    ESP = {
        Enabled      = true,
        Boxes        = true,
        Tracers      = true,
        Names        = true,
        Health       = true,
        Distance     = true,
        MaxDist      = 1500,
        BoxColor     = Color3.fromRGB(0, 255, 100),
        TracerColor  = Color3.fromRGB(255, 60, 60),
        NameColor    = Color3.fromRGB(255, 255, 255),
        DistColor    = Color3.fromRGB(180, 180, 180),
    },
    Aimbot = {
        Enabled      = true,
        Key          = Enum.UserInputType.MouseButton2,
        Smoothness   = 0.35,      -- höher = smoother, niedriger = snappier
        FOV          = 140,
        MaxDist      = 900,
        WallCheck    = true,
        TeamCheck    = true,
        ShowFOV      = true,
        TargetPart   = "Head",    -- "Head" | "HumanoidRootPart" | "UpperTorso"
    },
    Killaura = {
        Enabled      = true,
        Range        = 28,
        Key          = Enum.KeyCode.X,
        RemotePath   = nil,       -- z.B. RS.Remotes.Hit ; nil = Fallback (Tool:Activate + VirtualUser)
    },
    Speed = {
        Enabled      = true,
        Value        = 30,
    },
    JumpPower = 70,
    Fly = {
        Enabled      = false,
        Speed        = 55,
        Key          = Enum.KeyCode.F,
    },
    NoClip = false,
    AutoReload = true,
}

--============================================================
-- HELPERS
--============================================================
local function getChar(plr)
    return plr and plr.Character
end

local function getHum(plr)
    local c = getChar(plr)
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot(plr)
    local c = getChar(plr)
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function alive(plr)
    local h = getHum(plr)
    return h and h.Health > 0
end

local function sameTeam(a, b)
    return a and b and a.Team and b.Team and a.Team == b.Team
end

local function rayClear(from, to, ignore)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(from, to - from, p)
    return hit == nil
end

--============================================================
-- ESP (Drawing API)
--============================================================
local ESP = {}          -- [player] = {box, tracer, name, health_bg, health_fill, dist}
local Screen = Camera.ViewportSize

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    Screen = Camera.ViewportSize
end)

local function newDraw(type_)
    if not HAS_DRAWING then return nil end
    local ok, obj = pcall(Drawing.new, type_)
    return ok and obj or nil
end

local function createESP(plr)
    if plr == LP or ESP[plr] then return end
    if not HAS_DRAWING then return end
    ESP[plr] = {
        box        = newDraw("Square"),
        tracer     = newDraw("Line"),
        name       = newDraw("Text"),
        dist       = newDraw("Text"),
        health_bg  = newDraw("Square"),
        health_fill= newDraw("Square"),
    }
    local e = ESP[plr]
    if e.box then
        e.box.Thickness = 1
        e.box.Filled = false
        e.box.Color = Config.ESP.BoxColor
    end
    if e.tracer then
        e.tracer.Thickness = 1
        e.tracer.Color = Config.ESP.TracerColor
    end
    if e.name then
        e.name.Center = true
        e.name.Outline = true
        e.name.Size = 14
        e.name.Font = 2 -- Plex
        e.name.Color = Config.ESP.NameColor
    end
    if e.dist then
        e.dist.Center = true
        e.dist.Outline = true
        e.dist.Size = 12
        e.dist.Font = 2
        e.dist.Color = Config.ESP.DistColor
    end
    if e.health_bg then
        e.health_bg.Thickness = 0
        e.health_bg.Filled = true
        e.health_bg.Color = Color3.fromRGB(40, 40, 40)
    end
    if e.health_fill then
        e.health_fill.Thickness = 0
        e.health_fill.Filled = true
        e.health_fill.Color = Color3.fromRGB(0, 255, 0)
    end
end

local function destroyESP(plr)
    local e = ESP[plr]
    if not e then return end
    for _, obj in pairs(e) do
        pcall(function() obj:Remove() end)
    end
    ESP[plr] = nil
end

local function setVisible(e, state)
    for _, obj in pairs(e) do
        if obj and obj.Visible ~= nil then obj.Visible = state end
    end
end

local function headPos(plr)
    local c = getChar(plr)
    local h = c and c:FindFirstChild("Head")
    return h and h.Position or (getRoot(plr) and getRoot(plr).Position)
end

local function updateESP(plr)
    local e = ESP[plr]
    if not e then return end
    local char = getChar(plr)
    local hum = getHum(plr)
    local root = getRoot(plr)
    if not (Config.ESP.Enabled and char and hum and root and hum.Health > 0) then
        setVisible(e, false)
        return
    end

    local camPos = Camera.CFrame.Position
    local dist = (camPos - root.Position).Magnitude
    if dist > Config.ESP.MaxDist then
        setVisible(e, false)
        return
    end

    -- Berechne Bounding-Box auf dem Bildschirm
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local any = false
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local size = (Camera.CFrame.Position - part.Position).Magnitude
                local pad = math.clamp(1500 / size, 2, 40)
                minX = math.min(minX, pos.X - pad)
                minY = math.min(minY, pos.Y - pad)
                maxX = math.max(maxX, pos.X + pad)
                maxY = math.max(maxY, pos.Y + pad)
                any = true
            end
        end
    end
    if not any then
        setVisible(e, false)
        return
    end

    local w, h = maxX - minX, maxY - minY
    local headPix = Camera:WorldToViewportPoint(headPos(plr))

    if e.box then
        e.box.Visible   = Config.ESP.Boxes
        e.box.Size      = Vector2.new(w, h)
        e.box.Position  = Vector2.new(minX, minY)
        e.box.Color     = Config.ESP.BoxColor
    end

    if e.tracer then
        e.tracer.Visible = Config.ESP.Tracers
        e.tracer.From    = Vector2.new(Screen.X / 2, Screen.Y)
        e.tracer.To      = Vector2.new(headPix.X, headPix.Y)
    end

    if e.name then
        e.name.Visible   = Config.ESP.Names
        e.name.Position  = Vector2.new(minX + w / 2, minY - 16)
        e.name.Text      = plr.Name
    end

    if e.dist then
        e.dist.Visible   = Config.ESP.Distance
        e.dist.Position  = Vector2.new(minX + w / 2, maxY + 2)
        e.dist.Text      = ("%d m"):format(math.floor(dist / 3))
    end

    if e.health_bg and e.health_fill then
        local show = Config.ESP.Health
        e.health_bg.Visible   = show
        e.health_fill.Visible = show
        if show then
            local barH = h
            local barX = minX - 6
            e.health_bg.Size     = Vector2.new(3, barH)
            e.health_bg.Position = Vector2.new(barX, minY)
            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            e.health_fill.Size     = Vector2.new(3, barH * pct)
            e.health_fill.Position = Vector2.new(barX, maxY - barH * pct)
            local critical = pct <= 0.3
            e.health_fill.Color = critical
                and Color3.fromRGB(255, 60, 60)
                or Color3.fromRGB(0, 255, 100)
        end
    end
end

--============================================================
-- AIMBOT
--============================================================
local Aim = { active = false }

local fovCircle
if HAS_DRAWING and Config.Aimbot.ShowFOV then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1
    fovCircle.NumSides   = 60
    fovCircle.Radius     = Config.Aimbot.FOV
    fovCircle.Filled     = false
    fovCircle.Color      = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 0.6
end

local function getTargetPart(plr)
    local c = getChar(plr)
    if not c then return nil end
    return c:FindFirstChild(Config.Aimbot.TargetPart)
        or c:FindFirstChild("Head")
        or c:FindFirstChild("HumanoidRootPart")
end

local function closestTarget()
    local mouse = UIS:GetMouseLocation()
    local best, bestDist = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if Config.Aimbot.TeamCheck and sameTeam(plr, LP) then continue end
        if not alive(plr) then continue end

        local root = getRoot(plr)
        if not root then continue end
        if (Camera.CFrame.Position - root.Position).Magnitude > Config.Aimbot.MaxDist then continue end

        local part = getTargetPart(plr)
        if not part then continue end

        local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local px = Vector2.new(screen.X, screen.Y)
        local d  = (px - mouse).Magnitude
        if d > Config.Aimbot.FOV or d >= bestDist then continue end

        if Config.Aimbot.WallCheck then
            local ok = rayClear(Camera.CFrame.Position, part.Position, {LP.Character, plr.Character})
            if not ok then continue end
        end

        best, bestDist = plr, d
    end
    return best
end

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Config.Aimbot.Key then Aim.active = true end
end)

UIS.InputEnded:Connect(function(i, gp)
    if i.UserInputType == Config.Aimbot.Key then Aim.active = false end
end)

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = UIS:GetMouseLocation()
        fovCircle.Visible  = Config.Aimbot.Enabled and Config.Aimbot.ShowFOV
        fovCircle.Radius   = Config.Aimbot.FOV
    end
    if not Aim.active or not Config.Aimbot.Enabled then return end
    local target = closestTarget()
    if not target then return end
    local part = getTargetPart(target)
    if not part then return end
    local des = CFrame.new(Camera.CFrame.Position, part.Position)
    Camera.CFrame = Camera.CFrame:Lerp(des, Config.Aimbot.Smoothness)
end)

--============================================================
-- KILLAURA
--============================================================
local function fireHit(target)
    local remote = Config.Killaura.RemotePath
    if remote and typeof(remote) == "Instance" then
        pcall(function() remote:FireServer(target.Character) end)
        return
    end
    -- Fallback: Tool:Activate + VirtualUser
    local char = LP.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then pcall(function() t:Activate() end) end
        end
    end
    if VirtualUser then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(UIS:GetMouseLocation())
        end)
    end
end

task.spawn(function()
    while task.wait(0.06) do
        if not Config.Killaura.Enabled then continue end
        local root = getRoot(LP)
        if not root then continue end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP or not alive(plr) then continue end
            local tr = getRoot(plr)
            if tr and (root.Position - tr.Position).Magnitude <= Config.Killaura.Range then
                fireHit(plr)
                break
            end
        end
    end
end)

--============================================================
-- SPEED / JUMP
--============================================================
local function applyMovement()
    local hum = getHum(LP)
    if not hum then return end
    hum.WalkSpeed = Config.Speed.Enabled and Config.Speed.Value or 16
    hum.UseJumpPower = true
    hum.JumpPower = Config.JumpPower
end

LP.CharacterAdded:Connect(function()
    task.wait(0.4)
    applyMovement()
    if Config.Fly.Enabled then -- re-apply fly
        Fly.enable()
    end
end)
if LP.Character then applyMovement() end

--============================================================
-- FLY
--============================================================
Fly = {
    bv = nil,
    bg = nil,
    enable = function()
        local root = getRoot(LP)
        if not root or Fly.bv then return end
        Fly.bv = Instance.new("BodyVelocity")
        Fly.bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        Fly.bv.Velocity = Vector3.zero
        Fly.bv.Parent = root

        Fly.bg = Instance.new("BodyGyro")
        Fly.bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        Fly.bg.P = 1e4
        Fly.bg.Parent = root

        Config.Fly.Enabled = true
    end,
    disable = function()
        if Fly.bv then Fly.bv:Destroy() end
        if Fly.bg then Fly.bg:Destroy() end
        Fly.bv, Fly.bg = nil, nil
        Config.Fly.Enabled = false
    end,
}

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Config.Fly.Key then
        if Config.Fly.Enabled then Fly.disable() else Fly.enable() end
    end
end)

RunService.RenderStepped:Connect(function()
    if not Config.Fly.Enabled or not Fly.bv then return end
    local cam = Camera.CFrame
    local dir = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W)
