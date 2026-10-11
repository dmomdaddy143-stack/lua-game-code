-- ============================================================
-- cleanup.lua - render loops + X button teardown  (loaded by main.lua - do not run directly)
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
local x = UT.closeButton
local tabFrames = UT.tabFrames
local notify = UT.notify
local makeToggle = UT.makeToggle
local resetAllToggles = UT.resetAllToggles
local lagYield = UT.lagYield
local llYieldStep = UT.llYieldStep
local llBtnStep = UT.llBtnStep
local llCap = UT.llCap

-- ============================================
-- RENDER LOOPS & CLEANUP
-- ============================================
UT.espConnection = RunService.RenderStepped:Connect(function()
	if UT.updatePlayerEsp then UT.updatePlayerEsp() end
	if UT.updateEntityEsp then UT.updateEntityEsp() end
end)

x.MouseButton1Click:Connect(function()
	if UT.espConnection then UT.espConnection:Disconnect() end
	if UT.statsConn then UT.statsConn:Disconnect() end
	if UT.cframeSpeedConn then UT.cframeSpeedConn:Disconnect() end
	if UT.flyConn then UT.flyConn:Disconnect() end
	if UT.autoFarmConn then UT.autoFarmConn:Disconnect() end
	if UT.clickTPConn then UT.clickTPConn:Disconnect() end
	if UT.antiAfkConn then UT.antiAfkConn:Disconnect() end
	if UT.autoClickConn then UT.autoClickConn:Disconnect() end
	if UT.reachConn then UT.reachConn:Disconnect() end
	if UT.xrayConn then UT.xrayConn:Disconnect() end
	UT.xrayToken = nil
	if UT.mapConn then UT.mapConn:Disconnect() end
	if UT.magnetConn then UT.magnetConn:Disconnect() end
	if UT.spectateConn then UT.spectateConn:Disconnect() end
	UT.lagSpikeOn = false
	if UT.clearNoclip then UT.clearNoclip() end
	resetAllToggles()
	for plr, objs in pairs(UT.drawings) do
		for _, obj in pairs(objs) do
			pcall(function() obj:Remove() end)
		end
	end
	for _, d in pairs(UT.entityDrawings) do
		pcall(function() d.Box:Remove() end)
		pcall(function() d.Name:Remove() end)
		pcall(function() d.Tracer:Remove() end)
	end
	UT.drawings = {}
	UT.entityDrawings = {}
	gui:Destroy()
end)
