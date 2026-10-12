-- ============================================================
-- tab_remotes.lua - Remotes scanner  (loaded by main.lua - do not run directly)
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
-- REMOTES TAB
-- ============================================
local rFrame = tabFrames.Remotes
local rStatus = Instance.new("TextLabel")
rStatus.Size = UDim2.new(1, 0, 0, 16)
rStatus.Text = "Press Scan to find remotes"
rStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
rStatus.BackgroundTransparency = 1
rStatus.Font = Enum.Font.Gotham
rStatus.TextSize = 10
rStatus.TextXAlignment = Enum.TextXAlignment.Left
rStatus.Parent = rFrame

local rScan = Instance.new("TextButton")
rScan.Size = UDim2.new(0.32, 0, 0, 22)
rScan.Position = UDim2.new(0, 0, 0, 18)
rScan.Text = "Scan"
rScan.TextColor3 = Color3.new(1,1,1)
rScan.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
rScan.Font = Enum.Font.GothamBold
rScan.TextSize = 11
rScan.Parent = rFrame
Instance.new("UICorner", rScan).CornerRadius = UDim.new(0, 4)

local rClear = Instance.new("TextButton")
rClear.Size = UDim2.new(0.32, 0, 0, 22)
rClear.Position = UDim2.new(0.34, 0, 0, 18)
rClear.Text = "Clear"
rClear.TextColor3 = Color3.new(1,1,1)
rClear.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
rClear.Font = Enum.Font.GothamBold
rClear.TextSize = 11
rClear.Parent = rFrame
Instance.new("UICorner", rClear).CornerRadius = UDim.new(0, 4)

local rTest = Instance.new("TextButton")
rTest.Size = UDim2.new(0.32, 0, 0, 22)
rTest.Position = UDim2.new(0.68, 0, 0, 18)
rTest.Text = "Test All"
rTest.TextColor3 = Color3.new(1,1,1)
rTest.BackgroundColor3 = Color3.fromRGB(80, 20, 80)
rTest.Font = Enum.Font.GothamBold
rTest.TextSize = 11
rTest.Parent = rFrame
Instance.new("UICorner", rTest).CornerRadius = UDim.new(0, 4)

local rSearch = Instance.new("TextBox")
rSearch.Size = UDim2.new(1, 0, 0, 22)
rSearch.Position = UDim2.new(0, 0, 0, 42)
rSearch.PlaceholderText = "Search remotes..."
rSearch.Text = ""
rSearch.TextColor3 = Color3.new(1,1,1)
rSearch.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
rSearch.Font = Enum.Font.Gotham
rSearch.TextSize = 11
rSearch.Parent = rFrame
Instance.new("UICorner", rSearch).CornerRadius = UDim.new(0, 4)

local rScroll = Instance.new("ScrollingFrame")
rScroll.Size = UDim2.new(1, 0, 1, -66)
rScroll.Position = UDim2.new(0, 0, 0, 66)
rScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
rScroll.BorderSizePixel = 0
rScroll.ScrollBarThickness = 4
rScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
rScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
rScroll.Parent = rFrame
Instance.new("UICorner", rScroll).CornerRadius = UDim.new(0, 6)

local rLayout = Instance.new("UIListLayout")
rLayout.Padding = UDim.new(0, 2)
rLayout.Parent = rScroll

local rButtons = {}
local foundRemotes = {}

local function clearRemotes()
	for _, b in ipairs(rButtons) do pcall(function() b:Destroy() end) end
	rButtons = {}
	foundRemotes = {}
	rStatus.Text = "Press Scan to find remotes"
end

local function fireRemote(remote)
	pcall(function()
		if remote:IsA("RemoteEvent") then remote:FireServer("test")
		elseif remote:IsA("RemoteFunction") then remote:InvokeServer("test") end
	end)
end

local function makeRemoteBtn(name, remote)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 22)
	row.BackgroundTransparency = 1
	row.Parent = rScroll
	table.insert(rButtons, row)
	local nameBtn = Instance.new("TextButton")
	nameBtn.Size = UDim2.new(0.72, 0, 1, 0)
	nameBtn.Text = name
	nameBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	nameBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	nameBtn.Font = Enum.Font.Gotham
	nameBtn.TextSize = 9
	nameBtn.TextXAlignment = Enum.TextXAlignment.Left
	nameBtn.Parent = row
	Instance.new("UICorner", nameBtn).CornerRadius = UDim.new(0, 3)
	local fireBtn = Instance.new("TextButton")
	fireBtn.Size = UDim2.new(0.26, 0, 1, 0)
	fireBtn.Position = UDim2.new(0.74, 0, 0, 0)
	fireBtn.Text = "Fire"
	fireBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
	fireBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
	fireBtn.Font = Enum.Font.GothamBold
	fireBtn.TextSize = 9
	fireBtn.Parent = row
	Instance.new("UICorner", fireBtn).CornerRadius = UDim.new(0, 3)
	nameBtn.MouseButton1Click:Connect(function() fireRemote(remote); notify("Remote", "Fired: " .. remote.Name) end)
	fireBtn.MouseButton1Click:Connect(function() fireRemote(remote); notify("Remote", "Fired: " .. remote.Name) end)
end

local function scanRemotes()
	if not UT.beginHeavyWork("Remote scan") then
		rStatus.Text = "Waiting for lag recovery before scanning"
		return
	end
	clearRemotes()
	local found = {}
	local seen = {}
	local services = {game:GetService("ReplicatedStorage"), workspace, game:GetService("Players"), game:GetService("StarterGui"), game:GetService("StarterPack"), game:GetService("Lighting"), game:GetService("SoundService")}
	for _, service in ipairs(services) do
		lagYield()
		pcall(function()
			UT.forEachDescendant(service, function(obj)
				if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not seen[obj]
					and (not UT.safeMode or #found < llCap(LL_REMOTE_CAP)) then
					seen[obj] = true
					table.insert(found, obj)
				end
			end)
		end)
		if UT.cancelHeavyWork then break end
	end
	if UT.cancelHeavyWork then
		rStatus.Text = "Remote scan stopped because lag was detected. Rescan after recovery."
		UT.finishHeavyWork()
		return
	end
	table.sort(found, function(a,b) return a.Name:lower() < b.Name:lower() end)
	local shown = 0
	for i, remote in ipairs(found) do
		if UT.cancelHeavyWork then break end
		if i > llCap(LL_REMOTE_CAP) then break end
		if UT.lowLagMode and i % llBtnStep() == 0 then RunService.Heartbeat:Wait() end
		local path = remote:GetFullName()
		if #path > 45 then path = "..." .. path:sub(-42) end
		makeRemoteBtn("[" .. remote.ClassName .. "] " .. path, remote)
		table.insert(foundRemotes, remote)
		shown = i
	end
	rStatus.Text = "Found " .. shown .. (shown < #found and (" / " .. #found .. " (lag cap)") or " remotes")
	notify("Scanner", "Found " .. shown .. " remotes")
	UT.finishHeavyWork()
end

rScan.MouseButton1Click:Connect(function() task.spawn(scanRemotes) end)
rClear.MouseButton1Click:Connect(clearRemotes)
rTest.MouseButton1Click:Connect(function()
	for _, remote in ipairs(foundRemotes) do fireRemote(remote) end
	notify("Scanner", "Fired all " .. #foundRemotes .. " remotes")
end)

rSearch:GetPropertyChangedSignal("Text"):Connect(function()
	local text = rSearch.Text:lower()
	for _, row in ipairs(rButtons) do
		local nameBtn = row:FindFirstChildOfClass("TextButton")
		if nameBtn then
			row.Visible = text == "" or nameBtn.Text:lower():find(text, 1, true) ~= nil
		end
	end
end)

