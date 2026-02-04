local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

-- Main variables
local LocalPlayer = Players.LocalPlayer
local EspObjects = {}
local Connections = {}
local Settings = {
    Enabled = true,
    ShowFOV = true,
    FOVSize = 120,
    FOVColor = Color3.fromRGB(0, 255, 255),
    ShowTracers = true,
    ShowBox = true,
    ShowHealth = true,
    ShowNames = true,
    ShowDistance = true,
    MaxDistance = 1500,
    TeamCheck = false,
    TextSize = 14
}

-- Create the main Rayfield Window
local Window = Rayfield:CreateWindow({
    Name = "🦎 Kewl GUI | ESP Suite",
    LoadingTitle = "Kewl GUI is Loading...",
    LoadingSubtitle = "Powered by Rayfield Interface Suite",
    Theme = "Default", -- You can change to: "Dark", "Light", "Dracula", "Aqua"
    ToggleUIKeybind = "K", -- Press 'K' to open/close the GUI
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "KewlGUI",
        FileName = "Settings"
    }
})

-- Create the main 'ESP' tab
local MainTab = Window:CreateTab("ESP", "eye") -- Using Lucide icon "eye"

-- Master ESP Toggle Section
local MainSection = MainTab:CreateSection("Master Controls")

local MasterToggle = MainTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = Settings.Enabled,
    Flag = "ESP_Enabled",
    Callback = function(Value)
        Settings.Enabled = Value
        ToggleESP(Value)
    end,
})

local FOVToggle = MainTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = Settings.ShowFOV,
    Flag = "FOV_Enabled",
    Callback = function(Value)
        Settings.ShowFOV = Value
        FOVCircle.Visible = Value
    end,
})

-- Divider
MainTab:CreateDivider()

-- ESP Features Section
local FeaturesSection = MainTab:CreateSection("ESP Features")

local BoxToggle = MainTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = Settings.ShowBox,
    Flag = "Box_ESP",
    Callback = function(Value)
        Settings.ShowBox = Value
    end,
})

local TracerToggle = MainTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = Settings.ShowTracers,
    Flag = "Tracers",
    Callback = function(Value)
        Settings.ShowTracers = Value
    end,
})

local HealthToggle = MainTab:CreateToggle({
    Name = "Health Bars",
    CurrentValue = Settings.ShowHealth,
    Flag = "Health_Bars",
    Callback = function(Value)
        Settings.ShowHealth = Value
    end,
})

local NameToggle = MainTab:CreateToggle({
    Name = "Player Names",
    CurrentValue = Settings.ShowNames,
    Flag = "Player_Names",
    Callback = function(Value)
        Settings.ShowNames = Value
    end,
})

local DistanceToggle = MainTab:CreateToggle({
    Name = "Distance",
    CurrentValue = Settings.ShowDistance,
    Flag = "Distance",
    Callback = function(Value)
        Settings.ShowDistance = Value
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", "settings") -- Lucide icon "settings"

-- Visual Settings Section
local VisualSection = SettingsTab:CreateSection("Visual Settings")

local FOVSlider = SettingsTab:CreateSlider({
    Name = "FOV Circle Size",
    Range = {50, 250},
    Increment = 5,
    Suffix = "px",
    CurrentValue = Settings.FOVSize,
    Flag = "FOV_Size",
    Callback = function(Value)
        Settings.FOVSize = Value
        FOVCircle.Radius = Value
    end,
})

local DistanceSlider = SettingsTab:CreateSlider({
    Name = "Max Render Distance",
    Range = {500, 5000},
    Increment = 100,
    Suffix = "studs",
    CurrentValue = Settings.MaxDistance,
    Flag = "Max_Distance",
    Callback = function(Value)
        Settings.MaxDistance = Value
    end,
})

local TextSizeSlider = SettingsTab:CreateSlider({
    Name = "Text Size",
    Range = {10, 20},
    Increment = 1,
    Suffix = "px",
    CurrentValue = Settings.TextSize,
    Flag = "Text_Size",
    Callback = function(Value)
        Settings.TextSize = Value
    end,
})

-- Divider
SettingsTab:CreateDivider()

-- Color Settings Section
local ColorSection = SettingsTab:CreateSection("Color Settings")

local FOVColorPicker = SettingsTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Color = Settings.FOVColor,
    Flag = "FOV_Color",
    Callback = function(Value)
        Settings.FOVColor = Value
        FOVCircle.Color = Value
    end
})

-- Team Settings
local TeamSection = SettingsTab:CreateSection("Team Settings")

local TeamCheckToggle = SettingsTab:CreateToggle({
    Name = "Ignore Teammates",
    CurrentValue = Settings.TeamCheck,
    Flag = "Team_Check",
    Callback = function(Value)
        Settings.TeamCheck = Value
    end,
})

-- Mobile Tab (if on mobile)
local IsMobile = UserInputService.TouchEnabled
if IsMobile then
    local MobileTab = Window:CreateTab("Mobile", "smartphone")
    
    local MobileSection = MobileTab:CreateSection("Mobile Controls")
    
    MobileTab:CreateLabel({
        Text = "Mobile Gesture Controls:",
        TextXAlignment = "Left"
    })
    
    MobileTab:CreateLabel({
        Text = "• Double Tap: Toggle ESP",
        TextXAlignment = "Left"
    })
    
    MobileTab:CreateLabel({
        Text = "• Triple Tap: Toggle GUI",
        TextXAlignment = "Left"
    })
    
    MobileTab:CreateDivider()
    
    MobileTab:CreateButton({
        Name = "Toggle ESP Now",
        Callback = function()
            Settings.Enabled = not Settings.Enabled
            MasterToggle:Set(Settings.Enabled)
            ToggleESP(Settings.Enabled)
        end,
    })
    
    MobileTab:CreateButton({
        Name = "Hide/Show GUI",
        Callback = function()
            Rayfield:SetVisibility(not Rayfield:IsVisible())
        end,
    })
end

-- Info Tab
local InfoTab = Window:CreateTab("Info", "info") -- Lucide icon "info"

InfoTab:CreateSection("About Kewl GUI")

InfoTab:CreateLabel({
    Text = "Version: 2.0.0 (Rayfield Edition)",
    TextXAlignment = "Left"
})

InfoTab:CreateLabel({
    Text = "Features:",
    TextXAlignment = "Left"
})

InfoTab:CreateLabel({
    Text = "• Full ESP System with Boxes, Tracers",
    TextXAlignment = "Left"
})

InfoTab:CreateLabel({
    Text = "• Customizable FOV Circle",
    TextXAlignment = "Left"
})

InfoTab:CreateLabel({
    Text = "• Mobile & PC Support",
    TextXAlignment = "Left"
})

InfoTab:CreateLabel({
    Text = "• Team Check Filter",
    TextXAlignment = "Left"
})

InfoTab:CreateDivider()

InfoTab:CreateLabel({
    Text = "Controls:",
    TextXAlignment = "Left"
})

InfoTab:CreateLabel({
    Text = "PC: Press 'K' to toggle GUI",
    TextXAlignment = "Left"
})

InfoTab:CreateLabel({
    Text = "Mobile: Use gestures or Mobile tab",
    TextXAlignment = "Left"
})

InfoTab:CreateDivider()

InfoTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        DestroyAll()
    end,
})

-- Create FOV circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = Settings.ShowFOV
FOVCircle.Radius = Settings.FOVSize
FOVCircle.Color = Settings.FOVColor
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.NumSides = 64
FOVCircle.Transparency = 1
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- ESP Functions (same as before, but integrated)
function CreateEsp(player)
    if player == LocalPlayer then return end
    if EspObjects[player] then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        BoxFill = Drawing.new("Square")
    }
    
    -- Configuration code remains the same as your original
    esp.Box.Visible = false
    esp.Box.Thickness = 2
    esp.Box.Filled = false
    esp.Box.Color = Color3.fromRGB(0, 255, 255)
    
    esp.BoxFill.Visible = false
    esp.BoxFill.Thickness = 1
    esp.BoxFill.Filled = true
    esp.BoxFill.Color = Color3.new(0, 0, 0)
    esp.BoxFill.Transparency = 0.7
    
    esp.Tracer.Visible = false
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = Color3.fromRGB(255, 50, 150)
    
    esp.Name.Visible = false
    esp.Name.Size = Settings.TextSize
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Font = 2
    
    esp.Health.Visible = false
    esp.Health.Size = Settings.TextSize
    esp.Health.Center = true
    esp.Health.Outline = true
    esp.Health.Font = 2
    
    esp.Distance.Visible = false
    esp.Distance.Size = Settings.TextSize - 2
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Color = Color3.fromRGB(255, 255, 255)
    esp.Distance.Font = 2
    
    EspObjects[player] = esp
end

function RemoveEsp(player)
    if EspObjects[player] then
        for _, drawing in pairs(EspObjects[player]) do
            drawing:Remove()
        end
        EspObjects[player] = nil
    end
end

function UpdateEsp()
    if not Settings.Enabled then return end
    
    for player, esp in pairs(EspObjects) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local head = character and character:FindFirstChild("Head")
        
        if character and humanoid and humanoid.Health > 0 and head then
            local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
            local distance = (LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position - character:GetPivot().Position).Magnitude
            
            if headOnScreen and distance <= Settings.MaxDistance then
                if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                    for _, drawing in pairs(esp) do
                        drawing.Visible = false
                    end
                    continue
                end
                
                local scaleFactor = 1000 / distance
                local boxSize = Vector2.new(20 * scaleFactor, 30 * scaleFactor)
                local boxPos = Vector2.new(headPos.X - boxSize.X / 2, headPos.Y - boxSize.Y / 2)
                
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                local healthColor = Color3.fromRGB(
                    255 * (1 - healthPercent),
                    255 * healthPercent,
                    0
                )
                
                -- Box ESP
                esp.Box.Visible = Settings.ShowBox
                esp.BoxFill.Visible = Settings.ShowBox
                if Settings.ShowBox then
                    esp.Box.Size = boxSize
                    esp.Box.Position = boxPos
                    esp.BoxFill.Size = boxSize
                    esp.BoxFill.Position = boxPos
                end
                
                -- Tracer
                esp.Tracer.Visible = Settings.ShowTracers
                if Settings.ShowTracers then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Tracer.To = Vector2.new(headPos.X, headPos.Y + boxSize.Y / 2)
                    esp.Tracer.Color = healthColor
                end
                
                -- Name
                esp.Name.Visible = Settings.ShowNames
                if Settings.ShowNames then
                    esp.Name.Text = player.Name
                    esp.Name.Position = Vector2.new(headPos.X, boxPos.Y - 20)
                end
                
                -- Health
                esp.Health.Visible = Settings.ShowHealth
                if Settings.ShowHealth then
                    esp.Health.Text = math.floor(humanoid.Health) .. " HP"
                    esp.Health.Position = Vector2.new(headPos.X, boxPos.Y + boxSize.Y + 5)
                    esp.Health.Color = healthColor
                end
                
                -- Distance
                esp.Distance.Visible = Settings.ShowDistance
                if Settings.ShowDistance then
                    esp.Distance.Text = math.floor(distance) .. " studs"
                    esp.Distance.Position = Vector2.new(headPos.X, boxPos.Y + boxSize.Y + 25)
                end
            else
                for _, drawing in pairs(esp) do
                    drawing.Visible = false
                end
            end
        else
            for _, drawing in pairs(esp) do
                drawing.Visible = false
            end
        end
    end
end

function ToggleESP(enabled)
    Settings.Enabled = enabled
    
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreateEsp(player)
            end
        end
    else
        for _, esp in pairs(EspObjects) do
            for _, drawing in pairs(esp) do
                drawing.Visible = false
            end
        end
    end
end

function UpdateFOV()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Settings.FOVSize
    FOVCircle.Color = Settings.FOVColor
end

function DestroyAll()
    -- Destroy ESP drawings
    for player, esp in pairs(EspObjects) do
        RemoveEsp(player)
    end
    
    -- Destroy FOV circle
    if FOVCircle then
        FOVCircle:Remove()
    end
    
    -- Destroy Rayfield UI
    Rayfield:Destroy()
    
    print("🦎 Kewl GUI has been destroyed.")
end

-- Mobile gesture support
if IsMobile then
    local lastTapTime = 0
    local tapCount = 0
    local tapTimer = 0
    
    UserInputService.TouchTap:Connect(function(touchPos, processed)
        if not processed then
            local currentTime = tick()
            
            -- Double tap detection
            if currentTime - lastTapTime < 0.3 then
                Settings.Enabled = not Settings.Enabled
                MasterToggle:Set(Settings.Enabled)
                ToggleESP(Settings.Enabled)
            end
            lastTapTime = currentTime
            
            -- Triple tap detection
            if currentTime - tapTimer > 0.5 then
                tapCount = 0
            end
            
            tapCount = tapCount + 1
            tapTimer = currentTime
            
            if tapCount >= 3 then
                Rayfield:SetVisibility(not Rayfield:IsVisible())
                tapCount = 0
            end
        end
    end)
end

-- Main ESP loop
table.insert(Connections, RunService.RenderStepped:Connect(function()
    UpdateEsp()
    UpdateFOV()
end))

-- Player management
table.insert(Connections, Players.PlayerAdded:Connect(function(player)
    CreateEsp(player)
end))

table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
    RemoveEsp(player)
end))

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateEsp(player)
    end
end

-- Camera resize handler
table.insert(Connections, Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    UpdateFOV()
end))

-- Success message
print("🦎 Kewl GUI v2.0 (Rayfield Edition) Loaded!")
print("📌 Press 'K' to open/close the GUI")
print("📱 Mobile: Double tap to toggle ESP, triple tap for GUI")

-- Return the API
return {
    Version = "2.0.0",
    Settings = Settings,
    ToggleESP = function() 
        Settings.Enabled = not Settings.Enabled
        MasterToggle:Set(Settings.Enabled)
        ToggleESP(Settings.Enabled)
    end,
    ShowGUI = function() 
        Rayfield:SetVisibility(true) 
    end,
    HideGUI = function() 
        Rayfield:SetVisibility(false) 
    end,
    Destroy = DestroyAll
}
