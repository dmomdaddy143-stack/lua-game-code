-- ============================================================
-- tab_entities.lua - Entity scanner + ESP  (loaded by main.lua - do not run directly)
-- ============================================================
local UT = ...
local Players = UT.Players
local CollectionService = game:GetService("CollectionService")
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
local drawingSupported = UT.drawingSupported
local isPlayerModel = UT.isPlayerModel
local isPlayerRelated = UT.isPlayerRelated
local getEntityPrimaryPart = UT.getEntityPrimaryPart

local function hasEntityTag(instance)
	for _, tag in ipairs(CollectionService:GetTags(instance)) do
		local lowered = tag:lower()
		if lowered:find("npc", 1, true) or lowered:find("enemy", 1, true)
			or lowered:find("entity", 1, true) or lowered:find("mob", 1, true)
			or lowered:find("monster", 1, true) then
			return true
		end
	end
	return false
end
-- ============================================
-- ENTITIES TAB (FIXED ESP + SCANNING)
-- ============================================
local eFrame = tabFrames.Entities

local eStatus = Instance.new("TextLabel")
eStatus.Size = UDim2.new(1, 0, 0, 16)
eStatus.Text = "Press Scan to find entities"
eStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
eStatus.BackgroundTransparency = 1
eStatus.Font = Enum.Font.Gotham
eStatus.TextSize = 10
eStatus.TextXAlignment = Enum.TextXAlignment.Left
eStatus.Parent = eFrame

local eScan = Instance.new("TextButton")
eScan.Size = UDim2.new(0.18, 0, 0, 22)
eScan.Position = UDim2.new(0, 0, 0, 18)
eScan.Text = "Scan"
eScan.TextColor3 = Color3.new(1,1,1)
eScan.BackgroundColor3 = Color3.fromRGB(255, 80, 0)
eScan.Font = Enum.Font.GothamBold
eScan.TextSize = 11
eScan.Parent = eFrame
Instance.new("UICorner", eScan).CornerRadius = UDim.new(0, 4)

local eClear = Instance.new("TextButton")
eClear.Size = UDim2.new(0.18, 0, 0, 22)
eClear.Position = UDim2.new(0.20, 0, 0, 18)
eClear.Text = "Clear"
eClear.TextColor3 = Color3.new(1,1,1)
eClear.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
eClear.Font = Enum.Font.GothamBold
eClear.TextSize = 11
eClear.Parent = eFrame
Instance.new("UICorner", eClear).CornerRadius = UDim.new(0, 4)

local eHitboxBtn = Instance.new("TextButton")
eHitboxBtn.Size = UDim2.new(0.18, 0, 0, 22)
eHitboxBtn.Position = UDim2.new(0.40, 0, 0, 18)
eHitboxBtn.Text = "Expand All"
eHitboxBtn.TextColor3 = Color3.new(1,1,1)
eHitboxBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
eHitboxBtn.Font = Enum.Font.GothamBold
eHitboxBtn.TextSize = 11
eHitboxBtn.Parent = eFrame
Instance.new("UICorner", eHitboxBtn).CornerRadius = UDim.new(0, 4)

local repelBtn = Instance.new("TextButton")
repelBtn.Size = UDim2.new(0.18, 0, 0, 22)
repelBtn.Position = UDim2.new(0.60, 0, 0, 18)
repelBtn.Text = "Repel"
repelBtn.TextColor3 = Color3.new(1,1,1)
repelBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 160)
repelBtn.Font = Enum.Font.GothamBold
repelBtn.TextSize = 11
repelBtn.Parent = eFrame
Instance.new("UICorner", repelBtn).CornerRadius = UDim.new(0, 4)

local eEspBtn = Instance.new("TextButton")
eEspBtn.Size = UDim2.new(0.18, 0, 0, 22)
eEspBtn.Position = UDim2.new(0.80, 0, 0, 18)
eEspBtn.Text = "ESP: OFF"
eEspBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
eEspBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 60)
eEspBtn.Font = Enum.Font.GothamBold
eEspBtn.TextSize = 11
eEspBtn.Parent = eFrame
Instance.new("UICorner", eEspBtn).CornerRadius = UDim.new(0, 4)

local eSearch = Instance.new("TextBox")
eSearch.Size = UDim2.new(1, 0, 0, 22)
eSearch.Position = UDim2.new(0, 0, 0, 42)
eSearch.PlaceholderText = "Search entities..."
eSearch.Text = ""
eSearch.TextColor3 = Color3.new(1,1,1)
eSearch.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
eSearch.Font = Enum.Font.Gotham
eSearch.TextSize = 11
eSearch.Parent = eFrame
Instance.new("UICorner", eSearch).CornerRadius = UDim.new(0, 4)

local eScroll = Instance.new("ScrollingFrame")
eScroll.Size = UDim2.new(1, 0, 1, -66)
eScroll.Position = UDim2.new(0, 0, 0, 66)
eScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
eScroll.BorderSizePixel = 0
eScroll.ScrollBarThickness = 4
eScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
eScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
eScroll.Parent = eFrame
Instance.new("UICorner", eScroll).CornerRadius = UDim.new(0, 6)

local eLayout = Instance.new("UIListLayout")
eLayout.Padding = UDim.new(0, 2)
eLayout.Parent = eScroll

local eButtons = {}
local foundEntities = {}
local entityHitboxes = {}
local entityEspEnabled = false
UT.entityDrawings = {}

local function clearEntities()
	for _, b in ipairs(eButtons) do pcall(function() b:Destroy() end) end
	eButtons = {}
	foundEntities = {}
	for _, d in pairs(UT.entityDrawings) do
		pcall(function() d.Box:Remove() end)
		pcall(function() d.Name:Remove() end)
		pcall(function() d.Tracer:Remove() end)
	end
	UT.entityDrawings = {}
end




local function expandEntityHitbox(model)
	if not model or not model.Parent then return end
	local parts = {}
	if model:IsA("BasePart") then
		parts = {model}
	else
		parts = model:GetDescendants()
	end
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			if not entityHitboxes[part] then
				entityHitboxes[part] = {
					Size = part.Size, 
					Transparency = part.Transparency, 
					Material = part.Material, 
					Color = part.Color,
					CanCollide = part.CanCollide
				}
			end
			part.Size = Vector3.new(10, 10, 10)
			part.Transparency = 0.5
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(255, 80, 0)
			part.CanCollide = false
		end
	end
end

local function updateEntityEsp()
	if not drawingSupported then return end
	if not entityEspEnabled then
		for _, d in pairs(UT.entityDrawings) do
			d.Box.Visible = false
			d.Name.Visible = false
			d.Tracer.Visible = false
		end
		return
	end

	for model, objs in pairs(UT.entityDrawings) do
		if not model or not model.Parent then
			pcall(function() objs.Box:Remove() end)
			pcall(function() objs.Name:Remove() end)
			pcall(function() objs.Tracer:Remove() end)
			UT.entityDrawings[model] = nil
			continue
		end

		local primary = getEntityPrimaryPart(model)
		if not primary then
			objs.Box.Visible = false
			objs.Name.Visible = false
			objs.Tracer.Visible = false
			continue
		end

		local pos, vis = camera:WorldToViewportPoint(primary.Position)
		if vis and camera.ViewportSize.X > 0 then
			local dist = (primary.Position - camera.CFrame.Position).Magnitude
			local size = math.clamp(4000 / dist, 20, 250)

			objs.Box.Size = Vector2.new(size, size * 1.5)
			objs.Box.Position = Vector2.new(pos.X - size/2, pos.Y - size * 0.75)
			objs.Box.Visible = true

			objs.Name.Position = Vector2.new(pos.X, pos.Y - size * 0.75 - 15)
			objs.Name.Text = model.Name
			objs.Name.Visible = true

			objs.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
			objs.Tracer.To = Vector2.new(pos.X, pos.Y)
			objs.Tracer.Visible = true
		else
			objs.Box.Visible = false
			objs.Name.Visible = false
			objs.Tracer.Visible = false
		end
	end
end

local function createEntityDrawing(model)
	if not drawingSupported or UT.entityDrawings[model] then return end
	local box = Drawing.new("Square")
	box.Thickness = 1.5
	box.Filled = false
	box.Visible = false
	box.Color = Color3.fromRGB(255, 120, 0)
	local name = Drawing.new("Text")
	name.Size = 12
	name.Center = true
	name.Outline = true
	name.Visible = false
	name.Color = Color3.fromRGB(255, 180, 50)
	local tracer = Drawing.new("Line")
	tracer.Thickness = 1
	tracer.Visible = false
	tracer.Color = Color3.fromRGB(255, 120, 0)
	UT.entityDrawings[model] = {Box = box, Name = name, Tracer = tracer}
end

local function makeEntityBtn(name, model)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 22)
	row.BackgroundTransparency = 1
	row.Parent = eScroll
	table.insert(eButtons, row)
	local nameBtn = Instance.new("TextButton")
	nameBtn.Size = UDim2.new(0.45, 0, 1, 0)
	nameBtn.Text = name
	nameBtn.TextColor3 = Color3.fromRGB(255, 120, 50)
	nameBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	nameBtn.Font = Enum.Font.Gotham
	nameBtn.TextSize = 9
	nameBtn.TextXAlignment = Enum.TextXAlignment.Left
	nameBtn.Parent = row
	Instance.new("UICorner", nameBtn).CornerRadius = UDim.new(0, 3)
	local tpBtn = Instance.new("TextButton")
	tpBtn.Size = UDim2.new(0.16, 0, 1, 0)
	tpBtn.Position = UDim2.new(0.47, 0, 0, 0)
	tpBtn.Text = "TP"
	tpBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
	tpBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
	tpBtn.Font = Enum.Font.GothamBold
	tpBtn.TextSize = 9
	tpBtn.Parent = row
	Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 3)
	local hbBtn = Instance.new("TextButton")
	hbBtn.Size = UDim2.new(0.16, 0, 1, 0)
	hbBtn.Position = UDim2.new(0.65, 0, 0, 0)
	hbBtn.Text = "Hitbox"
	hbBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	hbBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
	hbBtn.Font = Enum.Font.GothamBold
	hbBtn.TextSize = 9
	hbBtn.Parent = row
	Instance.new("UICorner", hbBtn).CornerRadius = UDim.new(0, 3)
	local bringBtn = Instance.new("TextButton")
	bringBtn.Size = UDim2.new(0.16, 0, 1, 0)
	bringBtn.Position = UDim2.new(0.83, 0, 0, 0)
	bringBtn.Text = "Bring"
	bringBtn.TextColor3 = Color3.fromRGB(100, 255, 150)
	bringBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
	bringBtn.Font = Enum.Font.GothamBold
	bringBtn.TextSize = 9
	bringBtn.Parent = row
	Instance.new("UICorner", bringBtn).CornerRadius = UDim.new(0, 3)
	nameBtn.MouseButton1Click:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local target = getEntityPrimaryPart(model)
		if hrp and target then
			local ok, reason = UT.safeTeleportTo(target.Position + target.CFrame.LookVector * 4)
			notify("Entity", ok and ("Teleported near " .. model.Name) or reason)
		else
			notify("Entity", "No valid part found")
		end
	end)
	tpBtn.MouseButton1Click:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local target = getEntityPrimaryPart(model)
		if hrp and target then
			local ok, reason = UT.safeTeleportTo(target.Position + target.CFrame.LookVector * 4)
			notify("Entity", ok and ("Teleported near " .. model.Name) or reason)
		else
			notify("Entity", "No valid part found")
		end
	end)
	hbBtn.MouseButton1Click:Connect(function()
		expandEntityHitbox(model)
		notify("Hitbox", "Expanded: " .. model.Name)
	end)
	bringBtn.MouseButton1Click:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local target = getEntityPrimaryPart(model)
		if hrp and target then
			target.CFrame = hrp.CFrame + Vector3.new(0, 0, -5)
			notify("Bring", "Brought " .. model.Name)
		else
			notify("Bring", "No valid part found")
		end
	end)
end

local function scanEntities()
	if not UT.beginHeavyWork("Entity scan") then
		eStatus.Text = "Waiting for lag recovery before scanning"
		return
	end
	eStatus.Text = "Scanning workspace..."
	clearEntities()
	local found = {}
	local seen = {}

	if UT.safeMode then
		local safeRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local scanOk, scanError = pcall(function()
			UT.forEachDescendant(workspace, function(obj)
				local candidate = false
				if obj:IsA("Model") and not isPlayerModel(obj) and not isPlayerRelated(obj) then
					local nameLower = obj.Name:lower()
					local hasHumanoid = obj:FindFirstChildOfClass("Humanoid") ~= nil
					local hasRoot = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
					local enemyLike = nameLower:find("enemy") or nameLower:find("boss") or nameLower:find("npc")
						or nameLower:find("mob") or nameLower:find("monster") or nameLower:find("guard")
						or nameLower:find("bandit") or nameLower:find("zombie") or nameLower:find("skeleton")
						or nameLower:find("golem") or nameLower:find("villain") or nameLower:find("target")
						or nameLower:find("dummy") or nameLower:find("training")
					local hasHealth = obj:GetAttribute("Health") or obj:GetAttribute("HP") or obj:GetAttribute("MaxHealth")
					candidate = (hasHumanoid or hasRoot or enemyLike or hasHealth or hasEntityTag(obj))
						and obj:FindFirstChildWhichIsA("BasePart") ~= nil
				elseif obj:IsA("BasePart") and not isPlayerRelated(obj) then
					local nameLower = obj.Name:lower()
					candidate = nameLower:find("hitbox") or nameLower:find("hurtbox")
						or nameLower:find("enemybox") or nameLower:find("damage")
						or nameLower:find("weakpoint") or nameLower:find("critical")
						or nameLower:find("attackbox")
				end
				if candidate and (not safeRoot or (getEntityPrimaryPart(obj).Position - safeRoot.Position).Magnitude < 300)
					and #found < llCap(LL_ENTITY_CAP) then
					seen[obj] = true
					table.insert(found, obj)
				end
			end)
		end)
		if not scanOk then
			eStatus.Text = "Entity scan failed: " .. tostring(scanError)
			UT.finishHeavyWork()
			return
		end
	else
	local ok, descendants = pcall(function() return workspace:GetDescendants() end)
	if ok then
		if UT.lowLagMode then
			-- ONE combined pass instead of 4 separate GetDescendants passes
			for i, obj in ipairs(descendants) do
				if i % (UT.potatoMode and 250 or 500) == 0 then RunService.Heartbeat:Wait() end
				if obj:IsA("Model") and not seen[obj] and not isPlayerModel(obj) and not isPlayerRelated(obj) then
					local nameLower = obj.Name:lower()
					local hum = obj:FindFirstChildOfClass("Humanoid")
					local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
					local enemyLike = nameLower:find("enemy") or nameLower:find("boss")
						or nameLower:find("npc") or nameLower:find("mob")
						or nameLower:find("monster") or nameLower:find("guard")
						or nameLower:find("bandit") or nameLower:find("zombie")
						or nameLower:find("skeleton") or nameLower:find("golem")
						or nameLower:find("villain") or nameLower:find("target")
						or nameLower:find("hitbox") or nameLower:find("hurtbox")
						or nameLower:find("dummy") or nameLower:find("training")
					local attrHealth = obj:GetAttribute("Health") or obj:GetAttribute("HP") or obj:GetAttribute("MaxHealth")
					if (hum or hrp or enemyLike or attrHealth or hasEntityTag(obj)) and obj:FindFirstChildWhichIsA("BasePart") then
						seen[obj] = true
						table.insert(found, obj)
					end
				elseif obj:IsA("BasePart") and not seen[obj] and not isPlayerRelated(obj) then
					local nameLower = obj.Name:lower()
					if nameLower:find("hitbox") or nameLower:find("hurtbox")
						or nameLower:find("enemybox") or nameLower:find("damage")
						or nameLower:find("weakpoint") or nameLower:find("critical")
						or nameLower:find("attackbox") then
						seen[obj] = true
						table.insert(found, obj)
					end
				end
			end
		else
			-- Layer 1: Models with Humanoid
			for _, obj in ipairs(descendants) do
				if obj:IsA("Model") and not seen[obj] and not isPlayerModel(obj) then
					local hum = obj:FindFirstChildOfClass("Humanoid")
					local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
					if hum or hrp or hasEntityTag(obj) then
						seen[obj] = true
						table.insert(found, obj)
					end
				end
			end

			-- Layer 2: Enemy-like names
			for _, obj in ipairs(descendants) do
				if obj:IsA("Model") and not seen[obj] and not isPlayerModel(obj) and not isPlayerRelated(obj) then
					local nameLower = obj.Name:lower()
					local isEnemyLike = nameLower:find("enemy") or nameLower:find("boss")
						or nameLower:find("npc") or nameLower:find("mob")
						or nameLower:find("monster") or nameLower:find("guard")
						or nameLower:find("bandit") or nameLower:find("zombie")
						or nameLower:find("skeleton") or nameLower:find("golem")
						or nameLower:find("villain") or nameLower:find("target")
						or nameLower:find("hitbox") or nameLower:find("hurtbox")
						or nameLower:find("dummy") or nameLower:find("training")
					if isEnemyLike or hasEntityTag(obj) then
						local hasPart = obj:FindFirstChildWhichIsA("BasePart") ~= nil
						if hasPart then
							seen[obj] = true
							table.insert(found, obj)
						end
					end
				end
			end

			-- Layer 3: Standalone hitbox parts
			for _, obj in ipairs(descendants) do
				if obj:IsA("BasePart") and not seen[obj] and not isPlayerRelated(obj) then
					local nameLower = obj.Name:lower()
					local isHitbox = nameLower:find("hitbox") or nameLower:find("hurtbox")
						or nameLower:find("enemybox") or nameLower:find("damage")
						or nameLower:find("weakpoint") or nameLower:find("critical")
						or nameLower:find("attackbox")
					if isHitbox then
						seen[obj] = true
						table.insert(found, obj)
					end
				end
			end

			-- Layer 4: Any model with BasePart that has health-related attributes
			for _, obj in ipairs(descendants) do
				if obj:IsA("Model") and not seen[obj] and not isPlayerModel(obj) and not isPlayerRelated(obj) then
					if obj:GetAttribute("Health") or obj:GetAttribute("HP") or obj:GetAttribute("MaxHealth") then
						local hasPart = obj:FindFirstChildWhichIsA("BasePart") ~= nil
						if hasPart then
							seen[obj] = true
							table.insert(found, obj)
						end
					end
				end
			end
		end
	else
		eStatus.Text = "Entity scan failed: " .. tostring(descendants)
		UT.finishHeavyWork()
		return
	end
	end

	if UT.potatoMode then
		local hrpP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrpP then
			local filtered = {}
			for _, m in ipairs(found) do
				if UT.cancelHeavyWork then break end
				local pp = getEntityPrimaryPart(m)
				if pp and (pp.Position - hrpP.Position).Magnitude < 400 then
					table.insert(filtered, m)
				end
			end
			if UT.cancelHeavyWork then
				eStatus.Text = "Entity scan stopped because lag was detected. Rescan after recovery."
				UT.finishHeavyWork()
				return
			end
			found = filtered
		end
	end

	table.sort(found, function(a,b) return a.Name:lower() < b.Name:lower() end)
	local shown = 0
	for i, model in ipairs(found) do
		if UT.cancelHeavyWork then break end
		if i > llCap(LL_ENTITY_CAP) then break end
		if UT.lowLagMode and i % (UT.potatoMode and 8 or 20) == 0 then RunService.Heartbeat:Wait() end
		local path = model:GetFullName()
		if #path > 35 then path = "..." .. path:sub(-32) end
		local hp = ""
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then hp = " [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]" end
		makeEntityBtn(path .. hp, model)
		table.insert(foundEntities, model)
		createEntityDrawing(model)
		shown = i
	end
	if UT.cancelHeavyWork then
		eStatus.Text = "Entity scan stopped because lag was detected. Rescan after recovery."
		UT.finishHeavyWork()
		return
	end
	eStatus.Text = "Found " .. shown .. (shown < #found and (" / " .. #found .. " (lag cap)") or " entities")
	notify("Entities", "Found " .. shown .. " entities")

	-- Auto-enable ESP if drawings were created
	if shown > 0 and drawingSupported then
		entityEspEnabled = true
		eEspBtn.Text = "ESP: ON"
		eEspBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
		notify("Entity ESP", "Auto-enabled (" .. shown .. " entities)")
	end
	UT.finishHeavyWork()
end

local entityScanBusy = false
eScan.MouseButton1Click:Connect(function()
	if entityScanBusy then return end
	entityScanBusy = true
	eScan.Text = "Scanning..."
	eScan.Active = false
	task.spawn(function()
		local ok, err = pcall(scanEntities)
		if not ok then
			eStatus.Text = "Entity scan failed: " .. tostring(err)
			UT.finishHeavyWork()
		end
		entityScanBusy = false
		eScan.Text = "Scan"
		eScan.Active = true
	end)
end)
eClear.MouseButton1Click:Connect(clearEntities)

eHitboxBtn.MouseButton1Click:Connect(function()
	for _, model in ipairs(foundEntities) do
		expandEntityHitbox(model)
	end
	notify("Hitbox", "Expanded all " .. #foundEntities .. " entities")
end)

eEspBtn.MouseButton1Click:Connect(function()
	entityEspEnabled = not entityEspEnabled
	eEspBtn.Text = "ESP: " .. (entityEspEnabled and "ON" or "OFF")
	eEspBtn.TextColor3 = entityEspEnabled and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
	if not entityEspEnabled then
		for _, d in pairs(UT.entityDrawings) do
			d.Box.Visible = false
			d.Name.Visible = false
			d.Tracer.Visible = false
		end
	end
	notify("Entity ESP", entityEspEnabled and "Enabled" or "Disabled")
end)

repelBtn.MouseButton1Click:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then notify("Repel", "No character"); return end
	local count = 0
	for _, model in ipairs(foundEntities) do
		local target = getEntityPrimaryPart(model)
		if target and target.Parent then
			local offset = target.Position - hrp.Position
			if offset.Magnitude < 60 then
				local dir = offset.Magnitude > 0.1 and offset.Unit or Vector3.new(0, 0, 1)
				pcall(function()
					target.CFrame = CFrame.new(hrp.Position + dir * 80)
					target.AssemblyLinearVelocity = dir * 200
				end)
				count = count + 1
			end
		end
	end
	notify("Repel", "Pushed " .. count .. " entities away")
end)

eSearch:GetPropertyChangedSignal("Text"):Connect(function()
	local text = eSearch.Text:lower()
	for _, row in ipairs(eButtons) do
		local nameBtn = row:FindFirstChildOfClass("TextButton")
		if nameBtn then
			row.Visible = text == "" or nameBtn.Text:lower():find(text, 1, true) ~= nil
		end
	end
end)

-- export for cleanup.lua render loop
UT.updateEntityEsp = updateEntityEsp
