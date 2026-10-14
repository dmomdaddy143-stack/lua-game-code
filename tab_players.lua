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
local oldCameraType = nil
local oldCameraCFrame = nil
local spectateYaw = 0
local spectatePitch = 0
local spectateMouseHeld = false
local freeCamActive = false
local freeCamPosition
local freeCamYaw = 0
local freeCamPitch = 0
local freeCamKeys = {}
local freeCamMouseHeld = false
local oldMouseBehavior = nil
local oldOcclusionMode = nil
local cameraThroughWalls = false

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
local selectedPlayer
local sortMode = "Name"

local function stopSpectating()
	if UT.spectateConn then
		UT.spectateConn:Disconnect()
		UT.spectateConn = nil
	end
	if UT.spectateInputBeganConn then UT.spectateInputBeganConn:Disconnect(); UT.spectateInputBeganConn = nil end
	if UT.spectateInputEndedConn then UT.spectateInputEndedConn:Disconnect(); UT.spectateInputEndedConn = nil end
	if UT.spectateInputChangedConn then UT.spectateInputChangedConn:Disconnect(); UT.spectateInputChangedConn = nil end
	UserInputService.MouseBehavior = oldMouseBehavior or Enum.MouseBehavior.Default
	if spectateTarget then
		camera.CameraSubject = oldCameraSubject or player.Character
		camera.CameraType = oldCameraType or Enum.CameraType.Custom
		if oldCameraCFrame and camera.CameraType == Enum.CameraType.Scriptable then
			camera.CFrame = oldCameraCFrame
		end
	end
	spectateTarget = nil
	spectateBtn.Text = "Spectate: OFF"
	spectateBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
end

local function setCameraThroughWalls(enabled)
	if enabled then
		local ok, mode = pcall(function() return player.DevCameraOcclusionMode end)
		if not ok then
			notify("Camera", "Occlusion setting is unavailable in this client")
			return false
		end
		oldOcclusionMode = mode
		local setOk = pcall(function()
			player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
		end)
		if not setOk then
			notify("Camera", "Could not change camera occlusion")
			return false
		end
		cameraThroughWalls = true
	else
		if oldOcclusionMode then
			pcall(function() player.DevCameraOcclusionMode = oldOcclusionMode end)
		end
		oldOcclusionMode = nil
		cameraThroughWalls = false
	end
	return true
end

local freeCamButton = Instance.new("TextButton")
freeCamButton.Size = UDim2.new(0, 88, 0, 22)
freeCamButton.Position = UDim2.new(0, 104, 0, 0)
freeCamButton.Text = "Free Cam: OFF"
freeCamButton.TextColor3 = Color3.new(1, 1, 1)
freeCamButton.BackgroundColor3 = Color3.fromRGB(42, 58, 66)
freeCamButton.Font = Enum.Font.GothamBold
freeCamButton.TextSize = 9
freeCamButton.Parent = pFrame
Instance.new("UICorner", freeCamButton).CornerRadius = UDim.new(0, 3)

local cameraWallsButton = Instance.new("TextButton")
cameraWallsButton.Size = UDim2.new(0, 112, 0, 22)
cameraWallsButton.Position = UDim2.new(0, 196, 0, 0)
cameraWallsButton.Text = "Wall Fade: OFF"
cameraWallsButton.TextColor3 = Color3.new(1, 1, 1)
cameraWallsButton.BackgroundColor3 = Color3.fromRGB(42, 58, 66)
cameraWallsButton.Font = Enum.Font.GothamBold
cameraWallsButton.TextSize = 9
cameraWallsButton.Parent = pFrame
Instance.new("UICorner", cameraWallsButton).CornerRadius = UDim.new(0, 3)
if type(UT.addTooltip) == "function" then
	UT.addTooltip(cameraWallsButton, "Use Roblox Invisicam to fade camera obstructions; it does not reveal hidden objects.")
	UT.addTooltip(freeCamButton, "WASD move, Q/E rise or lower, Shift speed up, Ctrl slow down, hold right mouse to look around.")
end

local function stopFreeCam()
	if not freeCamActive then return end
	freeCamActive = false
	if UT.freeCamRenderConn then UT.freeCamRenderConn:Disconnect(); UT.freeCamRenderConn = nil end
	if UT.freeCamInputBeganConn then UT.freeCamInputBeganConn:Disconnect(); UT.freeCamInputBeganConn = nil end
	if UT.freeCamInputChangedConn then UT.freeCamInputChangedConn:Disconnect(); UT.freeCamInputChangedConn = nil end
	if UT.freeCamInputEndedConn then UT.freeCamInputEndedConn:Disconnect(); UT.freeCamInputEndedConn = nil end
	freeCamKeys = {}
	freeCamMouseHeld = false
	UserInputService.MouseBehavior = oldMouseBehavior or Enum.MouseBehavior.Default
	oldMouseBehavior = nil
	camera.CameraType = oldCameraType or Enum.CameraType.Custom
	camera.CameraSubject = oldCameraSubject or player.Character
	freeCamButton.Text = "Free Cam: OFF"
	freeCamButton.TextColor3 = Color3.new(1, 1, 1)
end

local function startFreeCam()
	if UT.spectateConn then stopSpectating() end
	oldCameraType = camera.CameraType
	oldCameraSubject = camera.CameraSubject
	oldCameraCFrame = camera.CFrame
	oldMouseBehavior = UserInputService.MouseBehavior
	freeCamPosition = camera.CFrame.Position
	freeCamPitch, freeCamYaw = camera.CFrame:ToOrientation()
	freeCamActive = true
	camera.CameraType = Enum.CameraType.Scriptable
	freeCamButton.Text = "Free Cam: ON"
	freeCamButton.TextColor3 = Color3.fromRGB(100, 255, 150)
	UT.freeCamInputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			freeCamMouseHeld = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		elseif input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.S
			or input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E
			or input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.LeftControl then
			freeCamKeys[input.KeyCode] = true
		end
	end)
	UT.freeCamInputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			freeCamMouseHeld = false
			UserInputService.MouseBehavior = oldMouseBehavior or Enum.MouseBehavior.Default
		elseif input.KeyCode then
			freeCamKeys[input.KeyCode] = nil
		end
	end)
	UT.freeCamInputChangedConn = UserInputService.InputChanged:Connect(function(input)
		if freeCamMouseHeld and input.UserInputType == Enum.UserInputType.MouseMovement then
			freeCamYaw = freeCamYaw - input.Delta.X * 0.0025
			freeCamPitch = math.clamp(freeCamPitch - input.Delta.Y * 0.0025, -1.5, 1.5)
		end
	end)
	UT.freeCamRenderConn = RunService.RenderStepped:Connect(function(deltaTime)
		local rotation = CFrame.fromOrientation(freeCamPitch, freeCamYaw, 0)
		local direction = Vector3.zero
		if freeCamKeys[Enum.KeyCode.W] then direction = direction + rotation.LookVector end
		if freeCamKeys[Enum.KeyCode.S] then direction = direction - rotation.LookVector end
		if freeCamKeys[Enum.KeyCode.D] then direction = direction + rotation.RightVector end
		if freeCamKeys[Enum.KeyCode.A] then direction = direction - rotation.RightVector end
		if freeCamKeys[Enum.KeyCode.E] then direction = direction + Vector3.yAxis end
		if freeCamKeys[Enum.KeyCode.Q] then direction = direction - Vector3.yAxis end
		local speed = freeCamKeys[Enum.KeyCode.LeftShift] and 80 or 32
		if freeCamKeys[Enum.KeyCode.LeftControl] then speed = 12 end
		if direction.Magnitude > 0 then
			freeCamPosition = freeCamPosition + direction.Unit * speed * deltaTime
		end
		camera.CFrame = CFrame.new(freeCamPosition) * rotation
		camera.Focus = CFrame.new(freeCamPosition + rotation.LookVector * 512)
	end)
end

freeCamButton.MouseButton1Click:Connect(function()
	if freeCamActive then
		stopFreeCam()
	else
		startFreeCam()
	end
end)

cameraWallsButton.MouseButton1Click:Connect(function()
	if setCameraThroughWalls(not cameraThroughWalls) then
		cameraWallsButton.Text = "Wall Fade: " .. (cameraThroughWalls and "ON" or "OFF")
	end
end)

local playerInfo = Instance.new("TextLabel")
playerInfo.Size = UDim2.new(0, 304, 0, 64)
playerInfo.Position = UDim2.new(0, 404, 0, 0)
playerInfo.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
playerInfo.TextColor3 = Color3.fromRGB(215, 215, 220)
playerInfo.Font = Enum.Font.Gotham
playerInfo.TextSize = 10
playerInfo.TextXAlignment = Enum.TextXAlignment.Left
playerInfo.TextYAlignment = Enum.TextYAlignment.Top
playerInfo.TextWrapped = true
playerInfo.Text = "Select a player to inspect their account and character."
playerInfo.Parent = pFrame
Instance.new("UICorner", playerInfo).CornerRadius = UDim.new(0, 4)

local function refreshPlayerInfo()
	local target = selectedPlayer
	if not target or not target.Parent then
		playerInfo.Text = "Select a player to inspect their account and character."
		return
	end
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local healthText = humanoid and (tostring(math.floor(humanoid.Health)) .. "/" .. tostring(math.floor(humanoid.MaxHealth))) or "Unavailable"
	local positionText = root and string.format("%.1f, %.1f, %.1f", root.Position.X, root.Position.Y, root.Position.Z) or "Unavailable"
	playerInfo.Text = target.Name .. " (" .. target.DisplayName .. ")\nUserId: " .. tostring(target.UserId)
		.. "\nHealth: " .. healthText .. "\nPosition: " .. positionText
end

local function copyPlayerValue(value)
	if type(setclipboard) == "function" then
		local ok = pcall(setclipboard, tostring(value))
		if ok then notify("Player Inspector", "Copied to clipboard") return end
	end
	playerInfo.Text = playerInfo.Text .. "\nClipboard API unavailable"
end

local copyNameButton = Instance.new("TextButton")
copyNameButton.Size = UDim2.new(0, 88, 0, 22)
copyNameButton.Position = UDim2.new(0, 404, 0, 70)
copyNameButton.Text = "Copy name"
copyNameButton.TextColor3 = Color3.new(1, 1, 1)
copyNameButton.BackgroundColor3 = Color3.fromRGB(40, 55, 68)
copyNameButton.Font = Enum.Font.GothamBold
copyNameButton.TextSize = 9
copyNameButton.Parent = pFrame
Instance.new("UICorner", copyNameButton).CornerRadius = UDim.new(0, 3)
copyNameButton.MouseButton1Click:Connect(function()
	if selectedPlayer then copyPlayerValue(selectedPlayer.Name) else notify("Player Inspector", "Select a player first") end
end)

local copyIdButton = Instance.new("TextButton")
copyIdButton.Size = UDim2.new(0, 88, 0, 22)
copyIdButton.Position = UDim2.new(0, 496, 0, 70)
copyIdButton.Text = "Copy UserId"
copyIdButton.TextColor3 = Color3.new(1, 1, 1)
copyIdButton.BackgroundColor3 = Color3.fromRGB(40, 55, 68)
copyIdButton.Font = Enum.Font.GothamBold
copyIdButton.TextSize = 9
copyIdButton.Parent = pFrame
Instance.new("UICorner", copyIdButton).CornerRadius = UDim.new(0, 3)
copyIdButton.MouseButton1Click:Connect(function()
	if selectedPlayer then copyPlayerValue(selectedPlayer.UserId) else notify("Player Inspector", "Select a player first") end
end)

local sortButton = Instance.new("TextButton")
sortButton.Size = UDim2.new(0, 62, 0, 22)
sortButton.Position = UDim2.new(0, 588, 0, 70)
sortButton.Text = "Sort: Name"
sortButton.TextColor3 = Color3.new(1, 1, 1)
sortButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
sortButton.Font = Enum.Font.GothamBold
sortButton.TextSize = 8
sortButton.Parent = pFrame
Instance.new("UICorner", sortButton).CornerRadius = UDim.new(0, 3)

local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(0, 52, 0, 22)
refreshButton.Position = UDim2.new(0, 656, 0, 70)
refreshButton.Text = "Refresh"
refreshButton.TextColor3 = Color3.new(1, 1, 1)
refreshButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
refreshButton.Font = Enum.Font.GothamBold
refreshButton.TextSize = 8
refreshButton.Parent = pFrame
Instance.new("UICorner", refreshButton).CornerRadius = UDim.new(0, 3)

spectateBtn.MouseButton1Click:Connect(function()
	if UT.spectateConn then
		stopSpectating()
		notify("Spectate", "Stopped")
	else
		if not selectedPlayerName then
			notify("Spectate", "Click a player name to select first!")
			return
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name == selectedPlayerName and p ~= player then
				if freeCamActive then stopFreeCam() end
				spectateTarget = p
				oldCameraSubject = camera.CameraSubject
				oldCameraType = camera.CameraType
				oldCameraCFrame = camera.CFrame
				oldMouseBehavior = UserInputService.MouseBehavior
				spectatePitch, spectateYaw = camera.CFrame:ToOrientation()
				local distance = 26
				local function updateCam()
					if not spectateTarget or not spectateTarget.Character then
						stopSpectating()
						return
					end
					local targetChar = spectateTarget.Character
					local root = targetChar:FindFirstChild("HumanoidRootPart")
					if not root then return end
					local targetPos = root.Position + Vector3.new(0, 2, 0)
					local orbit = CFrame.fromOrientation(spectatePitch, spectateYaw, 0)
					camera.CameraType = Enum.CameraType.Scriptable
					camera.CFrame = CFrame.lookAt(targetPos - orbit.LookVector * distance, targetPos)
					camera.Focus = CFrame.new(targetPos)
				end
				UT.spectateInputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
						spectateMouseHeld = true
						UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
					end
				end)
				UT.spectateInputEndedConn = UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						spectateMouseHeld = false
						UserInputService.MouseBehavior = oldMouseBehavior or Enum.MouseBehavior.Default
					end
				end)
				UT.spectateInputChangedConn = UserInputService.InputChanged:Connect(function(input)
					if spectateMouseHeld and input.UserInputType == Enum.UserInputType.MouseMovement then
						spectateYaw = spectateYaw - input.Delta.X * 0.0025
						spectatePitch = math.clamp(spectatePitch - input.Delta.Y * 0.0025, -1.3, 1.3)
					end
				end)
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

UT.cleanupPlayerCamera = function()
	stopFreeCam()
	if spectateTarget then stopSpectating() end
	if cameraThroughWalls then setCameraThroughWalls(false) end
	UserInputService.MouseBehavior = oldMouseBehavior or Enum.MouseBehavior.Default
end

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
	local targets = {}
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= player then table.insert(targets, target) end
	end
	if sortMode == "Distance" then
		local ownRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		table.sort(targets, function(first, second)
			local firstRoot = first.Character and first.Character:FindFirstChild("HumanoidRootPart")
			local secondRoot = second.Character and second.Character:FindFirstChild("HumanoidRootPart")
			local firstDistance = ownRoot and firstRoot and (ownRoot.Position - firstRoot.Position).Magnitude or math.huge
			local secondDistance = ownRoot and secondRoot and (ownRoot.Position - secondRoot.Position).Magnitude or math.huge
			return firstDistance == secondDistance and first.Name:lower() < second.Name:lower() or firstDistance < secondDistance
		end)
	else
		table.sort(targets, function(first, second) return first.Name:lower() < second.Name:lower() end)
	end
	for _, p in ipairs(targets) do
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
			selectedPlayer = p
			refreshPlayerInfo()
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
				local ok, reason = UT.safeTeleportTo(tHRP.Position + tHRP.CFrame.LookVector * 4)
				notify("TP", ok and ("Teleported near " .. p.Name) or reason)
			else
				notify("TP", p.Name .. " has no character")
			end
		end)
	end
end

Players.PlayerAdded:Connect(refreshPlrs)
Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == selectedPlayer then
		selectedPlayer = nil
		selectedPlayerName = nil
		refreshPlayerInfo()
	end
	if leavingPlayer == spectateTarget then stopSpectating() end
	refreshPlrs()
end)
sortButton.MouseButton1Click:Connect(function()
	sortMode = sortMode == "Name" and "Distance" or "Name"
	sortButton.Text = "Sort: " .. sortMode
	refreshPlrs()
end)
refreshButton.MouseButton1Click:Connect(refreshPlrs)
UT.playerInfoConn = RunService.Heartbeat:Connect(function(deltaTime)
	UT.playerInfoElapsed = (UT.playerInfoElapsed or 0) + deltaTime
	if UT.playerInfoElapsed >= 0.5 then
		UT.playerInfoElapsed = 0
		refreshPlayerInfo()
	end
end)
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


