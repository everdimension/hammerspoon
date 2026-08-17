hs.loadSpoon("WinWin")

if spoon.WinWin then
  local resizeKeys = {"cmd", "ctrl"}
  local moveKeys = {"cmd", "ctrl", "shift"}
  local directions = {
    {name = "up", key = "K"},
    {name = "down", key = "J"},
    {name = "left", key = "H"},
    {name = "right", key = "L"},
  }

  for _, direction in ipairs(directions) do
    local name = direction.name
    local key = direction.key

    hs.hotkey.bind(moveKeys, key, function()
      spoon.WinWin:stepMove(name)
    end)
    hs.hotkey.bind(resizeKeys, key, function()
      spoon.WinWin:stepResize(name)
    end)
  end
end

local LayoutPair = require("layout_pair")
local browserTerminalPair = LayoutPair.new({
  leftApps = {
    "Arc",
    "Brave Browser",
    "Firefox",
    "Google Chrome",
    "Safari",
  },
  rightApps = {
    "Alacritty",
    "Ghostty",
    "iTerm2",
    "kitty",
    "Terminal",
    "Warp",
    "WezTerm",
  },
  raiseBehindApps = {
    "Zed",
  },
  leftLabel = "Browser",
  missingMessage = "Open a visible browser and terminal first",
  initialSplit = 0.65,
  minimumSplit = 0.25,
  maximumSplit = 0.75,
  gap = 8,
})

local pairKeys = {"ctrl", "cmd"}
hs.hotkey.bind(pairKeys, "T", function()
  browserTerminalPair:toggle()
end)
hs.hotkey.bind(pairKeys, "[", function()
  browserTerminalPair:adjustSplit(-0.05)
end)
hs.hotkey.bind(pairKeys, "]", function()
  browserTerminalPair:adjustSplit(0.05)
end)
hs.hotkey.bind(pairKeys, "R", function()
  browserTerminalPair:toggleZoom()
end)

local function toggleMinimizeOtherWindows()
  local focused = hs.window.focusedWindow()
  local app = focused and focused:application() or hs.application.frontmostApplication()
  if not app then
    hs.alert.show("No active application")
    return
  end

  local focusedID = focused and focused:id()
  local visible = {}
  local minimized = {}

  for _, window in ipairs(app:allWindows()) do
    if window:isStandard() and not window:isFullScreen() and window:id() ~= focusedID then
      if window:isMinimized() then
        table.insert(minimized, window)
      else
        table.insert(visible, window)
      end
    end
  end

  if #visible > 0 then
    for _, window in ipairs(visible) do
      window:minimize()
    end
    hs.alert.show(string.format("%s: only this window", app:name()))
    return
  end

  if #minimized > 0 then
    for _, window in ipairs(minimized) do
      window:unminimize()
    end
    hs.alert.show(string.format("%s: restored %d window%s", app:name(), #minimized, #minimized == 1 and "" or "s"))
    return
  end

  hs.alert.show(string.format("%s: no other windows", app:name()))
end

hs.hotkey.bind({"ctrl", "cmd"}, "O", toggleMinimizeOtherWindows)

hs.hotkey.bind({"ctrl", "cmd"}, "f12", function()
  hs.execute("~/darkmode.sh")
end)

-- Reload config.
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
hs.alert.show("Config loaded")

-- Sleep.
hs.hotkey.bind({}, "f10", function()
  hs.caffeinate.systemSleep()
end)

local function dismissVisibleBanners()
  local script = [[
    tell application "System Events"
      tell process "NotificationCenter"
        try
          set _groups to groups of UI element 1 of scroll area 1 of group 1 of window "Notification Center"

          repeat with _group in _groups
            set _actions to actions of _group

            repeat with _action in _actions
              if description of _action is in {"Close All", "Close"} then
                perform _action
              end if
            end repeat
          end repeat
        end try

        key code 53 -- Escape as fallback
      end tell
    end tell
  ]]
  local ok, result = hs.osascript.applescript(script)
  print("ok:", ok, "result:", hs.inspect(result))
end

hs.hotkey.bind({"cmd", "ctrl"}, "D", dismissVisibleBanners)

-- Turn off the screen immediately.
hs.hotkey.bind({"ctrl", "cmd"}, "q", function()
  hs.execute("/usr/bin/pmset displaysleepnow", false)
end)
