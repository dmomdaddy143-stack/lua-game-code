-- ============================================================
-- tab_bring.lua - range-limited bring controls
-- ============================================================
local UT = ...
local Players = UT.Players
local RunService = UT.RunService
local UserInputService = UT.UserInputService
local Workspace = workspace
local player = UT.player
local frame = UT.tabFrames.Bring
local notify = UT.notify

local whitelist = {
	Food = true, Medkit = true, Bat = true, Crowbar = true, Bullets = true,
	Hammer = true, GPS = true, Shells = true, Shotgun = true, Lantern = true,
	Handgun = true, Money = true, Soda = true, Rocket = true,
	["Rocket Launcher"] = true, ["Pillar Hammer"] = true,
}

local rangeMin = 10
local rangeMax = 5000
local range = 100
local selectedPlayer
local active = false
local draggingSlider = false
local rangeScanPending = false
local trackedParts = {}
local trackedLookup = {}
local sourcePositions = {}
local originalCanCollide = {}
local connections = {}
local bringToggle

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 18)
status.BackgroundTransparency = 1
status.Text = "Select a player, choose items, then enable Bring"
status.TextColor3 = Color3.fromRGB(190, 190, 190)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local playerTitle = Instance.new("TextLabel")
playerTitle.Size = UDim2.new(0, 220, 0, 18)
playerTitle.Position = UDim2.new(0, 0, 0, 22)
playerTitle.BackgroundTransparency = 1
playerTitle.Text = "Target player"
playerTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
playerTitle.Font = Enum.Font.GothamBold
playerTitle.TextSize = 11
playerTitle.TextXAlignment = Enum.TextXAlignment.Left
playerTitle.Parent = frame

local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(0, 220, 0, 138)
playerList.Position = UDim2.new(0, 0, 0, 42)
playerList.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 4
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerList.Parent = frame
Instance.new("UICorner", playerList).CornerRadius = UDim.new(0, 4)

local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 2)
playerLayout.Parent = playerList

local whitelistTitle = Instance.new("TextLabel")
whitelistTitle.Size = UDim2.new(0, 460, 0, 18)
whitelistTitle.Position = UDim2.new(0, 235, 0, 22)
whitelistTitle.BackgroundTransparency = 1
whitelistTitle.Text = "Items"
whitelistTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
whitelistTitle.Font = Enum.Font.GothamBold
whitelistTitle.TextSize = 11
whitelistTitle.TextXAlignment = Enum.TextXAlignment.Left
whitelistTitle.Parent = frame

local itemList = Instance.new("ScrollingFrame")
itemList.Size = UDim2.new(1, -235, 0, 138)
itemList.Position = UDim2.new(0, 235, 0, 42)
itemList.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
itemList.BorderSizePixel = 0
itemList.ScrollBarThickness = 4
itemList.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
itemList.Parent = frame
Instance.new("UICorner", itemList).CornerRadius = UDim.new(0, 4)

local itemLayout = Instance.new("UIGridLayout")
itemLayout.CellSize = UDim2.new(0.5, -3, 0, 24)
itemLayout.CellPadding = UDim2.new(0, 4, 0, 3)
itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemLayout.Parent = itemList

local rangeLabel = Instance.new("TextLabel")
rangeLabel.Size = UDim2.new(1, 0, 0, 18)
rangeLabel.Position = UDim2.new(0, 0, 0, 190)
rangeLabel.BackgroundTransparency = 1
rangeLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
rangeLabel.Font = Enum.Font.GothamBold
rangeLabel.TextSize = 11
rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
rangeLabel.Parent = frame

local slider = Instance.new("TextButton")
slider.Size = UDim2.new(1, -4, 0, 14)
slider.Position = UDim2.new(0, 2, 0, 214)
slider.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
slider.BorderSizePixel = 0
slider.Text = ""
slider.AutoButtonColor = false
slider.Parent = frame
Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 7)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(70, 190, 120)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = slider
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 7)

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = slider
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

local function updateSlider(value)
	local previousRange = range
	range = math.clamp(math.floor(value / 25 + 0.5) * 25, rangeMin, rangeMax)
	if active and range ~= previousRange then rangeScanPending = true end
	local alpha = (range - rangeMin) / (rangeMax - rangeMin)
	sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	sliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	rangeLabel.Text = "Maximum range: " .. tostring(range) .. " studs"
end

local function updateSliderFromX(x)
	local width = math.max(1, slider.AbsoluteSize.X)
	local alpha = math.clamp((x - slider.AbsolutePosition.X) / width, 0, 1)
	updateSlider(rangeMin + alpha * (rangeMax - rangeMin))
end

slider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
		updateSliderFromX(input.Position.X)
	end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateSliderFromX(input.Position.X)
	end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = false
	end
end))
updateSlider(range)

local attachmentPart = Instance.new("Part")
attachmentPart.Name = "BringAttachmentPart"
attachmentPart.Anchored = true
attachmentPart.Transparency = 1
attachmentPart.CanCollide = false
attachmentPart.Size = Vector3.new(1, 1, 1)
attachmentPart.Parent = Workspace
local targetAttachment = Instance.new("Attachment")
targetAttachment.Parent = attachmentPart

local function getTargetPart()
	local character = selectedPlayer and selectedPlayer.Character
	return character and (character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso"))
end

local function isWhitelisted(part)
	return part and part:IsA("BasePart") and whitelist[part.Name] == true
end

local function cleanupPart(part)
	if not part then return end
	for _, name in ipairs({"BringAlignPosition", "BringAlignOrientation", "BringAttachment"}) do
		local child = part:FindFirstChild(name)
		if child then child:Destroy() end
	end
	if originalCanCollide[part] ~= nil then
		pcall(function() part.CanCollide = originalCanCollide[part] end)
		originalCanCollide[part] = nil
	end
	pcall(function()
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function untrackPart(index)
	local part = trackedParts[index]
	if part then
		trackedLookup[part] = nil
		sourcePositions[part] = nil
		cleanupPart(part)
	end
	table.remove(trackedParts, index)
end

local function isInRange(part, targetPart, sourcePosition)
	local position = sourcePosition or part.Position
	return targetPart and (position - targetPart.Position).Magnitude <= range
end

local function trackPart(part, targetPart)
	if not active or not isWhitelisted(part) or part.Anchored or trackedLookup[part] then return end
	if not isInRange(part, targetPart) then return end
	local sourcePosition = part.Position
	local ok = pcall(function()
		local attachment = Instance.new("Attachment")
		attachment.Name = "BringAttachment"
		attachment.Parent = part

		local alignPosition = Instance.new("AlignPosition")
		alignPosition.Name = "BringAlignPosition"
		alignPosition.Attachment0 = attachment
		alignPosition.Attachment1 = targetAttachment
		alignPosition.MaxForce = 100000
		alignPosition.Responsiveness = 200
		alignPosition.ReactionForceEnabled = false
		alignPosition.Parent = part

		local alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Name = "BringAlignOrientation"
		alignOrientation.Attachment0 = attachment
		alignOrientation.Attachment1 = targetAttachment
		alignOrientation.MaxTorque = 100000
		alignOrientation.Responsiveness = 200
		alignOrientation.ReactionTorqueEnabled = false
		alignOrientation.Parent = part

		originalCanCollide[part] = part.CanCollide
		part.CanCollide = false
	end)
	if ok then
		trackedLookup[part] = true
		sourcePositions[part] = sourcePosition
		table.insert(trackedParts, part)
	end
end

local function stopBring()
	active = false
	for _, connectionName in ipairs({"heartbeat", "descendantAdded"}) do
		local connection = connections[connectionName]
		if connection then
			connection:Disconnect()
			connections[connectionName] = nil
		end
	end
	for index = #trackedParts, 1, -1 do
		untrackPart(index)
	end
	if attachmentPart and attachmentPart.Parent then
		attachmentPart.CFrame = CFrame.new(0, -1000, 0)
	end
	status.Text = selectedPlayer and ("Stopped | Target: " .. selectedPlayer.Name) or "Select a target player"
end

local function startBring()
	local targetPart = getTargetPart()
	if not targetPart then
		status.Text = "Target has no character part available"
		if bringToggle then UT.setButtonToggle(bringToggle, false) end
		return
	end
	active = true
	status.Text = "Bringing whitelisted items within " .. tostring(range) .. " studs"
	attachmentPart.CFrame = targetPart.CFrame

	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(player, "SimulationRadius", 10000)
			sethiddenproperty(player, "MaximumSimulationRadius", 10000)
		end
	end)

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		trackPart(descendant, targetPart)
	end
	connections.descendantAdded = Workspace.DescendantAdded:Connect(function(descendant)
		trackPart(descendant, getTargetPart())
	end)
	connections.heartbeat = RunService.Heartbeat:Connect(function()
		local currentTarget = getTargetPart()
		if not currentTarget then
			stopBring()
			if bringToggle then UT.setButtonToggle(bringToggle, false) end
			return
		end
		attachmentPart.CFrame = currentTarget.CFrame
		for index = #trackedParts, 1, -1 do
			local part = trackedParts[index]
			if not part.Parent or not isWhitelisted(part) or not isInRange(part, currentTarget, sourcePositions[part]) then
				untrackPart(index)
			end
		end
		if rangeScanPending and not draggingSlider then
			rangeScanPending = false
			for _, descendant in ipairs(Workspace:GetDescendants()) do
				trackPart(descendant, currentTarget)
			end
		end
	end)
end

local function setSelectedPlayer(target)
	local wasActive = active
	if wasActive then stopBring() end
	selectedPlayer = target
	if wasActive then startBring() end
	if not wasActive then
		status.Text = target and ("Target: " .. target.Name) or "Select a target player"
	end
end

local function refreshPlayers()
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, target in ipairs(Players:GetPlayers()) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -6, 0, 24)
		button.BackgroundColor3 = target == selectedPlayer and Color3.fromRGB(45, 100, 70) or Color3.fromRGB(38, 38, 44)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.Gotham
		button.TextSize = 10
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Text = "  " .. target.Name .. (target == player and " (You)" or "")
		button.Parent = playerList
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 3)
		button.MouseButton1Click:Connect(function()
			setSelectedPlayer(target)
			refreshPlayers()
		end)
	end
end

local itemOrder = {
	"Food", "Medkit", "Bat", "Crowbar", "Bullets", "Hammer", "GPS", "Shells",
	"Shotgun", "Lantern", "Handgun", "Money", "Soda", "Rocket", "Rocket Launcher", "Pillar Hammer",
}

for _, itemName in ipairs(itemOrder) do
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = whitelist[itemName] and Color3.fromRGB(0, 135, 85) or Color3.fromRGB(55, 55, 62)
	button.Text = itemName
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.Gotham
	button.TextSize = 10
	button.Parent = itemList
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 3)
	button.MouseButton1Click:Connect(function()
		whitelist[itemName] = not whitelist[itemName]
		button.BackgroundColor3 = whitelist[itemName] and Color3.fromRGB(0, 135, 85) or Color3.fromRGB(55, 55, 62)
		if active and whitelist[itemName] then
			local targetPart = getTargetPart()
			if targetPart then
				for _, descendant in ipairs(Workspace:GetDescendants()) do
					if descendant.Name == itemName then trackPart(descendant, targetPart) end
				end
			end
		end
	end)
end

bringToggle = UT.makeToggle(frame, "Bring Items", 238, function(enabled)
	if enabled then
		startBring()
	else
		stopBring()
	end
end, UDim2.new(0, 180, 0, 28), UDim2.new(0, 0, 0, 238))

table.insert(connections, Players.PlayerAdded:Connect(refreshPlayers))
table.insert(connections, Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == selectedPlayer then
		stopBring()
		selectedPlayer = nil
		if bringToggle then UT.setButtonToggle(bringToggle, false) end
		status.Text = "Target left the game"
	end
	refreshPlayers()
end))
refreshPlayers()

UT.cleanupBring = function()
	stopBring()
	for _, connection in ipairs(connections) do
		if typeof(connection) == "RBXScriptConnection" then connection:Disconnect() end
	end
	connections = {}
	if attachmentPart and attachmentPart.Parent then attachmentPart:Destroy() end
end