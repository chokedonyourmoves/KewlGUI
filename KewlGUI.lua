diff --git a/KewlGUI.lua b/KewlGUI.lua
index ecc70590b5f180a8e19726662cedd844d27b8857..25330c987c2f3a58d768a2346c8944f3e99d0f05 100644
--- a/KewlGUI.lua
+++ b/KewlGUI.lua
@@ -1,31 +1,30 @@
 local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
 
 -- Services
 local Players = game:GetService("Players")
 local RunService = game:GetService("RunService")
-local UserInputService = game:GetService("UserInputService")
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
@@ -100,75 +99,87 @@ end
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
-        local root = char.PrimaryPart
+        local root = char and char.PrimaryPart
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
-                                if not Settings.VisibleCheck or onScreen then
+                                local isVisible = true
+                                if Settings.VisibleCheck then
+                                    local origin = Camera.CFrame.Position
+                                    local rayDir = headPos3d - origin
+                                    local params = RaycastParams.new()
+                                    params.FilterType = Enum.RaycastFilterType.Blacklist
+                                    params.FilterDescendantsInstances = {LocalPlayer.Character, char}
+
+                                    local result = workspace:Raycast(origin, rayDir, params)
+                                    isVisible = (result == nil)
+                                end
+
+                                if isVisible then
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
@@ -216,98 +227,135 @@ local function UpdateAll()
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
 
-    local part = char:FindFirstChild(Settings.TargetPart)
+    local targetPartName = Settings.TargetPart
+    if targetPartName == "Random" then
+        local candidates = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
+        local available = {}
+        for _, candidate in ipairs(candidates) do
+            local found = char:FindFirstChild(candidate)
+            if found then
+                table.insert(available, found)
+            end
+        end
+
+        if #available == 0 then return nil end
+        local part = available[math.random(1, #available)]
+
+        local targetPos = part.Position
+        if Settings.Predict then
+            local root = char.PrimaryPart
+            if root then
+                local vel = root.AssemblyLinearVelocity
+                local pingMs = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
+                local pingSeconds = pingMs / 1000
+                targetPos = targetPos + vel * (pingSeconds * Settings.PredictionAmount)
+            end
+        end
+
+        local randOffset = Vector3.new(
+            math.random(-1,1) * Settings.HitboxSize,
+            math.random(-1,1) * Settings.HitboxSize * 0.5,
+            math.random(-1,1) * Settings.HitboxSize
+        )
+        return targetPos + randOffset
+    end
+
+    local part = char:FindFirstChild(targetPartName)
     if not part then return nil end
 
     local targetPos = part.Position
     if Settings.Predict then
         local root = char.PrimaryPart
         if root then
             local vel = root.AssemblyLinearVelocity
-            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
-            targetPos = targetPos + vel * (ping * Settings.PredictionAmount)
+            local pingMs = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
+            local pingSeconds = pingMs / 1000
+            targetPos = targetPos + vel * (pingSeconds * Settings.PredictionAmount)
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
-local RaycastHook
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
+    setreadonly(mt, false)
+    mt.__namecall = oldRaycast
+    setreadonly(mt, true)
+
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
