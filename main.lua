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

for _, name in ipairs(FILES) do
	local ok, err = pcall(function()
		local src = fetchSource(name)
		local chunk, loadErr = loadstring(src, name)
		if not chunk then
			error("SYNTAX: " .. tostring(loadErr))
		end
		chunk(UT)
	end)
	if not ok then
		notify("Load Failed: " .. name, tostring(err))
		error("UltimateToolkit failed at " .. name .. ": " .. tostring(err))
	end
end

loaderReady = true
notify("Ultimate Toolkit", "All modules loaded!")
