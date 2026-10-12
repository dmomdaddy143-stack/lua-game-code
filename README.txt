ULTIMATE TOOLKIT v5++ - SPLIT FILE SETUP
==========================================

FILES
  main.lua          - the loader (this is what you paste into your executor)
  core.lua          - GUI, tab bar, dropdown component, shared helpers (ALWAYS loads first)
  tab_remotes.lua   - Remotes tab
  tab_items.lua     - Items tab + saved items system
  tab_players.lua   - Players tab + spectate
  tab_move.lua      - Move tab + 30 noclip methods
  tab_entities.lua  - Entities tab + ESP
  tab_visuals.lua   - Visuals tab + player ESP
  tab_misc.lua      - Misc tab + lag spike
  tab_map.lua       - Map/minimap tab + interactables
  tab_bring.lua     - Bring tab + target, item whitelist, and range controls
  cleanup.lua       - render loops + X button teardown (ALWAYS loads last)

SETUP (GitHub)
  1. Create a GitHub repo (must be PUBLIC).
  2. Upload ALL the .lua files to the repo root.
  3. Open main.lua and replace:
        https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/
     with your real raw URL, e.g.:
        https://raw.githubusercontent.com/cooluser/coolscripts/main/
  4. Paste main.lua into your executor and run it.
    5. During module loading, press Shift+X to choose tabs. Test mode loads one selected tab;
      Potato mode enables reduced scan caps and yields for lower startup load.
        Press Shift+Q during startup to enable Safe Mode for incremental, capped scans.

HOW IT WORKS
  - main.lua loads each file IN ORDER and hands it a shared table (UT).
  - To edit ONE tab, edit that ONE file, commit, re-run main.lua. Done.
  - Never rename core.lua / cleanup.lua or change the order in FILES.
  - GitHub raw has a CDN cache: changes can take 2-5 minutes to show up.

MAKING A NEW TAB FILE
  Copy any tab_*.lua header block (the local UT = ... aliases at the top).
  Add your file name to the FILES list in main.lua (before cleanup.lua).
  Create its tab container in core.lua's tabList if it needs a new tab.
