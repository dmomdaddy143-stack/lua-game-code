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
	NameDistance = false,
	HighlightPlayers = false,
	HighlightNPCs = false,
	HighlightInteractables = false,
	MaxRange = 250,
}

UT.drawings = {}
local playerHighlightMap = {}
local npcHighlightMap = {}
local interactableHighlightMap = {}

local function ensureModelHighlight(model, color, keyMap)
	if not model or not model.Parent then return end
	if keyMap[model] then return end
	local highlight = Instance.new("Highlight")
	highlight.Name = "ToolkitVisualHighlight"
	highlight.Adornee = model
	highlight.FillColor = color
	highlight.FillTransparency = 0.6
	highlight.OutlineColor = color
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = model
	keyMap[model] = highlight
end

local function clearHighlightMap(map)
	for model, highlight in pairs(map) do
		if highlight and highlight.Parent then highlight:Destroy() end
		map[model] = nil
	end
end

local function updateNameLabel(plr, hum, headPos)
	if not espSettings.Name then return nil end
	local text = plr.Name
	if espSettings.NameDistance and headPos then
		local dist = math.floor((headPos.Position - camera.CFrame.Position).Magnitude)
		text = text .. " [" .. dist .. "m]"
	end
	if hum and hum.Health > 0 then
		text = text .. " [" .. math.floor(hum.Health) .. "]"
	end
	return text
end

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
	local maxRange = espSettings.MaxRange or (UT.laggyPotatoMode and 80 or UT.potatoMode and 120 or 250)
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
		local distToCam = (head.Position - camera.CFrame.Position).Magnitude
		if distToCam > maxRange then
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
				local text = plr.Name
				if espSettings.NameDistance then
					local dist = math.floor((head.Position - camera.CFrame.Position).Magnitude)
					text = text .. " [" .. dist .. "m]"
				end
				text = text .. " [" .. math.floor(hum.Health) .. "]"
				objs.Name.Text = text
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
	if espSettings.HighlightPlayers and plr.Character then
		ensureModelHighlight(plr.Character, Color3.fromRGB(120, 200, 255), playerHighlightMap)
	end
end)
Players.PlayerRemoving:Connect(function(plr)
	removePlayerEsp(plr)
	if playerHighlightMap[plr.Character] then
		playerHighlightMap[plr.Character]:Destroy()
		playerHighlightMap[plr.Character] = nil
	end
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

makeToggle(vFrame, "Names + Dist", 140, function(enabled)
	espSettings.NameDistance = enabled
end)

makeToggle(vFrame, "Highlight Players", 170, function(enabled)
	espSettings.HighlightPlayers = enabled
	if enabled then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character then
				ensureModelHighlight(plr.Character, Color3.fromRGB(120, 200, 255), playerHighlightMap)
			end
		end
	else
		clearHighlightMap(playerHighlightMap)
	end
end)

makeToggle(vFrame, "Highlight NPCs", 200, function(enabled)
	espSettings.HighlightNPCs = enabled
	if not enabled then
		clearHighlightMap(npcHighlightMap)
		return
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= player.Character and not Players:GetPlayerFromCharacter(obj) then
			local nameLower = obj.Name:lower()
			if nameLower:find("npc") or nameLower:find("enemy") or nameLower:find("mob") or nameLower:find("bot") then
				ensureModelHighlight(obj, Color3.fromRGB(255, 140, 80), npcHighlightMap)
			end
		end
	end
end)

makeToggle(vFrame, "Highlight Interactables", 230, function(enabled)
	espSettings.HighlightInteractables = enabled
	if not enabled then
		clearHighlightMap(interactableHighlightMap)
		return
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		local isPrompt = obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") or obj:IsA("Seat") or obj:IsA("DragDetector")
		if isPrompt then
			local target = obj.Parent or obj
			if target and target:IsA("BasePart") then
				ensureModelHighlight(target, Color3.fromRGB(80, 255, 160), interactableHighlightMap)
			elseif target and target:IsA("Model") then
				ensureModelHighlight(target, Color3.fromRGB(80, 255, 160), interactableHighlightMap)
			end
		end
	end
end)

local origBrightness = Lighting.Brightness
local origGlobalShadows = Lighting.GlobalShadows
local origClockTime = Lighting.ClockTime
makeToggle(vFrame, "Full Bright", 260, function(enabled)
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
makeToggle(vFrame, "No Fog", 290, function(enabled)
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
		local scanRange = UT.laggyPotatoMode and 40 or (UT.potatoMode and 100 or 150)
		local function rebuild()
			parts = {}
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local function inspect(obj)
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
					local maxParts = UT.safeMode and 200 or math.huge
					if not isCharPart and #parts < maxParts and (obj.Position - hrp.Position).Magnitude < scanRange then
						table.insert(parts, obj)
					end
				end
			end
			if UT.safeMode then
				pcall(function() UT.forEachDescendant(workspace, inspect) end)
			else
				for _, obj in ipairs(workspace:GetDescendants()) do
					inspect(obj)
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

local espRangeBox = Instance.new("TextBox")
espRangeBox.Size = UDim2.new(0, 150, 0, 22)
espRangeBox.Position = UDim2.new(0, 0, 0, 330)
espRangeBox.PlaceholderText = "ESP range"
espRangeBox.Text = tostring(espSettings.MaxRange)
espRangeBox.TextColor3 = Color3.new(1, 1, 1)
espRangeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
espRangeBox.Font = Enum.Font.Gotham
espRangeBox.TextSize = 10
espRangeBox.Parent = vFrame
Instance.new("UICorner", espRangeBox).CornerRadius = UDim.new(0, 4)
if type(UT.addTooltip) == "function" then
	UT.addTooltip(espRangeBox, "Type the max ESP distance in studs. Higher values show more enemies and players.")
end
espRangeBox.FocusLost:Connect(function()
	local v = tonumber(espRangeBox.Text)
	if v and v > 0 then
		espSettings.MaxRange = math.clamp(v, 25, 2000)
		espRangeBox.Text = tostring(espSettings.MaxRange)
	end
end)

local targetPlayerBox = Instance.new("TextBox")
targetPlayerBox.Size = UDim2.new(0, 220, 0, 22)
targetPlayerBox.Position = UDim2.new(0, 0, 0, 360)
targetPlayerBox.PlaceholderText = "Player name for target ESP"
targetPlayerBox.Text = ""
targetPlayerBox.TextColor3 = Color3.new(1, 1, 1)
targetPlayerBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
targetPlayerBox.Font = Enum.Font.Gotham
targetPlayerBox.TextSize = 10
targetPlayerBox.Parent = vFrame
Instance.new("UICorner", targetPlayerBox).CornerRadius = UDim.new(0, 4)
if type(UT.addTooltip) == "function" then
	UT.addTooltip(targetPlayerBox, "Type the exact player name or display name for target ESP.")
end

local targetPlayerEspButton = Instance.new("TextButton")
targetPlayerEspButton.Size = UDim2.new(0, 130, 0, 22)
targetPlayerEspButton.Position = UDim2.new(0, 230, 0, 360)
targetPlayerEspButton.Text = "Target ESP: OFF"
targetPlayerEspButton.TextColor3 = Color3.new(1, 1, 1)
targetPlayerEspButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
targetPlayerEspButton.Font = Enum.Font.GothamBold
targetPlayerEspButton.TextSize = 10
targetPlayerEspButton.Parent = vFrame
Instance.new("UICorner", targetPlayerEspButton).CornerRadius = UDim.new(0, 4)

local targetPlayerEsp
local targetCharacterConnection
local targetHighlight
local targetBillboard

local function clearTargetPlayerEsp()
	if targetCharacterConnection then
		targetCharacterConnection:Disconnect()
		targetCharacterConnection = nil
	end
	if targetHighlight then targetHighlight:Destroy(); targetHighlight = nil end
	if targetBillboard then targetBillboard:Destroy(); targetBillboard = nil end
	targetPlayerEsp = nil
	targetPlayerEspButton.Text = "Target ESP: OFF"
	targetPlayerEspButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
end

local function attachTargetPlayerEsp(target, character)
	if not target or not character then return end
	if targetHighlight then targetHighlight:Destroy() end
	if targetBillboard then targetBillboard:Destroy() end
	local adornee = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not adornee then return end
	targetHighlight = Instance.new("Highlight")
	targetHighlight.Name = "ToolkitTargetHighlight"
	targetHighlight.Adornee = character
	targetHighlight.FillColor = Color3.fromRGB(255, 190, 50)
	targetHighlight.FillTransparency = 0.75
	targetHighlight.OutlineColor = Color3.fromRGB(255, 220, 100)
	targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	targetHighlight.Parent = character

	targetBillboard = Instance.new("BillboardGui")
	targetBillboard.Name = "ToolkitTargetLabel"
	targetBillboard.Adornee = adornee
	targetBillboard.Size = UDim2.new(0, 150, 0, 28)
	targetBillboard.StudsOffset = Vector3.new(0, 2.5, 0)
	targetBillboard.AlwaysOnTop = true
	targetBillboard.Parent = gui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = target.Name
	label.TextColor3 = Color3.fromRGB(255, 220, 100)
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.Parent = targetBillboard
end

targetPlayerEspButton.MouseButton1Click:Connect(function()
	if targetPlayerEsp then
		clearTargetPlayerEsp()
		return
	end
	local searchName = targetPlayerBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if searchName == "" then
		notify("Target ESP", "Enter a player name first")
		return
	end
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= player and (target.Name:lower() == searchName or target.DisplayName:lower() == searchName) then
			targetPlayerEsp = target
			targetPlayerEspButton.Text = "Target ESP: ON"
			targetPlayerEspButton.BackgroundColor3 = Color3.fromRGB(0, 125, 78)
			attachTargetPlayerEsp(target, target.Character)
			targetCharacterConnection = target.CharacterAdded:Connect(function(character)
				task.wait(0.25)
				if targetPlayerEsp == target then attachTargetPlayerEsp(target, character) end
			end)
			return
		end
	end
	notify("Target ESP", "Player not found; use the exact username or display name")
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == targetPlayerEsp then clearTargetPlayerEsp() end
end)

UT.cleanupTargetPlayerEsp = clearTargetPlayerEsp

-- export for cleanup.lua render loop
UT.updatePlayerEsp = updatePlayerEsp
