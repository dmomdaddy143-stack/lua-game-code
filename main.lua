-- ============================================================
-- ULTIMATE TOOLKIT v5++ - GITHUB LOADER
-- 1. Put all the .lua files in a GitHub repo
-- 2. Update BASE_URL below (use the raw.githubusercontent.com link)
-- 3. Paste THIS whole file into your executor
-- ============================================================

local BASE_URL = "https://raw.githubusercontent.com/dmomdaddy143-stack/lua-game-code/main/"

-- Files load IN ORDER - core.lua must always be first
local FILES = {
	"core.lua",
	"tab_remotes.lua",
	"tab_items.lua",
	"tab_players.lua",
	"tab_move.lua",
	"tab_entities.lua",
	"tab_visuals.lua",
	"tab_misc.lua",
	"tab_map.lua",
	"tab_bring.lua",
	"cleanup.lua",
}

local UT = {}
local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(1, 1000000000))
local loaderReady = false

local function notify(t, m)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = t, Text = m, Duration = 4})
	end)
end

local tabModules = {
	{"tab_remotes.lua", "Remotes"},
	{"tab_items.lua", "Items"},
	{"tab_players.lua", "Players"},
	{"tab_move.lua", "Move"},
	{"tab_entities.lua", "Entities"},
	{"tab_visuals.lua", "Visuals"},
	{"tab_misc.lua", "Misc"},
	{"tab_map.lua", "Map"},
	{"tab_bring.lua", "Bring"},
}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local bootRequested = false
local safeModeRequested = false
local pickerOpen = false
local lastShiftQAt = 0
local hotkeyConnection = UserInputService.InputBegan:Connect(function(input)
	local shiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	if not pickerOpen and shiftHeld then
		if input.KeyCode == Enum.KeyCode.Q then
			local now = os.clock()
			if now - lastShiftQAt < 0.45 then
				if UT.shutdown then pcall(UT.shutdown) end
				return
			end
			lastShiftQAt = now
			if not loaderReady then
				safeModeRequested = true
				bootRequested = false
			end
		elseif input.KeyCode == Enum.KeyCode.X then
			if not loaderReady then
				bootRequested = true
			end
		end
	end
end)
UT.hotkeyConnection = hotkeyConnection

local function showBootPicker(loadedModules)
	pickerOpen = true
	local selected = {}
	for _, module in ipairs(tabModules) do
		selected[module[1]] = not loadedModules[module[1]]
	end
	local testMode = false
	local potatoMode = false
	local bootEvent = Instance.new("BindableEvent")

	local bootGui = Instance.new("ScreenGui")
	bootGui.Name = "ToolkitBootPicker"
	bootGui.ResetOnSpawn = false
	bootGui.IgnoreGuiInset = true
	bootGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 380, 0, 450)
	panel.Position = UDim2.new(0.5, -190, 0.5, -225)
	panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	panel.BorderSizePixel = 0
	panel.Parent = bootGui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 28)
	title.Position = UDim2.new(0, 12, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "Choose tabs to load"
	title.TextColor3 = Color3.fromRGB(235, 235, 235)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, -24, 0, 22)
	hint.Position = UDim2.new(0, 12, 0, 38)
	hint.BackgroundTransparency = 1
	hint.Text = "Shift+X works during loading. Core and cleanup always load."
	hint.TextColor3 = Color3.fromRGB(165, 165, 170)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 10
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = panel

	local function makeModeButton(text, x)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 174, 0, 24)
		button.Position = UDim2.new(0, x, 0, 66)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 10
		button.Parent = panel
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
		return button
	end

	local testButton = makeModeButton("Test mode: OFF", 12)
	testButton.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
	local potatoButton = makeModeButton("Potato mode: OFF", 194)
	potatoButton.BackgroundColor3 = Color3.fromRGB(38, 38, 44)

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, -24, 0, 270)
	list.Position = UDim2.new(0, 12, 0, 96)
	list.BackgroundTransparency = 1
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.Parent = list

	local function refreshButton(button, fileName, tabName)
		local enabled = selected[fileName]
		button.Text = (enabled and "[x] " or "[ ] ") .. tabName
		button.BackgroundColor3 = enabled and Color3.fromRGB(34, 78, 56) or Color3.fromRGB(38, 38, 44)
	end

	local tabButtons = {}
	local function refreshButtons()
		for fileName, button in pairs(tabButtons) do
			local moduleName
			for _, module in ipairs(tabModules) do
				if module[1] == fileName then moduleName = module[2] break end
			end
			local loaded = loadedModules[fileName]
			button.Text = (loaded and "[loaded] " or (selected[fileName] and "[x] " or "[ ] ")) .. moduleName
			button.BackgroundColor3 = loaded and Color3.fromRGB(32, 55, 45)
				or (selected[fileName] and Color3.fromRGB(34, 78, 56) or Color3.fromRGB(38, 38, 44))
			button.Active = not loaded
			button.AutoButtonColor = not loaded
		end
	end

	for _, module in ipairs(tabModules) do
		local fileName, tabName = module[1], module[2]
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 26)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.Gotham
		button.TextSize = 11
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Parent = list
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
		tabButtons[fileName] = button
		refreshButtons()
		button.MouseButton1Click:Connect(function()
			if loadedModules[fileName] then return end
			if testMode then
				for otherName in pairs(selected) do selected[otherName] = false end
				selected[fileName] = true
				pickerOpen = false
				bootGui:Destroy()
				bootEvent:Fire(selected, testMode, potatoMode)
				return
			else
				selected[fileName] = not selected[fileName]
			end
			refreshButtons()
		end)
	end
	testButton.MouseButton1Click:Connect(function()
		testMode = not testMode
		testButton.Text = "Test mode: " .. (testMode and "ON" or "OFF")
		testButton.BackgroundColor3 = testMode and Color3.fromRGB(0, 105, 75) or Color3.fromRGB(38, 38, 44)
		if testMode then
			for fileName in pairs(selected) do selected[fileName] = false end
		end
		refreshButtons()
	end)
	potatoButton.MouseButton1Click:Connect(function()
		potatoMode = not potatoMode
		potatoButton.Text = "Potato mode: " .. (potatoMode and "ON" or "OFF")
		potatoButton.BackgroundColor3 = potatoMode and Color3.fromRGB(130, 90, 30) or Color3.fromRGB(38, 38, 44)
	end)

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -24, 0, 18)
	statusLabel.Position = UDim2.new(0, 12, 0, 372)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(255, 120, 110)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 10
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = panel

	local loadButton = Instance.new("TextButton")
	loadButton.Size = UDim2.new(1, -24, 0, 34)
	loadButton.Position = UDim2.new(0, 12, 0, 400)
	loadButton.Text = "Load selected tabs"
	loadButton.TextColor3 = Color3.new(1, 1, 1)
	loadButton.BackgroundColor3 = Color3.fromRGB(0, 125, 78)
	loadButton.Font = Enum.Font.GothamBold
	loadButton.TextSize = 12
	loadButton.Parent = panel
	Instance.new("UICorner", loadButton).CornerRadius = UDim.new(0, 4)
	loadButton.MouseButton1Click:Connect(function()
		local count = 0
		for _, isSelected in pairs(selected) do
			if isSelected then count = count + 1 end
		end
		if count == 0 then
			statusLabel.Text = "Select at least one tab."
			return
		end
		if testMode and count ~= 1 then
			statusLabel.Text = "Test mode loads exactly one tab."
			return
		end
		pickerOpen = false
		bootGui:Destroy()
		bootEvent:Fire(selected, testMode, potatoMode)
	end)
	return bootEvent.Event:Wait()
end

local selectedModules
local testMode = false
local potatoMode = false
local safeMode = false
local loadedModules = {}

local function fetchSource(name)
	local ok, source = pcall(function()
		return game:HttpGet(BASE_URL .. name .. "?v=" .. CACHE_BUSTER)
	end)
	if ok and type(source) == "string" and #source > 0 then
		return source
	end
	-- Fall back to local modules only when GitHub cannot be reached.
	if isfile and readfile and pcall(isfile, name) and isfile(name) then
		return readfile(name)
	end
	error(source or ("Unable to fetch " .. name))
end

UT.updateToolkit = function()
	if not loaderReady then
		notify("Update", "Wait for the toolkit to finish loading")
		return
	end
	local ok, source = pcall(function()
		local version = tostring(os.time()) .. "-" .. tostring(math.random(1, 1000000000))
		return game:HttpGet(BASE_URL .. "main.lua?update=" .. version)
	end)
	if not ok or type(source) ~= "string" or #source == 0 then
		notify("Update Failed", tostring(source or "Could not fetch the latest loader"))
		return
	end

	local chunk, loadErr = loadstring(source, "main.lua")
	if not chunk then
		notify("Update Failed", tostring(loadErr))
		return
	end

	if UT.shutdown then
		pcall(UT.shutdown)
	elseif UT.gui then
		UT.gui:Destroy()
	end
	task.spawn(function()
		local started, startErr = pcall(chunk)
		if not started then notify("Update Failed", tostring(startErr)) end
	end)
end

local function applyBootPicker()
	bootRequested = false
	selectedModules, testMode, potatoMode = showBootPicker(loadedModules)
	safeMode = potatoMode
	UT.safeMode = safeMode
	UT.potatoMode = potatoMode
	UT.lowLagMode = potatoMode
end

local function applySafeMode()
	safeModeRequested = false
	safeMode = true
	potatoMode = true
	UT.safeMode = true
	UT.potatoMode = true
	UT.lowLagMode = true
	notify("Safe Mode", "Enabled: scans use smaller batches and yield between work")
end

notify("Ultimate Toolkit", "Loading modules. Shift+Q enables Safe Mode; Shift+X opens tab choices.")

for index, name in ipairs(FILES) do
	task.wait()
	if safeModeRequested then applySafeMode() end
	if bootRequested then applyBootPicker() end

	local requiredModule = name == "core.lua" or name == "cleanup.lua"
	local shouldLoad = requiredModule or not selectedModules or selectedModules[name]
	if shouldLoad then
		if UT.setLoadProgress then
			UT.setLoadProgress(name, index, #FILES)
		end
		local ok, err = pcall(function()
			local src = fetchSource(name)
			local chunk, loadErr = loadstring(src, name)
			if not chunk then error("SYNTAX: " .. tostring(loadErr)) end
			chunk(UT)
		end)
		if not ok then
			if UT.failModuleLoad then UT.failModuleLoad(name, err) end
			notify("Load Failed: " .. name, tostring(err))
			hotkeyConnection:Disconnect()
			error("UltimateToolkit failed at " .. name .. ": " .. tostring(err))
		end
		loadedModules[name] = true
		if name == "core.lua" then
			UT.potatoMode = potatoMode
			UT.lowLagMode = potatoMode
		end
		if UT.markModuleLoaded then UT.markModuleLoaded(name, index, #FILES) end
	end
	task.wait()
end

loaderReady = true
if UT.finishModuleLoading then UT.finishModuleLoading() end
notify("Ultimate Toolkit", "All modules loaded!")
