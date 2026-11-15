-- 🤖 Roblox AI Engine (Description-based)
print('[AI] Starte Skript-Generierung per Beschreibung...')


-- ► Module: esp
-- ► ESP Module (Highlight)
pcall(function() local Players=game:GetService('Players') for _,p in pairs(Players:GetPlayers()) do if p~=Players.LocalPlayer and p.Character then local hl=Instance.new('Highlight', p.Character) hl.FillColor=Color3.fromRGB(132,220,210) end end end)

-- ► Module: aimbot
-- ► Aimbot Module
pcall(function() local lp=game.Players.LocalPlayer local cam=workspace.CurrentCamera game:GetService('RunService').RenderStepped:Connect(function() local closest,dist=nil,math.huge for _,p in pairs(game.Players:GetPlayers()) do if p~=lp and p.Character and p.Character:FindFirstChild('Head') then local d=(p.Character.Head.Position-cam.CFrame.Position).Magnitude if d<dist then closest,dist=p.Character.Head,d end end end if closest then cam.CFrame=CFrame.new(cam.CFrame.Position,closest.Position) end end) end)

-- ► Module: killaura
-- ► Killaura Module
pcall(function() local lp=game.Players.LocalPlayer game:GetService('RunService').Heartbeat:Connect(function() for _,p in pairs(game.Players:GetPlayers()) do if p~=lp and p.Character and p.Character:FindFirstChild('HumanoidRootPart') then local dist=(p.Character.HumanoidRootPart.Position-lp.Character.HumanoidRootPart.Position).Magnitude if dist<15 then lp.Character.HumanoidRootPart.CFrame=p.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,2) end end end end) end)

-- ► Module: player_esp
-- ► Player ESP / Visualizer Pattern
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local function addVisuals(character)
        if not character:FindFirstChild("AI_Highlight") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "AI_Highlight"
            highlight.Adornee = character
            highlight.FillColor = Color3.fromRGB(132, 220, 210)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Parent = character
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                addVisuals(player.Character)
            end
            player.CharacterAdded:Connect(addVisuals)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            if player ~= LocalPlayer then
                addVisuals(character)
            end
        end)
    end)
end)

-- ► Module: script_menu_ui
-- ► Modern Script Menu & UI Pattern
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    local UIS = game:GetService("UserInputService")
    
    -- Altes Menü löschen, falls bereits vorhanden
    if CoreGui:FindFirstChild("AI_ScriptMenu") then
        CoreGui.AI_ScriptMenu:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AI_ScriptMenu"
    screenGui.Parent = CoreGui

    -- Hauptfenster
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -140, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true -- Fenster ist im Spiel verschiebbar!
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    -- Titelbalken
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.Text = "🤖 AI Control Hub"
    title.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title

    -- Container für Buttons (Layout)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = mainFrame

    -- Abstandhalter nach dem Titel
    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, 10)
    spacer.BackgroundTransparency = 1
    spacer.LayoutOrder = 1
    spacer.Parent = mainFrame

    -- Hilfsfunktion zum Erstellen von Buttons
    local function createButton(name, order, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -30, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamSemibold
        btn.Text = name
        btn.LayoutOrder = order
        btn.Parent = mainFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Beispiel-Buttons hinzufügen
    createButton("Toggle ESP", 2, function()
        print("[AI UI] ESP Button gedrückt")
    end)

    createButton("Toggle Aimbot", 3, function()
        print("[AI UI] Aimbot Button gedrückt")
    end)

    createButton("Speed Boost (32)", 4, function()
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = 32
        end
    end)
    
    createButton("UI Schließen (Delete)", 5, function()
        screenGui:Destroy()
    end)
end)


print('[Omni Core] Skript zusammengestellt für: "mach mir einen Roblox Rivals Cheat mit:  • esp   • aimbot   • killaura  • script_menu_ui" ✓')
