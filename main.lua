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
local bootEvent = Instance.new("BindableEvent")
local hotkeyWindowOpen = true
local hotkeyConnection = UserInputService.InputBegan:Connect(function(input)
	if hotkeyWindowOpen and input.KeyCode == Enum.KeyCode.X
		and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
		bootRequested = true
	end
end)

local function showBootPicker()
	local selected = {}
	for _, module in ipairs(tabModules) do selected[module[1]] = true end

	local bootGui = Instance.new("ScreenGui")
	bootGui.Name = "ToolkitBootPicker"
	bootGui.ResetOnSpawn = false
	bootGui.IgnoreGuiInset = true
	bootGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 380, 0, 420)
	panel.Position = UDim2.new(0.5, -190, 0.5, -210)
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
	hint.Text = "Core and cleanup always load. Uncheck unused tabs."
	hint.TextColor3 = Color3.fromRGB(165, 165, 170)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 10
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = panel

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, -24, 0, 270)
	list.Position = UDim2.new(0, 12, 0, 66)
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
		refreshButton(button, fileName, tabName)
		button.MouseButton1Click:Connect(function()
			selected[fileName] = not selected[fileName]
			refreshButton(button, fileName, tabName)
		end)
	end

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -24, 0, 18)
	statusLabel.Position = UDim2.new(0, 12, 0, 342)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(255, 120, 110)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 10
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = panel

	local loadButton = Instance.new("TextButton")
	loadButton.Size = UDim2.new(1, -24, 0, 34)
	loadButton.Position = UDim2.new(0, 12, 0, 370)
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
		bootGui:Destroy()
		bootEvent:Fire(selected)
	end)
end

notify("Toolkit Startup", "Press Shift+X now to choose which tabs load")
task.wait(1.5)
hotkeyWindowOpen = false
hotkeyConnection:Disconnect()

local selectedModules
if bootRequested then
	showBootPicker()
	selectedModules = bootEvent.Event:Wait()
end

local loadFiles = {}
for _, name in ipairs(FILES) do
	if not selectedModules or name == "core.lua" or name == "cleanup.lua" or selectedModules[name] then
		table.insert(loadFiles, name)
	end
end

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

notify("Ultimate Toolkit", "Loading " .. tostring(#FILES) .. " modules...")

for index, name in ipairs(loadFiles) do
	if UT.setLoadProgress then
		UT.setLoadProgress(name, index, #loadFiles)
	else
		notify("Loading", name .. " (" .. tostring(index) .. "/" .. tostring(#loadFiles) .. ")")
	end
	task.wait()
	local ok, err = pcall(function()
		local src = fetchSource(name)
		local chunk, loadErr = loadstring(src, name)
		if not chunk then
			error("SYNTAX: " .. tostring(loadErr))
		end
		chunk(UT)
	end)
	if not ok then
		if UT.failModuleLoad then UT.failModuleLoad(name, err) end
		notify("Load Failed: " .. name, tostring(err))
		error("UltimateToolkit failed at " .. name .. ": " .. tostring(err))
	end
	if UT.markModuleLoaded then UT.markModuleLoaded(name, index, #loadFiles) end
	task.wait()
end

loaderReady = true
if UT.finishModuleLoading then UT.finishModuleLoading() end
notify("Ultimate Toolkit", "All modules loaded!")
