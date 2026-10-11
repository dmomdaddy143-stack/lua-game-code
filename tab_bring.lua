-- ============================================================
-- tab_bring.lua - range-limited bring controls
-- ============================================================
local UT = ...
local Players = UT.Players
local RunService = UT.RunService
local UserInputService = UT.UserInputService
local CollectionService = game:GetService("CollectionService")
local Workspace = workspace
local player = UT.player
local frame = UT.tabFrames.Bring
local notify = UT.notify

local whitelist = {}
local itemButtons = {}
local itemCatalog = {}
local itemCounts = {}

local function hasItemMarker(instance)
	if instance:IsA("Tool") or instance:GetAttribute("IsItem") == true or instance:GetAttribute("IsPickup") == true then
		return true
	end
	return CollectionService:HasTag(instance, "Item")
		or CollectionService:HasTag(instance, "Pickup")
		or CollectionService:HasTag(instance, "Collectible")
end

local function isItemContainerName(name)
	name = name:lower()
	for _, marker in ipairs({"item", "pickup", "collectible", "loot", "drop", "resource"}) do
		if string.find(name, marker, 1, true) then return true end
	end
	return false
end

local function findItemRoot(instance)
	local cursor = instance
	local interactiveRoot
	while cursor and cursor ~= Workspace do
		if hasItemMarker(cursor) then return cursor end
		local parentName = cursor.Parent and cursor.Parent.Name
		if parentName and isItemContainerName(parentName) then
			if cursor:IsA("Model") or cursor:IsA("BasePart") or cursor:IsA("Tool") then
				return cursor
			end
		end
		local hasPrompt = cursor:FindFirstChildWhichIsA("ProximityPrompt", true)
		local hasClickDetector = cursor:FindFirstChildWhichIsA("ClickDetector", true)
		if (cursor:IsA("Model") or cursor:IsA("BasePart")) and (hasPrompt or hasClickDetector) then
			if not interactiveRoot then interactiveRoot = cursor end
		end
		cursor = cursor.Parent
	end
	if interactiveRoot then return interactiveRoot end
	return nil
end

local function getItemPart(root)
	if root:IsA("BasePart") then return root end
	if root:IsA("Model") and root.PrimaryPart then return root.PrimaryPart end
	local handle = root:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then return handle end
	return root:FindFirstChildWhichIsA("BasePart", true)
end

local function getItemInfo(instance)
	local root = findItemRoot(instance)
	if root then return root.Name, root end
	return nil
end

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
local originalAnchored = {}
local connections = {}
local bringToggle

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -108, 0, 18)
status.BackgroundTransparency = 1
status.Text = "Select a player and scan items to begin"
status.TextColor3 = Color3.fromRGB(190, 190, 190)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, 102, 0, 18)
scanButton.Position = UDim2.new(1, -102, 0, 0)
scanButton.Text = "Scan items"
scanButton.TextColor3 = Color3.new(1, 1, 1)
scanButton.BackgroundColor3 = Color3.fromRGB(35, 95, 65)
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 10
scanButton.Parent = frame
Instance.new("UICorner", scanButton).CornerRadius = UDim.new(0, 3)

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
whitelistTitle.Text = "Items detected: 0"
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

local function addItemOption(itemName)
	if whitelist[itemName] == nil then whitelist[itemName] = true end
	if itemButtons[itemName] then return end
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = whitelist[itemName] and Color3.fromRGB(0, 135, 85) or Color3.fromRGB(55, 55, 62)
	button.Text = itemName
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.Gotham
	button.TextSize = 10
	button.Parent = itemList
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 3)
	itemButtons[itemName] = button
	local detectedCount = 0
	for _ in pairs(itemButtons) do detectedCount = detectedCount + 1 end
	whitelistTitle.Text = "Item filters (types: " .. tostring(detectedCount) .. ")"
	button.MouseButton1Click:Connect(function()
		whitelist[itemName] = not whitelist[itemName]
		button.BackgroundColor3 = whitelist[itemName] and Color3.fromRGB(0, 135, 85) or Color3.fromRGB(55, 55, 62)
		if active and whitelist[itemName] then rangeScanPending = true end
	end)
end

local function removeItemOption(itemName)
	if itemCounts[itemName] and itemCounts[itemName] > 0 then return end
	itemCounts[itemName] = nil
	whitelist[itemName] = nil
	local button = itemButtons[itemName]
	if button then
		button:Destroy()
		itemButtons[itemName] = nil
	end
	local count = 0
	for _ in pairs(itemButtons) do count = count + 1 end
	whitelistTitle.Text = "Items detected: " .. tostring(count)
end

local function isPlayerOwned(root)
	for _, target in ipairs(Players:GetPlayers()) do
		local character = target.Character
		local backpack = target:FindFirstChildOfClass("Backpack")
		if (character and (root == character or root:IsDescendantOf(character)))
			or (backpack and (root == backpack or root:IsDescendantOf(backpack))) then
			return true
		end
	end
	return false
end

local function registerItem(instance)
	local itemName, root = getItemInfo(instance)
	if not itemName or not root or isPlayerOwned(root) then return end
	local part = getItemPart(root)
	if not part then return end
	if itemCatalog[root] then return end
	itemCatalog[root] = itemName
	itemCounts[itemName] = (itemCounts[itemName] or 0) + 1
	addItemOption(itemName)
end

local function unregisterItemsUnder(instance)
	for root, itemName in pairs(itemCatalog) do
		if root == instance or root:IsDescendantOf(instance) then
			itemCatalog[root] = nil
			itemCounts[itemName] = math.max(0, (itemCounts[itemName] or 1) - 1)
			removeItemOption(itemName)
		end
	end
end

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

local function getWhitelistedItem(instance)
	local itemName, root = getItemInfo(instance)
	if not itemName or not whitelist[itemName] then return nil end
	local part = getItemPart(root)
	if not part then return nil end
	return itemName, root, part
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
	if originalAnchored[part] ~= nil then
		pcall(function() part.Anchored = originalAnchored[part] end)
		originalAnchored[part] = nil
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
	if not active then return end
	local itemName, itemRoot, itemPart = getWhitelistedItem(part)
	if not itemPart or trackedLookup[itemPart] then return end
	if not isInRange(itemPart, targetPart) then return end
	local sourcePosition = itemPart.Position
	local modelParts = {itemPart}
	if not itemRoot:IsA("BasePart") then
		for _, descendant in ipairs(itemRoot:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant ~= itemPart then
				table.insert(modelParts, descendant)
			end
		end
	end
	local ok = pcall(function()
		for _, modelPart in ipairs(modelParts) do
			if originalAnchored[modelPart] == nil then
				originalAnchored[modelPart] = modelPart.Anchored
			end
			modelPart.Anchored = false
		end
		local attachment = Instance.new("Attachment")
		attachment.Name = "BringAttachment"
		attachment.Parent = itemPart

		local alignPosition = Instance.new("AlignPosition")
		alignPosition.Name = "BringAlignPosition"
		alignPosition.Attachment0 = attachment
		alignPosition.Attachment1 = targetAttachment
		alignPosition.MaxForce = 100000
		alignPosition.Responsiveness = 200
		alignPosition.ReactionForceEnabled = false
		alignPosition.Parent = itemPart

		local alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Name = "BringAlignOrientation"
		alignOrientation.Attachment0 = attachment
		alignOrientation.Attachment1 = targetAttachment
		alignOrientation.MaxTorque = 100000
		alignOrientation.Responsiveness = 200
		alignOrientation.ReactionTorqueEnabled = false
		alignOrientation.Parent = itemPart

		originalCanCollide[itemPart] = itemPart.CanCollide
		itemPart.CanCollide = false
	end)
	if ok then
		trackedLookup[itemPart] = true
		sourcePositions[itemPart] = sourcePosition
		table.insert(trackedParts, itemPart)
	else
		cleanupPart(itemPart)
		for _, modelPart in ipairs(modelParts) do
			local wasAnchored = originalAnchored[modelPart]
			if wasAnchored ~= nil then
				pcall(function() modelPart.Anchored = wasAnchored end)
				originalAnchored[modelPart] = nil
			end
		end
	end
end

local function stopBring()
	active = false
	if connections.heartbeat then
		connections.heartbeat:Disconnect()
		connections.heartbeat = nil
	end
	for index = #trackedParts, 1, -1 do
		untrackPart(index)
	end
	for part, wasAnchored in pairs(originalAnchored) do
		if part.Parent then pcall(function() part.Anchored = wasAnchored end) end
		originalAnchored[part] = nil
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

	for root in pairs(itemCatalog) do
		trackPart(root, targetPart)
	end
	if #trackedParts == 0 then
		stopBring()
		if bringToggle then UT.setButtonToggle(bringToggle, false) end
		status.Text = "ERROR: No enabled detected items in range. Run Scan items or enable an item type."
		return
	end
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
			if not part.Parent or not getWhitelistedItem(part) or not isInRange(part, currentTarget, sourcePositions[part]) then
				untrackPart(index)
			end
		end
		if rangeScanPending and not draggingSlider then
			rangeScanPending = false
			for root in pairs(itemCatalog) do
				trackPart(root, currentTarget)
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

local function discoverItem(instance)
	registerItem(instance)
	if active then trackPart(instance, getTargetPart()) end
end

local scanning = false
local function scanWorldItems()
	if scanning then return end
	scanning = true
	if active then
		stopBring()
		if bringToggle then UT.setButtonToggle(bringToggle, false) end
	end
	scanButton.Text = "Scanning..."
	status.Text = "Scanning the map for supported items..."
	for itemName, button in pairs(itemButtons) do
		button:Destroy()
		itemButtons[itemName] = nil
		whitelist[itemName] = nil
	end
	for root in pairs(itemCatalog) do itemCatalog[root] = nil end
	for itemName in pairs(itemCounts) do itemCounts[itemName] = nil end

	local descendants = Workspace:GetDescendants()
	for index, descendant in ipairs(descendants) do
		registerItem(descendant)
		if index % 1000 == 0 then task.wait() end
	end

	local instanceCount = 0
	for _ in pairs(itemCatalog) do instanceCount = instanceCount + 1 end
	local typeCount = 0
	for _ in pairs(itemButtons) do typeCount = typeCount + 1 end
	if instanceCount == 0 then
		status.Text = "ERROR: No supported items found. Add an Item/Pickup tag, IsItem attribute, Tool, prompt, or item folder."
	else
		status.Text = "Found " .. tostring(instanceCount) .. " items across " .. tostring(typeCount) .. " types"
	end
	scanButton.Text = "Scan items"
	scanning = false
end

scanButton.MouseButton1Click:Connect(function()
	task.spawn(scanWorldItems)
end)

connections.worldDescendantAdded = Workspace.DescendantAdded:Connect(discoverItem)
connections.worldDescendantRemoving = Workspace.DescendantRemoving:Connect(unregisterItemsUnder)
for _, tagName in ipairs({"Item", "Pickup", "Collectible"}) do
	table.insert(connections, CollectionService:GetInstanceAddedSignal(tagName):Connect(discoverItem))
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
	for _, connection in pairs(connections) do
		if typeof(connection) == "RBXScriptConnection" then connection:Disconnect() end
	end
	connections = {}
	if attachmentPart and attachmentPart.Parent then attachmentPart:Destroy() end
end