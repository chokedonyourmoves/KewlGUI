local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera

-- Main variables
local LocalPlayer = Players.LocalPlayer
local EspObjects = {}
local Connections = {}
local ClosestTarget = nil

local Settings = {
    -- ESP
    Enabled = false,
    ShowFOV = true,
    FOVSize = 180,
    FOVColor = Color3.fromRGB(0, 255, 255),
    ShowTracers = true,
    ShowBox = true,
    ShowHealth = true,
    ShowNames = true,
    ShowDistance = true,
    MaxDistance = 2000,
    TeamCheck = true,
    TextSize = 13,
    -- Aimbot / Silent Aim
    AimEnabled = false,
    ShowAimFOV = true,
    AimFOVSize = 120,
    AimFOVColor = Color3.fromRGB(255, 0, 255),
    TargetPart = "Head",  -- "Head", "HumanoidRootPart", "UpperTorso", "Random"
    Predict = true,
    VisibleCheck = true,
    AimMaxDistance = 1500,
    PredictionAmount = 0.13,
    HitboxSize = 1.4,  -- Expansion multiplier
}

-- Drawing Objects
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = Settings.ShowFOV
FOVCircle.Radius = Settings.FOVSize
FOVCircle.Color = Settings.FOVColor
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.NumSides = 60
FOVCircle.Transparency = 1

local AimFOVCircle = Drawing.new("Circle")
AimFOVCircle.Visible = Settings.ShowAimFOV
AimFOVCircle.Radius = Settings.AimFOVSize
AimFOVCircle.Color = Settings.AimFOVColor
AimFOVCircle.Thickness = 2
AimFOVCircle.Filled = false
AimFOVCircle.NumSides = 60
AimFOVCircle.Transparency = 1

-- ESP Functions
local function CreateEsp(player)
    if player == LocalPlayer or EspObjects[player] then return end
    local esp = {
        Box = Drawing.new("Square"),
        BoxFill = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
    }
    esp.Box.Thickness = 1.5
    esp.Box.Filled = false
    esp.Box.Color = Color3.fromRGB(0, 255, 255)
    esp.BoxFill.Filled = true
    esp.BoxFill.Color = Color3.new(0,0,0)
    esp.BoxFill.Transparency = 0.7
    esp.Tracer.Thickness = 1.5
    esp.Tracer.Color = Color3.fromRGB(255, 50, 50)
    for _, text in pairs({esp.Name, esp.Health, esp.Distance}) do
        text.Center = true
        text.Outline = true
        text.Font = 2
        text.Color = Color3.new(1,1,1)
        text.Size = Settings.TextSize
    end
    esp.Distance.Size = Settings.TextSize - 1
    EspObjects[player] = esp
end

local function RemoveEsp(player)
    if EspObjects[player] then
        for _, obj in pairs(EspObjects[player]) do obj:Remove() end
        EspObjects[player] = nil
    end
end

-- Update FOV Circles
local function UpdateFOVs()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = center
    FOVCircle.Radius = Settings.FOVSize
    FOVCircle.Color = Settings.FOVColor
    AimFOVCircle.Position = center
    AimFOVCircle.Radius = Settings.AimFOVSize
    AimFOVCircle.Color = Settings.AimFOVColor
end

-- Main Update Loop (ESP + Find Closest for Aimbot)
local function UpdateAll()
    if not Settings.Enabled and not Settings.AimEnabled then return end

    local center2d = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local lpChar = LocalPlayer.Character
    local lpRoot = lpChar and lpChar.PrimaryPart
    local lpPos = lpRoot and lpRoot.Position

    ClosestTarget = nil
    local closestAimDist = math.huge

    for player, esp in pairs(EspObjects) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char.PrimaryPart
        local head = char:FindFirstChild("Head")

        if not (char and hum and hum.Health > 0 and root and head and lpPos) then
            for _, d in pairs(esp) do d.Visible = false end
        else
            local dist3d = (lpPos - root.Position).Magnitude
            if dist3d > math.max(Settings.MaxDistance, Settings.AimMaxDistance) then
                for _, d in pairs(esp) do d.Visible = false end
            else
                local headPos3d = head.Position
                local headScreen, onScreen = Camera:WorldToViewportPoint(headPos3d)

                if not onScreen then
                    for _, d in pairs(esp) do d.Visible = false end
                else
                    -- Team Check
                    if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                        for _, d in pairs(esp) do d.Visible = false end
                    else
                        -- Aimbot Closest Check
                        if Settings.AimEnabled then
                            local screenDist = (Vector2.new(headScreen.X, headScreen.Y) - center2d).Magnitude
                            if screenDist <= Settings.AimFOVSize and dist3d <= Settings.AimMaxDistance and screenDist < closestAimDist then
                                if not Settings.VisibleCheck or onScreen then
                                    closestAimDist = screenDist
                                    ClosestTarget = player
                                end
                            end
                        end

                        -- ESP Rendering (same as refined before)
                        local scale = math.clamp(2500 / dist3d, 1, 50)
                        local boxW = scale * 0.9
                        local boxH = scale * 1.5
                        local boxPos = Vector2.new(headScreen.X - boxW/2, headScreen.Y - boxH/2)

                        local hpPct = hum.Health / hum.MaxHealth
                        local hpCol = Color3.new(1 - hpPct, hpPct, 0)

                        -- Box
                        if Settings.ShowBox then
                            esp.Box.Size = Vector2.new(boxW, boxH)
                            esp.Box.Position = boxPos
                            esp.Box.Color = hpCol
                            esp.Box.Visible = true
                            esp.BoxFill.Size = Vector2.new(boxW, boxH)
                            esp.BoxFill.Position = boxPos
                            esp.BoxFill.Visible = true
                        else
                            esp.Box.Visible = esp.BoxFill.Visible = false
                        end

                        -- Tracer
                        if Settings.ShowTracers then
                            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 20)
                            esp.Tracer.To = Vector2.new(headScreen.X, headScreen.Y + boxH / 2)
                            esp.Tracer.Color = hpCol
                            esp.Tracer.Visible = true
                        else
                            esp.Tracer.Visible = false
                        end

                        -- Name
                        if Settings.ShowNames then
                            esp.Name.Text = player.Name
                            esp.Name.Position = Vector2.new(headScreen.X, boxPos.Y - 16)
                            esp.Name.Visible = true
                        else
                            esp.Name.Visible = false
                        end

                        -- Health
                        if Settings.ShowHealth then
                            esp.Health.Text = tostring(math.floor(hum.Health))
                            esp.Health.Position = Vector2.new(headScreen.X, boxPos.Y + boxH + 2)
                            esp.Health.Color = hpCol
                            esp.Health.Visible = true
                        else
                            esp.Health.Visible = false
                        end

                        -- Distance
                        if Settings.ShowDistance then
                            esp.Distance.Text = tostring(math.floor(dist3d))
                            esp.Distance.Position = Vector2.new(headScreen.X, boxPos.Y + boxH + 18)
                            esp.Distance.Visible = true
                        else
                            esp.Distance.Visible = false
                        end
                    end
                end
            end
        end
    end

    UpdateFOVs()
end

-- Toggle ESP
local function ToggleESP(en)
    Settings.Enabled = en
    if en then
        for _, p in ipairs(Players:GetPlayers()) do CreateEsp(p) end
    else
        for _, esp in pairs(EspObjects) do
            for _, d in pairs(esp) do d.Visible = false end
        end
    end
end

-- Get Prediction Position
local function GetPredictedPos(targetPlayer)
    local char = targetPlayer.Character
    if not char then return nil end

    local part = char:FindFirstChild(Settings.TargetPart)
    if not part then return nil end

    local targetPos = part.Position
    if Settings.Predict then
        local root = char.PrimaryPart
        if root then
            local vel = root.AssemblyLinearVelocity
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            targetPos = targetPos + vel * (ping * Settings.PredictionAmount)
        end
    end

    -- Hitbox Expansion (random point inside sphere)
    local randOffset = Vector3.new(
        math.random(-1,1) * Settings.HitboxSize,
        math.random(-1,1) * Settings.HitboxSize * 0.5,
        math.random(-1,1) * Settings.HitboxSize
    )
    return targetPos + randOffset
end

-- Silent Aim Hook (Raycast)
local RaycastHook
local mt = getrawmetatable(game)
local oldRaycast = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if Settings.AimEnabled and ClosestTarget and method == "Raycast" and self == workspace then
        local origin = args[1]
        local direction = args[2]
        local targetPos = GetPredictedPos(ClosestTarget)
        if targetPos then
            local newDir = (targetPos - origin).Unit * direction.Magnitude
            args[2] = newDir
        end
    end

    return oldRaycast(self, unpack(args))
end)
setreadonly(mt, true)

-- Destroy
local function DestroyAll()
    for p in pairs(EspObjects) do RemoveEsp(p) end
    FOVCircle:Remove()
    AimFOVCircle:Remove()
    Rayfield:Destroy()
    for _, conn in ipairs(Connections) do conn:Disconnect() end
end

-- UI
local Window = Rayfield:CreateWindow({
    Name = "🦎 Kewl GUI | ESP + Silent Aim",
    LoadingTitle = "Loading v2.2...",
    LoadingSubtitle = "ESP & Aimbot Suite",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "KewlGUI",
        FileName = "KewlConfig"
    },
    ToggleUIKeybind = "RightControl"
})

-- ESP Tab
local ESPTab = Window:CreateTab("ESP", "eye")
ESPTab:CreateToggle({Name = "Enable ESP", CurrentValue = false, Flag = "ESP_Main", Callback = ToggleESP})
ESPTab:CreateToggle({Name = "FOV Circle", CurrentValue = Settings.ShowFOV, Flag = "ESP_FOV", Callback = function(v) Settings.ShowFOV = v; FOVCircle.Visible = v end})
ESPTab:CreateToggle({Name = "Boxes", CurrentValue = Settings.ShowBox, Flag = "ESP_Box", Callback = function(v) Settings.ShowBox = v end})
ESPTab:CreateToggle({Name = "Tracers", CurrentValue = Settings.ShowTracers, Flag = "ESP_Tracer", Callback = function(v) Settings.ShowTracers = v end})
ESPTab:CreateToggle({Name = "Names", CurrentValue = Settings.ShowNames, Flag = "ESP_Name", Callback = function(v) Settings.ShowNames = v end})
ESPTab:CreateToggle({Name = "Health", CurrentValue = Settings.ShowHealth, Flag = "ESP_Health", Callback = function(v) Settings.ShowHealth = v end})
ESPTab:CreateToggle({Name = "Distance", CurrentValue = Settings.ShowDistance, Flag = "ESP_Dist", Callback = function(v) Settings.ShowDistance = v end})
ESPTab:CreateToggle({Name = "Team Check", CurrentValue = Settings.TeamCheck, Flag = "ESP_Team", Callback = function(v) Settings.TeamCheck = v end})

-- Aimbot Tab
local AimTab = Window:CreateTab("Aimbot", "target")
AimTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "Aim_Main",
    Callback = function(Value)
        Settings.AimEnabled = Value
    end
})
AimTab:CreateToggle({Name = "Aim FOV Circle", CurrentValue = Settings.ShowAimFOV, Flag = "Aim_FOV", Callback = function(v) Settings.ShowAimFOV = v; AimFOVCircle.Visible = v end})
AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Random"},
    CurrentOption = {"Head"},
    Flag = "Aim_Part",
    Callback = function(Option)
        Settings.TargetPart = Option[1]
    end
})
AimTab:CreateToggle({Name = "Movement Prediction", CurrentValue = Settings.Predict, Flag = "Aim_Predict", Callback = function(v) Settings.Predict = v end})
AimTab:CreateToggle({Name = "Visible Check", CurrentValue = Settings.VisibleCheck, Flag = "Aim_Vis", Callback = function(v) Settings.VisibleCheck = v end})
AimTab:CreateSlider({Name = "Aim FOV Size", Range = {50, 300}, Increment = 10, CurrentValue = 120, Flag = "Aim_FOVSize", Callback = function(v) Settings.AimFOVSize = v end})
AimTab:CreateSlider({Name = "Max Aim Dist", Range = {500, 5000}, Increment = 100, Suffix = "studs", CurrentValue = 1500, Flag = "Aim_Dist", Callback = function(v) Settings.AimMaxDistance = v end})
AimTab:CreateSlider({Name = "Hitbox Size", Range = {1, 3}, Increment = 0.1, Suffix = "x", CurrentValue = 1.4, Flag = "Aim_Hitbox", Callback = function(v) Settings.HitboxSize = v end})
AimTab:CreateSlider({Name = "Prediction", Range = {0, 0.3}, Increment = 0.01, Suffix = "", CurrentValue = 0.13, Flag = "Aim_PredAmt", Callback = function(v) Settings.PredictionAmount = v end})

-- Settings Tab
local SetTab = Window:CreateTab("Settings", "settings")
SetTab:CreateSlider({Name = "ESP FOV", Range = {50, 400}, Increment = 10, Suffix = "px", CurrentValue = 180, Flag = "ESP_FOVSize", Callback = function(v) Settings.FOVSize = v end})
SetTab:CreateSlider({Name = "ESP Max Dist", Range = {500, 5000}, Increment = 100, Suffix = "studs", CurrentValue = 2000, Flag = "ESP_DistMax", Callback = function(v) Settings.MaxDistance = v end})
SetTab:CreateSlider({Name = "Text Size", Range = {10, 20}, Increment = 1, Suffix = "px", CurrentValue = 13, Flag = "TextSize", Callback = function(v)
    Settings.TextSize = v
    for _, esp in pairs(EspObjects) do
        esp.Name.Size = v
        esp.Health.Size = v
        esp.Distance.Size = v - 1
    end
end})

-- Info Tab
local InfoTab = Window:CreateTab("Info", "info")
InfoTab:CreateButton({Name = "Destroy GUI", Callback = DestroyAll})

-- Connections
table.insert(Connections, RunService.RenderStepped:Connect(UpdateAll))
table.insert(Connections, Players.PlayerAdded:Connect(CreateEsp))
table.insert(Connections, Players.PlayerRemoving:Connect(RemoveEsp))
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateEsp(player)
    end
end

-- Initial
print("🦎 Kewl GUI v2.2 | ESP + SILENT AIM Loaded! (FOV Adjustable)")
print("Toggle: RightControl")

return {
    ToggleESP = ToggleESP,
    Settings = Settings,
    Destroy = DestroyAll
}
