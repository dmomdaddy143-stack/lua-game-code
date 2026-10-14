-- ============================================================
-- tab_misc.lua - Utilities  (loaded by main.lua - do not run directly)
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
local toolScanBusy = false
local nextToolScanAt = 0
local scannedTools = setmetatable({}, {__mode = "k"})

local function scanWorldTools(callback)
	local now = os.clock()
	local interval = UT.safeMode and 4 or (UT.lowLagMode and 1 or 0.25)
	if toolScanBusy or now < nextToolScanAt then return end
	nextToolScanAt = now + interval
	toolScanBusy = true
	task.spawn(function()
		pcall(function()
			if UT.forEachDescendant then
				UT.forEachDescendant(workspace, callback)
			else
				for _, obj in ipairs(workspace:GetDescendants()) do callback(obj) end
			end
		end)
		toolScanBusy = false
	end)
end

-- ============================================
-- MISC TAB
-- ============================================
local miscFrame = tabFrames.Misc

local miscTitle = Instance.new("TextLabel")
miscTitle.Size = UDim2.new(1, 0, 0, 18)
miscTitle.Text = "Utilities & Extras"
miscTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
miscTitle.BackgroundTransparency = 1
miscTitle.Font = Enum.Font.GothamBold
miscTitle.TextSize = 12
miscTitle.TextXAlignment = Enum.TextXAlignment.Left
miscTitle.Parent = miscFrame

UT.autoFarmConn = nil
makeToggle(miscFrame, "Auto Farm Items", 20, function(enabled)
	if enabled then
		UT.autoFarmConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local bp = player:FindFirstChildOfClass("Backpack")
			if not bp then return end
			scanWorldTools(function(obj)
				if obj:IsA("Tool") and obj.Parent and obj.Parent ~= bp and obj.Parent ~= char and not scannedTools[obj] then
					local part = obj:FindFirstChildWhichIsA("BasePart")
					if part then
						local dist = (part.Position - hrp.Position).Magnitude
						if dist < 20 then
							local ok = pcall(function() obj:Clone().Parent = bp end)
							if ok then scannedTools[obj] = true end
						end
					end
				end
			end)
		end)
	else
		if UT.autoFarmConn then UT.autoFarmConn:Disconnect(); UT.autoFarmConn = nil end
	end
end)

UT.clickTPConn = nil
makeToggle(miscFrame, "Click TP (Ctrl+Click)", 50, function(enabled)
	if enabled then
		UT.clickTPConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local mouse = player:GetMouse()
					if mouse.Hit then
						hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
						notify("Click TP", "Teleported!")
					end
				end
			end
		end)
	else
		if UT.clickTPConn then UT.clickTPConn:Disconnect(); UT.clickTPConn = nil end
	end
end)

UT.antiAfkConn = nil
makeToggle(miscFrame, "Anti AFK", 80, function(enabled)
	if enabled then
		local vu = game:GetService("VirtualUser")
		UT.antiAfkConn = player.Idled:Connect(function()
			vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			wait(1)
			vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		end)
	else
		if UT.antiAfkConn then UT.antiAfkConn:Disconnect(); UT.antiAfkConn = nil end
	end
end)

UT.autoClickConn = nil
makeToggle(miscFrame, "Auto Clicker", 110, function(enabled)
	if enabled then
		UT.autoClickConn = RunService.Heartbeat:Connect(function()
			local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
			if tool then
				pcall(function() tool:Activate() end)
			end
		end)
	else
		if UT.autoClickConn then UT.autoClickConn:Disconnect(); UT.autoClickConn = nil end
	end
end)

UT.reachConn = nil
local reachOriginalSizes = {}
makeToggle(miscFrame, "Reach", 140, function(enabled)
	if enabled then
		UT.reachConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			if not char then return end
			local tool = char:FindFirstChildOfClass("Tool")
			if tool then
				for _, part in ipairs(tool:GetDescendants()) do
					if part:IsA("BasePart") and (part.Name:lower():find("handle") or part.Name:lower():find("blade") or part.Name:lower():find("hit")) then
						if not reachOriginalSizes[part] then
							reachOriginalSizes[part] = part.Size
						end
						part.Size = Vector3.new(30, 30, 30)
						part.Transparency = 0.9
					end
				end
			end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and (part.Name:lower():find("arm") or part.Name:lower():find("hand") or part.Name:lower():find("leg")) then
					if not reachOriginalSizes[part] then
						reachOriginalSizes[part] = part.Size
					end
					part.Size = Vector3.new(20, 20, 20)
				end
			end
		end)
	else
		if UT.reachConn then UT.reachConn:Disconnect(); UT.reachConn = nil end
		for part, size in pairs(reachOriginalSizes) do
			if part and part.Parent then
				part.Size = size
			end
		end
		reachOriginalSizes = {}
	end
end)

-- Item Magnet
UT.magnetConn = nil
makeToggle(miscFrame, "Item Magnet", 170, function(enabled)
	if enabled then
		UT.magnetConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local bp = player:FindFirstChildOfClass("Backpack")
			if not bp then return end
			scanWorldTools(function(obj)
				if obj:IsA("Tool") and obj.Parent and obj.Parent ~= bp and obj.Parent ~= char and not scannedTools[obj] then
					local part = obj:FindFirstChildWhichIsA("BasePart")
					if part then
						local dist = (part.Position - hrp.Position).Magnitude
						if dist < 30 then
							part.CFrame = hrp.CFrame + Vector3.new(0, 0, -3)
							local ok = pcall(function() obj:Clone().Parent = bp end)
							if ok then scannedTools[obj] = true end
						end
					end
				end
			end)
		end)
	else
		if UT.magnetConn then UT.magnetConn:Disconnect(); UT.magnetConn = nil end
	end
end)

makeToggle(miscFrame, "Low Lag Mode", 200, function(enabled)
	UT.lowLagMode = enabled or UT.laggyPotatoMode
	notify("Low Lag Mode", enabled
		and "ON - scans yield per frame, results capped"
		or "OFF - full scans (may hitch)")
end)

makeToggle(miscFrame, "Potato Mode (laggy PC)", 230, function(enabled)
	UT.potatoMode = enabled or UT.laggyPotatoMode
	notify("Potato Mode", enabled
		and "ON - tiny scans, near-only, extra yields (stacks with Low Lag)"
		or "OFF")
end)

makeToggle(miscFrame, "Laggy Potato Mode", 260, function(enabled)
	UT.laggyPotatoMode = enabled
	UT.lowLagMode = enabled or UT.lowLagMode
	UT.potatoMode = enabled or UT.potatoMode
	notify("Laggy Potato Mode", enabled and "ON - strips heavy visuals and scans to a tiny budget" or "OFF")
end)

local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.new(1, 0, 0, 26)
rejoinBtn.Position = UDim2.new(0, 0, 0, 290)
rejoinBtn.Text = "Rejoin Server"
rejoinBtn.TextColor3 = Color3.new(1,1,1)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.TextSize = 11
rejoinBtn.Parent = miscFrame
Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 4)
rejoinBtn.MouseButton1Click:Connect(function()
	notify("Server", "Rejoining...")
	TeleportService:Teleport(game.PlaceId, player)
end)

local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(1, 0, 0, 26)
hopBtn.Position = UDim2.new(0, 0, 0, 320)
hopBtn.Text = "Server Hop"
hopBtn.TextColor3 = Color3.new(1,1,1)
hopBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 180)
hopBtn.Font = Enum.Font.GothamBold
hopBtn.TextSize = 11
hopBtn.Parent = miscFrame
Instance.new("UICorner", hopBtn).CornerRadius = UDim.new(0, 4)
hopBtn.MouseButton1Click:Connect(function()
	notify("Server", "Hopping servers...")
	local success, result = pcall(function()
		local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
		local response = game:HttpGet(url)
		local data = HttpService:JSONDecode(response)
		if data and data.data then
			for _, server in ipairs(data.data) do
				if server.playing < server.maxPlayers and server.id ~= game.JobId then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
					return
				end
			end
		end
	end)
	if not success then
		notify("Server", "Server hop failed: " .. tostring(result))
	end
end)

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(1, 0, 0, 26)
resetBtn.Position = UDim2.new(0, 0, 0, 320)
resetBtn.Text = "Reset Character"
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 11
resetBtn.Parent = miscFrame
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 4)
resetBtn.MouseButton1Click:Connect(function()
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0 end
	end
end)

-- ============================================
-- LAG SPIKE (normal play, 1s freeze every N seconds)
-- ============================================
UT.lagSpikeOn = false
local lagSpikeDelay = 3

local lagSpikeBox = Instance.new("TextBox")
lagSpikeBox.Size = UDim2.new(1, 0, 0, 20)
lagSpikeBox.Position = UDim2.new(0, 0, 0, 380)
lagSpikeBox.Text = "3"
lagSpikeBox.PlaceholderText = "Seconds between spikes (1-60)"
lagSpikeBox.TextColor3 = Color3.new(1,1,1)
lagSpikeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
lagSpikeBox.Font = Enum.Font.Gotham
lagSpikeBox.TextSize = 11
lagSpikeBox.Parent = miscFrame
Instance.new("UICorner", lagSpikeBox).CornerRadius = UDim.new(0, 4)
lagSpikeBox.FocusLost:Connect(function()
	lagSpikeDelay = math.clamp(tonumber(lagSpikeBox.Text) or 3, 1, 60)
	lagSpikeBox.Text = tostring(lagSpikeDelay)
end)

makeToggle(miscFrame, "Lag Spike", 350, function(enabled)
	UT.lagSpikeOn = enabled
	if enabled then
		task.spawn(function()
			while UT.lagSpikeOn do
				task.wait(lagSpikeDelay)
				if not UT.lagSpikeOn then break end
				-- Freeze for 1 second
				local t0 = tick()
				repeat until tick() - t0 >= 1
			end
		end)
		notify("Lag Spike", "ON - freezes 1s every " .. lagSpikeDelay .. "s")
	else
		notify("Lag Spike", "OFF")
	end
end)


