-- ============================================================
-- tab_items.lua - Item grabber + saved items  (loaded by main.lua - do not run directly)
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
local isInChar = UT.isInChar
-- ============================================
-- ITEMS TAB
-- ============================================
local iFrame = tabFrames.Items
local iStatus = Instance.new("TextLabel")
iStatus.Size = UDim2.new(1, 0, 0, 16)
iStatus.Text = "Press Scan to find items"
iStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
iStatus.BackgroundTransparency = 1
iStatus.Font = Enum.Font.Gotham
iStatus.TextSize = 10
iStatus.TextXAlignment = Enum.TextXAlignment.Left
iStatus.Parent = iFrame

local iScan = Instance.new("TextButton")
iScan.Size = UDim2.new(0.48, 0, 0, 22)
iScan.Position = UDim2.new(0, 0, 0, 18)
iScan.Text = "Scan"
iScan.TextColor3 = Color3.new(1,1,1)
iScan.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
iScan.Font = Enum.Font.GothamBold
iScan.TextSize = 11
iScan.Parent = iFrame
Instance.new("UICorner", iScan).CornerRadius = UDim.new(0, 4)

local iClear = Instance.new("TextButton")
iClear.Size = UDim2.new(0.48, 0, 0, 22)
iClear.Position = UDim2.new(0.52, 0, 0, 18)
iClear.Text = "Clear"
iClear.TextColor3 = Color3.new(1,1,1)
iClear.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
iClear.Font = Enum.Font.GothamBold
iClear.TextSize = 11
iClear.Parent = iFrame
Instance.new("UICorner", iClear).CornerRadius = UDim.new(0, 4)

local iSearch = Instance.new("TextBox")
iSearch.Size = UDim2.new(1, 0, 0, 22)
iSearch.Position = UDim2.new(0, 0, 0, 66)
iSearch.PlaceholderText = "Search items..."
iSearch.Text = ""
iSearch.TextColor3 = Color3.new(1,1,1)
iSearch.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
iSearch.Font = Enum.Font.Gotham
iSearch.TextSize = 11
iSearch.Parent = iFrame
Instance.new("UICorner", iSearch).CornerRadius = UDim.new(0, 4)

local iScroll = Instance.new("ScrollingFrame")
iScroll.Size = UDim2.new(1, 0, 0.40, -50)
iScroll.Position = UDim2.new(0, 0, 0, 90)
iScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
iScroll.BorderSizePixel = 0
iScroll.ScrollBarThickness = 4
iScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
iScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
iScroll.Parent = iFrame
Instance.new("UICorner", iScroll).CornerRadius = UDim.new(0, 6)

local iLayout = Instance.new("UIListLayout")
iLayout.Padding = UDim.new(0, 2)
iLayout.Parent = iScroll

local iButtons = {}
local allTools = {}

-- ============================================
-- SAVED ITEMS SYSTEM
-- Auto-saves tools when you pick them up
-- ============================================
local savedItemsLabel = Instance.new("TextLabel")
savedItemsLabel.Size = UDim2.new(1, 0, 0, 16)
savedItemsLabel.Position = UDim2.new(0, 0, 0.40, -55)
savedItemsLabel.Text = "Saved Items (auto-saved when picked up)"
savedItemsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
savedItemsLabel.BackgroundTransparency = 1
savedItemsLabel.Font = Enum.Font.GothamBold
savedItemsLabel.TextSize = 10
savedItemsLabel.TextXAlignment = Enum.TextXAlignment.Left
savedItemsLabel.Parent = iFrame

local savedScroll = Instance.new("ScrollingFrame")
savedScroll.Size = UDim2.new(1, 0, 0.60, -40)
savedScroll.Position = UDim2.new(0, 0, 0.40, -38)
savedScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
savedScroll.BorderSizePixel = 0
savedScroll.ScrollBarThickness = 4
savedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
savedScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
savedScroll.Parent = iFrame
Instance.new("UICorner", savedScroll).CornerRadius = UDim.new(0, 6)

local savedLayout = Instance.new("UIListLayout")
savedLayout.Padding = UDim.new(0, 2)
savedLayout.Parent = savedScroll

-- Hidden storage for saved item clones
local savedStorage = Instance.new("Folder")
savedStorage.Name = "SavedItemStorage"
savedStorage.Parent = gui

local savedItems = {} -- name -> {clone, button}
local savedButtons = {}

local function deepCloneTool(tool)
	-- Clone the tool and preserve all descendants
	local clone = tool:Clone()
	if clone then
		-- Remove any scripts that might cause issues when stored
		for _, desc in ipairs(clone:GetDescendants()) do
			if desc:IsA("Script") or desc:IsA("LocalScript") then
				-- Keep scripts but disable them while stored
				pcall(function() desc.Disabled = true end)
			end
		end
		clone.Parent = savedStorage
		return clone
	end
	return nil
end

local function saveTool(tool)
	if not tool or not tool:IsA("Tool") then return end
	local name = tool.Name
	-- Remove old save if exists
	if savedItems[name] then
		pcall(function() savedItems[name].clone:Destroy() end)
		if savedItems[name].button then
			pcall(function() savedItems[name].button:Destroy() end)
		end
	end
	local clone = deepCloneTool(tool)
	if clone then
		savedItems[name] = {clone = clone, originalName = name}
		-- Create or update button
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -6, 0, 22)
		btn.Text = name .. " [RESTORE]"
		btn.TextColor3 = Color3.fromRGB(255, 220, 80)
		btn.BackgroundColor3 = Color3.fromRGB(45, 35, 20)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = savedScroll
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
		btn.MouseButton1Click:Connect(function()
			local bp = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack")
			local stored = savedItems[name]
			if stored and stored.clone then
				local newClone = stored.clone:Clone()
				if newClone then
					-- Re-enable any scripts
					for _, desc in ipairs(newClone:GetDescendants()) do
						if desc:IsA("Script") or desc:IsA("LocalScript") then
							pcall(function() desc.Disabled = false end)
						end
					end
					newClone.Parent = bp
					notify("Saved Items", "Restored: " .. name)
				end
			else
				notify("Saved Items", "Save lost for: " .. name)
			end
		end)
		savedItems[name].button = btn
		table.insert(savedButtons, btn)
	end
end

-- Hook into backpack and character to auto-save
local function hookToolSaving(container)
	if not container then return end
	container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			-- Wait a frame for tool to fully initialize
			task.wait(0.1)
			if child.Parent then
				saveTool(child)
				notify("Auto-Save", "Saved: " .. child.Name)
			end
		end
	end)
	-- Save existing tools
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") then
			saveTool(child)
		end
	end
end

-- Hook current backpack and character
local bp = player:FindFirstChildOfClass("Backpack")
if bp then hookToolSaving(bp) end
local char = player.Character
if char then hookToolSaving(char) end

-- Hook future characters
player.CharacterAdded:Connect(function(newChar)
	task.wait(0.5)
	hookToolSaving(newChar)
	local newBp = player:FindFirstChildOfClass("Backpack")
	if newBp then hookToolSaving(newBp) end
end)

-- Also hook backpack when it appears
player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		hookToolSaving(child)
	end
end)

-- Manual save button for items in the found list
local function saveFoundItem(tool)
	saveTool(tool)
end

local function clearItems()
	for _, b in ipairs(iButtons) do pcall(function() b:Destroy() end) end
	iButtons = {}
	allTools = {}
	iStatus.Text = "Press Scan to find items"
end

local function clearSavedItems()
	for name, data in pairs(savedItems) do
		pcall(function() data.clone:Destroy() end)
		pcall(function() data.button:Destroy() end)
	end
	savedItems = {}
	for _, b in ipairs(savedButtons) do
		pcall(function() b:Destroy() end)
	end
	savedButtons = {}
end

local function grabItem(tool)
	if not tool or not tool.Parent then notify("Grabber", "Item gone"); return end
	local bp = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack")
	local ok, clone = pcall(function() return tool:Clone() end)
	if ok and clone then
		clone.Parent = bp
		-- Auto-save the grabbed item
		task.wait(0.1)
		saveTool(clone)
		notify("Grabber", "Got & Saved: " .. tool.Name)
	else
		notify("Grabber", "Got: " .. tool.Name)
	end
end

local function makeItemBtn(name, tool)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 22)
	row.BackgroundTransparency = 1
	row.Parent = iScroll
	table.insert(iButtons, row)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.52, 0, 1, 0)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(100, 255, 150)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 10
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = row
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)

	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(0.20, 0, 1, 0)
	saveBtn.Position = UDim2.new(0.54, 0, 0, 0)
	saveBtn.Text = "Save"
	saveBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
	saveBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 15)
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.TextSize = 9
	saveBtn.Parent = row
	Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 3)

	local tpBtn2 = Instance.new("TextButton")
	tpBtn2.Size = UDim2.new(0.22, 0, 1, 0)
	tpBtn2.Position = UDim2.new(0.76, 0, 0, 0)
	tpBtn2.Text = "TP"
	tpBtn2.TextColor3 = Color3.fromRGB(255, 200, 0)
	tpBtn2.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
	tpBtn2.Font = Enum.Font.GothamBold
	tpBtn2.TextSize = 9
	tpBtn2.Parent = row
	Instance.new("UICorner", tpBtn2).CornerRadius = UDim.new(0, 3)

	btn.MouseButton1Click:Connect(function() grabItem(tool) end)
	saveBtn.MouseButton1Click:Connect(function()
		local ok, clone = pcall(function() return tool:Clone() end)
		if ok and clone then saveTool(clone) end
		notify("Saver", "Saved: " .. tool.Name)
	end)
	tpBtn2.MouseButton1Click:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local part = tool:FindFirstChildWhichIsA("BasePart")
		if part then
			hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
			notify("Item TP", tool.Name)
		else
			notify("Item TP", "No part found")
		end
	end)
end


local function scanItems()
	clearItems()
	local found = {}
	local seen = {}
	local locations = {workspace, game:GetService("ReplicatedStorage"), game:GetService("ServerStorage"), game:GetService("StarterPack"), game:GetService("StarterGear"), game:GetService("Lighting")}
	for _, loc in ipairs(locations) do
		lagYield()
		local ok, stuff = pcall(function() return loc:GetDescendants() end)
		if ok then
			for i, obj in ipairs(stuff) do
				if UT.lowLagMode and i % llYieldStep() == 0 then RunService.Heartbeat:Wait() end
				if obj:IsA("Tool") and not isInChar(obj) and not seen[obj] then
					seen[obj] = true
					table.insert(found, {tool = obj, where = loc.Name})
				end
			end
		end
	end
	table.sort(found, function(a,b) return a.tool.Name:lower() < b.tool.Name:lower() end)
	local shown = 0
	for i, entry in ipairs(found) do
		if i > llCap(LL_ITEM_CAP) then break end
		if UT.lowLagMode and i % llBtnStep() == 0 then RunService.Heartbeat:Wait() end
		allTools[#allTools+1] = entry.tool
		makeItemBtn(entry.tool.Name .. " (" .. entry.where .. ")", entry.tool)
		shown = i
	end
	iStatus.Text = "Found " .. shown .. (shown < #found and (" / " .. #found .. " (lag cap)") or " items")
	notify("Grabber", "Found " .. shown .. " items")
end

iScan.MouseButton1Click:Connect(function() task.spawn(scanItems) end)
iClear.MouseButton1Click:Connect(clearItems)

local iClearSaved = Instance.new("TextButton")
iClearSaved.Size = UDim2.new(0.48, 0, 0, 22)
iClearSaved.Position = UDim2.new(0.52, 0, 0, 42)
iClearSaved.Text = "Clear Saved"
iClearSaved.TextColor3 = Color3.new(1,1,1)
iClearSaved.BackgroundColor3 = Color3.fromRGB(180, 100, 30)
iClearSaved.Font = Enum.Font.GothamBold
iClearSaved.TextSize = 11
iClearSaved.Parent = iFrame
Instance.new("UICorner", iClearSaved).CornerRadius = UDim.new(0, 4)
iClearSaved.MouseButton1Click:Connect(clearSavedItems)

iSearch:GetPropertyChangedSignal("Text"):Connect(function()
	local text = iSearch.Text:lower()
	for _, row in ipairs(iButtons) do
		local btn = row:FindFirstChildOfClass("TextButton")
		if btn then
			row.Visible = text == "" or btn.Text:lower():find(text, 1, true) ~= nil
		end
	end
end)

