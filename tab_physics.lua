-- ============================================================
-- tab_physics.lua - local latency monitoring and workload control
-- ============================================================
local UT = ...
local player = UT.player
local runService = UT.RunService
local statsService = game:GetService("Stats")
local frame = UT.tabFrames.Physics

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 20)
title.Position = UDim2.new(0, 6, 0, 2)
title.BackgroundTransparency = 1
title.Text = "Physics Latency Monitor"
title.TextColor3 = Color3.fromRGB(230, 230, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local description = Instance.new("TextLabel")
description.Size = UDim2.new(1, -12, 0, 30)
description.Position = UDim2.new(0, 6, 0, 23)
description.BackgroundTransparency = 1
description.Text = "Monitors local frame rate, ping, respawns, and teleports. Adaptive mode throttles toolkit scans under load."
description.TextColor3 = Color3.fromRGB(165, 165, 172)
description.Font = Enum.Font.Gotham
description.TextSize = 10
description.TextWrapped = true
description.TextXAlignment = Enum.TextXAlignment.Left
description.Parent = frame

local metrics = Instance.new("TextLabel")
metrics.Size = UDim2.new(1, -12, 0, 92)
metrics.Position = UDim2.new(0, 6, 0, 58)
metrics.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
metrics.BorderSizePixel = 0
metrics.TextColor3 = Color3.fromRGB(220, 220, 226)
metrics.Font = Enum.Font.Code
metrics.TextSize = 11
metrics.TextXAlignment = Enum.TextXAlignment.Left
metrics.TextYAlignment = Enum.TextYAlignment.Top
metrics.TextWrapped = true
metrics.Text = "FPS: measuring...\nPing: unavailable\nCharacter: waiting\nTeleport: idle"
metrics.Parent = frame
Instance.new("UICorner", metrics).CornerRadius = UDim.new(0, 4)

local reasonLabel = Instance.new("TextLabel")
reasonLabel.Size = UDim2.new(1, -12, 0, 42)
reasonLabel.Position = UDim2.new(0, 6, 0, 184)
reasonLabel.BackgroundTransparency = 1
reasonLabel.Text = "Network ownership is controlled by the Roblox server; this tab does not change ownership."
reasonLabel.TextColor3 = Color3.fromRGB(175, 175, 182)
reasonLabel.Font = Enum.Font.Gotham
reasonLabel.TextSize = 10
reasonLabel.TextWrapped = true
reasonLabel.TextXAlignment = Enum.TextXAlignment.Left
reasonLabel.TextYAlignment = Enum.TextYAlignment.Top
reasonLabel.Parent = frame

local teleportStatus = "Idle"
local characterStatus = "Waiting"
local adaptiveEnabled = false
local frameCount = 0
local elapsed = 0
local fps = 0
local pingMs

local function readPing()
	local ok, value = pcall(function()
		local item = statsService.Network.ServerStatsItem["Data Ping"]
		return item:GetValue()
	end)
	if ok and type(value) == "number" then return value end
	return nil
end

local function updateCharacterStatus(character, message)
	if message then
		characterStatus = message
		return
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character then
		characterStatus = "Not spawned"
	elseif not root then
		characterStatus = "Loading character"
	elseif humanoid then
		characterStatus = "Ready (" .. humanoid:GetState().Name .. ")"
	else
		characterStatus = "Ready"
	end
end

UT.physicsCharacterAddedConn = player.CharacterAdded:Connect(function(character)
	updateCharacterStatus(character, "Respawn detected")
	task.defer(function()
		if player.Character == character then updateCharacterStatus(character) end
	end)
end)
UT.physicsCharacterRemovingConn = player.CharacterRemoving:Connect(function()
	updateCharacterStatus(nil, "Respawning")
end)
updateCharacterStatus(player.Character)

local teleportSignalOk, teleportConnection = pcall(function()
	return player.OnTeleport:Connect(function(state, placeId)
		teleportStatus = tostring(state):gsub("Enum%.TeleportState%.", "")
		if placeId then teleportStatus = teleportStatus .. " to " .. tostring(placeId) end
	end)
end)
if teleportSignalOk then UT.physicsTeleportConn = teleportConnection end

UT.physicsMonitorConn = runService.Heartbeat:Connect(function(deltaTime)
	frameCount = frameCount + 1
	elapsed = elapsed + deltaTime
	if elapsed < 1 then return end
	fps = math.floor(frameCount / elapsed + 0.5)
	frameCount = 0
	elapsed = 0
	pingMs = readPing()
	updateCharacterStatus(player.Character)
	metrics.Text = string.format("FPS: %d\nPing: %s\nCharacter: %s\nTeleport: %s",
		fps,
		pingMs and (tostring(math.floor(pingMs + 0.5)) .. " ms") or "unavailable",
		characterStatus,
		teleportStatus)

	if adaptiveEnabled then
		local overloaded = fps < 40 or (pingMs and pingMs > 180)
		local recovered = fps >= 50 and (not pingMs or pingMs <= 140)
		if overloaded then
			UT.physicsThrottleActive = true
		elseif recovered then
			UT.physicsThrottleActive = false
		end
	end
	if UT.physicsThrottleActive then
		reasonLabel.Text = "Adaptive workload: throttling scans due to low FPS or high ping. Server ownership is unchanged."
	else
		reasonLabel.Text = "Network ownership is controlled by the Roblox server; this tab does not change ownership."
	end
end)

UT.makeToggle(frame, "Adaptive Workload", 156, function(enabled)
	adaptiveEnabled = enabled
	if not enabled then UT.physicsThrottleActive = false end
end, UDim2.new(0, 220, 0, 24), UDim2.new(0, 6, 0, 156))