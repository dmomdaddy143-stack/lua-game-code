-- ============================================================
-- core.lua - services, GUI, tab bar, shared helpers
-- loaded first by main.lua (receives shared context via ...)
-- ============================================================
local UT = ...
-- ============================================
-- ULTIMATE TOOLKIT v5++
-- Tabs: Remotes | Items | Players | Move | Entities | Visuals | Misc | Map
-- Fixes: Entity ESP + Scanning, Spectate, 30 Noclip Methods
-- Added: Minimap with walls, Click TP, Waypoints, Item Magnet
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Drawing API check (MUST be at top)
local Drawing = Drawing or nil
local drawingSupported = false
if Drawing then
	local ok, _ = pcall(function()
		local d = Drawing.new("Square")
		d:Remove()
	end)
	drawingSupported = ok
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "UltimateToolkitV5"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 720, 0, 560)
frame.Position = UDim2.new(0.5, -360, 0.5, -280)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -200, 0, 28)
title.Text = "Ultimate Toolkit v5++"
title.TextColor3 = Color3.fromRGB(0, 255, 130)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local x = Instance.new("TextButton")
x.Size = UDim2.new(0, 28, 0, 28)
x.Position = UDim2.new(1, -30, 0, 0)
x.Text = "X"
x.TextColor3 = Color3.fromRGB(255, 60, 60)
x.BackgroundTransparency = 1
x.Font = Enum.Font.GothamBold
x.TextSize = 14
x.Parent = frame

local tabColors = {
	Remotes = Color3.fromRGB(180, 30, 30),
	Items = Color3.fromRGB(0, 140, 255),
	Players = Color3.fromRGB(255, 200, 0),
	Move = Color3.fromRGB(0, 255, 100),
	Entities = Color3.fromRGB(255, 80, 0),
	Visuals = Color3.fromRGB(180, 0, 255),
	Misc = Color3.fromRGB(0, 200, 200),
	Map = Color3.fromRGB(255, 100, 255),
}

local tabList = {"Remotes", "Items", "Players", "Move", "Entities", "Visuals", "Misc", "Map"}
local tabBtns = {}
local tabFrames = {}
local currentTab = "Remotes"

-- Low Lag Mode: scans yield across frames + capped results
-- Potato Mode: stacks on top of Low Lag Mode, tiny scans + near-only
UT.lowLagMode = false
UT.potatoMode = false
local LL_REMOTE_CAP = 250
local LL_ITEM_CAP = 250
local LL_ENTITY_CAP = 200
local function lagYield()
	if UT.lowLagMode then RunService.Heartbeat:Wait() end
end
local function llYieldStep()
	return UT.potatoMode and 250 or 1000
end
local function llBtnStep()
	return UT.potatoMode and 10 or 25
end
local function llCap(n)
	return UT.lowLagMode and (UT.potatoMode and math.max(25, math.floor(n / 3)) or n) or math.huge
end

local function switchTab(name)
	currentTab = name
	for n, c in pairs(tabFrames) do c.Visible = (n == name) end
	for n, b in pairs(tabBtns) do b.BackgroundColor3 = (n == name) and tabColors[n] or Color3.fromRGB(35,35,40) end
end

for i, name in ipairs(tabList) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 82, 0, 24)
	btn.Position = UDim2.new(0, 5 + (i-1)*88, 0, 30)
	btn.Text = name
	btn.TextColor3 = Color3.new(1,1,1)
	btn.BackgroundColor3 = (name == currentTab) and tabColors[name] or Color3.fromRGB(35, 35, 40)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = frame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	tabBtns[name] = btn
	local cont = Instance.new("Frame")
	cont.Size = UDim2.new(1, -10, 1, -64)
	cont.Position = UDim2.new(0, 5, 0, 58)
	cont.BackgroundTransparency = 1
	cont.Visible = (name == currentTab)
	cont.Parent = frame
	tabFrames[name] = cont
	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

local function notify(t, m)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = t, Text = m, Duration = 3})
	end)
end

local toggleRegistry = {}
local toggleSetters = {}

local function makeToggle(parent, text, y, callback, size, pos)
	local btn = Instance.new("TextButton")
	btn.Size = size or UDim2.new(1, 0, 0, 26)
	btn.Position = pos or UDim2.new(0, 0, 0, y)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	local state = {enabled = false}
	local function setToggle(on)
		state.enabled = on
		btn.Text = text .. (on and ": ON" or ": OFF")
		btn.TextColor3 = on and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
	end
	toggleSetters[btn] = setToggle
	setToggle(false)
	btn.MouseButton1Click:Connect(function()
		setToggle(not state.enabled)
		callback(state.enabled)
	end)
	toggleRegistry[btn] = {state = state, callback = callback}
	return btn
end

local function setButtonToggle(btn, on)
	local setter = toggleSetters[btn]
	if setter then
		setter(on)
	end
end

local function resetAllToggles()
	for btn, entry in pairs(toggleRegistry) do
		if entry.state.enabled then
			setButtonToggle(btn, false)
			pcall(entry.callback, false)
		end
	end
end

-- ============================================
-- REUSABLE DROPDOWN COMPONENT
-- Usage: makeDropdown(parent, label, options, default, callback, size, pos)
-- ============================================
local function makeDropdown(parent, label, options, default, callback, size, pos)
	local container = Instance.new("Frame")
	container.Size = size or UDim2.new(1, 0, 0, 22)
	container.Position = pos or UDim2.new(0, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.ZIndex = 50
	container.Parent = parent

	local header = Instance.new("TextButton")
	header.Size = UDim2.new(1, 0, 0, 22)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 11
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.ZIndex = 51
	header.Parent = container
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 4)

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 6)
	headerPad.Parent = header

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 16, 1, 0)
	arrow.Position = UDim2.new(1, -18, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "v"
	arrow.TextColor3 = Color3.fromRGB(180, 180, 180)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 10
	arrow.ZIndex = 52
	arrow.Parent = header

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, 0, 0, 0)
	list.Position = UDim2.new(0, 0, 0, 24)
	list.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	list.BorderSizePixel = 0
	list.Visible = false
	list.ZIndex = 53
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.Parent = container
	Instance.new("UICorner", list).CornerRadius = UDim.new(0, 4)

	local listStroke = Instance.new("UIStroke")
	listStroke.Color = Color3.fromRGB(60, 60, 70)
	listStroke.Thickness = 1
	listStroke.Parent = list

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 1)
	listLayout.Parent = list

	local listPad = Instance.new("UIPadding")
	listPad.PaddingTop = UDim.new(0, 2)
	listPad.PaddingBottom = UDim.new(0, 2)
	listPad.PaddingLeft = UDim.new(0, 2)
	listPad.PaddingRight = UDim.new(0, 2)
	listPad.Parent = list

	local selected = default
	local open = false

	local function refreshHeader()
		header.Text = label .. ": " .. tostring(selected) .. "  "
	end
	refreshHeader()

	local function setOpen(state)
		open = state
		list.Visible = open
		arrow.Text = open and "^" or "v"
	end

	for _, opt in ipairs(options) do
		local optBtn = Instance.new("TextButton")
		optBtn.Size = UDim2.new(1, -4, 0, 20)
		optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
		optBtn.TextColor3 = Color3.new(1, 1, 1)
		optBtn.Font = Enum.Font.Gotham
		optBtn.TextSize = 10
		optBtn.Text = tostring(opt)
		optBtn.ZIndex = 54
		optBtn.Parent = list
		Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 3)
		optBtn.MouseButton1Click:Connect(function()
			selected = opt
			refreshHeader()
			setOpen(false)
			pcall(callback, opt)
		end)
	end

	header.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	return container, function() return selected end, setOpen
end

-- ============================================
-- MAIN CATEGORY DROPDOWN (top-right of window)
-- Synced with the tab buttons - picking one updates the other
-- ============================================
local ddOk, ddErr = pcall(function()
	makeDropdown(frame, "Category", tabList, currentTab, function(name)
		switchTab(name)
	end, UDim2.new(0, 132, 0, 22), UDim2.new(1, -166, 0, 3))
end)
if not ddOk then
	notify("Dropdown Error", tostring(ddErr))
end


-- ============================================
-- SHARED ENTITY/ITEM HELPERS (used by Items, Entities, Map tabs)
-- ============================================
local function isInChar(obj)
	if not obj or not obj.Parent then return false end
	local p = obj.Parent
	if p:FindFirstChildOfClass("Humanoid") and p:FindFirstChild("HumanoidRootPart") then return true end
	return false
end

local function isPlayerModel(obj)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character == obj then return true end
	end
	return false
end

local function isPlayerRelated(obj)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and (obj:IsDescendantOf(p.Character) or obj == p.Character) then
			return true
		end
	end
	return false
end

local function getEntityPrimaryPart(model)
	if not model then return nil end
	if model:IsA("BasePart") then return model end
	local primary = model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChild("Hitbox")
		or model:FindFirstChild("Hurtbox")
		or model:FindFirstChild("RootPart")
		or model:FindFirstChild("Root")
	if primary and primary:IsA("BasePart") then return primary end
	return model:FindFirstChildWhichIsA("BasePart")
end

-- ============================================
-- EXPORTS (tab files access these through UT)
-- ============================================
UT.Players = Players
UT.RunService = RunService
UT.UserInputService = UserInputService
UT.Lighting = Lighting
UT.TeleportService = TeleportService
UT.HttpService = HttpService
UT.TweenService = TweenService
UT.PhysicsService = PhysicsService
UT.player = player
UT.camera = camera
UT.gui = gui
UT.frame = frame
UT.tabFrames = tabFrames
UT.tabBtns = tabBtns
UT.tabList = tabList
UT.tabColors = tabColors
UT.drawingSupported = drawingSupported
UT.notify = notify
UT.makeToggle = makeToggle
UT.setButtonToggle = setButtonToggle
UT.makeDropdown = makeDropdown
UT.resetAllToggles = resetAllToggles
UT.switchTab = switchTab
UT.lagYield = lagYield
UT.llYieldStep = llYieldStep
UT.llBtnStep = llBtnStep
UT.llCap = llCap
UT.isInChar = isInChar
UT.isPlayerModel = isPlayerModel
UT.isPlayerRelated = isPlayerRelated
UT.getEntityPrimaryPart = getEntityPrimaryPart
