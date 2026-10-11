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
	"cleanup.lua",
}

local UT = {}

local function notify(t, m)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = t, Text = m, Duration = 4})
	end)
end

local function fetchSource(name)
	-- local-file fallback for executors that support it (same folder as this script)
	if isfile and pcall(isfile, name) and isfile(name) then
		return readfile(name)
	end
	return game:HttpGet(BASE_URL .. name)
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

notify("Ultimate Toolkit", "All modules loaded!")
