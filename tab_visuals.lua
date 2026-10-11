-- ============================================================
-- tab_visuals.lua - Player ESP + world visuals  (loaded by main.lua - do not run directly)
-- ============================================================
local UT = ...
local Players = UT.Players
local RunService = UT.RunService
local UserInputService = UT.UserInputService
local Lighting = UT.Lighting
local TeleportService = UT.TeleportService
local HttpService = UT.HttpService
local TweenService = UT.TweenService
local PhysicsService = UT.PhysicsService
local player = UT.player
local camera = UT.camera
local gui = UT.gui
local tabFrames = UT.tabFrames
local notify = UT.notify
local makeToggle = UT.makeToggle
local resetAllToggles = UT.resetAllToggles
local lagYield = UT.lagYield
local llYieldStep = UT.llYieldStep
local llBtnStep = UT.llBtnStep
local llCap = UT.llCap

-- ============================================
-- VISUALS TAB
-- ============================================
local vFrame = tabFrames.Visuals

local vTitle = Instance.new("TextLabel")
vTitle.Size = UDim2.new(1, 0, 0, 18)
vTitle.Text = "Player ESP & Environment"
vTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
vTitle.BackgroundTransparency = 1
vTitle.Font = Enum.Font.GothamBold
vTitle.TextSize = 12
vTitle.TextXAlignment = Enum.TextXAlignment.Left
vTitle.Parent = vFrame

local espSettings = {
	Box = false,
	Name = false,
	Tracer = false,
	TeamCheck = false,
}

UT.drawings = {}

local function createPlayerEsp(plr)
	if not drawingSupported or UT.drawings[plr] then return end
	local box = Drawing.new("Square")
	box.Thickness = 1
	box.Filled = false
	box.Visible = false
	local tracer = Drawing.new("Line")
	tracer.Thickness = 1
	tracer.Visible = false
	local name = Drawing.new("Text")
	name.Size = 13
	name.Center = true
	name.Outline = true
	name.Visible = false
	UT.drawings[plr] = {Box = box, Tracer = tracer, Name = name}
end

local function removePlayerEsp(plr)
	local d = UT.drawings[plr]
	if d then
		for _, obj in pairs(d) do
			pcall(function() obj:Remove() end)
		end
		UT.drawings[plr] = nil
	end
end

local function updatePlayerEsp()
	if not drawingSupported then return end
	for plr, objs in pairs(UT.drawings) do
		if not plr.Parent then
			removePlayerEsp(plr)
			continue
		end
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not head or not hum or hum.Health <= 0 then
			objs.Box.Visible = false
			objs.Tracer.Visible = false
			objs.Name.Visible = false
			continue
		end
		if espSettings.TeamCheck and plr.Team == player.Team then
			objs.Box.Visible = false
			objs.Tracer.Visible = false
			objs.Name.Visible = false
			continue
		end
		local headPos, headVis = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
		local footPos, footVis = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
		if (headVis or footVis) and camera.ViewportSize.X > 0 then
			local height = math.abs(headPos.Y - footPos.Y)
			local width = height / 2.2
			local color = (plr.Team == player.Team) and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
			if espSettings.Box then
				objs.Box.Size = Vector2.new(width, height)
				objs.Box.Position = Vector2.new(headPos.X - width/2, headPos.Y)
				objs.Box.Color = color
				objs.Box.Visible = true
			else
				objs.Box.Visible = false
			end
			if espSettings.Tracer then
				objs.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				objs.Tracer.To = Vector2.new(headPos.X, headPos.Y + height/2)
				objs.Tracer.Color = color
				objs.Tracer.Visible = true
			else
				objs.Tracer.Visible = false
			end
			if espSettings.Name then
				objs.Name.Position = Vector2.new(headPos.X, headPos.Y - 15)
				objs.Name.Text = plr.Name .. " [" .. math.floor(hum.Health) .. "]"
				objs.Name.Color = color
				objs.Name.Visible = true
			else
				objs.Name.Visible = false
			end
		else
			objs.Box.Visible = false
			objs.Tracer.Visible = false
			objs.Name.Visible = false
		end
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= player then createPlayerEsp(plr) end
end
Players.PlayerAdded:Connect(function(plr)
	if plr ~= player then createPlayerEsp(plr) end
end)
Players.PlayerRemoving:Connect(function(plr)
	removePlayerEsp(plr)
end)

makeToggle(vFrame, "Box ESP", 20, function(enabled)
	if not drawingSupported then notify("Visuals", "Drawing API not supported"); return end
	espSettings.Box = enabled
end)

makeToggle(vFrame, "Name ESP", 50, function(enabled)
	if not drawingSupported then notify("Visuals", "Drawing API not supported"); return end
	espSettings.Name = enabled
end)

makeToggle(vFrame, "Tracer ESP", 80, function(enabled)
	if not drawingSupported then notify("Visuals", "Drawing API not supported"); return end
	espSettings.Tracer = enabled
end)

makeToggle(vFrame, "Team Check", 110, function(enabled)
	espSettings.TeamCheck = enabled
end)

local origBrightness = Lighting.Brightness
local origGlobalShadows = Lighting.GlobalShadows
local origClockTime = Lighting.ClockTime
makeToggle(vFrame, "Full Bright", 140, function(enabled)
	if enabled then
		Lighting.Brightness = 10
		Lighting.GlobalShadows = false
		Lighting.ClockTime = 14
	else
		Lighting.Brightness = origBrightness
		Lighting.GlobalShadows = origGlobalShadows
		Lighting.ClockTime = origClockTime
	end
end)

local origFogEnd = Lighting.FogEnd
local origFogStart = Lighting.FogStart
makeToggle(vFrame, "No Fog", 170, function(enabled)
	if enabled then
		Lighting.FogEnd = 100000
		Lighting.FogStart = 100000
	else
		Lighting.FogEnd = origFogEnd
		Lighting.FogStart = origFogStart
	end
end)

-- X-Ray (near-only + cached part list, refreshes every few seconds - low lag)
local xrayOriginals = {}
local xraySet = {}
UT.xrayConn = nil
UT.xrayToken = nil
makeToggle(vFrame, "X-Ray", 200, function(enabled)
	if enabled then
		local parts = {}
		local scanRange = UT.potatoMode and 100 or 150
		local function rebuild()
			parts = {}
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") then
					local isCharPart = char and obj:IsDescendantOf(char)
					if not isCharPart then
						for _, p in ipairs(Players:GetPlayers()) do
							if p.Character and obj:IsDescendantOf(p.Character) then
								isCharPart = true
								break
							end
						end
					end
					if not isCharPart and (obj.Position - hrp.Position).Magnitude < scanRange then
						table.insert(parts, obj)
					end
				end
			end
		end
		rebuild()
		local token = {}
		UT.xrayToken = token
		task.spawn(function()
			while UT.xrayToken == token do
				task.wait(UT.potatoMode and 5 or 3)
				if UT.xrayToken ~= token then break end
				rebuild()
			end
		end)
		UT.xrayConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			for _, part in ipairs(parts) do
				if part and part.Parent then
					local d = (part.Position - hrp.Position).Magnitude
					if d < scanRange then
						if not xrayOriginals[part] then
							xrayOriginals[part] = part.LocalTransparencyModifier
						end
						if part.LocalTransparencyModifier ~= 0.7 then
							part.LocalTransparencyModifier = 0.7
						end
						xraySet[part] = true
					elseif xraySet[part] then
						part.LocalTransparencyModifier = xrayOriginals[part] or 0
						xraySet[part] = nil
					end
				end
			end
		end)
	else
		if UT.xrayConn then UT.xrayConn:Disconnect(); UT.xrayConn = nil end
		UT.xrayToken = nil
		for part, val in pairs(xrayOriginals) do
			if part and part.Parent then
				part.LocalTransparencyModifier = val
			end
		end
		xrayOriginals = {}
		xraySet = {}
	end
end)

-- export for cleanup.lua render loop
UT.updatePlayerEsp = updatePlayerEsp
