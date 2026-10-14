-- ============================================================
-- tab_security.lua - static dependency and loading audit
-- ============================================================
local UT = ...
local frame = UT.tabFrames.Security
local runService = UT.RunService

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 20)
title.Position = UDim2.new(0, 6, 0, 2)
title.BackgroundTransparency = 1
title.Text = "Project Security Auditor"
title.TextColor3 = Color3.fromRGB(230, 230, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local description = Instance.new("TextLabel")
description.Size = UDim2.new(1, -12, 0, 28)
description.Position = UDim2.new(0, 6, 0, 23)
description.BackgroundTransparency = 1
description.Text = "Static scan of loaded module text. Findings are indicators, not proof of malicious behavior."
description.TextColor3 = Color3.fromRGB(165, 165, 172)
description.Font = Enum.Font.Gotham
description.TextSize = 10
description.TextWrapped = true
description.TextXAlignment = Enum.TextXAlignment.Left
description.Parent = frame

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, 112, 0, 24)
scanButton.Position = UDim2.new(0, 6, 0, 56)
scanButton.Text = "Scan modules"
scanButton.TextColor3 = Color3.new(1, 1, 1)
scanButton.BackgroundColor3 = Color3.fromRGB(120, 82, 28)
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 10
scanButton.Parent = frame
Instance.new("UICorner", scanButton).CornerRadius = UDim.new(0, 4)
if type(UT.addTooltip) == "function" then
	UT.addTooltip(scanButton, "Inspect loaded source text only. Discovered URLs and loader calls are never executed.")
end

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -132, 0, 24)
status.Position = UDim2.new(0, 124, 0, 56)
status.BackgroundTransparency = 1
status.Text = "Not scanned"
status.TextColor3 = Color3.fromRGB(190, 190, 196)
status.Font = Enum.Font.Gotham
status.TextSize = 10
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local results = Instance.new("ScrollingFrame")
results.Name = "AuditResults"
results.Size = UDim2.new(1, -12, 1, -92)
results.Position = UDim2.new(0, 6, 0, 86)
results.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
results.BorderSizePixel = 0
results.ScrollBarThickness = 5
results.AutomaticCanvasSize = Enum.AutomaticSize.Y
results.CanvasSize = UDim2.new(0, 0, 0, 0)
results.Parent = frame
Instance.new("UICorner", results).CornerRadius = UDim.new(0, 4)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = results

local function clearResults()
	for _, child in ipairs(results:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end
end

local function addFinding(moduleName, lineNumber, kind, lineText, order)
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -8, 0, 48)
	row.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	row.BorderSizePixel = 0
	row.TextColor3 = Color3.fromRGB(225, 225, 230)
	row.Font = Enum.Font.Code
	row.TextSize = 10
	row.TextWrapped = true
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextYAlignment = Enum.TextYAlignment.Top
	row.LayoutOrder = order
	row.Text = string.format("[%s] %s:%d\n%s", kind, moduleName, lineNumber, lineText:sub(1, 180))
	row.Parent = results
end

local function scanSources()
	clearResults()
	local sources = UT.moduleSources or {}
	local moduleNames = {}
	for name, source in pairs(sources) do
		if type(name) == "string" and type(source) == "string" then
			table.insert(moduleNames, name)
		end
	end
	table.sort(moduleNames)
	if #moduleNames == 0 then
		status.Text = "No module source has been captured yet."
		return
	end

	local findingCount = 0
	local lineCount = 0
	local maxFindings = 80
	for _, moduleName in ipairs(moduleNames) do
		local lineNumber = 0
		for lineText in (sources[moduleName] .. "\n"):gmatch("(.-)\n") do
			lineNumber = lineNumber + 1
			lineCount = lineCount + 1
			local lowered = lineText:lower()
			local kind
			if lowered:find("https://", 1, true) or lowered:find("http://", 1, true) then
				kind = "External URL"
			elseif lowered:find("loadstring", 1, true) then
				kind = "Dynamic code"
			elseif lowered:match("require%s*%(%s*%d+") then
				kind = "Asset require"
			elseif lowered:find("httpget", 1, true) then
				kind = "HTTP fetch"
			end
			if kind then
				findingCount = findingCount + 1
				addFinding(moduleName, lineNumber, kind, lineText, findingCount)
				if findingCount >= maxFindings then break end
			end
			if lineCount % 300 == 0 then
				if UT.lagYield then UT.lagYield() else runService.Heartbeat:Wait() end
			end
		end
		if findingCount >= maxFindings then break end
	end
	if findingCount == 0 then
		addFinding("Audit", 0, "Clear", "No matching external URL, HTTP fetch, dynamic loader, or numeric asset require was found.", 1)
	end
	status.Text = string.format("Scanned %d modules; %d indicator(s).", #moduleNames, findingCount)
end

scanButton.MouseButton1Click:Connect(function()
	if scanButton:GetAttribute("Scanning") then return end
	scanButton:SetAttribute("Scanning", true)
	scanButton.Text = "Scanning..."
	task.spawn(function()
		local ok, err = pcall(scanSources)
		if not ok then status.Text = "Scan failed: " .. tostring(err) end
		scanButton:SetAttribute("Scanning", false)
		scanButton.Text = "Scan modules"
	end)
end)