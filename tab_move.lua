-- ============================================================
-- tab_move.lua - Speed/fly/noclip x30  (loaded by main.lua - do not run directly)
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
-- MOVE TAB - 30 Noclip Methods + Speed/Jump/Fly
-- ============================================
local mFrame = tabFrames.Move

local speedLbl = Instance.new("TextLabel")
speedLbl.Size = UDim2.new(1, 0, 0, 16)
speedLbl.Text = "Walk Speed"
speedLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
speedLbl.BackgroundTransparency = 1
speedLbl.Font = Enum.Font.Gotham
speedLbl.TextSize = 10
speedLbl.Parent = mFrame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(1, -80, 0, 22)
speedBox.Position = UDim2.new(0, 0, 0, 16)
speedBox.Text = "50"
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 11
speedBox.Parent = mFrame
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 4)

local defaultSpeedButton = Instance.new("TextButton")
defaultSpeedButton.Size = UDim2.new(0, 72, 0, 22)
defaultSpeedButton.Position = UDim2.new(1, -72, 0, 16)
defaultSpeedButton.Text = "Default"
defaultSpeedButton.TextColor3 = Color3.new(1, 1, 1)
defaultSpeedButton.BackgroundColor3 = Color3.fromRGB(45, 65, 55)
defaultSpeedButton.Font = Enum.Font.GothamBold
defaultSpeedButton.TextSize = 10
defaultSpeedButton.Parent = mFrame
Instance.new("UICorner", defaultSpeedButton).CornerRadius = UDim.new(0, 4)

local jumpLbl = Instance.new("TextLabel")
jumpLbl.Size = UDim2.new(1, 0, 0, 16)
jumpLbl.Position = UDim2.new(0, 0, 0, 44)
jumpLbl.Text = "Jump Power"
jumpLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
jumpLbl.BackgroundTransparency = 1
jumpLbl.Font = Enum.Font.Gotham
jumpLbl.TextSize = 10
jumpLbl.Parent = mFrame

local jumpBox = Instance.new("TextBox")
jumpBox.Size = UDim2.new(1, -80, 0, 22)
jumpBox.Position = UDim2.new(0, 0, 0, 60)
jumpBox.Text = "50"
jumpBox.TextColor3 = Color3.new(1,1,1)
jumpBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
jumpBox.Font = Enum.Font.Gotham
jumpBox.TextSize = 11
jumpBox.Parent = mFrame
Instance.new("UICorner", jumpBox).CornerRadius = UDim.new(0, 4)

local defaultJumpButton = Instance.new("TextButton")
defaultJumpButton.Size = UDim2.new(0, 72, 0, 22)
defaultJumpButton.Position = UDim2.new(1, -72, 0, 60)
defaultJumpButton.Text = "Default"
defaultJumpButton.TextColor3 = Color3.new(1, 1, 1)
defaultJumpButton.BackgroundColor3 = Color3.fromRGB(45, 65, 55)
defaultJumpButton.Font = Enum.Font.GothamBold
defaultJumpButton.TextSize = 10
defaultJumpButton.Parent = mFrame
Instance.new("UICorner", defaultJumpButton).CornerRadius = UDim.new(0, 4)

local defaultWalkSpeed = 16
local defaultJumpPower = 50
local defaultJumpHeight = 7.2
local function captureDefaultStats(humanoid)
	defaultWalkSpeed = humanoid.WalkSpeed
	defaultJumpPower = humanoid.JumpPower
	defaultJumpHeight = humanoid.JumpHeight
end

local function applyStats()
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			local s = tonumber(speedBox.Text)
			local j = tonumber(jumpBox.Text)
			if s then hum.WalkSpeed = s end
			if j then
				if hum.UseJumpPower then hum.JumpPower = j else hum.JumpHeight = j end
			end
		end
	end
end

local function resetWalkSpeed()
	speedBox.Text = tostring(defaultWalkSpeed)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = defaultWalkSpeed end
end

local function resetJump()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local defaultJump = humanoid and humanoid.UseJumpPower and defaultJumpPower or defaultJumpHeight
	jumpBox.Text = tostring(defaultJump)
	if humanoid then
		if humanoid.UseJumpPower then humanoid.JumpPower = defaultJumpPower else humanoid.JumpHeight = defaultJumpHeight end
	end
end

defaultSpeedButton.MouseButton1Click:Connect(resetWalkSpeed)
defaultJumpButton.MouseButton1Click:Connect(resetJump)

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	captureDefaultStats(humanoid)
	speedBox.Text = tostring(defaultWalkSpeed)
	jumpBox.Text = tostring(humanoid.UseJumpPower and defaultJumpPower or defaultJumpHeight)
end

local initialHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
if initialHumanoid then
	captureDefaultStats(initialHumanoid)
	jumpBox.Text = tostring(initialHumanoid.UseJumpPower and defaultJumpPower or defaultJumpHeight)
end
UT.statsCharacterConn = player.CharacterAdded:Connect(onCharacterAdded)

speedBox.FocusLost:Connect(applyStats)
jumpBox.FocusLost:Connect(applyStats)

UT.statsConn = RunService.Heartbeat:Connect(function()
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			local s = tonumber(speedBox.Text)
			local j = tonumber(jumpBox.Text)
			if s and hum.WalkSpeed ~= s then hum.WalkSpeed = s end
			if j then
				if hum.UseJumpPower and hum.JumpPower ~= j then hum.JumpPower = j end
				if not hum.UseJumpPower and hum.JumpHeight ~= j then hum.JumpHeight = j end
			end
		end
	end
end)

-- CFrame Speed
UT.cframeSpeedConn = nil
makeToggle(mFrame, "CFrame Speed", 90, function(enabled)
	if enabled then
		UT.cframeSpeedConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum then return end
			if hum.MoveDirection.Magnitude > 0 then
				local s = tonumber(speedBox.Text) or 50
				hrp.CFrame = hrp.CFrame + (hum.MoveDirection * s * 0.02)
			end
		end)
	else
		if UT.cframeSpeedConn then UT.cframeSpeedConn:Disconnect(); UT.cframeSpeedConn = nil end
	end
end)

-- Fly
UT.flyConn = nil
local flyBV = nil
local flyBG = nil
makeToggle(mFrame, "Fly", 120, function(enabled)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if enabled and hrp then
		flyBV = Instance.new("BodyVelocity")
		flyBV.MaxForce = Vector3.new(9e4, 9e4, 9e4)
		flyBV.Velocity = Vector3.zero
		flyBV.Parent = hrp
		flyBG = Instance.new("BodyGyro")
		flyBG.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
		flyBG.CFrame = hrp.CFrame
		flyBG.Parent = hrp
		UT.flyConn = RunService.RenderStepped:Connect(function()
			if not hrp or not flyBV or not flyBG then return end
			local dir = Vector3.zero
			local look = camera.CFrame.LookVector
			local right = camera.CFrame.RightVector
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
			local s = tonumber(speedBox.Text) or 50
			if dir.Magnitude > 0.01 then dir = dir.Unit * s else dir = Vector3.zero end
			flyBV.Velocity = dir
			flyBG.CFrame = camera.CFrame
		end)
	else
		if UT.flyConn then UT.flyConn:Disconnect(); UT.flyConn = nil end
		if flyBV then flyBV:Destroy(); flyBV = nil end
		if flyBG then flyBG:Destroy(); flyBG = nil end
	end
end)

-- Inf Jump
local infJump = false
UserInputService.JumpRequest:Connect(function()
	if infJump then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)
makeToggle(mFrame, "Inf Jump", 150, function(enabled)
	infJump = enabled
end)

-- God Mode
makeToggle(mFrame, "God Mode", 180, function(enabled)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if enabled and hum then
		hum.Health = hum.MaxHealth
		hum:GetPropertyChangedSignal("Health"):Connect(function()
			if hum and hum.Health < hum.MaxHealth then
				hum.Health = hum.MaxHealth
			end
		end)
	end
end)

-- No Fall
makeToggle(mFrame, "No Fall", 210, function(enabled)
	if enabled then
		RunService.Heartbeat:Connect(function()
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum:GetState() == Enum.HumanoidStateType.Freefall then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end
end)

-- ============================================
-- 30 NOCCLIP METHODS
-- ============================================
local noclipConns = {}
local noclipOriginals = {}

local function clearNoclip()
	for i = 1, 30 do
		if noclipConns[i] then noclipConns[i]:Disconnect(); noclipConns[i] = nil end
	end
	-- Restore originals for methods that need it
	for part, data in pairs(noclipOriginals) do
		if part and part.Parent then
			if data.CanCollide ~= nil then part.CanCollide = data.CanCollide end
			if data.Size then part.Size = data.Size end
			if data.Transparency ~= nil then part.Transparency = data.Transparency end
			if data.Massless ~= nil then part.Massless = data.Massless end
		end
	end
	noclipOriginals = {}
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = false
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum.Sit = false
			hum.AutoRotate = true
		end
	end
	workspace.Gravity = 196.2
end

local noclipMethods = {
	"Noclip 1: Stepped CanCollide",
	"Noclip 2: Heartbeat CanCollide",
	"Noclip 3: RenderStepped CanCollide",
	"Noclip 4: Stepped + Transparency",
	"Noclip 5: CollisionGroup",
	"Noclip 6: PlatformStand",
	"Noclip 7: BodyVelocity Push",
	"Noclip 8: BodyPosition Float",
	"Noclip 9: CFrame Teleport",
	"Noclip 10: Velocity Bypass",
	"Noclip 11: Massless Parts",
	"Noclip 12: Humanoid Sit",
	"Noclip 13: GettingUp State",
	"Noclip 14: Jumping State",
	"Noclip 15: Freefall State",
	"Noclip 16: Tween CFrame",
	"Noclip 17: HipHeight Max",
	"Noclip 18: RootPart Anchored Flash",
	"Noclip 19: WalkSpeed 0 + Fly",
	"Noclip 20: AssemblyVelocity",
	"Noclip 21: AssemblyAngularVelocity",
	"Noclip 22: Zero Gravity",
	"Noclip 23: AutoRotate False",
	"Noclip 24: Part Resize Small",
	"Noclip 25: Part Resize Big",
	"Noclip 26: Network Ownership",
	"Noclip 27: Stepped + Size Reset",
	"Noclip 28: Heartbeat + Size Reset",
	"Noclip 29: Combined Method A",
	"Noclip 30: Combined Method B",
}

-- Collapsible dropdown section for the 30 noclip methods
local noclipSectionOpen = false
local noclipSectionHeader = Instance.new("TextButton")
noclipSectionHeader.Size = UDim2.new(1, 0, 0, 22)
noclipSectionHeader.Position = UDim2.new(0, 0, 0, 240)
noclipSectionHeader.Text = "Noclip Methods (30)  v"
noclipSectionHeader.TextColor3 = Color3.fromRGB(0, 255, 100)
noclipSectionHeader.BackgroundColor3 = Color3.fromRGB(25, 45, 32)
noclipSectionHeader.Font = Enum.Font.GothamBold
noclipSectionHeader.TextSize = 11
noclipSectionHeader.Parent = mFrame
Instance.new("UICorner", noclipSectionHeader).CornerRadius = UDim.new(0, 4)

local noclipContainer = Instance.new("ScrollingFrame")
noclipContainer.Size = UDim2.new(1, 0, 0, 230)
noclipContainer.Position = UDim2.new(0, 0, 0, 266)
noclipContainer.BackgroundTransparency = 1
noclipContainer.BorderSizePixel = 0
noclipContainer.ScrollBarThickness = 5
noclipContainer.ScrollingDirection = Enum.ScrollingDirection.Y
noclipContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
noclipContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
noclipContainer.Visible = false
noclipContainer.Parent = mFrame

noclipSectionHeader.MouseButton1Click:Connect(function()
	noclipSectionOpen = not noclipSectionOpen
	noclipContainer.Visible = noclipSectionOpen
	noclipSectionHeader.Text = "Noclip Methods (30)  " .. (noclipSectionOpen and "^" or "v")
end)
local noclipBtns = {}
for idx, name in ipairs(noclipMethods) do
	local ncol = (idx - 1) % 3
	local nrow = math.floor((idx - 1) / 3)
	local btn
	btn = makeToggle(noclipContainer, name, 0, function(enabled)
		if enabled then
			-- Visually reset all other noclip toggles
			for i2, other in ipairs(noclipBtns) do
				if other ~= btn then
					UT.setButtonToggle(other, false)
				end
			end
			clearNoclip()

			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if idx == 1 then -- Stepped CanCollide
				noclipConns[1] = RunService.Stepped:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide = false end
						end
					end
				end)

			elseif idx == 2 then -- Heartbeat CanCollide
				noclipConns[2] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide = false end
						end
					end
				end)

			elseif idx == 3 then -- RenderStepped CanCollide
				noclipConns[3] = RunService.RenderStepped:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide = false end
						end
					end
				end)

			elseif idx == 4 then -- Stepped + Transparency
				noclipConns[4] = RunService.Stepped:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then
								if not noclipOriginals[part] then noclipOriginals[part] = {CanCollide = part.CanCollide, Transparency = part.Transparency} end
								part.CanCollide = false
								part.Transparency = 0.5
							end
						end
					end
				end)

			elseif idx == 5 then -- CollisionGroup
				pcall(function()
					PhysicsService:CreateCollisionGroup("NoclipGroup")
					PhysicsService:CollisionGroupSetCollidable("NoclipGroup", "Default", false)
				end)
				noclipConns[5] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then
								pcall(function() PhysicsService:SetPartCollisionGroup(part, "NoclipGroup") end)
							end
						end
					end
				end)

			elseif idx == 6 then -- PlatformStand
				if hum then
					hum.PlatformStand = true
					noclipConns[6] = RunService.Heartbeat:Connect(function()
						if hum then hum.PlatformStand = true end
					end)
				end

			elseif idx == 7 then -- BodyVelocity Push
				if hrp then
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.new(9e4, 0, 9e4)
					bv.Velocity = Vector3.zero
					bv.Parent = hrp
					noclipConns[7] = RunService.Heartbeat:Connect(function()
						if hrp and bv then
							local c = player.Character
							if c then
								for _, part in ipairs(c:GetDescendants()) do
									if part:IsA("BasePart") then part.CanCollide = false end
								end
							end
						end
					end)
					noclipOriginals["bv7"] = bv
				end

			elseif idx == 8 then -- BodyPosition Float
				if hrp then
					local bp = Instance.new("BodyPosition")
					bp.MaxForce = Vector3.new(9e4, 9e4, 9e4)
					bp.Position = hrp.Position
					bp.Parent = hrp
					noclipConns[8] = RunService.Heartbeat:Connect(function()
						if hrp and bp then
							bp.Position = hrp.Position
							local c = player.Character
							if c then
								for _, part in ipairs(c:GetDescendants()) do
									if part:IsA("BasePart") then part.CanCollide = false end
								end
							end
						end
					end)
					noclipOriginals["bp8"] = bp
				end

			elseif idx == 9 then -- CFrame Teleport
				noclipConns[9] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local h = c and c:FindFirstChild("HumanoidRootPart")
					local hm = c and c:FindFirstChildOfClass("Humanoid")
					if h and hm and hm.MoveDirection.Magnitude > 0 then
						h.CFrame = h.CFrame + hm.MoveDirection * 2
					end
				end)

			elseif idx == 10 then -- Velocity Bypass
				noclipConns[10] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local h = c and c:FindFirstChild("HumanoidRootPart")
					if h then
						h.Velocity = h.Velocity + Vector3.new(0, 0.1, 0)
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide = false end
						end
					end
				end)

			elseif idx == 11 then -- Massless Parts
				noclipConns[11] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then
								if not noclipOriginals[part] then noclipOriginals[part] = {Massless = part.Massless} end
								part.Massless = true
								part.CanCollide = false
							end
						end
					end
				end)

			elseif idx == 12 then -- Humanoid Sit
				if hum then
					hum.Sit = true
					noclipConns[12] = RunService.Heartbeat:Connect(function()
						if hum then hum.Sit = true end
					end)
				end

			elseif idx == 13 then -- GettingUp State
				noclipConns[13] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local hm = c and c:FindFirstChildOfClass("Humanoid")
					if hm then hm:ChangeState(Enum.HumanoidStateType.GettingUp) end
				end)

			elseif idx == 14 then -- Jumping State
				noclipConns[14] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local hm = c and c:FindFirstChildOfClass("Humanoid")
					if hm then hm:ChangeState(Enum.HumanoidStateType.Jumping) end
				end)

			elseif idx == 15 then -- Freefall State
				noclipConns[15] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local hm = c and c:FindFirstChildOfClass("Humanoid")
					if hm then hm:ChangeState(Enum.HumanoidStateType.Freefall) end
				end)

			elseif idx == 16 then -- Tween CFrame
				noclipConns[16] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local h = c and c:FindFirstChild("HumanoidRootPart")
					local hm = c and c:FindFirstChildOfClass("Humanoid")
					if h and hm and hm.MoveDirection.Magnitude > 0 then
						local goal = h.CFrame + hm.MoveDirection * 1.5
						pcall(function() TweenService:Create(h, TweenInfo.new(0.05), {CFrame = goal}):Play() end)
					end
				end)

			elseif idx == 17 then -- HipHeight Max
				if hum then
					hum.HipHeight = 50
					noclipConns[17] = RunService.Heartbeat:Connect(function()
						if hum then hum.HipHeight = 50 end
					end)
				end

			elseif idx == 18 then -- RootPart Anchored Flash
				noclipConns[18] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local h = c and c:FindFirstChild("HumanoidRootPart")
					if h then
						h.Anchored = true
						task.wait(0.01)
						h.Anchored = false
					end
				end)

			elseif idx == 19 then -- WalkSpeed 0 + Fly
				if hum then hum.WalkSpeed = 0 end
				if hrp then
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
					bv.Velocity = Vector3.zero
					bv.Parent = hrp
					noclipOriginals["bv19"] = bv
					noclipConns[19] = RunService.RenderStepped:Connect(function()
						if hrp and bv then
							local dir = Vector3.zero
							if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
							if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
							if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
							bv.Velocity = dir * 50
						end
					end)
				end

			elseif idx == 20 then -- AssemblyVelocity
				noclipConns[20] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local h = c and c:FindFirstChild("HumanoidRootPart")
					if h then
						h.AssemblyLinearVelocity = Vector3.new(0, 0.1, 0)
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide = false end
						end
					end
				end)

			elseif idx == 21 then -- AssemblyAngularVelocity
				noclipConns[21] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local h = c and c:FindFirstChild("HumanoidRootPart")
					if h then
						h.AssemblyAngularVelocity = Vector3.new(0, 0.1, 0)
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide = false end
						end
					end
				end)

			elseif idx == 22 then -- Zero Gravity
				workspace.Gravity = 0
				noclipConns[22] = RunService.Heartbeat:Connect(function()
					workspace.Gravity = 0
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide = false end
						end
					end
				end)

			elseif idx == 23 then -- AutoRotate False
				if hum then hum.AutoRotate = false end
				noclipConns[23] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local h = c and c:FindFirstChild("HumanoidRootPart")
					local hm = c and c:FindFirstChildOfClass("Humanoid")
					if h and hm then
						hm.AutoRotate = false
						if hm.MoveDirection.Magnitude > 0 then
							h.CFrame = h.CFrame + hm.MoveDirection * 0.5
						end
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then part.CanCollide = false end
						end
					end
				end)

			elseif idx == 24 then -- Part Resize Small
				noclipConns[24] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
								if not noclipOriginals[part] then noclipOriginals[part] = {Size = part.Size, CanCollide = part.CanCollide} end
								part.Size = Vector3.new(0.1, 0.1, 0.1)
								part.CanCollide = false
							end
						end
					end
				end)

			elseif idx == 25 then -- Part Resize Big
				noclipConns[25] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then
								if not noclipOriginals[part] then noclipOriginals[part] = {Size = part.Size, CanCollide = part.CanCollide} end
								part.Size = Vector3.new(10, 10, 10)
								part.CanCollide = false
							end
						end
					end
				end)

			elseif idx == 26 then -- Network Ownership
				noclipConns[26] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then
								pcall(function() part:SetNetworkOwner(player) end)
								part.CanCollide = false
							end
						end
					end
				end)

			elseif idx == 27 then -- Stepped + Size Reset
				noclipConns[27] = RunService.Stepped:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then
								part.CanCollide = false
								if part.Size.Y > 5 then
									if not noclipOriginals[part] then noclipOriginals[part] = {Size = part.Size} end
									part.Size = Vector3.new(2, 2, 2)
								end
							end
						end
					end
				end)

			elseif idx == 28 then -- Heartbeat + Size Reset
				noclipConns[28] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then
								part.CanCollide = false
								if part.Size.Y > 5 then
									if not noclipOriginals[part] then noclipOriginals[part] = {Size = part.Size} end
									part.Size = Vector3.new(2, 2, 2)
								end
							end
						end
					end
				end)

			elseif idx == 29 then -- Combined Method A
				if hum then hum.PlatformStand = true end
				if hrp then
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
					bv.Velocity = Vector3.zero
					bv.Parent = hrp
					noclipOriginals["bv29"] = bv
				end
				noclipConns[29] = RunService.Stepped:Connect(function()
					local c = player.Character
					if c then
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then
								part.CanCollide = false
								part.Massless = true
							end
						end
					end
				end)

			elseif idx == 30 then -- Combined Method B
				workspace.Gravity = 0
				if hum then
					hum.AutoRotate = false
					hum.Sit = true
				end
				noclipConns[30] = RunService.Heartbeat:Connect(function()
					local c = player.Character
					local h = c and c:FindFirstChild("HumanoidRootPart")
					local hm = c and c:FindFirstChildOfClass("Humanoid")
					if h and hm then
						if hm.MoveDirection.Magnitude > 0 then
							h.CFrame = h.CFrame + hm.MoveDirection * 0.8
						end
						for _, part in ipairs(c:GetDescendants()) do
							if part:IsA("BasePart") then
								part.CanCollide = false
								part.Massless = true
							end
						end
					end
				end)
			end

			notify("Noclip", "Method " .. idx .. " enabled")
		else
			clearNoclip()
			notify("Noclip", "All methods disabled")
		end
	end, UDim2.new(0.325, 0, 0, 22), UDim2.new(0, ncol * 0.3375, 0, nrow * 24))
	noclipBtns[idx] = btn
end

-- Auto-disable noclip + all toggles on death (fixes stuck settings)
player.CharacterAdded:Connect(function()
	clearNoclip()
	resetAllToggles()
end)

-- Re-apply speed/jump on respawn
player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	local s = tonumber(speedBox.Text) or 50
	local j = tonumber(jumpBox.Text) or 50
	hum.WalkSpeed = s
	hum.JumpPower = j
end)

notify("Ultimate Toolkit", "Loaded v5+++! Lag Spike + 3-col Noclip + Reset-on-Death + Near-only X-Ray + Repel + Interactables TP + Potato Mode.")

-- export for cleanup.lua (X button)
UT.clearNoclip = clearNoclip
