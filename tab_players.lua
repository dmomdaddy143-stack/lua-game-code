-- ============================================================
-- tab_players.lua - Player list, spectate, steal  (loaded by main.lua - do not run directly)
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
-- PLAYERS TAB
-- ============================================
local pFrame = tabFrames.Players

-- Spectate controls
local spectateTarget = nil
UT.spectateConn = nil
local oldCameraSubject = nil

local spectateBtn = Instance.new("TextButton")
spectateBtn.Size = UDim2.new(0, 100, 0, 22)
spectateBtn.Position = UDim2.new(0, 0, 0, 0)
spectateBtn.Text = "Spectate: OFF"
spectateBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
spectateBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 60)
spectateBtn.Font = Enum.Font.GothamBold
spectateBtn.TextSize = 10
spectateBtn.Parent = pFrame
Instance.new("UICorner", spectateBtn).CornerRadius = UDim.new(0, 3)

local selectedPlayerName = nil

spectateBtn.MouseButton1Click:Connect(function()
	if UT.spectateConn then
		UT.spectateConn:Disconnect()
		UT.spectateConn = nil
		camera.CameraSubject = oldCameraSubject or player.Character
		spectateBtn.Text = "Spectate: OFF"
		spectateBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
		spectateTarget = nil
		notify("Spectate", "Stopped")
	else
		if not selectedPlayerName then
			notify("Spectate", "Click a player name to select first!")
			return
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name == selectedPlayerName and p ~= player then
				spectateTarget = p
				oldCameraSubject = camera.CameraSubject
				local function updateCam()
					if spectateTarget and spectateTarget.Character then
						local hum = spectateTarget.Character:FindFirstChildOfClass("Humanoid")
						if hum then camera.CameraSubject = hum end
					end
				end
				updateCam()
				UT.spectateConn = RunService.RenderStepped:Connect(updateCam)
				spectateBtn.Text = "Spectate: ON"
				spectateBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
				notify("Spectate", "Watching " .. selectedPlayerName)
				return
			end
		end
		notify("Spectate", "Player not found!")
	end
end)

local pSearch = Instance.new("TextBox")
pSearch.Size = UDim2.new(0, 140, 0, 18)
pSearch.Position = UDim2.new(0, 0, 0, 26)
pSearch.PlaceholderText = "Search players..."
pSearch.Text = ""
pSearch.TextColor3 = Color3.new(1,1,1)
pSearch.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
pSearch.Font = Enum.Font.Gotham
pSearch.TextSize = 10
pSearch.Parent = pFrame
Instance.new("UICorner", pSearch).CornerRadius = UDim.new(0, 3)

local iSearch2 = Instance.new("TextBox")
iSearch2.Size = UDim2.new(0, 234, 0, 18)
iSearch2.Position = UDim2.new(0, 154, 0, 26)
iSearch2.PlaceholderText = "Search inventory..."
iSearch2.Text = ""
iSearch2.TextColor3 = Color3.new(1,1,1)
iSearch2.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
iSearch2.Font = Enum.Font.Gotham
iSearch2.TextSize = 10
iSearch2.Parent = pFrame
Instance.new("UICorner", iSearch2).CornerRadius = UDim.new(0, 3)

local pScroll2 = Instance.new("ScrollingFrame")
pScroll2.Size = UDim2.new(0, 140, 1, -40)
pScroll2.Position = UDim2.new(0, 0, 0, 46)
pScroll2.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
pScroll2.BorderSizePixel = 0
pScroll2.ScrollBarThickness = 4
pScroll2.CanvasSize = UDim2.new(0, 0, 0, 0)
pScroll2.AutomaticCanvasSize = Enum.AutomaticSize.Y
pScroll2.Parent = pFrame
Instance.new("UICorner", pScroll2).CornerRadius = UDim.new(0, 6)

local pLayout2 = Instance.new("UIListLayout")
pLayout2.Padding = UDim.new(0, 2)
pLayout2.Parent = pScroll2

local iScroll2 = Instance.new("ScrollingFrame")
iScroll2.Size = UDim2.new(0, 234, 1, -40)
iScroll2.Position = UDim2.new(0, 154, 0, 46)
iScroll2.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
iScroll2.BorderSizePixel = 0
iScroll2.ScrollBarThickness = 4
iScroll2.CanvasSize = UDim2.new(0, 0, 0, 0)
iScroll2.AutomaticCanvasSize = Enum.AutomaticSize.Y
iScroll2.Parent = pFrame
Instance.new("UICorner", iScroll2).CornerRadius = UDim.new(0, 6)

local iLayout2 = Instance.new("UIListLayout")
iLayout2.Padding = UDim.new(0, 2)
iLayout2.Parent = iScroll2

local p2Buttons = {}
local i2Buttons = {}

local function clearInv()
	for _, b in ipairs(i2Buttons) do pcall(function() b:Destroy() end) end
	i2Buttons = {}
end

local function clearPlrs()
	for _, b in ipairs(p2Buttons) do pcall(function() b:Destroy() end) end
	p2Buttons = {}
end

local function steal(tool)
	if not tool or not tool.Parent then notify("Stealer", "Item gone"); return end
	local bp = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack")
	pcall(function() tool:Clone().Parent = bp end)
	notify("Stealer", "Stole: " .. tool.Name)
end

local function showInv(target)
	clearInv()
	if not target or not target.Parent then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -6, 0, 20)
		empty.Text = "Player left"
		empty.TextColor3 = Color3.fromRGB(255, 80, 80)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 10
		empty.Parent = iScroll2
		table.insert(i2Buttons, empty)
		return
	end
	local bp = target:FindFirstChildOfClass("Backpack")
	if not bp then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -6, 0, 20)
		empty.Text = "No backpack"
		empty.TextColor3 = Color3.fromRGB(255, 80, 80)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 10
		empty.Parent = iScroll2
		table.insert(i2Buttons, empty)
		return
	end
	local items = {}
	for _, obj in ipairs(bp:GetChildren()) do
		if obj:IsA("Tool") then table.insert(items, obj) end
	end
	if #items == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -6, 0, 20)
		empty.Text = "Empty"
		empty.TextColor3 = Color3.fromRGB(180, 180, 180)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 10
		empty.Parent = iScroll2
		table.insert(i2Buttons, empty)
		return
	end
	for _, tool in ipairs(items) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -6, 0, 22)
		btn.Text = tool.Name
		btn.TextColor3 = Color3.fromRGB(100, 255, 150)
		btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 10
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = iScroll2
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
		table.insert(i2Buttons, btn)
		btn.MouseButton1Click:Connect(function() steal(tool) end)
	end
end

local function refreshPlrs()
	clearPlrs()
	clearInv()
	for _, p in ipairs(Players:GetPlayers()) do
		if p == player then continue end
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -6, 0, 22)
		row.BackgroundTransparency = 1
		row.Parent = pScroll2
		table.insert(p2Buttons, row)
		local nameBtn = Instance.new("TextButton")
		nameBtn.Size = UDim2.new(0.68, 0, 1, 0)
		nameBtn.Text = p.Name
		nameBtn.TextColor3 = Color3.new(1,1,1)
		nameBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		nameBtn.Font = Enum.Font.Gotham
		nameBtn.TextSize = 10
		nameBtn.Parent = row
		Instance.new("UICorner", nameBtn).CornerRadius = UDim.new(0, 3)
		local tpBtn = Instance.new("TextButton")
		tpBtn.Size = UDim2.new(0.30, 0, 1, 0)
		tpBtn.Position = UDim2.new(0.70, 0, 0, 0)
		tpBtn.Text = "TP"
		tpBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
		tpBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
		tpBtn.Font = Enum.Font.GothamBold
		tpBtn.TextSize = 9
		tpBtn.Parent = row
		Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 3)
		nameBtn.MouseButton1Click:Connect(function()
			selectedPlayerName = p.Name
			for _, b in ipairs(p2Buttons) do
				local child = b:FindFirstChildOfClass("TextButton")
				if child then child.BackgroundColor3 = Color3.fromRGB(40, 40, 45) end
			end
			nameBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
			showInv(p)
		end)
		tpBtn.MouseButton1Click:Connect(function()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local tChar = p.Character
			local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
			if hrp and tHRP then
				hrp.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0)
				notify("TP", "Teleported to " .. p.Name)
			else
				notify("TP", p.Name .. " has no character")
			end
		end)
	end
end

Players.PlayerAdded:Connect(refreshPlrs)
Players.PlayerRemoving:Connect(refreshPlrs)
refreshPlrs()

pSearch:GetPropertyChangedSignal("Text"):Connect(function()
	local text = pSearch.Text:lower()
	for _, row in ipairs(p2Buttons) do
		local nameBtn = row:FindFirstChildOfClass("TextButton")
		if nameBtn then
			row.Visible = text == "" or nameBtn.Text:lower():find(text, 1, true) ~= nil
		end
	end
end)

iSearch2:GetPropertyChangedSignal("Text"):Connect(function()
	local text = iSearch2.Text:lower()
	for _, btn in ipairs(i2Buttons) do
		if btn:IsA("TextButton") then
			btn.Visible = text == "" or btn.Text:lower():find(text, 1, true) ~= nil
		elseif btn:IsA("TextLabel") then
			btn.Visible = text == ""
		end
	end
end)


