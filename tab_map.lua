-- ============================================================
-- tab_map.lua - Minimap + interactables  (loaded by main.lua - do not run directly)
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
local CollectionService = game:GetService("CollectionService")
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
local LL_ITEM_CAP = 250
local LL_ENTITY_CAP = 200
local isInChar = UT.isInChar
local isPlayerModel = UT.isPlayerModel
local isPlayerRelated = UT.isPlayerRelated
-- ============================================
-- MAP / MINIMAP TAB
-- Shows: Walls/Terrain, Items, Entities, Players
-- Features: Click-to-TP, Waypoints, Compass, Wall rendering
-- ============================================
local mapFrame = tabFrames.Map

local mapTitle = Instance.new("TextLabel")
mapTitle.Size = UDim2.new(1, 0, 0, 18)
mapTitle.Text = "Live Minimap + Terrain"
mapTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
mapTitle.BackgroundTransparency = 1
mapTitle.Font = Enum.Font.GothamBold
mapTitle.TextSize = 12
mapTitle.TextXAlignment = Enum.TextXAlignment.Left
mapTitle.Parent = mapFrame

-- Top controls
local mapScanBtn = Instance.new("TextButton")
mapScanBtn.Size = UDim2.new(0.24, 0, 0, 22)
mapScanBtn.Position = UDim2.new(0, 0, 0, 20)
mapScanBtn.Text = "Scan Map"
mapScanBtn.TextColor3 = Color3.new(1,1,1)
mapScanBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
mapScanBtn.Font = Enum.Font.GothamBold
mapScanBtn.TextSize = 11
mapScanBtn.Parent = mapFrame
Instance.new("UICorner", mapScanBtn).CornerRadius = UDim.new(0, 4)

local mapRangeBox = Instance.new("TextBox")
mapRangeBox.Size = UDim2.new(0.22, 0, 0, 22)
mapRangeBox.Position = UDim2.new(0.26, 0, 0, 20)
mapRangeBox.Text = "400"
mapRangeBox.PlaceholderText = "Range"
mapRangeBox.TextColor3 = Color3.new(1,1,1)
mapRangeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mapRangeBox.Font = Enum.Font.Gotham
mapRangeBox.TextSize = 11
mapRangeBox.Parent = mapFrame
Instance.new("UICorner", mapRangeBox).CornerRadius = UDim.new(0, 4)

local mapClickTpBtn = Instance.new("TextButton")
mapClickTpBtn.Size = UDim2.new(0.24, 0, 0, 22)
mapClickTpBtn.Position = UDim2.new(0.50, 0, 0, 20)
mapClickTpBtn.Text = "Click TP: OFF"
mapClickTpBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
mapClickTpBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 60)
mapClickTpBtn.Font = Enum.Font.GothamBold
mapClickTpBtn.TextSize = 11
mapClickTpBtn.Parent = mapFrame
Instance.new("UICorner", mapClickTpBtn).CornerRadius = UDim.new(0, 4)

local mapClearWpBtn = Instance.new("TextButton")
mapClearWpBtn.Size = UDim2.new(0.24, 0, 0, 22)
mapClearWpBtn.Position = UDim2.new(0.76, 0, 0, 20)
mapClearWpBtn.Text = "Clear WP"
mapClearWpBtn.TextColor3 = Color3.new(1,1,1)
mapClearWpBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
mapClearWpBtn.Font = Enum.Font.GothamBold
mapClearWpBtn.TextSize = 11
mapClearWpBtn.Parent = mapFrame
Instance.new("UICorner", mapClearWpBtn).CornerRadius = UDim.new(0, 4)

-- Toggles row
local mapShowItems = true
local mapShowEntities = true
local mapShowPlayers = true
local mapShowWalls = true
local mapRotate = true
local mapClickTp = false

local function makeMiniToggle(parent, text, xPos, default, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 82, 0, 20)
	btn.Position = UDim2.new(0, xPos, 0, 46)
	btn.Text = text .. (default and ": ON" or ": OFF")
	btn.TextColor3 = default and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 9
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
	local enabled = default
	btn.MouseButton1Click:Connect(function()
		enabled = not enabled
		btn.Text = text .. (enabled and ": ON" or ": OFF")
		btn.TextColor3 = enabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
		callback(enabled)
	end)
end

makeMiniToggle(mapFrame, "Items", 0, true, function(v) mapShowItems = v end)
makeMiniToggle(mapFrame, "Entities", 88, true, function(v) mapShowEntities = v end)
makeMiniToggle(mapFrame, "Players", 176, true, function(v) mapShowPlayers = v end)
makeMiniToggle(mapFrame, "Walls", 264, true, function(v) mapShowWalls = v end)
makeMiniToggle(mapFrame, "Rotate", 352, true, function(v) mapRotate = v end)

-- ============================================
-- INTERACTABLES TP PANEL (right of minimap)
-- ProximityPrompts + ClickDetectors -> one-click TP
-- ============================================
local intLabel = Instance.new("TextLabel")
intLabel.Size = UDim2.new(0, 250, 0, 16)
intLabel.Position = UDim2.new(0, 350, 0, 72)
intLabel.Text = "Interactables TP (prompts, click detectors)"
intLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
intLabel.BackgroundTransparency = 1
intLabel.Font = Enum.Font.GothamBold
intLabel.TextSize = 10
intLabel.TextXAlignment = Enum.TextXAlignment.Left
intLabel.Parent = mapFrame

local intScan = Instance.new("TextButton")
intScan.Size = UDim2.new(0, 100, 0, 20)
intScan.Position = UDim2.new(0, 350, 0, 90)
intScan.Text = "Scan"
intScan.TextColor3 = Color3.new(1,1,1)
intScan.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
intScan.Font = Enum.Font.GothamBold
intScan.TextSize = 10
intScan.Parent = mapFrame
Instance.new("UICorner", intScan).CornerRadius = UDim.new(0, 3)

local intClear = Instance.new("TextButton")
intClear.Size = UDim2.new(0, 60, 0, 20)
intClear.Position = UDim2.new(0, 456, 0, 90)
intClear.Text = "Clear"
intClear.TextColor3 = Color3.new(1,1,1)
intClear.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
intClear.Font = Enum.Font.GothamBold
intClear.TextSize = 10
intClear.Parent = mapFrame
Instance.new("UICorner", intClear).CornerRadius = UDim.new(0, 3)

local intSearch = Instance.new("TextBox")
intSearch.Size = UDim2.new(0, 168, 0, 20)
intSearch.Position = UDim2.new(0, 522, 0, 90)
intSearch.PlaceholderText = "Search..."
intSearch.Text = ""
intSearch.TextColor3 = Color3.new(1,1,1)
intSearch.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
intSearch.Font = Enum.Font.Gotham
intSearch.TextSize = 10
intSearch.Parent = mapFrame
Instance.new("UICorner", intSearch).CornerRadius = UDim.new(0, 3)

local intAllEspButton = Instance.new("TextButton")
intAllEspButton.Size = UDim2.new(0, 80, 0, 20)
intAllEspButton.Position = UDim2.new(0, 610, 0, 66)
intAllEspButton.Text = "ESP all: OFF"
intAllEspButton.TextColor3 = Color3.new(1, 1, 1)
intAllEspButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
intAllEspButton.Font = Enum.Font.GothamBold
intAllEspButton.TextSize = 9
intAllEspButton.Parent = mapFrame
Instance.new("UICorner", intAllEspButton).CornerRadius = UDim.new(0, 3)

local intScroll = Instance.new("ScrollingFrame")
intScroll.Size = UDim2.new(0, 345, 0, 294)
intScroll.Position = UDim2.new(0, 350, 0, 114)
intScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
intScroll.BorderSizePixel = 0
intScroll.ScrollBarThickness = 4
intScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
intScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
intScroll.Parent = mapFrame
Instance.new("UICorner", intScroll).CornerRadius = UDim.new(0, 6)

local intLayout = Instance.new("UIListLayout")
intLayout.Padding = UDim.new(0, 2)
intLayout.Parent = intScroll

local intButtons = {}
local interactableEspGuis = {}
local interactableEspButtons = {}
local allInteractableEspEnabled = false

local function clearInteractables()
	for _, b in ipairs(intButtons) do pcall(function() b:Destroy() end) end
	intButtons = {}
	for holder, billboard in pairs(interactableEspGuis) do
		if billboard then pcall(function() billboard:Destroy() end) end
		interactableEspGuis[holder] = nil
	end
	interactableEspButtons = {}
	allInteractableEspEnabled = false
	intAllEspButton.Text = "ESP all: OFF"
	intAllEspButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	intLabel.Text = "Interactables TP (prompts, click detectors)"
end

local function getInteractablePart(holder)
	if holder:IsA("BasePart") then return holder end
	if holder:IsA("Model") and holder.PrimaryPart then return holder.PrimaryPart end
	local part = holder:FindFirstChildWhichIsA("BasePart", true)
	if part then return part end
	if holder.Parent and holder.Parent:IsA("BasePart") then return holder.Parent end
	return nil
end

local function tpToInteractable(holder)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local part = getInteractablePart(holder)
	if part then
		local ok, reason = UT.safeTeleportTo(part.Position + part.CFrame.LookVector * 4)
		notify("Interact TP", ok and holder.Name or reason)
	else
		notify("Interact TP", "No part found for " .. holder.Name)
	end
end

local function toggleInteractableEsp(holder, button)
	local existing = interactableEspGuis[holder]
	if existing then
		existing:Destroy()
		interactableEspGuis[holder] = nil
		button.Text = "ESP"
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		allInteractableEspEnabled = false
		intAllEspButton.Text = "ESP all: OFF"
		intAllEspButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		return
	end
	local part = getInteractablePart(holder)
	if not part then
		notify("Interactable ESP", "No part found for " .. holder.Name)
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ToolkitInteractableESP"
	billboard.Adornee = part
	billboard.Size = UDim2.new(0, 160, 0, 24)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = gui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = holder.Name
	label.TextColor3 = Color3.fromRGB(100, 255, 170)
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.Parent = billboard
	interactableEspGuis[holder] = billboard
	interactableEspButtons[holder] = button
	button.Text = "ESP ON"
	button.BackgroundColor3 = Color3.fromRGB(0, 110, 72)
end

intAllEspButton.MouseButton1Click:Connect(function()
	allInteractableEspEnabled = not allInteractableEspEnabled
	if allInteractableEspEnabled then
		for holder, button in pairs(interactableEspButtons) do
			if not interactableEspGuis[holder] then toggleInteractableEsp(holder, button) end
		end
		intAllEspButton.Text = "ESP all: ON"
		intAllEspButton.BackgroundColor3 = Color3.fromRGB(0, 110, 72)
	else
		for holder, billboard in pairs(interactableEspGuis) do
			if billboard then billboard:Destroy() end
			interactableEspGuis[holder] = nil
			local button = interactableEspButtons[holder]
			if button and button.Parent then
				button.Text = "ESP"
				button.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
			end
		end
		intAllEspButton.Text = "ESP all: OFF"
		intAllEspButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	end
end)

local function scanInteractables()
	if not UT.beginHeavyWork("Interactable scan") then
		intLabel.Text = "Waiting for lag recovery before scanning"
		return
	end
	clearInteractables()
	local found = {}
	local seenH = {}
	local function inspect(obj)
		if UT.cancelHeavyWork then return end
		local isDetector = obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector")
			or obj:IsA("DragDetector")
		local hasMarker = obj:GetAttribute("IsInteractable") == true
			or obj:GetAttribute("IsItem") == true
			or CollectionService:HasTag(obj, "Interactable")
			or CollectionService:HasTag(obj, "Pickup")
		local isUsableObject = obj:IsA("Tool") or obj:IsA("Seat") or obj:IsA("VehicleSeat")
		if isDetector or hasMarker or isUsableObject then
			local holder = (isDetector and obj.Parent) or obj
			if not holder then return end
			local skip = isCharacterPart(holder)
			if not skip and not seenH[holder] and (not UT.safeMode or #found < llCap(150)) then
				seenH[holder] = true
				table.insert(found, holder)
			end
		end
	end
	local scanOk = pcall(function() UT.forEachDescendant(workspace, inspect) end)
	if not scanOk then
		intLabel.Text = "Interactable scan failed. Try again after the map settles."
		UT.finishHeavyWork()
		return
	end
	if UT.cancelHeavyWork then
		intLabel.Text = "Interactables scan stopped because lag was detected. Rescan after recovery."
		UT.finishHeavyWork()
		return
	end
	table.sort(found, function(a,b) return a.Name:lower() < b.Name:lower() end)
	local shown = 0
	for i, holder in ipairs(found) do
		if UT.cancelHeavyWork then break end
		if i > llCap(150) then break end
		if UT.lowLagMode and i % llBtnStep() == 0 then RunService.Heartbeat:Wait() end
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -6, 0, 22)
		row.BackgroundTransparency = 1
		row.Parent = intScroll
		table.insert(intButtons, row)
		local nameBtn = Instance.new("TextButton")
		nameBtn.Size = UDim2.new(0.52, 0, 1, 0)
		nameBtn.Text = holder.Name
		nameBtn.TextColor3 = Color3.fromRGB(100, 255, 150)
		nameBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		nameBtn.Font = Enum.Font.Gotham
		nameBtn.TextSize = 10
		nameBtn.TextXAlignment = Enum.TextXAlignment.Left
		nameBtn.Parent = row
		Instance.new("UICorner", nameBtn).CornerRadius = UDim.new(0, 3)
		local tpB = Instance.new("TextButton")
		tpB.Size = UDim2.new(0.22, 0, 1, 0)
		tpB.Position = UDim2.new(0.54, 0, 0, 0)
		tpB.Text = "Go"
		tpB.TextColor3 = Color3.fromRGB(255, 200, 0)
		tpB.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
		tpB.Font = Enum.Font.GothamBold
		tpB.TextSize = 9
		tpB.Parent = row
		Instance.new("UICorner", tpB).CornerRadius = UDim.new(0, 3)
		tpB.MouseButton1Click:Connect(function() tpToInteractable(holder) end)
		local espButton = Instance.new("TextButton")
		espButton.Size = UDim2.new(0.22, 0, 1, 0)
		espButton.Position = UDim2.new(0.78, 0, 0, 0)
		espButton.Text = "ESP"
		espButton.TextColor3 = Color3.new(1, 1, 1)
		espButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		espButton.Font = Enum.Font.GothamBold
		espButton.TextSize = 9
		espButton.Parent = row
		Instance.new("UICorner", espButton).CornerRadius = UDim.new(0, 3)
		espButton.MouseButton1Click:Connect(function() toggleInteractableEsp(holder, espButton) end)
		shown = i
	end
	if UT.cancelHeavyWork then
		intLabel.Text = "Interactables scan stopped because lag was detected. Rescan after recovery."
		UT.finishHeavyWork()
		return
	end
	intLabel.Text = "Interactables: " .. shown .. (shown < #found and (" / " .. #found .. " (lag cap)") or "")
	notify("Interactables", "Found " .. shown .. " (" .. #found .. " total)")
	UT.finishHeavyWork()
end

intScan.MouseButton1Click:Connect(function() task.spawn(scanInteractables) end)
intClear.MouseButton1Click:Connect(clearInteractables)

intSearch:GetPropertyChangedSignal("Text"):Connect(function()
	local text = intSearch.Text:lower()
	for _, row in ipairs(intButtons) do
		local nameBtn = row:FindFirstChildOfClass("TextButton")
		if nameBtn then
			row.Visible = text == "" or nameBtn.Text:lower():find(text, 1, true) ~= nil
		end
	end
end)

-- Minimap container
local mapContainer = Instance.new("Frame")
mapContainer.Size = UDim2.new(0, 340, 0, 340)
mapContainer.Position = UDim2.new(0, 0, 0, 72)
mapContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
mapContainer.BorderSizePixel = 0
mapContainer.Parent = mapFrame
Instance.new("UICorner", mapContainer).CornerRadius = UDim.new(0, 10)

local mapBorder = Instance.new("UIStroke")
mapBorder.Color = Color3.fromRGB(60, 60, 70)
mapBorder.Thickness = 2
mapBorder.Parent = mapContainer

-- Inner canvas
local mapCanvas = Instance.new("Frame")
mapCanvas.Size = UDim2.new(1, -10, 1, -10)
mapCanvas.Position = UDim2.new(0, 5, 0, 5)
mapCanvas.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mapCanvas.BorderSizePixel = 0
mapCanvas.ClipsDescendants = true
mapCanvas.Parent = mapContainer
Instance.new("UICorner", mapCanvas).CornerRadius = UDim.new(0, 6)

-- Grid
for i = 1, 5 do
	local h = Instance.new("Frame")
	h.Size = UDim2.new(1, 0, 0, 1)
	h.Position = UDim2.new(0, 0, 0, i * 55)
	h.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	h.BorderSizePixel = 0
	h.Parent = mapCanvas
	local v = Instance.new("Frame")
	v.Size = UDim2.new(0, 1, 1, 0)
	v.Position = UDim2.new(0, i * 55, 0, 0)
	v.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	v.BorderSizePixel = 0
	v.Parent = mapCanvas
end

-- Compass labels
local compassLabels = {}
for _, dir in ipairs({{"N", 0.5, 0}, {"E", 1, 0.5}, {"S", 0.5, 1}, {"W", 0, 0.5}}) do
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 20, 0, 14)
	lbl.Position = UDim2.new(dir[2], -10, dir[3], -7)
	lbl.Text = dir[1]
	lbl.TextColor3 = Color3.fromRGB(120, 120, 140)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.Parent = mapCanvas
	compassLabels[dir[1]] = lbl
end

-- Wall blip pool
local wallPool = {}
local wallPoolIndex = 0
local function getWallFrame()
	wallPoolIndex = wallPoolIndex + 1
	if wallPoolIndex <= #wallPool then
		return wallPool[wallPoolIndex]
	else
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		f.BorderSizePixel = 0
		f.Parent = mapCanvas
		table.insert(wallPool, f)
		return f
	end
end

local function clearWallPool()
	for _, f in ipairs(wallPool) do
		f.Visible = false
	end
	wallPoolIndex = 0
end

-- Player arrow (center)
local playerArrow = Instance.new("Frame")
playerArrow.Size = UDim2.new(0, 10, 0, 10)
playerArrow.Position = UDim2.new(0.5, -5, 0.5, -5)
playerArrow.BackgroundColor3 = Color3.fromRGB(0, 255, 130)
playerArrow.BorderSizePixel = 0
playerArrow.ZIndex = 10
playerArrow.Parent = mapCanvas
Instance.new("UICorner", playerArrow).CornerRadius = UDim.new(1, 0)

local playerDir = Instance.new("Frame")
playerDir.Size = UDim2.new(0, 2, 0, 12)
playerDir.Position = UDim2.new(0.5, -1, 0.5, -14)
playerDir.BackgroundColor3 = Color3.fromRGB(0, 255, 130)
playerDir.BorderSizePixel = 0
playerDir.ZIndex = 10
playerDir.Parent = mapCanvas

-- Blip folder
local mapBlipFolder = Instance.new("Folder")
mapBlipFolder.Name = "Blips"
mapBlipFolder.Parent = mapCanvas
local blipPool = {}
local blipPoolIndex = 0

local function clearBlipPool()
	for _, entry in ipairs(blipPool) do
		entry.frame.Visible = false
		if entry.label then entry.label.Visible = false end
	end
	blipPoolIndex = 0
end

local function getBlip()
	blipPoolIndex = blipPoolIndex + 1
	local entry = blipPool[blipPoolIndex]
	if not entry then
		local blip = Instance.new("Frame")
		blip.BorderSizePixel = 0
		blip.Parent = mapBlipFolder
		entry = {frame = blip}
		blipPool[blipPoolIndex] = entry
	end
	return entry
end

-- Waypoint
local waypoint = nil
local waypointGui = Instance.new("Frame")
waypointGui.Size = UDim2.new(0, 12, 0, 12)
waypointGui.BackgroundColor3 = Color3.fromRGB(255, 50, 200)
waypointGui.BorderSizePixel = 0
waypointGui.Visible = false
waypointGui.ZIndex = 9
waypointGui.Parent = mapCanvas
Instance.new("UICorner", waypointGui).CornerRadius = UDim.new(1, 0)
local wpLabel = Instance.new("TextLabel")
wpLabel.Size = UDim2.new(1, 0, 0, 12)
wpLabel.Position = UDim2.new(0, 0, 0, -12)
wpLabel.Text = "WP"
wpLabel.TextColor3 = Color3.fromRGB(255, 50, 200)
wpLabel.BackgroundTransparency = 1
wpLabel.Font = Enum.Font.GothamBold
wpLabel.TextSize = 8
wpLabel.Parent = waypointGui

-- Tracked objects
local trackedItems = {}
local trackedEntities = {}
local mapWalls = {}

local function isCharacterPart(obj)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and obj:IsDescendantOf(p.Character) then return true end
	end
	return false
end

local function scanMapObjects()
	if not UT.beginHeavyWork("Map scan") then
		notify("Minimap", "Waiting for lag recovery before scanning")
		return
	end
	trackedItems = {}
	trackedEntities = {}
	mapWalls = {}
	local myHrpM = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local myPosM = myHrpM and myHrpM.Position
	local function inspect(obj)
		if UT.cancelHeavyWork then return end
		if obj:IsA("Tool") and not isInChar(obj) then
			local part = obj:FindFirstChildWhichIsA("BasePart")
			if part and (not UT.safeMode or #trackedItems < llCap(LL_ITEM_CAP)) then
				table.insert(trackedItems, {obj = obj, part = part})
			end
		elseif obj:IsA("Model") and not isPlayerModel(obj) and not isPlayerRelated(obj) then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
			if hum and hrp and (not UT.safeMode or #trackedEntities < llCap(LL_ENTITY_CAP)) then
				table.insert(trackedEntities, {obj = obj, part = hrp})
			end
		elseif obj:IsA("BasePart") and not isCharacterPart(obj) then
			local sz = obj.Size
			if (sz.X > 6 or sz.Z > 6) and sz.Y > 0.5 and sz.Y < 40
				and (not UT.lowLagMode or not myPosM or (obj.Position - myPosM).Magnitude < (UT.safeMode and 250 or (UT.potatoMode and 350 or 600)))
				and (not UT.safeMode or #mapWalls < llCap(LL_ENTITY_CAP)) then
				table.insert(mapWalls, obj)
			end
		end
	end

	local scanOk = pcall(function() UT.forEachDescendant(workspace, inspect) end)
	if not scanOk then
		notify("Minimap", "Map scan failed. Try again after the map settles.")
		UT.finishHeavyWork()
		return
	end
	if UT.cancelHeavyWork then
		notify("Minimap", "Scan stopped because lag was detected. Rescan after recovery.")
		UT.finishHeavyWork()
		return
	end
	notify("Minimap", "Scanned " .. #mapWalls .. " walls, " .. #trackedItems .. " items, " .. #trackedEntities .. " entities")
	UT.finishHeavyWork()
end

mapScanBtn.MouseButton1Click:Connect(function() task.spawn(scanMapObjects) end)

-- Click to TP / Waypoint
mapCanvas.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = input.Position
		local relX = pos.X - mapCanvas.AbsolutePosition.X
		local relY = pos.Y - mapCanvas.AbsolutePosition.Y
		local mapSize = mapCanvas.AbsoluteSize.X
		local half = mapSize / 2
		local range = tonumber(mapRangeBox.Text) or 400
		local scale = half / range
		local dx = (relX - half) / scale
		local dz = (relY - half) / scale
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local yaw = math.atan2(camera.CFrame.LookVector.X, camera.CFrame.LookVector.Z)
			if mapRotate then
				local c = math.cos(yaw)
				local s = math.sin(yaw)
				dx, dz = dx * c + dz * s, -dx * s + dz * c
			end
			local worldPos = hrp.Position + Vector3.new(dx, 0, dz)
			if mapClickTp then
				local ok, reason = UT.safeTeleportTo(worldPos)
				notify("Minimap", ok and "Teleported to waypoint area" or reason)
			else
				waypoint = worldPos
				waypointGui.Position = UDim2.new(0, relX - 6, 0, relY - 6)
				waypointGui.Visible = true
				notify("Minimap", "Waypoint set")
			end
		end
	end
end)

mapClickTpBtn.MouseButton1Click:Connect(function()
	mapClickTp = not mapClickTp
	mapClickTpBtn.Text = "Click TP: " .. (mapClickTp and "ON" or "OFF")
	mapClickTpBtn.TextColor3 = mapClickTp and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
end)

mapClearWpBtn.MouseButton1Click:Connect(function()
	waypoint = nil
	waypointGui.Visible = false
end)

-- Minimap render loop
UT.mapConn = nil
local function startMinimap()
	if UT.mapConn then UT.mapConn:Disconnect() end
	UT.mapConn = RunService.RenderStepped:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local playerPos = hrp.Position
		local lookVec = camera.CFrame.LookVector
		local yaw = math.atan2(lookVec.X, lookVec.Z)

		-- Reuse blip instances instead of creating/destroying them every frame.
		clearBlipPool()
		clearWallPool()

		local range = tonumber(mapRangeBox.Text) or 400
		local mapSize = mapCanvas.AbsoluteSize.X
		local half = mapSize / 2
		local scale = half / range

		local function worldToMap(wx, wz)
			local rx, rz = wx - playerPos.X, wz - playerPos.Z
			if mapRotate then
				local c = math.cos(-yaw)
				local s = math.sin(-yaw)
				rx, rz = rx * c - rz * s, rx * s + rz * c
			end
			return half + rx * scale, half + rz * scale
		end

		-- Draw walls
		if mapShowWalls then
			for _, wall in ipairs(mapWalls) do
				if wall and wall.Parent then
					local bx, by = worldToMap(wall.Position.X, wall.Position.Z)
					if bx > -20 and bx < mapSize + 20 and by > -20 and by < mapSize + 20 then
						local wf = getWallFrame()
						local sz = wall.Size
						local sx = math.clamp(sz.X * scale * 0.5, 2, 20)
						local sz2 = math.clamp(sz.Z * scale * 0.5, 2, 20)
						wf.Size = UDim2.new(0, sx, 0, sz2)
						wf.Position = UDim2.new(0, bx - sx/2, 0, by - sz2/2)
						wf.Visible = true
						wf.BackgroundTransparency = 0.6
					end
				end
			end
		end

		local function addBlip(worldPos, color, size, label, zIndex)
			local bx, by = worldToMap(worldPos.X, worldPos.Z)
			if bx < -size or bx > mapSize + size or by < -size or by > mapSize + size then return end
			local entry = getBlip()
			local blip = entry.frame
			blip.Size = UDim2.new(0, size, 0, size)
			blip.Position = UDim2.new(0, bx - size/2, 0, by - size/2)
			blip.BackgroundColor3 = color
			blip.ZIndex = zIndex or 5
			blip.Visible = true
			if not blip:FindFirstChildOfClass("UICorner") then
				Instance.new("UICorner", blip).CornerRadius = UDim.new(1, 0)
			end
			if label then
				if not entry.label then
					entry.label = Instance.new("TextLabel")
					entry.label.Size = UDim2.new(1, 0, 0, 10)
					entry.label.Position = UDim2.new(0, 0, 0, -10)
					entry.label.BackgroundTransparency = 1
					entry.label.Font = Enum.Font.Gotham
					entry.label.TextSize = 7
					entry.label.Parent = blip
				end
				entry.label.Text = label
				entry.label.TextColor3 = color
				entry.label.Visible = true
			elseif entry.label then
				entry.label.Visible = false
			end
		end

		if mapShowItems then
			for _, entry in ipairs(trackedItems) do
				if entry.part and entry.part.Parent then
					addBlip(entry.part.Position, Color3.fromRGB(0, 200, 255), 6)
				end
			end
		end
		if mapShowEntities then
			for _, entry in ipairs(trackedEntities) do
				if entry.part and entry.part.Parent then
					addBlip(entry.part.Position, Color3.fromRGB(255, 80, 0), 8)
				end
			end
		end
		if mapShowPlayers then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player then
					local pChar = plr.Character
					local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
					if pHrp then
						local col = (plr.Team == player.Team) and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 235, 50)
						addBlip(pHrp.Position, col, 7, plr.Name, 6)
					end
				end
			end
		end

		-- Update waypoint on map
		if waypoint then
			local wbx, wby = worldToMap(waypoint.X, waypoint.Z)
			if wbx > -20 and wbx < mapSize + 20 and wby > -20 and wby < mapSize + 20 then
				waypointGui.Position = UDim2.new(0, wbx - 6, 0, wby - 6)
				waypointGui.Visible = true
			else
				waypointGui.Visible = false
			end
		end

		-- Rotate compass
		if mapRotate then
			playerDir.Rotation = 0
			compassLabels["N"].Position = UDim2.new(0.5, -10, 0, 2)
			compassLabels["E"].Position = UDim2.new(1, -18, 0.5, -7)
			compassLabels["S"].Position = UDim2.new(0.5, -10, 1, -14)
			compassLabels["W"].Position = UDim2.new(0, 2, 0.5, -7)
		else
			playerDir.Rotation = math.deg(yaw)
			local rot = math.deg(yaw)
			compassLabels["N"].Rotation = rot
			compassLabels["E"].Rotation = rot
			compassLabels["S"].Rotation = rot
			compassLabels["W"].Rotation = rot
		end
	end)
end

startMinimap()

UT.cleanupMap = function()
	clearInteractables()
	if UT.mapConn then
		UT.mapConn:Disconnect()
		UT.mapConn = nil
	end
end

