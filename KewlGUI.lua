local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera

-- State
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
    AimMaxDistance = 1000,
    AimFOVSize = 120,
    AimFOVColor = Color3.fromRGB(255, 0, 0),
    TargetPart = "Head",
    Predict = true,
    PredictionAmount = 1,
    HitboxSize = 0,
    VisibleCheck = true,
    Tracking = true,
    AimSmooth = 0,
}

-- FOV circles (Drawing API)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64

local AimFOVCircle = Drawing.new("Circle")
AimFOVCircle.Thickness = 1
AimFOVCircle.Filled = false
AimFOVCircle.Transparency = 1
AimFOVCircle.NumSides = 64

-- ESP object lifecycle
local function CreateEsp(player)
    if EspObjects[player] then return end

    local esp = {
        Box       = Drawing.new("Square"),
        BoxFill   = Drawing.new("Square"),
        Tracer    = Drawing.new("Line"),
        HealthBar = Drawing.new("Line"),
        Name      = Drawing.new("Text"),
        Distance  = Drawing.new("Text"),
    }

    esp.Box.Thickness = 1
    esp.Box.Filled = false

    esp.BoxFill.Filled = true
    esp.BoxFill.Transparency = 0.5

    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Distance.Center = true
    esp.Distance.Outline = true

    for _, d in pairs(esp) do d.Visible = false end
    EspObjects[player] = esp
end

local function RemoveEsp(player)
    local esp = EspObjects[player]
    if not esp then return end
    for _, d in pairs(esp) do d:Remove() end
    EspObjects[player] = nil
end

-- FOV layout
local function UpdateFOVs()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = center
    FOVCircle.Radius = Settings.FOVSize
    FOVCircle.Color = Settings.FOVColor
    FOVCircle.Visible = Settings.ShowFOV and Settings.Enabled

    AimFOVCircle.Position = center
    AimFOVCircle.Radius = Settings.AimFOVSize
    AimFOVCircle.Color = Settings.AimFOVColor
    AimFOVCircle.Visible = Settings.AimEnabled and Settings.Tracking
end

-- Main loop: ESP render + closest target acquisition
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
        local root = char and char.PrimaryPart
        local head = char and char:FindFirstChild("Head")

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
                elseif Settings.TeamCheck and player.Team == LocalPlayer.Team then
                    for _, d in pairs(esp) do d.Visible = false end
                else
                    -- Aimbot: pick closest within FOV
                    if Settings.AimEnabled then
                        local screenDist = (Vector2.new(headScreen.X, headScreen.Y) - center2d).Magnitude
                        if screenDist <= Settings.AimFOVSize
                            and dist3d <= Settings.AimMaxDistance
                            and screenDist < closestAimDist then

                            local isVisible = true
                            if Settings.VisibleCheck then
                                local origin = Camera.CFrame.Position
                                local params = RaycastParams.new()
                                params.FilterType = Enum.RaycastFilterType.Blacklist
                                params.FilterDescendantsInstances = {LocalPlayer.Character, char}
                                local result = workspace:Raycast(origin, headPos3d - origin, params)
                                isVisible = (result == nil)
                            end

                            if isVisible then
                                closestAimDist = screenDist
                                ClosestTarget = player
                            end
                        end
                    end

                    -- ESP rendering
                    local scale = math.clamp(2500 / dist3d, 1, 50)
                    local boxW = scale * 0.9
                    local boxH = scale * 1.5
                    local boxPos = Vector2.new(headScreen.X - boxW / 2, headScreen.Y - boxH / 2)

                    local hpPct = hum.Health / hum.MaxHealth
                    local hpCol = Color3.new(1 - hpPct, hpPct, 0)

                    if Settings.ShowBox then
                        esp.Box.Size = Vector2.new(boxW, boxH)
                        esp.Box.Position = boxPos
                        esp.Box.Color = hpCol
                        esp.Box.Visible = true

                        esp.BoxFill.Size = Vector2.new(boxW, boxH)
                        esp.BoxFill.Position = boxPos
                        esp.BoxFill.Color = hpCol
                        esp.BoxFill.Visible = true
                    else
                        esp.Box.Visible = false
                        esp.BoxFill.Visible = false
                    end

                    if Settings.ShowNames then
                        esp.Name.Text = player.Name
                        esp.Name.Size = Settings.TextSize
                        esp.Name.Position = Vector2.new(headScreen.X, boxPos.Y - 16)
                        esp.Name.Color = Color3.new(1, 1, 1)
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end

                    if Settings.ShowDistance then
                        esp.Distance.Text = math.floor(dist3d) .. "m"
                        esp.Distance.Size = Settings.TextSize
                        esp.Distance.Position = Vector2.new(headScreen.X, boxPos.Y + boxH + 4)
                        esp.Distance.Color = Color3.new(1, 1, 1)
                        esp.Distance.Visible = true
                    else
                        esp.Distance.Visible = false
                    end

                    if Settings.ShowHealth then
                        esp.HealthBar.From = Vector2.new(boxPos.X - 5, boxPos.Y)
                        esp.HealthBar.To = Vector2.new(boxPos.X - 5, boxPos.Y + boxH)
                        esp.HealthBar.Color = hpCol
                        esp.HealthBar.Thickness = 2
                        esp.HealthBar.Visible = true
                    else
                        esp.HealthBar.Visible = false
                    end

                    if Settings.ShowTracers then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(headScreen.X, headScreen.Y)
                        esp.Tracer.Color = hpCol
                        esp.Tracer.Thickness = 1
                        esp.Tracer.Visible = true
                    else
                        esp.Tracer.Visible = false
                    end
                end
            end
        end
    end

    UpdateFOVs()
end

-- ESP toggle
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

-- Predicted aim point
local function GetPredictedPos(targetPlayer)
    local char = targetPlayer.Character
    if not char then return nil end

    local part
    if Settings.TargetPart == "Random" then
        local candidates = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" }
        local available = {}
        for _, name in ipairs(candidates) do
            local found = char:FindFirstChild(name)
            if found then table.insert(available, found) end
        end
        if #available == 0 then return nil end
        part = available[math.random(1, #available)]
    else
        part = char:FindFirstChild(Settings.TargetPart)
    end
    if not part then return nil end

    local targetPos = part.Position

    if Settings.Predict then
        local root = char.PrimaryPart
        if root then
            local vel = root.AssemblyLinearVelocity
            local pingMs = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            local pingSeconds = pingMs / 1000
            targetPos = targetPos + vel * (pingSeconds * Settings.PredictionAmount)
        end
    end

    local randOffset = Vector3.new(
        math.random(-1, 1) * Settings.HitboxSize,
        math.random(-1, 1) * Settings.HitboxSize * 0.5,
        math.random(-1, 1) * Settings.HitboxSize
    )
    return targetPos + randOffset
end

-- Silent-aim raycast hook (with smoothing)
local mt = getrawmetatable(game)
local oldRaycast = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = { ... }
    local method = getnamecallmethod()

    if Settings.AimEnabled and Settings.Tracking and ClosestTarget
        and method == "Raycast" and self == workspace then

        local origin = args[1]
        local direction = args[2]
        local targetPos = GetPredictedPos(ClosestTarget)

        if targetPos then
            local desiredDir = (targetPos - origin).Unit
            local finalDir = desiredDir

            if Settings.AimSmooth > 0 then
                local alpha = math.clamp(1 - Settings.AimSmooth, 0.01, 1)
                finalDir = direction.Unit:Lerp(desiredDir, alpha).Unit
            end

            args[2] = finalDir * direction.Magnitude
        end
    end

    return oldRaycast(self, unpack(args))
end)
setreadonly(mt, true)

-- Teardown
local function DestroyAll()
    setreadonly(mt, false)
    mt.__namecall = oldRaycast
    setreadonly(mt, true)

    for p in pairs(EspObjects) do RemoveEsp(p) end
    FOVCircle:Remove()
    AimFOVCircle:Remove()
    Rayfield:Destroy()
    for _, conn in ipairs(Connections) do conn:Disconnect() end
end

-- UI (Rayfield Gen 2)
local Window = Rayfield:CreateWindow({
    name = "🦎 Kewl GUI | ESP + Silent Aim",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,
    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "KewlConfig",
        customFolder = "KewlGUI",
    },
})

-- ESP tab
local ESPTab = Window:CreateTab({ name = "ESP", icon = "eye" })

ESPTab:CreateToggle({
    name = "Enable ESP",
    value = false,
    flag = "ESP_Main",
    callback = ToggleESP,
})

ESPTab:CreateToggle({
    name = "FOV Circle",
    value = Settings.ShowFOV,
    flag = "ESP_FOV",
    callback = function(v)
        Settings.ShowFOV = v
        FOVCircle.Visible = v
    end,
})

ESPTab:CreateToggle({
    name = "Boxes",
    value = Settings.ShowBox,
    flag = "ESP_Box",
    callback = function(v) Settings.ShowBox = v end,
})

ESPTab:CreateToggle({
    name = "Health",
    value = Settings.ShowHealth,
    flag = "ESP_Health",
    callback = function(v) Settings.ShowHealth = v end,
})

ESPTab:CreateToggle({
    name = "Names",
    value = Settings.ShowNames,
    flag = "ESP_Names",
    callback = function(v) Settings.ShowNames = v end,
})

ESPTab:CreateToggle({
    name = "Distance",
    value = Settings.ShowDistance,
    flag = "ESP_Dist",
    callback = function(v) Settings.ShowDistance = v end,
})

ESPTab:CreateToggle({
    name = "Tracers",
    value = Settings.ShowTracers,
    flag = "ESP_Tracers",
    callback = function(v) Settings.ShowTracers = v end,
})

ESPTab:CreateToggle({
    name = "Team Check",
    value = Settings.TeamCheck,
    flag = "ESP_Team",
    callback = function(v) Settings.TeamCheck = v end,
})

ESPTab:CreateSlider({
    name = "Max Distance",
    range = { 100, 5000 },
    increment = 50,
    value = Settings.MaxDistance,
    flag = "ESP_MaxDist",
    callback = function(v) Settings.MaxDistance = v end,
})

ESPTab:CreateSlider({
    name = "FOV Size",
    range = { 50, 600 },
    increment = 5,
    value = Settings.FOVSize,
    flag = "ESP_FOVSize",
    callback = function(v) Settings.FOVSize = v end,
})

ESPTab:CreateSlider({
    name = "Text Size",
    range = { 8, 24 },
    increment = 1,
    value = Settings.TextSize,
    flag = "ESP_TextSize",
    callback = function(v) Settings.TextSize = v end,
})

-- Aimbot tab
local AimTab = Window:CreateTab({ name = "Aimbot", icon = "crosshair" })

AimTab:CreateToggle({
    name = "Enable Silent Aim",
    value = Settings.AimEnabled,
    flag = "Aim_Main",
    callback = function(v) Settings.AimEnabled = v end,
})

AimTab:CreateToggle({
    name = "Tracking",
    value = Settings.Tracking,
    flag = "Aim_Tracking",
    callback = function(v) Settings.Tracking = v end,
})

AimTab:CreateSlider({
    name = "Smoothing",
    range = { 0, 1 },
    increment = 0.01,
    value = Settings.AimSmooth,
    flag = "Aim_Smooth",
    callback = function(v) Settings.AimSmooth = v end,
})

AimTab:CreateSlider({
    name = "FOV Size",
    range = { 10, 600 },
    increment = 5,
    value = Settings.AimFOVSize,
    flag = "Aim_FOV",
    callback = function(v) Settings.AimFOVSize = v end,
})

AimTab:CreateSlider({
    name = "Max Distance",
    range = { 100, 3000 },
    increment = 50,
    value = Settings.AimMaxDistance,
    flag = "Aim_Dist",
    callback = function(v) Settings.AimMaxDistance = v end,
})

AimTab:CreateToggle({
    name = "Visible Check",
    value = Settings.VisibleCheck,
    flag = "Aim_Visible",
    callback = function(v) Settings.VisibleCheck = v end,
})

AimTab:CreateToggle({
    name = "Prediction",
    value = Settings.Predict,
    flag = "Aim_Predict",
    callback = function(v) Settings.Predict = v end,
})

AimTab:CreateSlider({
    name = "Prediction Amount",
    range = { 0, 5 },
    increment = 0.1,
    value = Settings.PredictionAmount,
    flag = "Aim_PredAmt",
    callback = function(v) Settings.PredictionAmount = v end,
})

AimTab:CreateSlider({
    name = "Hitbox Size",
    range = { 0, 5 },
    increment = 0.1,
    value = Settings.HitboxSize,
    flag = "Aim_Hitbox",
    callback = function(v) Settings.HitboxSize = v end,
})

AimTab:CreateDropdown({
    name = "Target Part",
    options = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Random" },
    multiSelect = false,
    value = Settings.TargetPart,
    flag = "Aim_Part",
    callback = function(v) Settings.TargetPart = v end,
})

-- Player connections + main loop
table.insert(Connections, Players.PlayerAdded:Connect(function(p)
    if Settings.Enabled then CreateEsp(p) end
end))
table.insert(Connections, Players.PlayerRemoving:Connect(RemoveEsp))
table.insert(Connections, RunService.RenderStepped:Connect(UpdateAll))
